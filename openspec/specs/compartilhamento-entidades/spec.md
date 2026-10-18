# compartilhamento-entidades Specification

## Purpose

Permite que escaladores compartilhem links curtos canônicos (`https://aresta.cc/s/<uid>`) diretamente das páginas principais de Pico/Croqui, Grupo, Setor e Escalada utilizando o menu de compartilhamento nativo do sistema operacional, com mensagens naturais em português e resolução do nome legível do croqui.

## Requirements

### Requirement: Botões de Compartilhamento para Croqui, Grupo, Setor e Escalada
O aplicativo DEVE (MUST) disponibilizar um botão de compartilhamento visível nas páginas principais de **Pico/Croqui** (`pico.dart`), **Grupo** (`grupo.dart`), **Setor** (`setor.dart`) e **Escalada/Via** (`via.dart`) — sem exibi-lo na barra superior do Mapa Interativo (`mapa_interativo.dart`) —, acionando o compartilhamento nativo (`share_plus`) com uma mensagem natural em português (sem duplicar prefixos como `"Setor"`, `"Bloco"`, `"Falésia"` ou `"Grupo"` e resolvendo sempre o nome real do croqui em vez do `id_slug`) e o link curto no formato `https://aresta.cc/s/<uid>`.

#### Scenario: Compartilhamento a partir da página de uma Escalada
- **WHEN** o usuário toca no botão de compartilhar na tela de detalhes de uma escalada com `uid` `"x8siJek3FiG3aB"`
- **THEN** o sistema abre o menu nativo de compartilhamento contendo o nome da via, graduação, setor, o nome legível do croqui e a URL `https://aresta.cc/s/x8siJek3FiG3aB`.

#### Scenario: Compartilhamento a partir da página de um Setor, Grupo ou Pico
- **WHEN** o usuário toca no botão de compartilhar na tela de um Pico, Grupo ou Setor
- **THEN** o sistema abre o menu nativo de compartilhamento contendo o nome da entidade, o nome legível do croqui (resolvido via `DatasetRepository` caso não informado diretamente) e a URL `https://aresta.cc/s/<uid>` correspondente ao UID daquela entidade.

### Requirement: Telemetria de Ação de Compartilhamento
O sistema DEVE (MUST) registrar um evento analítico no `TelemetryService` sempre que o usuário acionar o compartilhamento de um croqui, grupo, setor, escalada ou mapa, informando `id_croqui`, `tipo_entidade` (`'pico'`, `'grupo'`, `'setor'`, `'via'`), `uid` e se o compartilhamento partiu da página ou do mapa.

#### Scenario: Registro de telemetria ao tocar em compartilhar
- **WHEN** o usuário toca no botão de compartilhar de um setor no pico `"br_mg_igarape_pedra_grande"`
- **THEN** o `TelemetryService` registra o evento de compartilhamento com `id_croqui: "br_mg_igarape_pedra_grande"`, `tipo_entidade: "setor"` e o `uid` do setor.
