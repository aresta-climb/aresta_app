# smoke-test-pos-build Specification

## Purpose
Garante que os artefatos móveis compilados em modo de lançamento do Aresta App (Android e iOS) sejam validados de ponta a ponta em ambiente virtualizado nativo (emulador Android KVM e iOS Simulator) — cobrindo inicialização nativa, extração de croquis pré-carregados, autenticação OIDC, abertura de croqui Protobuf e registro na caderneta — assegurando ausência absoluta de código de teste nos binários distribuídos às lojas.

## Requirements

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
Antes da aprovação de um lançamento, o pacote descartável compilado com minificação/ofuscação de lançamento no Android e para o iOS Simulator DEVE (MUST) concluir com sucesso a jornada principal do escalador sem mockar SQLite, decodificação Protobuf, caderneta, repositório de interações, modais de interface ou canais nativos.

#### Scenario: Execução completa da jornada de smoke em Android e iOS
- **WHEN** o orquestrador inicia o servidor local de smoke e lança o aplicativo no emulador Android ou no iOS Simulator
- **THEN** o aplicativo inicializa o banco local e os croquis pré-carregados, aceita os Termos de Uso, carrega um croqui Protobuf real (`Pico`, `Setor` e `Escalada`), executa os fluxos reais de UI de autenticação sem senha (OTP, Apple no iOS e Google OIDC/PKCE), edita o perfil, registra cadena com voto de grau e beta público, edita comentário, exercita alertas Waze com fila offline e confirmação `+1`, confere a `CadernetaPage`, renova token, exclui a conta e reporta sucesso sem erros não tratados ao orquestrador

#### Scenario: Falha imediata ao capturar erro de framework ou plataforma durante o smoke
- **WHEN** ocorre qualquer exceção não tratada no framework ou na plataforma nativa, ou alguma etapa falha durante a jornada de smoke
- **THEN** o aplicativo reporta a falha detalhada ao orquestrador local e o pipeline encerra com erro antes do corte de versão

### Requirement: Condução Real da Árvore de Widgets e Modais em Binário Ofuscado
O módulo isolado de smoke pós-build SHALL conduzir a interface gráfica real em execução (`--release --obfuscate` no Android e build de simulador no iOS) utilizando exclusivamente `WidgetsBinding`, `GestureBinding` e `SchedulerBinding` (sem dependência de `flutter_test`), localizando elementos por `ValueKey<String>`, garantindo visibilidade em rolagem, disparando eventos físicos de toque por *hit-test* e inserindo texto em `EditableTextState` com respeito aos `inputFormatters`.

#### Scenario: Interação física com botões e campos em modal Bottom Sheet real
- **WHEN** o piloto de UI do smoke pós-build aciona um botão ou campo de texto identificado por `ValueKey<String>` dentro de um `BottomSheet` ou `AlertDialog`
- **THEN** o piloto garante visibilidade do alvo, injeta `PointerDownEvent` e `PointerUpEvent` no centro do `RenderBox` ou atualiza o `EditableTextState` passando pelos formatadores ativos, e avança os quadros necessários até a transição da interface.

### Requirement: Validação Multiplataforma de Autenticação Sem Senha em Loopback
O servidor local e a jornada pós-build SHALL validar em loopback local todos os fluxos de autenticação sem senha (Magic Code OTP por e-mail, Apple ID nativo no iOS Simulator, Google `id_token` no Android e Google PKCE S256 no iOS Simulator), além de logout, edição de perfil, renovação por `refresh_token` e exclusão de conta via RPC.

#### Scenario: Ciclo de Magic Code OTP, logout e login social específico por plataforma
- **WHEN** a jornada pós-build executa a sequência de autenticação pela `LoginPage` real
- **THEN** o app conclui login via Magic Code OTP de 6 dígitos e faz logout pelo diálogo real de confirmação, valida ausência ou presença do botão da Apple conforme a plataforma (concluindo login Apple OIDC com `nonce` e logout no iOS Simulator) e conclui o login Google nativo (`id_token` no Android e PKCE `callbackUrl` no iOS Simulator) seguido de edição de perfil pelo `DialogoEditarPerfil`.

#### Scenario: Renovação de token e exclusão definitiva de conta pela interface
- **WHEN** a jornada conclui as verificações de caderneta e aciona a renovação de sessão e a exclusão de conta no `HubPerfilCadernetaPage`
- **THEN** o servidor local valida `POST /auth/v1/token?grant_type=refresh_token` e `POST /rest/v1/rpc/excluir_minha_conta`, e o aplicativo encerra a sessão local zerando a caderneta do dispositivo.

### Requirement: Ciclo Ponta a Ponta de Interações Comunitárias, Alertas Waze e Outbox Offline
O servidor local e a jornada pós-build SHALL prover persistência para `/rest/v1/fila_interacoes` com injeção de falha transitória (`503`), exercitando pelos modais reais o registro de cadena com voto de grau e beta, edição de comentário, alerta Waze offline/online, confirmação (`+1`) em *"Ainda está lá?"* e conferência na `CadernetaPage`.

#### Scenario: Registro e edição de interação comunitária mais ciclo offline/online de alerta Waze
- **WHEN** a jornada navega até a `ViaPage` contendo um alerta inicial de outro escalador e dispara uma falha `503` controlada na fila remota
- **THEN** o app registra cadena, voto de grau e beta público pelo `ModalRegistroCadena`, edita o comentário pelo modal de edição, reporta um novo alerta retendo-o localmente na fila offline, drena a fila assim que o servidor volta a responder, confirma (`+1`) o alerta do terceiro pelo modal *"Ainda está lá?"* e exibe ambos os alertas contribuídos na `CadernetaPage`.
