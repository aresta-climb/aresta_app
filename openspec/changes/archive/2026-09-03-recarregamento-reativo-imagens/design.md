## Context

O Aresta possui um ecossistema de visualização de croquis com suporte tanto a croquis instalados offline (`/downloads`) quanto a croquis transmitidos online sob demanda (`GerenciadorSessaoOnline`). No modo experimental de desenvolvimento, o aplicativo conecta via WebSocket ao Editor Desktop e recebe notificações push de Live Reload sempre que dados ou mídias são salvos.

Embora os dados textuais fossem atualizados com sucesso, a alteração de imagens (mapas de setor, fotos embutidas em markdown ou capas) não refletia na tela aberta sem que o usuário navegasse de volta e reabrisse a aba/página. A investigação apontou três gargalos arquiteturais:
1. **Falha na recuperação de SHA-256 para croquis online**: A rotina `obterSha256DaMidia` continha uma guarda `(mapaPico == null || mapaPico.isEmpty)` que nunca era satisfeita para croquis online (pois a miniatura já ocupava o mapa), retornando `null` para qualquer outra mídia do croqui e impedindo o cache-busting `?v=<hash>`.
2. **Persistência de Texturas na GPU**: O `PaintingBinding.instance.imageCache` do Flutter retém imagens decodificadas em RAM e não era expurgado ao receber o evento de Live Reload.
3. **Ciclo de Vida do Carrossel**: O `MapasCarrosselPage` não disparava `setState()` no `didUpdateWidget`, impedindo que os filhos (`MapaInterativoPage`) fossem notificados de atualizações no croqui ativo.

## Goals / Non-Goals

**Goals:**
- Garantir a atualização visual imediata de imagens na tela ativa (sem necessidade de voltar e reabrir tela) ao receber eventos de Live Reload.
- Suportar a atualização reativa de imagens tanto para croquis baixados no disco quanto para croquis abertos em sessão online (streaming CDN/HTTP).
- Assegurar a indexação e recuperação imediata dos hashes SHA-256 de todas as mídias de `Croqui.arquivosExternos` no `DatasetRepository`.
- Purgação explícita do cache de imagens do Flutter (`PaintingBinding.instance.imageCache`) no recebimento do evento de Live Reload.
- Manter aderência estrita a `PRINCIPIOS.md`: 100% português, testes unitários e de widgets em primeiro lugar (TDD) e 100% de cobertura nos trechos alterados.

**Non-Goals:**
- Alterar as estruturas ou contratos Protobuf existentes.
- Forçar o download de arquivos pesados desnecessariamente fora do modo experimental / Live Reload.
- Reescrever os componentes de renderização de mapa vetorial.

## Decisions e Conformidade com PRINCIPIOS.md

