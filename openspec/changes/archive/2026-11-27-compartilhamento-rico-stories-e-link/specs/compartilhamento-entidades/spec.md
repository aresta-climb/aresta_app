# Spec Delta

## MODIFIED Requirements

### Requirement: Botões de Compartilhamento para Croqui, Grupo, Setor e Escalada
O aplicativo DEVE (MUST) disponibilizar um botão de compartilhamento visível nas páginas principais de **Pico/Croqui** (`pico.dart`), **Grupo** (`grupo.dart`), **Setor** (`setor.dart`) e **Escalada/Via** (`via.dart`) — sem exibi-lo na barra superior do Mapa Interativo (`mapa_interativo.dart`) —, abrindo um BottomSheet unificado com pré-visualização visual do cartão editorial da entidade e opções explícitas para compartilhar como **Imagem (Stories)** ou **Link Rápido (WhatsApp)**, mantendo as mensagens naturais em português (sem duplicar prefixos como `"Setor"`, `"Bloco"`, `"Falésia"` ou `"Grupo"` e resolvendo sempre o nome real do croqui em vez do `id_slug`) e o link curto no formato `https://aresta.cc/s/<uid>`.

#### Scenario: Compartilhamento a partir da página de uma Escalada
- **WHEN** o usuário toca no botão de compartilhar na tela de detalhes de uma escalada com `uid` `"x8siJek3FiG3aB"` e escolhe a opção de link rápido no BottomSheet
- **THEN** o sistema abre o menu nativo de compartilhamento contendo o nome da via, graduação, setor, o nome legível do croqui e a URL `https://aresta.cc/s/x8siJek3FiG3aB`.

#### Scenario: Compartilhamento a partir da página de um Setor, Grupo ou Pico
- **WHEN** o usuário toca no botão de compartilhar na tela de um Pico, Grupo ou Setor e escolhe a opção de link rápido no BottomSheet
- **THEN** o sistema abre o menu nativo de compartilhamento contendo o nome da entidade, o nome legível do croqui (resolvido via `DatasetRepository` caso não informado diretamente) e a URL `https://aresta.cc/s/<uid>` correspondente ao UID daquela entidade.

### Requirement: Telemetria de Ação de Compartilhamento
O sistema DEVE (MUST) registrar um evento analítico no `TelemetryService` sempre que o usuário acionar o compartilhamento de um croqui, grupo, setor, escalada ou mapa, informando `id_croqui`, `tipo_entidade` (`'pico'`, `'grupo'`, `'setor'`, `'via'`), `uid`, se o compartilhamento partiu da página ou do mapa (`abrir_mapa`) e o `formato` escolhido (`'link'` ou `'imagem_stories'`).

#### Scenario: Registro de telemetria ao tocar em compartilhar
- **WHEN** o usuário toca no botão de compartilhar de um setor no pico `"br_mg_igarape_pedra_grande"` e confirma o envio do link rápido
- **THEN** o `TelemetryService` registra o evento de compartilhamento com `id_croqui: "br_mg_igarape_pedra_grande"`, `tipo_entidade: "setor"`, `formato: "link"` e o `uid` do setor.

#### Scenario: Registro de telemetria ao compartilhar cartão visual nos Stories
- **WHEN** o usuário escolhe compartilhar a imagem para Stories a partir do BottomSheet de uma escalada no pico `"br_mg_igarape_pedra_grande"`
- **THEN** o `TelemetryService` registra o evento de compartilhamento com `id_croqui: "br_mg_igarape_pedra_grande"`, `tipo_entidade: "via"`, `formato: "imagem_stories"` e o `uid` da escalada.

## ADDED Requirements

