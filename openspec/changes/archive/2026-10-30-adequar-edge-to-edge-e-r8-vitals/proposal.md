# Proposal

## Why

No Android 15+ (SDK 35/36), o sistema operacional força a renderização de ponta a ponta (*edge-to-edge*) por padrão, enquanto dispositivos com Android 8 a 14 (SDK 26 a 34) permanecem no modo legado se o aplicativo não habilitar `SystemUiMode.edgeToEdge`, gerando o alerta de experiência do usuário no Android Vitals e causando colisões visuais com a barra de navegação de 3 botões em telas específicas (`QRScannerPage`, `SettingsPage` e `MapaGlobalPage`). Adicionalmente, explicitar `android.r8.optimizedResourceShrinking=true` no `gradle.properties` blinda a configuração de redução otimizada de recursos do R8 exigida pelo diagnóstico de memória e desempenho do Google Play Console.

## What Changes

- **Ativação Unificada de Exibição de Ponta a Ponta (`edge-to-edge`)**:
  - Introduzir a função `configurarExibicaoPontaAPonta()` em `frontend/lib/services/inicializacao_app.dart` (invocada na inicialização em `frontend/lib/main.dart`), aplicando `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` e `SystemChrome.setSystemUIOverlayStyle` com barras de status e de navegação transparentes (`Colors.transparent`) e sem contraste forçado pelo sistema (`systemStatusBarContrastEnforced: false`, `systemNavigationBarContrastEnforced: false`).
- **Correção de Recuos Inferiores (*Window Insets*) nas Telas Afetadas**:
  - Em `QRScannerPage` (`frontend/lib/pages/qr_scanner.dart`), somar `MediaQuery.paddingOf(context).bottom` ao posicionamento inferior (`bottom: 40 + MediaQuery.paddingOf(context).bottom`) da pílula de instrução da câmera para evitar sobreposição com a barra de navegação de 3 botões.
  - Em `SettingsPage` (`frontend/lib/pages/configuracoes.dart`), incluir `MediaQuery.paddingOf(context).bottom` no `padding` inferior do `ListView` (`EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.paddingOf(context).bottom)`) para que o rodapé de versão nunca fique oculto atrás da barra de navegação do sistema.
  - Em `MapaGlobalPage` (`frontend/lib/pages/mapa_global.dart`), repassar `padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom)` ao widget `GoogleMap` para que o logotipo do Google e os controles inferiores do mapa respeitem a área segura do sistema operacional.
- **Blindagem da Redução de Recursos Otimizada do R8**:
  - Declarar explicitamente `android.r8.optimizedResourceShrinking=true` em `frontend/android/gradle.properties` em conjunto com `isShrinkResources = true` já ativo em `frontend/android/app/build.gradle.kts`, garantindo que o pipeline unificado de poda de código e recursos do R8 permaneça sempre habilitado e auditável.

## Capabilities

### New Capabilities
- `exibicao-ponta-a-ponta-insets`: Configuração unificada do modo `SystemUiMode.edgeToEdge` com barras do sistema transparentes na inicialização do aplicativo e respeito aos recuos inferiores do sistema operacional (*window insets*) nas telas de leitura de QR Code, Configurações e Mapa Global.

### Modified Capabilities
- `otimizacao-compilacao-build`: Inclusão da flag explícita `android.r8.optimizedResourceShrinking=true` no `gradle.properties` como parte dos requisitos de compilação release com R8 e redução de recursos.

## Impact

- **Inicialização e Configuração Flutter**: `frontend/lib/services/inicializacao_app.dart`, `frontend/lib/main.dart` e respectivos testes espelhados (`frontend/test/services/inicializacao_app_test.dart`, `frontend/test/main_test.dart`).
- **Telas de UI Flutter**: `frontend/lib/pages/qr_scanner.dart`, `frontend/lib/pages/configuracoes.dart`, `frontend/lib/pages/mapa_global.dart` e respectivos testes espelhados (`frontend/test/pages/qr_scanner_test.dart`, `frontend/test/pages/configuracoes_test.dart`, `frontend/test/pages/mapa_global_test.dart`).
- **Build Android / R8**: `frontend/android/gradle.properties`.
