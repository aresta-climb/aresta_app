# Spec Delta

## Purpose

Permite que escaladores compartilhem links curtos canônicos (`https://aresta.cc/s/<uid>` e `https://aresta.cc/sm/<uid>`) diretamente das telas de Pico/Croqui, Grupo, Setor, Escalada e Mapa Interativo utilizando o menu de compartilhamento nativo do sistema operacional.

## ADDED Requirements

### Requirement: Botões de Compartilhamento para Croqui, Grupo, Setor e Escalada
O aplicativo DEVE (MUST) disponibilizar um botão de compartilhamento visível na barra superior das telas de **Pico/Croqui** (`tela_pico.dart`), **Grupo** (`tela_grupo.dart`), **Setor** (`tela_setor.dart`) e **Escalada/Via** (`tela_via.dart`), acionando o compartilhamento nativo (`share_plus`) com uma mensagem amigável descritiva e o link curto no formato `https://aresta.cc/s/<uid>`.

#### Scenario: Compartilhamento a partir da página de uma Escalada
- **WHEN** o usuário toca no botão de compartilhar na tela de detalhes de uma escalada com `uid` `"x8siJek3FiG3aB"`
- **THEN** o sistema abre o menu nativo de compartilhamento contendo o nome da via, graduação, nome do pico e a URL `https://aresta.cc/s/x8siJek3FiG3aB`.

#### Scenario: Compartilhamento a partir da página de um Setor, Grupo ou Pico
- **WHEN** o usuário toca no botão de compartilhar na tela de um Pico, Grupo ou Setor
- **THEN** o sistema abre o menu nativo de compartilhamento contendo o nome da entidade, localização e a URL `https://aresta.cc/s/<uid>` correspondente ao UID daquela entidade.

### Requirement: Compartilhamento Direto de Visualização no Mapa Interativo (`/sm/<uid>`)
Quando o usuário acionar o compartilhamento a partir do Mapa Interativo contextualizado a uma entidade (`uid`), o sistema DEVE (MUST) gerar o link com o prefixo de abertura de mapa `https://aresta.cc/sm/<uid>`.

#### Scenario: Compartilhamento de mapa interativo de um setor ou via
- **WHEN** o usuário compartilha a partir da visualização do Mapa Interativo focado em uma entidade com `<uid>`
- **THEN** o link gerado utiliza o formato `https://aresta.cc/sm/<uid>` para que o destinatário abra diretamente no mapa interativo.

### Requirement: Telemetria de Ação de Compartilhamento
O sistema DEVE (MUST) registrar um evento analítico no `TelemetryService` sempre que o usuário acionar o compartilhamento de um croqui, grupo, setor, escalada ou mapa, informando `id_croqui`, `tipo_entidade` (`'pico'`, `'grupo'`, `'setor'`, `'via'`), `uid` e se o compartilhamento partiu da página ou do mapa.

#### Scenario: Registro de telemetria ao tocar em compartilhar
- **WHEN** o usuário toca no botão de compartilhar de um setor no pico `"br_mg_igarape_pedra_grande"`
- **THEN** o `TelemetryService` registra o evento de compartilhamento com `id_croqui: "br_mg_igarape_pedra_grande"`, `tipo_entidade: "setor"` e o `uid` do setor.
