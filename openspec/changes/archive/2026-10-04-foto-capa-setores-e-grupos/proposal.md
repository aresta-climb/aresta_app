# Proposal: Foto de Capa em Setores e Grupos com Header Adaptativo

## Why

Atualmente, `SetorPage` e `GrupoPage` buscam fotos de apresentação realizando parsing frágil via expressão regular sobre o JSON do Markdown, além de exibir a foto geral do pico como fallback quando o setor/grupo não tem imagem própria, o que gera confusão nos usuários. Com a introdução do campo nativo `caminho_imagem_capa` no Protobuf do Aresta, o aplicativo agora pode carregar capas de setores e grupos de forma determinística e exibir uma interface adaptativa (cabeçalho expandido quando houver capa e compacto quando não houver).

## What Changes

- **Resolução Nativa de Capa**: Leitura direta do campo `caminhoImagemCapa` das mensagens Protobuf `Setor` e `Grupo`, eliminando a varredura por expressão regular no corpo Markdown.
- **Eliminação de Fallback Enganoso**: Remoção do fallback para a foto geral do pico (`buildCragBackground` / `_buildDefaultCover`) nas páginas de setor e grupo.
- **Cabeçalho Adaptativo (SliverAppBar)**:
  - Se o setor ou grupo possui foto de capa definida, exibe o `SliverAppBar` expandido em 300px com imagem em tela cheia, gradientes de legibilidade e título dinâmico.
  - Se o setor ou grupo não possui foto de capa, o cabeçalho permanece compacto (altura padrão de AppBar), permitindo que o usuário visualize imediatamente o nome do setor, descrições, mapas e lista de vias sem espaço escuro ocioso.
- **Atualização do Submódulo `aresta_api`**: Atualização do ponteiro do submódulo Dart em `frontend/lib/aresta_api` para integrar os stubs gerados com `caminhoImagemCapa`.

## Capabilities

### New Capabilities
- `capas-setores-e-grupos`: Resolução de imagem de capa direta e renderização adaptativa de cabeçalho para setores e grupos.

### Modified Capabilities
<!-- Nenhuma especificação existente teve seus requisitos funcionais alterados. -->

## Impact

- **Código Afetado**:
  - `frontend/lib/pages/setor.dart` (`SetorPage`)
  - `frontend/lib/pages/grupo.dart` (`GrupoPage`)
  - `frontend/lib/aresta_api` (submódulo git)
  - `frontend/test/pages/setor_test.dart`
  - `frontend/test/pages/grupo_test.dart`
- **APIs / Contratos**: Utiliza `caminhoImagemCapa` gerado em `croqui.pb.dart` para `Setor` e `Grupo`.
- **Breaking Changes**: Nenhuma. Clientes e dados existentes continuam compatíveis (setores sem capa simplesmente renderizam o novo cabeçalho compacto).
