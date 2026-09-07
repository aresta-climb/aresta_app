## Context

Na versão `0.2.4+66` foram registradas 3 falhas de estabilidade em produção via Firebase Crashlytics:
1. Erro de rede transitório (`HTTP 504 Gateway Timeout`) ao baixar webp no `sync_isolate`, classificado indevidamente como crash fatal e com stack trace acidental da thread principal (`EditorDeCroqui._writeConfig`). Identificou-se também ausência total de retentativa para erros de gateway, fazendo com que uma única falha em um arquivo abortasse o download do setor inteiro.
2. `Null check operator used on a null value` no Google Maps exclusivo de aparelhos OnePlus rodando Android 11, provocado por interceptação de platform channels pelo SO nativo (`com.mojito.utility.FlutterMessageDecode`) e force-unwraps (`!`) em buffers de marcadores.
3. `Null check operator used on a null value` em `ButtonStyle.merge` em widgets de botões e menus durante alternâncias de estados e temas.

Esta solução é concebida sob os preceitos mandatórios de `PRINCIPIOS.md` do Aresta App.

## Goals / Non-Goals

**Goals:**
- **Tudo em Português (Princípio I)**: Todo novo identificador (ex: propriedade `rastreamentoPilha` em `DownloadIsolateResult`, métodos auxiliares como `ehStatusTransitorio`), docstrings e testes devem ser escritos em português brasileiro.
- **TDD e Espelhamento de Diretórios (Princípios III, IV e V)**:
  - Escrever primeiro os testes para falhar (Red), priorizando testes de Widget (Princípio V) e testes unitários espelhados em `frontend/test/`.
  - Exigir 100% de cobertura de testes nos trechos e arquivos modificados.
- **Simplicidade e Anti-Abstração (Princípio VI)**:
  - Adotar soluções diretas e declarativas (ex: loop simples de retentativas com recuo linear/progressivo, operador `??` e checagem de nulidade em vez de bibliotecas pesadas de resiliência ou fábricas complexas).
- **Retentativas Inteligentes no Download Atômico**:
  - Implementar até 3 tentativas para erros de rede transitórios (`502`, `503`, `504`, `429` e timeouts de conexão) com pausa progressiva (500ms, 1000ms), recuperando downloads sem abortar a sincronização.
- **Rastreabilidade Fiel de Isolates**:
  - Capturar `rastreamentoPilha` na origem do erro dentro de `sync_isolate.dart`, propagar via `DownloadIsolateResult` e reconstruir via `StackTrace.fromString` no `sync_service.dart`.
- **Classificação Precisa de Rede**:
  - Reconhecer códigos `502`, `503`, `504` no `AppLogger.isFalhaConexaoOuTimeout`, registrando-os como falhas não-fatais (`fatal: false`).
- **Defensiva em Marcadores de Mapa**:
  - Eliminar operadores `!` em `mapa_marker.dart` e `mapa_global_functions.dart`, provendo fallback seguro para `BitmapDescriptor.defaultMarker`.
- **Consistência de Temas**:
  - Definir `iconButtonTheme`, `menuButtonTheme` e `popupMenuTheme` no `ThemeData` em `main.dart`.
- **Documentação Contínua (Princípio VII)**:
  - Documentar com docstrings `///` em português todo método, classe e função modificados.

**Non-Goals:**
- Não reescrever o motor de sincronização nem introduzir novas dependências no `pubspec.yaml`.
- Não alterar os layouts visuais existentes ou paleta de cores do aplicativo.

## Decisions

### 1. Mecanismo de Retentativa com Espera Progressiva (Princípios I e VI)
- **Decisão**: Dentro de `downloadAtomic` em `sync_isolate.dart`, encapsular a requisição HTTP em um laço de até 3 tentativas para status transitórios (`502`, `503`, `504`, `429`) ou exceções de socket/timeout. Entre as tentativas, aplicar espera assíncrona (`Future.delayed`) progressiva (ex: 500ms na 1ª, 1000ms na 2ª). Erros definitivos (ex: 404) abortam de imediato sem retentar.
- **Alternativas consideradas**:
  - Adicionar biblioteca externa de retry (como `retry` ou `dio`): violaria o Princípio VI ("Simplicidade e Anti-Abstração"), já que um laço `while` de 15 linhas no próprio `sync_isolate.dart` resolve com transparência e zero dependências externas.
  - Deixar sem retry: qualquer oscilação de 1 segundo de CDN continuaria abortando sincronismos grandes.

### 2. Nomenclatura e Serialização em Isolates (Princípios I e VI)
- **Decisão**: Adicionar o campo `final String? rastreamentoPilha;` ao `DownloadIsolateResult`. Quando uma exceção ou falha HTTP esgotar todas as tentativas, capturamos `stack.toString()` ou `StackTrace.current.toString()`. No `sync_service.dart`, reconstituímos via `StackTrace.fromString(mensagem.rastreamentoPilha!)`.
- **Alternativas consideradas**:
  - Manter o nome em inglês `stackTrace`: violaria o Princípio I ("Tudo em Português").

### 3. Reconhecimento de Erros Transitórios de Infraestrutura no `AppLogger`
- **Decisão**: Estender `AppLogger.isFalhaConexaoOuTimeout` com regex/verificações simples para `502`, `503`, `504`, `gateway timeout`, `bad gateway`, `service unavailable`.

### 4. Fallbacks Seguros sem Force-Unwrap em Marcadores
- **Decisão**: Substituir `byteData!.buffer.asUint8List()` por checagem condicional com retorno de `BitmapDescriptor.defaultMarker`. Substituir `textIcons[id]!` por `textIcons?[id] ?? customIcon ?? BitmapDescriptor.defaultMarker`.

### 5. Configuração Baseline de Temas de Botões e Menus
- **Decisão**: Declarar temas base para `iconButtonTheme`, `menuButtonTheme` e `popupMenuTheme` no `ThemeData` claro e escuro em `main.dart`.

## Risks / Trade-offs

- **[Risco]** Retentativas aumentarem o tempo de sincronização em caso de servidor fora do ar
  $\rightarrow$ **Mitigação**: O limite é de no máximo 3 tentativas com esperas curtas (500ms e 1000ms), totalizando no máximo ~1.5s de atraso antes de registrar a falha caso o servidor permaneça indisponível.
- **[Risco]** Volume de dados trafegados entre Isolates
  $\rightarrow$ **Mitigação**: A string `rastreamentoPilha` ocupa poucos kilobytes e só é enviada em cenários de falha esgotada.
