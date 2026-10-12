# Proposal: Caderneta Pessoal de Cadenas e Perfil do Escalador

## Why

Com a consolidação dos **Identificadores Estáveis Universais (NanoID 14c)** em todo o ecossistema e a migração concluída no `aresta_api` e no `aresta_app`, cada via de escalada possui um `uid` permanente e único.

Conforme estabelecido na especificação de arquitetura oficial (`docs/arquitetura/mds/arquitetura_unificada_contas_cadenas_uids.md`), o aplicativo deve fornecer ao montanhista duas experiências integradas e livres de atrito:
1. **Caderneta Pessoal Esportiva (Offline-First):** Registro seguro, privado e local de suas ascensões (`cadenas`), incluindo estilo esportivo (À Vista, Flash, Trabalhado, Tentativa), data, tentativas e notas técnicas privadas (métodos do crux, costuras longas, condições da rocha).
2. **Perfil e Estatísticas do Escalador:** Visão consolidada da evolução esportiva do atleta, exibindo seu identificador estável público (`autor_id_publico`), apelido esportivo (`autor_nome_publico`), pirâmide de graduação acumulada, proporção de estilos e histórico cronológico filtrável.

Esta proposta implementa o núcleo da Caderneta Pessoal e do Perfil no aplicativo móvel em padrão *Local-First* reativo, preparando a estrutura para posterior replicação em nuvem via PowerSync SDK sem quebrar o funcionamento offline nas falésias.

## What Changes

- **Modelos de Domínio (`frontend/lib/data/modelos/`):**
  - Criação da entidade imutável `Cadena` com `id` (UUID v4), `escaladaUid` (NanoID 14c), `dataAscensao`, `tipoAscensao`, `tipoEscalada`, `tentativas`, `grauSugerido` e `notasPrivadas` (até 200 caracteres).
  - Criação do modelo `PerfilEscalador` contendo `autorIdPublico` (NanoID 14c), `autorNomePublico` e `userId`.
  - Enums fortemente tipados em português: `TipoAscensao` (À Vista, Flash, Trabalhado, Tentativa) e `TipoEscalada` (Guiado, Top Rope, Boulder, Solo), com rótulos e ícones de interface.
- **Serviço e Repositório Reativo de Caderneta (`frontend/lib/services/caderneta/`):**
  - Implementação de `RepositorioCaderneta` local reativo baseado em persistência atômica segura no dispositivo, expondo `ValueListenable` / `Stream` para reatividade imediata na UI.
  - Métodos de agregação: cálculo de pirâmide de graduação por categoria (Vias e Boulders), melhor estilo alcançado por via e contadores de ascensões.
- **Modal de Registro de Cadena na Via (`frontend/lib/widgets/caderneta/` e `frontend/lib/pages/via.dart`):**
  - Inclusão do botão de ação de registro na página da via e nos cartões de escalada.
  - Implementação do `ModalRegistroCadena`: seleção de estilo com chips táteis, contador de tentativas, seletor de data e campo de texto de `notasPrivadas` (com contador de 200 caracteres).
  - Exibição de selo esportivo na tela da via indicando ascensão prévia (ex: *"✓ Você encadenou esta via em 14/09 (Flash)"*).
- **Tela de Perfil do Escalador (`frontend/lib/pages/perfil.dart`):**
  - Página com arquitetura MVVM (`PerfilPage` e `PerfilViewModel`) apresentando cabeçalho com apelido e UID estável, cartões de resumo, gráfico da pirâmide de cadenas e lista histórica filtrável.
- **Navegação:**
  - Integração da rota e acesso ao Perfil a partir do fluxo de navegação do app.

## Capabilities

### New Capabilities
- `caderneta-pessoal`: Modelo de dados de cadenas associado a `escalada_uid`, repositório local reativo e motor de agregação estatística (pirâmide de graus e distribuição por estilo).
- `registro-cadena-via`: Modal e fluxo de registro de ascensão na página da via com validação de campos, feedback tátil e exibição do selo de cadena conquistada.
- `perfil-escalador`: Interface completa do perfil esportivo do escalador com métricas de desempenho, pirâmide de cadenas e histórico cronológico com edição e exclusão.

## Impact

- **Código de Produção:**
  - Novos modelos em `frontend/lib/data/modelos/cadena.dart`, `tipo_ascensao.dart`, `tipo_escalada.dart`, `perfil_escalador.dart`.
  - Novos serviços em `frontend/lib/services/caderneta/repositorio_caderneta.dart`.
  - Novos widgets em `frontend/lib/widgets/caderneta/modal_registro_cadena.dart` e `card_estatistica_perfil.dart`.
  - Novas páginas em `frontend/lib/pages/perfil.dart`.
  - Atualizações pontuais em `frontend/lib/pages/via.dart` e `frontend/lib/view/function_library/via_functions.dart`.
- **Governança e Testes:**
  - TDD obrigatório em 100% dos novos arquivos com testes de unidade e widget correspondentes em `frontend/test/`.
  - Todo o código, símbolos, comentários e docstrings em português brasileiro conforme `AGENTS.md`.
