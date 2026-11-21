# Spec Delta

## Purpose

Garante que os artefatos móveis compilados em modo de lançamento do Aresta App (Android e iOS) sejam validados de ponta a ponta em ambiente virtualizado nativo (emulador Android KVM e iOS Simulator) — cobrindo inicialização nativa, extração de croquis pré-carregados, autenticação OIDC, abertura de croqui Protobuf e registro na caderneta — assegurando ausência absoluta de código de teste nos binários distribuídos às lojas.

## ADDED Requirements

### Requirement: Pureza Binária dos Artefatos Oficiais de Loja
Os pacotes oficiais gerados para distribuição nas lojas (`.aab` Android e `.ipa` iOS) DEVEM (MUST) ser compilados com o modo de smoke desativado em tempo de compilação e auditados automaticamente antes da publicação para impedir que rotinas, canais ou rotas de teste alcancem dispositivos reais.

#### Scenario: Auditoria aprova pacote oficial isento de símbolos de smoke
- **WHEN** o pacote oficial `.aab` ou `.ipa` é inspecionado pelo auditor pós-build
- **THEN** o auditor confirma a presença das bibliotecas nativas essenciais e a ausência total de marcadores de smoke test nos binários compilados

#### Scenario: Auditoria bloqueia pacote oficial contaminado por artefatos de smoke
- **WHEN** qualquer arquivo executável ou biblioteca compartilhada dentro do `.aab` ou `.ipa` oficial contiver marcadores de rota ou canal de smoke test
- **THEN** a auditoria falha imediatamente com código diferente de zero antes do corte de versão

#### Scenario: Validação de Cold Start puro do pacote Android oficial
- **WHEN** o APK universal extraído do `.aab` oficial da loja é instalado e iniciado no emulador Android
- **THEN** o processo do aplicativo permanece vivo até a renderização inicial sem registrar exceções fatais nativas ou Dart

### Requirement: Restrição Dupla de Hardware Virtual e Loopback no Binário de Smoke
O binário descartável de smoke test DEVE (MUST) restringir sua ativação simultaneamente à flag explícita de compilação de CI, à detecção de execução em emulador Android ou iOS Simulator e a endereços exclusivos de loopback local (`127.0.0.1`, `localhost` ou `10.0.2.2`), silenciando o envio de eventos externos ao Sentry durante a sessão.

#### Scenario: Rejeição de endereço externo fora de loopback
- **WHEN** o binário de smoke recebe um endereço de servidor cujo host não pertence ao conjunto de loopback local permitido
- **THEN** a inicialização de smoke recusa o servidor com erro explícito sem executar desvios de autenticação

#### Scenario: Bloqueio físico fora de emulador ou simulador
- **WHEN** o canal nativo de smoke é consultado fora de um emulador Android QEMU ou fora do ambiente iOS Simulator
- **THEN** a camada nativa não expõe nem executa o desvio local de emissão de token OIDC

### Requirement: Jornada Ponta a Ponta Pós-Build com Login OIDC e Abertura de Croqui
Antes da aprovação de um lançamento, o pacote descartável compilado com minificação/ofuscação de lançamento no Android e para o iOS Simulator DEVE (MUST) concluir com sucesso a jornada principal do escalador sem mockar SQLite, decodificação Protobuf, caderneta ou canais nativos.

#### Scenario: Execução completa da jornada de smoke em Android e iOS
- **WHEN** o orquestrador inicia o servidor local de smoke e lança o aplicativo no emulador Android ou no iOS Simulator
- **THEN** o aplicativo inicializa o banco local e os croquis pré-carregados, aceita os Termos de Uso, autentica via OIDC pelo canal nativo sincronizando `public.perfis`, carrega e navega até um croqui Protobuf real (`Pico`, `Setor` e `Escalada`), registra uma ascensão na caderneta local e reporta sucesso sem erros não tratados ao orquestrador

#### Scenario: Falha imediata ao capturar erro de framework ou plataforma durante o smoke
- **WHEN** ocorre qualquer exceção não tratada no framework ou na plataforma nativa, ou alguma etapa falha durante a jornada de smoke
- **THEN** o aplicativo reporta a falha detalhada ao orquestrador local e o pipeline encerra com erro antes do corte de versão
