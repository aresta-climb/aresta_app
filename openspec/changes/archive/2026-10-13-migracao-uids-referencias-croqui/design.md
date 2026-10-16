# Design: Arquitetura de Resolução por UIDs e Normalização In-Place de Croquis

## Context

A versão v5 da API Aresta (`aresta_api`) substitui identificadores locais e acoplamento por nomes textuais por UIDs descentralizados permanentes (NanoID 14c) em `Croqui`, `Botao`, `Grupo`, `Setor`, `Escalada` e `PontoDeInteresse`. O campo `indice_mapa_alvo` foi tornado `reserved 5` no Protobuf. Para detalhes motivacionais e requisitos, ver [proposal.md](proposal.md) e as especificações em `specs/`.

## Goals / Non-Goals

**Goals:**
- Isolar a compatibilidade com croquis legados em um componente de **Normalização In-Place** executado exclusivamente na leitura de arquivos ou streams de rede.
- Prover resolução de entidades (`Botao`, `Grupo`, `Setor`, `Escalada`) e seus ancestrais em $O(1)$ através do `DatasetResolver` baseado 100% em UIDs.
- Associar a cada entidade a lista pré-computada de mapas onde é desenhada, eliminando buscas lineares repetidas durante a renderização de telas e carrosséis.
- Aposentar e deletar por completo a classe `CroquiMapIndex` e a chave composta `ReferenceKey`.
- Manter a resolução de pontos de interesse (`pontos_uids` / `rotulo`) estritamente local a cada `Mapa`.
- Remover limpa e definitivamente o código dependente de `indice_mapa_alvo`.
- Implementar teste arquitetural para proibir o consumo de getters deprecados fora do normalizador.

**Non-Goals:**
- Não gerar UIDs sintéticos para botões em croquis legados (botões legados não são alvos de referências).
- Não indexar globalmente `PontoDeInteresse` ou `Mapa` no `DatasetResolver` (mantendo-os no escopo visual local de cada mapa).
- Não alterar os formatos de armazenamento SQLite de índices offline existentes.

## Decisions

### 1. Normalização In-Place no Carregamento do Croqui
- **Decisão**: Criar a classe utilitária `NormalizadorCroqui` chamada no momento em que um `Croqui` ou `Pico` é desserializado (`GerenciadorArquivosLocais`, `ServicoCroquiOnline`, `RepositorioDataset`).
  - Para `Grupo`, `Setor` e `Escalada` sem `uid`: sintetiza UIDs canônicos:
    - Grupo: `sintetico:grupo:<nome_grupo>`
    - Setor: `sintetico:setor:<grupo?>:<setor>`
    - Escalada: `sintetico:escalada:<grupo?>:<setor?>:<via>`
  - Para `PontoDeInteresse`: se `rotulo` estiver vazio e `label` existir, copia `rotulo = label`; se `uid` estiver vazio e `id` existir, copia `uid = id`.
  - Para `Referencia`: se `pontosUids` estiver vazio, copia `ref.ids`; se `alvoUid` estiver vazio, calcula o UID canônico correspondente do alvo e preenche `alvoUid`.
- **Racional**: Todo o restante da aplicação opera com a premissa de que os novos campos v5 estão garantidamente populados. Zero condicionais legadas na UI ou na navegação.

### 2. Teste de Governança Arquitetural
- **Decisão**: Adicionar teste unitário de arquitetura (`test/architecture/uso_campos_legados_croqui_test.dart`) que inspeciona o código-fonte em `frontend/lib/` (exceto `normalizador_croqui.dart` e os bindings gerados em `aresta_api/`) para validar que nenhum getter deprecado (`.label`, `.ids`, `ref.escalada`, `ref.setor`, `ref.grupo`, `.indiceMapaAlvo`) é referenciado.
- **Racional**: Assegura de forma estrita e automatizada que a dívida técnica foi 100% contida e previne regressões futuras.

### 3. Escopo Restrito do `DatasetResolver` (Entidades Lógicas)
- **Decisão**: O `DatasetResolver` indexará exclusivamente o quarteto estrutural: `Botao`, `Grupo`, `Setor` e `Escalada`.
- **Racional**: Respeita o Princípio de Simplicidade e Anti-Abstração (Princípio VI). O `DatasetResolver` cuida da hierarquia de dados e navegação; cada `Mapa` cuida de seus próprios pontos de interesse locais.

### 4. Estrutura do `ResolvedDataset` com Tipo Explícito e Referências
- **Decisão**: 
  - Adicionar o enum `TipoEntidadeResolved { botao, grupo, setor, escalada }`.
  - Adicionar a lista imutável `List<ReferenciaNoMapa> referencias` (onde `ReferenciaNoMapa` armazena `final Mapa mapa; final Mapa_Referencia referencia;`).
- **Racional**: Elimina checagens nulas ambíguas (`if (resolved.escalada != null)`) e entrega em $O(1)$ os mapas onde o alvo aparece para qualquer tela (ex: carrossel da via ou mapa do setor).

### 5. Aposentadoria Completa do `CroquiMapIndex`
- **Decisão**: Deletar `CroquiMapIndex` e `ReferenceKey` em `frontend/lib/utils/indice_mapas_croqui.dart`. As páginas que consumiam esse índice (`via_functions.dart`, `mapa_interativo.dart`) passam a ler diretamente `resolved.referencias`.
- **Racional**: `CroquiMapIndex` recalculava iterativamente todo o pico a cada renderização de página. A centralização no `DatasetResolver` reduz código duplicado, elimina chaves compostas por string e acelera o tempo de resposta da UI.

## Risks / Trade-offs

- **[Risco] Quebra de compilação com `indice_mapa_alvo` ao atualizar submódulo `aresta_api`**  
  → *Mitigação*: Remover os acessos a `ref.hasIndiceMapaAlvo()` e `ref.indiceMapaAlvo` em `mapa_interativo.dart` como parte da tarefa de atualização do submódulo, abrindo o carrossel no índice zero por padrão.
- **[Risco] Omissão de chamada do normalizador em algum ponto de entrada de dados**  
  → *Mitigação*: Centralizar a desserialização de `Croqui` e `Pico` e validar com testes de integração e teste arquitetural.

## Migration Plan

1. Atualizar o submódulo `aresta_api` para o commit `16ebee3`.
2. Implementar `NormalizadorCroqui` e seus testes unitários cobrindo todos os cenários legados.
3. Adicionar o teste arquitetural de governança contra getters deprecados.
4. Refatorar `DatasetResolver` para operar 100% sobre `uid` e alimentar `referencias`.
5. Atualizar `extrairRotuloReferencia` e `mapa_interativo.dart` para consumir exclusivamente `rotulo`, `pontosUids` e `alvoUid`.
6. Deletar `CroquiMapIndex` e atualizar `via_functions.dart` e `setor_functions.dart`.
7. Rodar suíte completa de testes com 100% de cobertura.
