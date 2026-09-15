## Context

Atualmente, o repositório conta com workflows no GitHub Actions para release unificada (`release_new_app_version.yml`), build Android (`build_android.yml`) e build iOS (`build_ios.yml`). As credenciais da Google Play Store (Service Account JSON) e do App Store Connect (chave de API `.p8`, Key ID e Issuer ID) já estão disponíveis nos GitHub Secrets do repositório.

## Goals / Non-Goals

**Goals:**
- Simplificar o acionamento de release através de um único seletor booleano de negócio `enviar_para_producao`.
- Validar as notas de versão logo no primeiro segundo do workflow (`length <= 500`), abortando precocemente antes de qualquer build.
- Enviar notas de lançamento formatadas em português (`whatsnew-pt-BR`) para o Google Play Console.
- Desacoplar o build do iOS (em runner macOS) da espera pelo processamento e submissão à App Store (em runner Linux gratuito), otimizando custos e tempo de máquina.
- Utilizar Fastlane `deliver` em Linux com `skip_binary_upload: true` para associar o build, aplicar as notas de versão, desativar rollout gradual e submeter para revisão oficial da Apple.

**Non-Goals:**
- Não gerar notas de versão automaticamente a partir de commits (o operador insere manualmente o texto desejado).
- Não poluir mensagens de commit ou anotações de tags com as notas de lançamento.
- Não utilizar liberação gradual em fases na App Store (`phased_release: false`).

## Decisions

### 1. Parâmetro Booleano `enviar_para_producao` Unificado
- **Decisão**: Substituir listas de tracks técnicas por um switch único `enviar_para_producao: true/false` no `workflow_dispatch`.
- **Racional**: Elimina descompasso entre Android e iOS. Quando ativo, publica em produção em ambas as lojas (`internal,production` no Android e submissão de App Review no iOS). Quando falso, restringe a teste interno no Google Play e TestFlight no iOS.
- **Alternativas consideradas**: Manter seletores independentes por plataforma (rejeitado por gerar complexidade cognitiva desnecessária).

### 2. Validação "Fail-Early" de Tamanho de Notas (< 500 Chars)
- **Decisão**: No primeiro job (`prepare_release`), checar `${#release_notes}` antes de qualquer operação Git ou Flutter.
- **Racional**: A Google Play Store impõe limite rígido de 500 caracteres para o campo `whatsnew`. Falhar no primeiro passo evita desperdício de tempo e criação de tags inválidas.
- **Alternativas consideradas**: Truncar silenciosamente as notas no Android (rejeitado para não desfigurar a mensagem do operador).

### 3. Pipeline iOS em Dois Estágios (macOS ➔ Linux)
- **Decisão**:
  - **Job 1 (macOS - `build_ios`)**: Executa `flutter build ipa` e sobe o binário para o App Store Connect via `altool` (tempo de runner macOS: ~8 a 10 min).
  - **Job 2 (Linux - `submit_ios_review`)**: Disparado com `needs: build_ios` apenas quando `enviar_para_producao == true`.
- **Racional**: A Apple leva entre 10 e 25 minutos processando o binário após o upload. Runners Linux em repositórios públicos são ilimitados e gratuitos, e o Fastlane em Linux executa perfeitamente chamadas HTTP REST para a App Store Connect API sem precisar do Xcode.
- **Alternativas consideradas**: Manter a espera no runner macOS (rejeitado pelo alto consumo de cotas de runner proprietário).

### 4. Fastlane `deliver` com `skip_binary_upload: true`
- **Decisão**: Configurar o Fastlane (`Fastfile` e `Appfile`) em `frontend/ios/` para usar a chave de API da Apple nativamente em base64 (`is_key_content_base64: true`) e pular o upload de binário.
- **Racional**: O binário já foi enviado no Job 1. O Job 2 apenas realiza polling até o status virar `VALID`, anexa à versão correspondente, injeta as `release_notes` em `pt-BR`, desativa fases e submete para revisão.
- **Alternativas consideradas**: Criar script customizado via `curl`/Python (rejeitado porque o Fastlane lida nativamente com timeouts, geração de JWT e paginação da API da Apple).

### 5. Telemetria Ativa via Polling e Pré-configuração de Environment
- **Decisão**: Executar o polling ativo com timestamps no Linux para registrar o tempo médio de processamento da Apple, associando o job ao GitHub Environment `appstore-review` (com timer baixo inicial de 1 minuto).
- **Racional**: Permite mensurar a média real de processamento antes de aumentar o timer de espera no servidor do GitHub no futuro.

## Risks / Trade-offs

- **[Apple demorar mais de 30 minutos no processamento do IPA]**  
  *Mitigação*: Configurar timeout de até 60 minutos no job Linux e logs frequentes de progresso a cada intervalo de verificação.
- **[Falta de informações de contato obrigatórias no App Store Connect na submissão]**  
  *Mitigação*: Assegurar que as informações de contato do revisor já estejam previamente salvas no painel do App Store Connect.
- **[Conflito com o bot existente de release notes do Git]**  
  *Mitigação*: O texto de notas de lançamento nunca é injetado nos commits ou nas tags do Git.
