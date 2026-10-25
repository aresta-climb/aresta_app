# subpaginas-hub-pico Specification

## Purpose
Controla a visibilidade condicional dos cards de subpáginas no Hub do Pico e fornece o atalho de localização para o Google Maps dentro da subpágina Explorar Local.

## Requirements

### Requirement: Visibilidade Condicional do Card Explorar Local
O sistema DEVE (MUST) exibir o card "Explorar Local" no Hub do Pico somente quando houver ao menos uma seção textual de exploração (`capa`, `introducao`, `sobre`, `descricao` do pico, `comoChegar` ou `outros`) ou quando houver link ou coordenadas geográficas válidas para o Google Maps.

#### Scenario: Pico sem textos de exploração e sem localização oculta Explorar Local
- **WHEN** o usuário abre o Hub de um pico que não possui seções textuais de exploração, nem `url_google_maps`, nem coordenadas `localizacao`
- **THEN** o card "Explorar Local" não é renderizado na página do pico.

#### Scenario: Pico apenas com coordenadas exibe Explorar Local
- **WHEN** o usuário abre o Hub de um pico sem seções textuais de exploração, mas com coordenadas `localizacao` válidas
- **THEN** o card "Explorar Local" é exibido normalmente no Hub do pico.

### Requirement: Visibilidade Condicional do Card Comunidade
O sistema DEVE (MUST) exibir o card "Comunidade" no Hub do Pico somente quando o croqui possuir ao menos uma seção textual de comunidade (informações, parceiros ou comércio local) ou dados completos de associação local (nome e URL de filiação preenchidos).

#### Scenario: Pico sem dados de comunidade oculta card Comunidade
- **WHEN** o usuário abre o Hub de um pico que não possui seções de comunidade nem associação local configurada
- **THEN** o card "Comunidade" não é renderizado na página do pico.

#### Scenario: Pico com parceiros ou associação exibe card Comunidade
- **WHEN** o usuário abre o Hub de um pico que possui seção de parceiros, comércio, informações de comunidade ou associação local
- **THEN** o card "Comunidade" é exibido no Hub do pico.

### Requirement: Visibilidade Permanente de Regras e Recomendações com Mensagem Padrão
O sistema DEVE (MUST) manter o card "Regras e recomendações" sempre visível no Hub do Pico e exibir a mensagem educativa padrão quando não houver regras específicas cadastradas no croqui.

#### Scenario: Pico sem regras específicas exibe mensagem padrão no modal
- **WHEN** o usuário toca em "Regras e recomendações" em um pico sem botões de regras cadastrados
- **THEN** o modal é aberto exibindo a recomendação padrão de conduta ética e ambiental.

### Requirement: Botão Único do Google Maps em Explorar Local com Fallback de Coordenadas
Na subpágina "Explorar Local", o sistema DEVE (MUST) exibir no máximo um botão de navegação para o Google Maps posicionado logo abaixo da seção "Como chegar", priorizando `url_google_maps` quando preenchido e utilizando as coordenadas `localizacao` (convertidas do padrão E7) como fallback automático.

#### Scenario: Prioridade para url_google_maps quando ambos estão presentes
- **WHEN** o usuário acessa "Explorar Local" em um pico que possui tanto `url_google_maps` quanto `localizacao` preenchidos
- **THEN** o sistema renderiza apenas um botão do Google Maps abaixo da seção "Como chegar"
- **AND** tocar nesse botão abre a URL definida em `url_google_maps`.

#### Scenario: Fallback automático para coordenadas quando url_google_maps está vazio
- **WHEN** o usuário acessa "Explorar Local" em um pico sem `url_google_maps`, mas com coordenadas `localizacao` válidas em formato E7
- **THEN** o sistema renderiza o botão do Google Maps abaixo da seção "Como chegar"
- **AND** tocar nesse botão abre a URL universal do Google Maps com a latitude e longitude convertidas para graus decimais.

#### Scenario: Omissão do botão do Google Maps quando não há link nem coordenadas
- **WHEN** o usuário acessa "Explorar Local" em um pico que possui textos de exploração, mas não possui `url_google_maps` nem coordenadas `localizacao` válidas
- **THEN** nenhum botão do Google Maps é exibido na página.
