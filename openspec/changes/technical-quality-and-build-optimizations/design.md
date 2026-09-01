## Context

O Google Play introduziu novas métricas de qualidade técnica no Android Vitals para 2026/2027 com enforcements mandatórios:
1. **Memory Usage (P90) & Bitmaps em Background:** O uso de bitmaps por aplicativos fora do primeiro plano (em background ou com UI oculta) não pode ultrapassar 200 MB (P90).
2. **Otimização de Código DEX:** Aplicações com DEX > 10 MB devem apresentar pelo menos 25% de redução, otimização e ofuscação de código (R8).

O Aresta é um aplicativo Flutter para escalada em rocha (offline-first), onde o usuário visualiza croquis detalhados, mapas e listas de setores. Atualmente, miniaturas de listas são decodificadas sem restrição de tamanho de buffer (`cacheWidth`/`cacheHeight`), o cache de imagens do Flutter usa limites padrões não ajustados e o build de release do Android não tem R8 (`isMinifyEnabled`) configurado, assim como o build de iOS e Dart não aplicam ofuscação e ThinLTO.

Todas as decisões e implementações deste design obedecem rigorosamente aos **Princípios de Engenharia do Aresta App (PRINCIPIOS.md)**:
- Todo o código, comentários, docstrings e documentações são em português brasileiro.
- Desenvolvimento orientado a testes (TDD obrigatório, Red-Green-Refactor).
- Cobertura de 100% de testes unitários e de widget.
- Código simples, declarativo e sem abstrações prematuras.
- Documentação contínua (`///` detalhando o *porquê* e atualizações nos `README.md`).

## Goals / Non-Goals

**Goals:**
- Implementar decodificação com downsampling em todas as miniaturas de listas e cards (armazenando ~160 KB por miniatura na RAM em vez de ~16 MB), testado via TDD com cobertura de 100%.
- Configurar um teto global de LRU de 100 MB para o `imageCache` do Flutter, retendo os últimos 5-6 croquis completos em alta resolução para consulta rápida sem recarregar e sem estourar o limite de 200 MB da Google Play.
- Ativar minificação R8 (`isMinifyEnabled = true`, `isShrinkResources = true`, `proguard-android-optimize.txt`) e regras ProGuard para o Android.
- Ativar ofuscação no código Dart (`--obfuscate --split-debug-info`) no pipeline de CI/CD para Android e iOS.
- Ativar ThinLTO e Dead Code Stripping no projeto iOS.
- Automatizar no GitHub Actions o upload de `mapping.txt` (Play Console e Crashlytics), `.symbols` (Dart) e `dSYMs` (iOS) para manter relatórios de erro no Firebase Crashlytics e Android Vitals 100% legíveis e desofuscados.
- Garantir que todos os arquivos `.dart` modificados/criados tenham seus correspondentes `_test.dart` em `test/` espelhando a hierarquia de `lib/`.

**Non-Goals:**
- Implementar sistema de login/Restore Credentials API (o app opera sem autenticação de usuário).
- Alterar o formato de armazenamento dos arquivos no disco (as imagens locais já utilizam WebP q=85 e área máx de 4 MP).
- Expurgar o cache inteiro a cada bloqueio de tela (o que gastaria bateria desnecessária na pedra).

## Decisions

### 1. Downsampling de Imagens via `cacheWidth` e `ResizeImage`
- **Decisão:** Em todos os componentes que exibem listas de crags, setores ou cards (como `browse_functions.dart` e `mapa_thumbnail.dart`), utilizar `cacheWidth: 300` ou `ResizeImage` com dimensões limitadas.
- **Alternativa considerada:** Carregar `Image.file` direto sem `cacheWidth`. *Rejeitada porque decodifica o bitmap em resolução total (~16 MB por item), estourando a RAM em listas longas.*
- **Alinhamento com PRINCIPIOS.md:** Nomes de parâmetros e helpers auxiliares em português brasileiro, com testes de widget prévios validando a renderização correta.

### 2. Cache LRU Global de 100 MB
- **Decisão:** Na inicialização do Flutter (`main.dart`), configurar `PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024` (100 MB).
- **Alternativa considerada:** Chamar `imageCache.clear()` toda vez que o app for pausado/bloqueado. *Rejeitada pois prejudica o escalador na rocha, que bloqueia e desbloqueia o celular com frequência e sofreria consumo extra de bateria e latência ao reabrir o croqui.*
- **Alinhamento com PRINCIPIOS.md:** Função declarativa em português com docstring `///` explicando a intenção do teto de memória e teste unitário cobrindo o setup.

### 3. R8 e ProGuard Rules no Android
- **Decisão:** Ativar `isMinifyEnabled = true` e `isShrinkResources = true` em `android/app/build.gradle.kts` usando `proguard-android-optimize.txt` e um arquivo `proguard-rules.pro` customizado preservando `androidx.work.*`, `com.google.protobuf.*`, `com.google.android.gms.maps.*` e `com.google.firebase.*`.
- **Alternativa considerada:** Manter minificação desativada. *Rejeitada pois não cumpriria o requisito de >= 25% de shrinking de DEX da Play Store.*

### 4. Ofuscação Dart com `--split-debug-info` no GitHub Actions
- **Decisão:** Passar `--obfuscate --split-debug-info=build/symbols/...` no comando do Flutter nos workflows de CI/CD e adicionar etapas para enviar os símbolos ao Firebase Crashlytics e o `mapping.txt` ao Google Play Console via action `upload-google-play`.
- **Alternativa considerada:** Manter o código Dart não ofuscado. *Rejeitada pois a ofuscação reduz 10-20% do tamanho do binário compilado e protege a lógica de negócio.*

### 5. ThinLTO e Dead Code Stripping no iOS
- **Decisão:** Configurar `LLVM_LTO = YES_THIN` e `DEAD_CODE_STRIPPING = YES` para o build de Release do Xcode e enviar `dSYMs` ao Crashlytics.
- **Alternativa considerada:** Manter LTO padrão desativado no iOS. *Rejeitada pois ThinLTO reduz significativamente o tamanho do binário final dos frameworks no iOS.*

### 6. Estratégia de Testes (TDD) e Documentação
- **Decisão:** O ciclo de desenvolvimento para cada tarefa em Dart seguirá estritamente o ciclo Vermelho-Verde-Refatorar (Red-Green-Refactor). Antes de tocar em qualquer arquivo em `lib/`, o teste correspondente em `test/` será criado e executado para verificar a falha. A cobertura total da suíte deve atingir 100%. Todos os métodos e widgets conterão docstrings `///` em português.

## Risks / Trade-offs

- **[R8 remover classes necessárias para reflexão nos plugins]** → Mitigado criando regras explícitas no `proguard-rules.pro` para WorkManager, Protobuf, Maps e Firebase, e testando o build de release localmente antes do deploy.
- **[Crashes aparecerem ofuscados no Firebase Crashlytics]** → Mitigado automatizando o upload de `mapping.txt`, `.symbols` de Dart e `dSYMs` no pipeline do GitHub Actions.
- **[Imagens de croqui perderem nitidez ao dar zoom]** → Mitigado aplicando `cacheWidth` apenas em miniaturas e listas de navegação; a tela cheia de croqui interativo continua carregando a resolução total de 4 MP.