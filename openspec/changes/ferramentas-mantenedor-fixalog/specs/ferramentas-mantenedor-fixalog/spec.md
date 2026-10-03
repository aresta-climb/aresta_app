## Purpose

Permite que mantenedores e conquistadores ativem ferramentas especializadas nas configurações e acessem diretamente o fluxo de manutenção de proteções de vias no Fixalog via deep links padronizados.

## ADDED Requirements

### Requirement: Configuração de Ferramentas para Mantenedores
O aplicativo DEVE (MUST) disponibilizar uma opção de configuração denominada "Ferramentas para Mantenedores" na tela de Configurações, desativada por padrão e persistida localmente no dispositivo.

#### Scenario: Estado inicial desativado por padrão
- **WHEN** o usuário abre as configurações pela primeira vez
- **THEN** o interruptor de ferramentas para mantenedores DEVE estar desligado

#### Scenario: Ativação e persistência da preferência
- **WHEN** o usuário ativa o interruptor de ferramentas para mantenedores
- **THEN** o estado DEVE ser salvo localmente e permanecer ativado em sessões subsequentes do aplicativo

#### Scenario: Desativação da preferência
- **WHEN** o usuário desativa o interruptor de ferramentas para mantenedores
- **THEN** o estado DEVE ser atualizado localmente e as ferramentas para mantenedores DEVEM ser ocultadas imediatamente

### Requirement: Exibição condicional da ação de manutenção na página da escalada
A página de detalhes da escalada DEVE (MUST) exibir a opção "Manutenir no Fixalog" associada à seção de Histórico e Conquista exclusivamente quando a configuração de ferramentas para mantenedores estiver ativada.

#### Scenario: Ação visível com ferramentas ativadas
- **WHEN** a configuração de ferramentas para mantenedores estiver ativada e o usuário visualiza uma via de escalada
- **THEN** o botão "Manutenir no Fixalog" DEVE estar visível no bloco de histórico da via

#### Scenario: Ação oculta com ferramentas desativadas
- **WHEN** a configuração de ferramentas para mantenedores estiver desativada e o usuário visualiza uma via de escalada
- **THEN** o botão "Manutenir no Fixalog" NÃO DEVE ser exibido na interface

#### Scenario: Exibição em via sem histórico cadastrado prévio
- **WHEN** a configuração estiver ativada em uma via que não possui conquistadores ou datas cadastradas
- **THEN** a seção com o botão "Manutenir no Fixalog" DEVE ser apresentada para permitir o registro da manutenção

### Requirement: Geração e abertura de Deep Link padronizado para o Fixalog
Ao acionar o botão de manutenção, o sistema DEVE (MUST) gerar uma URL no domínio `fixalog.arestaclimb.com` preservando os identificadores e a hierarquia slugificada da via, abrindo-a no aplicativo externo ou navegador.

#### Scenario: Disparo de deep link para via em setor direto
- **WHEN** o usuário toca em "Manutenir no Fixalog" para uma via pertencente a um setor direto do pico
- **THEN** o sistema DEVE disparar a abertura da URL no formato `https://fixalog.arestaclimb.com/<pico_id>/<setor_slug>/<via_slug>`

#### Scenario: Disparo de deep link para via em setor dentro de grupo
- **WHEN** o usuário toca em "Manutenir no Fixalog" para uma via pertencente a um setor dentro de um grupo
- **THEN** o sistema DEVE disparar a abertura da URL no formato `https://fixalog.arestaclimb.com/<pico_id>/<grupo_slug>/<setor_slug>/<via_slug>`

#### Scenario: Tratamento de falha na abertura do link
- **WHEN** o sistema operacional não conseguir abrir o link externo
- **THEN** uma notificação amigável de erro DEVE ser exibida ao usuário sem travar a interface
