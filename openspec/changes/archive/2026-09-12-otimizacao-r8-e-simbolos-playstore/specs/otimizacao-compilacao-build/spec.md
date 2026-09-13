## MODIFIED Requirements

### Requirement: Android R8 e Redução de Recursos (Resource Shrinking)
O sistema de build do Android DEVE compilar o aplicativo em modo release com minificação de código (R8), otimização de bytecode em R8 Full Mode e redução de recursos não utilizados (resource shrinking) habilitados.

#### Scenario: Compilação de Release do Android
- **WHEN** o Gradle compilar a variante de `release` do Android
- **THEN** `isMinifyEnabled` e `isShrinkResources` são aplicados com as regras do `proguard-android-optimize.txt`, `proguard-rules.pro` e `android.enableR8.fullMode=true` no `gradle.properties`

### Requirement: Regras de Preservação do ProGuard
O arquivo de regras ProGuard DEVE preservar atributos essenciais para stacktraces e membros críticos sem utilizar regras genéricas de preservação total em bibliotecas que possuem suas próprias Consumer ProGuard Rules.

#### Scenario: Execução de Tarefas em Segundo Plano e Serialização
- **WHEN** o app compilar em modo release com R8
- **THEN** o `proguard-rules.pro` preserva atributos de anotação e depuração (`*Annotation*`, `Signature`, `InnerClasses`, `EnclosingMethod`, `SourceFile`, `LineNumberTable`), delega a otimização de Firebase, Google Play Services, AndroidX WorkManager e MLKit às suas respectivas Consumer Rules, e suprime warnings não críticos com `-dontwarn`