### Requirement: Cartão Visual Editorial para Stories com Omissão de Notas Privadas e Assinatura Minimalista
O aplicativo DEVE (MUST) gerar um cartão visual editorial consistente em tema escuro para qualquer entidade compartilhável (**Pico**, **Grupo**, **Setor** ou **Escalada**) destacando a imagem de capa/croqui disponível em cascata (incluindo a pílula `LINHA #N` quando a escalada possuir número no mapa), título, localização, grau em destaque, selo esportivo pessoal (quando houver cadena ou tentativa registrada para a via) e chips técnicos/estatísticos resumidos, **omitindo integralmente** qualquer texto de `notasPrivadas` da caderneta pessoal e exibindo ao final uma assinatura minimalista e discreta (`Aresta Climb • arestaclimb.com • @arestaclimb`) sem QR Code.

#### Scenario: Pré-visualização de cartão de Escalada com Cadena e nota privada oculta
- **WHEN** o usuário abre o BottomSheet de compartilhamento de uma escalada com cadena registrada e nota privada `"Crux na 4ª costura"`
- **THEN** o cartão renderizado exibe o selo da ascensão (data e estilo), grau, modalidade e a assinatura discreta com `arestaclimb.com` e `@arestaclimb`, sem exibir o texto `"Crux na 4ª costura"` nem QR Code.

#### Scenario: Pré-visualização de cartão de Pico, Grupo ou Setor
- **WHEN** o usuário abre o BottomSheet de compartilhamento em uma página de Pico, Grupo ou Setor
- **THEN** o cartão renderizado exibe o título da entidade, localização hierárquica, contagem de setores/escaladas, faixa de graus ou modalidades aplicáveis e a assinatura discreta no rodapé.

### Requirement: Compartilhamento de Imagem para Stories com Cópia Automática do Link Curto
Ao acionar a opção **Compartilhar Imagem (Stories)** no BottomSheet, o sistema DEVE (MUST) capturar o cartão visual em PNG (`image/png`) de forma assíncrona sem bloquear a interface, copiar automaticamente a URL canônica `https://aresta.cc/s/<uid>` para a área de transferência do dispositivo, exibir um aviso orientativo informando que o link foi copiado para uso opcional na figurinha de Link dos Stories, e invocar o menu nativo do sistema operacional enviando exclusivamente o arquivo PNG (`MIME: image/png`) para habilitar o destino Instagram Stories.

#### Scenario: Envio de imagem para Stories com cópia automática do link
- **WHEN** o usuário toca em **Compartilhar Imagem (Stories)** no BottomSheet de uma via com `uid` `"x8siJek3FiG3aB"`
- **THEN** o sistema copia `"https://aresta.cc/s/x8siJek3FiG3aB"` para a área de transferência, exibe o toast orientativo e aciona o compartilhamento nativo apenas com o arquivo PNG (`image/png`), sem texto acoplado.

### Requirement: Gatilhos Rápidos de Compartilhamento na Caderneta da Via
Na tela de detalhes da Escalada (`ViaPage`), quando a via possuir `uid` válido, o sistema DEVE (MUST) oferecer um botão rápido de compartilhamento no selo de ascensão registrada dentro do Passaporte da Via e uma ação `"Compartilhar"` no toast exibido imediatamente após salvar uma cadena ou tentativa, ambos abrindo o mesmo BottomSheet unificado de pré-visualização.

#### Scenario: Compartilhar imediatamente após salvar uma cadena na caderneta
- **WHEN** o usuário salva uma nova cadena ou tentativa em uma escalada com `uid` válido e toca na ação `"Compartilhar"` do toast exibido
- **THEN** o sistema abre o BottomSheet de compartilhamento já exibindo o cartão atualizado com o selo da ascensão recém-registrada.

#### Scenario: Compartilhar a partir do selo de ascensão no Passaporte da Via
- **WHEN** o usuário visualiza uma escalada que já possui cadena ou tentativa registrada e toca no ícone de compartilhamento do selo de ascensão
- **THEN** o sistema abre o BottomSheet de compartilhamento daquela escalada exibindo o selo esportivo correspondente sem notas privadas.
