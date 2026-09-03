# Design: Pipeline de Símbolos e Artefatos de Release

## Context

O Aresta utiliza o Firebase Crashlytics para monitoramento e diagnóstico de estabilidade em produção. Recentemente, relatórios de crash no iOS foram recebidos sem desofuscação de pilha de chamadas (*unsymbolicated*), apontando a falta de arquivos `.dSYM`.

Historicamente, o App Store Connect disponibilizava o download de dSYMs gerados por recompilação de Bitcode. Com a remoção do Bitcode no Xcode 14+, os arquivos `.dSYM` e tabelas de símbolos Dart passam a existir apenas no ambiente efêmero da máquina de CI (GitHub Actions). Sem um passo explícito de envio ao Firebase e sem retenção de artefatos, esses arquivos eram descartados ao término da execução do workflow.

## Goals / Non-Goals

**Goals:**
- Configurar o upload automatizado de símbolos de depuração (`dSYMs` do iOS e `.symbols` do Dart) para o Firebase Crashlytics diretamente no GitHub Actions para iOS e Android.
- Configurar a retenção versionada de todos os artefatos de release (.ipa, .aab, dSYMs, símbolos Dart e mapeamentos ProGuard) como GitHub Actions Artifacts com retenção de 90 dias.
- Manter o pipeline seguro utilizando autenticação oficial com Service Account do Google Cloud / Firebase (`FIREBASE_SERVICE_ACCOUNT_JSON`).
- Documentar os passos de configuração e operação de credenciais.

**Non-Goals:**
- Modificar o código da aplicação Dart em `lib/` (a inicialização do Crashlytics em `init_firebase.dart` já está funcional).
- Publicar binários em canais de distribuição de terceiros não utilizados pelo projeto (ex: Firebase App Distribution).

## Decisions

### 1. Autenticação no Firebase via Service Account JSON
- **Decisão:** Utilizar uma Google Cloud Service Account com a permissão `Firebase Crashlytics Admin` armazenada no segredo `FIREBASE_SERVICE_ACCOUNT_JSON` do GitHub Actions.
- **Racional:** É o padrão recomendado pelo Google para ambientes de CI/CD não-interativos. Evita a expiração de tokens gerados via `firebase login:ci` (legado).
- **Alternativa considerada:** `FIREBASE_TOKEN` via login interativo legado. *Rejeitada pela depreciação anunciada pelo time do Firebase.*

### 2. Uso do `npx firebase-tools` para Upload de Símbolos
- **Decisão:** Executar `npx firebase-tools crashlytics:symbols:upload` apontando diretamente para o App ID e para os diretórios de símbolos (`dSYMs` e `build/symbols`).
- **Racional:** O Firebase CLI unifica o tratamento tanto de pastas `.dSYM` nativas do macOS/iOS quanto dos arquivos `.symbols` gerados pelo compilador AOT do Dart/Flutter.
- **Alternativa considerada:** Invocar o binário nativo `upload-symbols` do CocoaPods. *Rejeitada porque depende de paths específicos do CocoaPods e não suporta diretamente a desofuscação das tabelas de símbolos do Dart.*

### 3. Geração de Símbolos Dart com `--split-debug-info`
- **Decisão:** Adicionar a flag `--split-debug-info=build/symbols` nas etapas de `flutter build ipa` e `flutter build appbundle`.
- **Racional:** Permite que o Flutter extraia os símbolos para arquivos separados, reduzindo o tamanho do binário de distribuição e viabilizando o upload isolado para desofuscação no Crashlytics.

### 4. Retenção de Artefatos no GitHub Actions com `actions/upload-artifact@v4`
- **Decisão:** Armazenar os artefatos completos vinculados à tag da release (`ios-release-<tag>` e `android-release-<tag>`) com retenção de 90 dias.
- **Racional:** Garante rastreabilidade forense. Caso qualquer serviço de terceiros falhe ou precise de auditoria, o desenvolvedor pode baixar exatamente os binários e símbolos de qualquer release direto do GitHub.

## Risks / Trade-offs

- **[Ausência do secret `FIREBASE_SERVICE_ACCOUNT_JSON` no GitHub]** → Mitigado validando a presença da variável de ambiente no workflow ou exibindo mensagem de aviso caso a secret não esteja populada, garantindo instruções claras de configuração no README.
- **[Tempo adicional no pipeline de release]** → O comando `npx firebase-tools` adiciona menos de 30 segundos ao tempo total da pipeline, um impacto negligenciável diante do benefício de diagnósticos legíveis.
