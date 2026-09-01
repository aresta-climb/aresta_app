## Why

O Google Play anunciou novos requisitos técnicos de qualidade obrigatórios para 2026/2027 focados em redução de consumo de memória (Anonymous RSS + Swap e Bitmaps < 200 MB em background) e otimização mínima de 25% de código DEX. Além disso, o binário atual do Aresta não possui ofuscação/shrinking nativo (R8 no Android, ThinLTO no iOS, e ofuscação no Dart), o que gera binários desnecessariamente grandes e deixa de proteger a base de código.

Em estrita consonância com os princípios de engenharia do Aresta (PRINCIPIOS.md: tudo em português, TDD estrito Red-Green-Refactor, 100% de cobertura de testes, simplicidade e documentação contínua via docstrings `///`), esta mudança implementa a gestão eficiente de memória de imagens, downsampling de miniaturas, preservação de cache LRU equilibrado que poupa bateria na rocha, otimizações agressivas de compilação e automação de CI/CD para desofuscação no Google Play Console e Firebase Crashlytics.

## What Changes

- **Gestão de Memória e Bitmaps (Flutter / Dart):**
  - Implementar decodificação com downsampling (`cacheWidth`/`cacheHeight` ou `ResizeImage`) para todas as miniaturas em cards, listas de picos e setores, reduzindo o uso de RAM por miniatura de ~16 MB para < 200 KB.
  - Configurar teto de cache de imagens LRU (`PaintingBinding.instance.imageCache.maximumSizeBytes` de 100 MB) para garantir retenção das últimas 5-6 fotos em tela cheia sem exceder o teto de 200 MB em background do Google Play.
  - Tratar alertas críticos de memória do sistema operacional (`onTrimMemory` / `AppLifecycleState.paused` sob baixa memória).
  - Toda a lógica e widgets em Dart serão desenvolvidos via TDD estrito com 100% de cobertura de testes e identificadores em português brasileiro.
- **Otimização de Build Android (R8 & Shrinking):**
  - Habilitar `isMinifyEnabled = true` e `isShrinkResources = true` com `proguard-android-optimize.txt` em `frontend/android/app/build.gradle.kts`.
  - Criar `frontend/android/app/proguard-rules.pro` com regras de preservação para `WorkManager`, `Protobuf`, `Google Maps` e `Firebase`.
- **Ofuscação de Código Dart & Otimizações iOS:**
  - Ativar `--obfuscate --split-debug-info` nos builds de release (AAB e IPA) no GitHub Actions.
  - Configurar Link-Time Optimization (`LLVM_LTO = YES_THIN`) e Dead Code Stripping no projeto iOS.
- **Automação de CI/CD e Desofuscação no Crashlytics:**
  - Atualizar `.github/workflows/build_android.yml` para enviar o `mapping.txt` do R8 para o Google Play Console (Android Vitals) e fazer upload de símbolos Dart/R8 para o Firebase Crashlytics.
  - Atualizar `.github/workflows/build_ios.yml` para fazer upload de dSYMs da Apple e símbolos Dart para o Firebase Crashlytics.
- **Documentação e Padrões:**
  - Documentação em docstrings `///` em português em todas as classes, métodos e widgets novos/modificados.
  - Atualização dos arquivos `README.md` pertinentes no frontend.

## Capabilities

### New Capabilities
- `otimizacao-compilacao-build`: Configurações de R8 (Android), ThinLTO (iOS), ofuscação Dart (`--obfuscate --split-debug-info`) e pipeline de desofuscação de crashes no Firebase Crashlytics e Google Play Console.
- `gestao-memoria-vitals`: Gestão de memória do Flutter com decodificação downsampled de miniaturas, orçamento de cache LRU de 100 MB e resposta a avisos de memória crítica do sistema.

### Modified Capabilities
- `local-thumbnail-cache`: As miniaturas salvas localmente agora DEVEM ser decodificadas com restrição de dimensões (`cacheWidth`/`cacheHeight`) para evitar alocação de bitmaps em resolução máxima na memória RAM.

## Impact

- **Build & CI/CD**: Arquivos `.github/workflows/build_android.yml`, `.github/workflows/build_ios.yml`, `frontend/android/app/build.gradle.kts`, `frontend/android/app/proguard-rules.pro`.
- **Flutter / Dart**: `frontend/lib/main.dart` (configuração do `imageCache`), `frontend/lib/view_functions/browse_functions.dart`, `frontend/lib/widgets/mapa_thumbnail.dart`, `frontend/lib/pages/grupo.dart`, `frontend/lib/pages/setor.dart`.
- **Testes (TDD)**: Testes de unidade e widgets correspondentes em `frontend/test/` com 100% de cobertura.
- **Documentação**: Atualização de docstrings e `frontend/README.md`.
- **Crashlytics / Play Console**: Relatórios de crashes continuarão 100% legíveis via upload automatizado de `mapping.txt`, `.symbols` e `dSYMs`.