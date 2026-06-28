## Why

O aplicativo recentemente migrou seu backend e modelos de dados para a v3. Como parte dessa migração, os "Mapas Gerais" (como mapas de acesso ao pico) deixaram de ser botões em markdown legados e passaram a ser coleções nativas de mapas (`pico.mapasGerais`). O problema atual é que a interface do aplicativo ainda trata mapas gerais como botões markdown estáticos, impedindo que os usuários tenham acesso ao pan/zoom interativo e integração profunda de navegação.

## What Changes

- Renderizar a nova propriedade `mapasGerais` de forma nativa na tela do Pico (`PicoDetailsPage`), posicionando a(s) thumbnail(s) logo acima da seção de setores para um fluxo visual coeso.
- Eliminar o código de processamento legado em `mapa_geral_pico.dart` e remover lógicas frágeis baseadas em parse de texto Markdown para identificar mapas.
- Garantir que o clique em marcadores (POIs) de Setores nos Mapas Gerais permita ao usuário navegar diretamente para o Setor ou para o Mapa do Setor (funcionalidade já coberta em grande parte pela infraestrutura existente, exigindo apenas roteamento adequado).
- Atualizar o botão "Ir para Grupo" nos modais do mapa interativo para de fato navegar para o grupo usando `AppNav.toGrupo` (removendo a limitação legada).

## Capabilities

### New Capabilities
Nenhuma.

### Modified Capabilities
- `interactive-map`: A capacidade do mapa interativo será expandida para suportar mapas raiz do Pico (Mapas Gerais) sem necessitar de um contexto preestabelecido de Grupo ou Setor na hierarquia, resolvendo corretamente a navegação dos POIs em escopo global do Pico.

## Impact

- **UI/UX**: Usuários agora verão e interagirão com Mapas Gerais de acesso com a mesma fluidez de mapas de setores.
- **Limpeza Técnica**: O app perderá código legado de interpretação de Markdown para Mapas (`mapa_geral_pico.dart`).
- **Navegação**: A página `PicoDetailsPage` (e funções em `pico_functions.dart`) será a principal área de impacto.
