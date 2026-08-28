## ADDED Requirements

### Requirement: Navegação Direta para Croquis Não Baixados
O sistema DEVE (MUST) permitir que a seleção de qualquer pico listado nas telas de Explorar (`browse.dart`), Home (`home.dart`) e Mapa Global (`mapa_global.dart`) transicione diretamente para a rota `PicoContextNode` (`PicoDetailsPage`), independentemente de o pico estar previamente baixado ou não no dispositivo.

#### Scenario: Seleção de pico não baixado na grade de croquis
- **WHEN** o usuário toca no card de um pico que possui `isDownloaded == false`
- **THEN** o sistema despacha a navegação para `AppNav.toPico`
- **AND** renderiza a página de detalhes em modo online sem exibir modais de bloqueio de download.

#### Scenario: Seleção de marcador de pico não baixado no Mapa Global
- **WHEN** o usuário seleciona um pico no Mapa Global e toca para abrir seus detalhes
- **THEN** a tela de detalhes do pico é aberta imediatamente consumindo os dados da sessão online.

### Requirement: Contexto de Modo Online na Árvore de Navegação
Os nós de navegação contextualizados a um pico (`PicoContextNode` e seus descendentes `SetorNode`, `ViaNode`, `MapaInterativoNode`) DEVEM (MUST) propagar e manter acessível o estado indicativo de que o pico está sendo visualizado em sessão online, permitindo que as subpáginas renderizem os controles e proteções de modo online.

#### Scenario: Navegação de subpágina dentro de um croqui online
- **WHEN** o usuário navega da página do Pico para um Setor ou Via de um croqui online
- **THEN** a subpágina herda o contexto online
- **AND** mantém o banner e os comportamentos de proteção ativos.
