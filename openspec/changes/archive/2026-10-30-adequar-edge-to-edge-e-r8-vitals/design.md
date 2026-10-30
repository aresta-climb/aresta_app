# Design

## Context

Conforme detalhado em `proposal.md`, o Google Play Console reportou duas recomendações do Android Vitals para o bundle `100.aab` (`0.6.1`):
1. **Exibição de ponta a ponta (`edge-to-edge`)**: Como o aplicativo segmenta `targetSdk = 36`, dispositivos com Android 15+ (SDK 35+) já forçam a janela a desenhar atrás das barras de sistema, enquanto o Android 8 a 14 (SDK 26 a 34) não entra em `edge-to-edge` automaticamente sem configuração explícita no Flutter. Além disso, três telas específicas (`QRScannerPage`, `SettingsPage` e `MapaGlobalPage`) não aplicavam o recuo inferior (`MediaQuery.paddingOf(context).bottom`), causando sobreposição em aparelhos com navegação por 3 botões (`48 dp`).
2. **Otimização do R8 e Redução de Recursos**: Na versão `0.6.1`, `isShrinkResources` esteve temporariamente desativado (`false`), o que desabilitou em cascata a redução de recursos e a redução de recursos otimizada no relatório do bundle. Com a correção da Issue #20 e reativação de `isShrinkResources = true` na `main`, convém declarar explicitamente `android.r8.optimizedResourceShrinking=true` em `frontend/android/gradle.properties` para blindar o pipeline unificado de recursos e código do R8 no AGP 9.0.1.

## Goals / Non-Goals

**Goals:**
- Habilitar `SystemUiMode.edgeToEdge` e barras do sistema transparentes na inicialização do app de forma rápida, determinística e testável via `configurarExibicaoPontaAPonta()`.
- Corrigir os recuos inferiores (`MediaQuery.paddingOf(context).bottom`) em `QRScannerPage`, `SettingsPage` e `MapaGlobalPage`.
- Declarar `android.r8.optimizedResourceShrinking=true` em `frontend/android/gradle.properties`.
- Garantir 100% de cobertura comportamental via TDD nos arquivos modificados, seguindo os princípios do `AGENTS.md`.

**Non-Goals:**
- Migrar `MainActivity.kt` de `FlutterActivity` para `FlutterFragmentActivity`, preservando intocado o ciclo de vida nativo da `SurfaceView` e a blindagem contra flash branco em Cold/Warm Start.

## Decisions

### 1. Ativação de Edge-to-Edge via `SystemChrome` em `inicializacao_app.dart` (Opção 1)
- **Escolha**: Criar `Future<void> configurarExibicaoPontaAPonta()` em `frontend/lib/services/inicializacao_app.dart` (re-exportado em `main.dart`) que invoca `SystemChrome.setSystemUIOverlayStyle(...)` com barras transparentes e `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)`, chamando-o em `main()`.
- **Alternativas consideradas**:
  - *Migrar `MainActivity` para `FlutterFragmentActivity` e chamar `enableEdgeToEdge()` nativo (Opção 3)*: Descartado porque adiciona uma camada de `Fragment` ao redor da `FlutterView`, introduzindo risco desnecessário na restauração da superfície gráfica (`onStop` / `window.setBackgroundDrawable`) apenas para silenciar uma heurística estática do console que procura `ComponentActivity.enableEdgeToEdge`.
  - *Alterar `windowDrawsSystemBarBackgrounds` nos `styles.xml` da `LaunchTheme`*: Descartado para o `LaunchTheme` porque o `flutter_native_splash` gerencia a transição da splash screen no Cold Start, e o `FlutterActivity` já transiciona para `NormalTheme` e delega o controle das barras do sistema ao `SystemChrome` do Flutter.

### 2. Uso de `MediaQuery.paddingOf(context).bottom` nas 3 telas afetadas
- **Escolha**:
  - `QRScannerPage`: `Positioned(bottom: 40 + MediaQuery.paddingOf(context).bottom, left: 0, right: 0, ...)`
  - `SettingsPage`: `ListView(padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.paddingOf(context).bottom), ...)`
  - `MapaGlobalPage`: `GoogleMap(..., padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom))`
- **Racional**: `MediaQuery.paddingOf(context)` inscreve o widget apenas em mudanças da propriedade `padding` (e não em `viewInsets` de teclado ou tamanho de tela), evitando reconstruções desnecessárias e mantendo o fundo do `Scaffold` / câmera / mapa contínuo até a borda física inferior (verdadeiro *edge-to-edge*) enquanto desloca apenas os elementos interativos/informativos para dentro da área segura.

### 3. Explicitação de `android.r8.optimizedResourceShrinking=true` no `gradle.properties`
- **Escolha**: Adicionar `android.r8.optimizedResourceShrinking=true` em `frontend/android/gradle.properties`.
- **Racional**: Embora o AGP 9.0+ ative o *optimized resource shrinking* por padrão quando `isShrinkResources = true`, declará-lo explicitamente documenta o contrato arquitetural exigido pelo Android Vitals e protege contra variações de comportamento entre versões do Gradle/AGP.

## Risks / Trade-offs

- **[Aviso informativo residual no Play Console sobre `enableEdgeToEdge()`]** → Como o scanner estático do Google Play Console verifica a presença da chamada Kotlin `ComponentActivity.enableEdgeToEdge()`, apps baseados em `FlutterActivity` podem continuar vendo a recomendação informativa no console mesmo operando em `edge-to-edge` real via `SystemChrome`. Isso não afeta a publicação nem a experiência real do usuário.
- **[Poda de recursos não referenciados estaticamente pelo R8]** → O único recurso carregado por string em plugins nativos (`@mipmap/ic_launcher` no `flutter_local_notifications`) já é referenciado estaticamente no `AndroidManifest.xml`, estando protegido contra remoção pelo grafo unificado do R8.
