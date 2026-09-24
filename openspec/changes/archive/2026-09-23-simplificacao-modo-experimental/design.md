# Technical Design: Simplificação do Modo Experimental

## Context

Conforme descrito no `proposal.md`, o modo experimental atualmente possui uma contagem regressiva de 20 minutos que causa reconstruções a cada 1 segundo no `BannerModoExperimental`, além de manter código legado e guardas obsoletas para arquivos `.croqui` e `.zip`. O aplicativo já possui um sistema consolidado de conexão remota híbrida (Direct LAN, Cloudflare Relay via código Base36 de 8 dígitos, URL direta e QR Code) com Live Reload via WebSocket.

Uma restrição essencial do projeto é que o repositório `frontend/lib/aresta_api` é um git submodule consumido por outros projetos (como o `aresta_db`). Portanto, os arquivos de proto do `aresta_api` (`croqui_experimental.proto` e arquivos gerados) não devem ser modificados ou deletados do submódulo, mas todo código, imports e lógica de suporte a arquivos locais devem ser removidos do `aresta_app`.

## Goals / Non-Goals

**Goals:**
- Eliminar o timer periódico de 20 minutos (`_countdownTimer`), o notificador `timeRemaining` e a expiração automática por tempo no `EditorDeCroqui`.
- Eliminar as reconstruções periódicas de 1 segundo no `BannerModoExperimental`, tornando a UI estática e reativa apenas a eventos de Live Reload (pulso) ou mudança de status experimental.
- Garantir a política da **Opção A (Sessão Volátil)**: manter a conexão ativa enquanto o app estiver em execução e garantir que, ao ser reiniciado do zero (boot), o app limpe dados experimentais locais e retorne ao Modo Oficial seguro.
- Remover checagens residuais de arquivos `.croqui`, `.zip` e o scheme `aresta-zip://` no `aresta_app`.
- Simplificar e atualizar mensagens de interface em `settings_functions.dart` e documentações técnicas.
- Garantir 100% de cobertura de testes unitários e de widget para todos os arquivos afetados.

**Non-Goals:**
- Não alterar nem remover arquivos do submódulo git `frontend/lib/aresta_api`.
- Não alterar o protocolo de comunicação remota (Broker Cloudflare, WebSocket Live Reload, rotas `/handshake`, `/info`, etc.).
- Não persistir o estado de conexão experimental após o encerramento do processo do app (boot sempre volta ao modo oficial seguro).

## Decisions

### Decisão 1: Remoção completa do temporizador e notificador `timeRemaining`
- **Abordagem**:
  - Em `EditorDeCroqui`, remover as variáveis `_expirationTime`, `_countdownTimer` e o notificador `timeRemaining`.
  - Remover o método `_startCountdown()`.
  - Simplificar o método `activateExperimental({String? url})`, removendo o parâmetro `forceResetTimer` e a chave `expiryTime` do arquivo de configuração `editor_config.yaml`.
  - Em `nukeExperimentalData()`, simplificar a rotina, mantendo a exclusão dos diretórios `${directory.path}/editor/experimental` e `edited`, resetando `isExperimentalMode.value = false` e `editorUrl.value = null`.
- **Alternativas consideradas**:
  - *Manter o timer opcional (com flag configurável)*: Rejeitado por adicionar complexidade desnecessária e manter código duplicado/inútil quando a intenção do usuário é não ter mais limite de tempo.

### Decisão 2: Sessão Volátil (Opção A) no Boot
- **Abordagem**:
  - Em `loadFromDisk()` no `EditorDeCroqui`, preservar e consolidar a regra de segurança: se `isExperimental` estiver marcado como verdadeiro no YAML ao abrir o app, executa `await nukeExperimentalData()`.
  - Dessa forma, o usuário pode testar sem interrupção enquanto o app estiver aberto, mas nunca corre o risco de abrir o app dias depois em campo e estar preso em uma base experimental desatualizada.
- **Alternativas consideradas**:
  - *Opção B (Persistência no boot)*: Descartada conforme preferência explícita do usuário.

### Decisão 3: Descontinuação definitiva e limpeza de código de `.croqui`, `.zip` e `aresta-zip://`
- **Abordagem**:
  - Em `settings_functions.dart`:
    - Na função `conectarEditor`, remover a checagem `checkUrl.toLowerCase().endsWith('.zip') || checkUrl.toLowerCase().endsWith('.croqui')` e o SnackBar correspondente.
    - No `buildEditorCard`, atualizar a descrição do card de:
      `"Visualizando croquis transmitidos em tempo real pelo Editor Desktop ou arquivo importado."`
      para:
      `"Visualizando croquis sincronizados em tempo real com o Editor Desktop."`
  - Em `editor_croqui.dart`:
    - Remover as guardas `if (urlBase.startsWith('aresta-zip://')) return;` em `iniciarEscutaLiveReload` e `activateExperimental`.
    - Atualizar a docstring de `isExperimentalMode`: de `"Se o modo experimental (zip importado) está ativo"` para `"Se o modo experimental (conectado ao Editor Desktop) está ativo"`.
- **Alternativas consideradas**:
  - *Manter o aviso de arquivo descontinuado*: Não é necessário, pois a única interface para conexão é a digitação do código/URL remota ou scanner de QR Code.

### Decisão 4: Simplificação do `BannerModoExperimental`
- **Abordagem**:
  - Remover o `ValueListenableBuilder<Duration?>` aninhado que escutava `widget.editorDeCroqui.timeRemaining`.
  - O banner agora tem estrutura mais limpa: exibe o ícone `Icons.bolt`, o texto `'MODO EXPERIMENTAL ATIVO'` e o botão `'SAIR'` (quando fornecido).
  - Mantém o `AnimatedBuilder` para a cor de fundo pulsante durante o Live Reload (`notificadorGatilhoRecarregamento`).

## Risks / Trade-offs

- **[Risco: Testes existentes falhando devido à remoção de `timeRemaining` ou `forceResetTimer`]** → **Mitigação**: Atualizar previamente os testes de `experimental_mode_test.dart` e `banner_modo_experimental_test.dart`, seguindo TDD rigoroso para validar o novo comportamento antes de finalizar o código.
- **[Risco: Inconsistência no arquivo YAML salvo com chaves legadas `expiryTime`]** → **Mitigação**: `loadFromDisk` e `_writeConfig` ignoram ou removem a chave `expiryTime` de forma graciosa sem gerar exceções.
- **[Risco: Modificação acidental no submódulo `aresta_api`]** → **Mitigação**: Nenhuma alteração será feita em `frontend/lib/aresta_api/`, garantindo compatibilidade com o repositório externo.

## Migration Plan

1. Nenhuma migração de banco de dados é necessária.
2. Arquivos de configuração legados `editor_config.yaml` que possuírem `expiryTime` serão lidos normalmente sem erros e a chave será desconsiderada.