### Decisão 1: Indexação Imediata e Correção da Consulta de Hashes em `DatasetRepository` (Princípios I, II, VI)
- **Contexto**: `obterSha256DaMidia` dependia de `(mapaPico == null || mapaPico.isEmpty)` para indexar o croqui online sob demanda, o que nunca ocorria se a miniatura do pico já estivesse presente. Além disso, o registro de croquis online não chamava a indexação proativamente.
- **Escolha**:
  1. No `obterSha256DaMidia`, se a mídia não for encontrada no mapa existente de um pico, verificar se existe um `croquiOnline` em memória e indexá-lo imediatamente, re-consultando a tabela.
  2. Normalizar todos os caminhos de busca e indexação, removendo prefixos `./`, `/` e convertendo barras invertidas do Windows (`\`) para barras normais (`/`).
  3. No `DatasetRepository.notificarAtualizacaoSessaoOnline`, garantir que `indexarMidiasDoCroqui` seja sempre chamado antes de disparar a notificação de dataset.
- **Conformidade com Princípios**:
  - *Princípio I (Tudo em Português)*: Métodos `obterSha256DaMidia`, `indexarMidiasDoCroqui`, variáveis e testes em português brasileiro.
  - *Princípio II (Componentes Independentes)*: O repositório centraliza a fonte da verdade para indexação $O(1)$ sem espalhar lógica de banco em widgets.
  - *Princípio VI (Simplicidade e Anti-Abstração)*: Normalização direta de strings e manipulação simples de mapas nativos (`Map<String, String>`).

### Decisão 2: Invalidação Global do `imageCache` do Flutter no Live Reload (Princípios II, VI)
- **Contexto**: O Flutter mantém texturas decodificadas na GPU. Se o `ImageProvider` mantiver uma chave similar ou se o arquivo local for sobrescrito, o Flutter reutiliza a textura em cache.
- **Escolha**:
  - Em `registrarOuvintesLiveReload`, logo após a conclusão da sincronização (`syncIndex` e `datasetRepo.init` / `recarregarCroquiOnline`), invocar explicitamente:
    ```dart
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    ```
  - Isso remove tanto as imagens inativas quanto as imagens vivas atualmente exibidas, forçando o motor de renderização a buscar os novos bytes atualizados.
- **Conformidade com Princípios**:
  - *Princípio VI (Simplicidade)*: Uso direto da API oficial do Flutter sem criar wrappers complexos em torno do `ImageCache`.

### Decisão 3: Reatividade no Ciclo de Vida de `MapasCarrosselPage` (Princípios II, V)
- **Contexto**: Quando o `PageListenableBuilder` reconstrói a árvore após o Live Reload, o `MapasCarrosselPage.didUpdateWidget` não executava `setState()`, deixando o `PageView.builder` inerte.
- **Escolha**:
  - Adicionar `setState()` em `MapasCarrosselPage.didUpdateWidget` para que a tela seja marcada como suja e reavalie os filhos.
  - No construtor de `MapaInterativoPage`, passar uma `Key` reativa contendo o caminho da imagem e o hash de dados ou contador de pulso, assegurando que o Flutter reconstrua o estado visual do mapa interativo.
- **Conformidade com Princípios**:
  - *Princípio V (Testes de Widget em Primeiro Lugar)*: Validar a reconstrução do widget carrossel através de `testWidgets` antes da implementação de produção.

### Decisão 4: Fallback Dinâmico no `ProvedorImagemAresta` para Arquivos Locais (Princípio VI)
- **Contexto**: Caso algum arquivo local em `/downloads` não possua um hash explícito no `.binarypb`, ele poderia manter uma chave estática.
- **Escolha**: Se `hashEfetivo` for nulo para um arquivo existente no disco, utilizar o timestamp de modificação (`localFile.lastModifiedSync().millisecondsSinceEpoch.toString()`) como hash dinâmico na `ChaveImagemArquivoAresta`.

### Decisão 5: Disciplina Estrita de TDD, Cobertura Integral e Documentação (Princípios III, IV, VII)
- **Ciclo Red-Green-Refactor**:
  1. Escrever testes de widget e testes unitários em falha (Red) em `frontend/test/`.
  2. Implementar a menor quantidade de código para fazê-los passar (Green).
  3. Refatorar garantindo 100% de cobertura de código nos arquivos tocados.
- **Documentação**:
  - Adicionar docstrings `///` em todos os métodos e classes modificados explicando o porquê da decisão.
  - Atualizar os arquivos `README.md` pertinentes em `frontend/lib/services/` e `frontend/lib/pages/`.

## Risks / Trade-offs

- **[Pequeno piscar visual ao recarregar a tela aberta]** → Mitigação: Em ambiente de desenvolvimento e edição ao vivo (Live Reload), uma breve atualização visual de fração de segundo é esperada e fornece feedback imediato ao usuário de que a alteração do editor foi aplicada.
- **[Chamadas múltiplas a `clearLiveImages()`]** → Mitigação: Restrito ao listener de eventos de Live Reload via WebSocket (modo experimental), não impactando a navegação comum em produção.
