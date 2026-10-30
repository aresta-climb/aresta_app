# Spec Delta

## MODIFIED Requirements

### Requirement: Android R8 e Redução de Recursos (Resource Shrinking)
O sistema de build do Android DEVE (MUST) compilar o aplicativo em modo release com minificação de código (R8), encolhimento de recursos (`isShrinkResources`), otimização de bytecode em R8 Full Mode, reempacotamento de classes (`-repackageclasses`) e permissão de modificação de acesso (`-allowaccessmodification`) habilitados.

#### Scenario: Compilação de Release do Android
- **WHEN** o Gradle compilar a variante de `release` do Android
- **THEN** `isMinifyEnabled = true` e `isShrinkResources = true` são aplicados com as regras do `proguard-android-optimize.txt`, `proguard-rules.pro` com `-repackageclasses 'app.escalada.croquis.r8'` e `-allowaccessmodification`, e `android.enableR8.fullMode=true` no `gradle.properties`
