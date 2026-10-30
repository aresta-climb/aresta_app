# Spec Delta

## MODIFIED Requirements

### Requirement: Android R8 e Redução de Recursos (Resource Shrinking)
O sistema de build do Android DEVE (MUST) compilar o aplicativo em modo release com minificação de código (R8), otimização de bytecode em R8 Full Mode, reempacotamento de classes (`-repackageclasses`) e permissão de modificação de acesso (`-allowaccessmodification`) habilitados, mantendo o encolhimento de recursos (`isShrinkResources`) desativado para preservar a integridade estrutural de todos os blocos `ResTable_typeSpec` na tabela `resources.arsc` em APKs divididos de App Bundles.

#### Scenario: Compilação de Release do Android
- **WHEN** o Gradle compilar a variante de `release` do Android
- **THEN** `isMinifyEnabled = true` e `isShrinkResources = false` são aplicados com as regras do `proguard-android-optimize.txt`, `proguard-rules.pro` com `-repackageclasses 'app.escalada.croquis.r8'` e `-allowaccessmodification`, e `android.enableR8.fullMode=true` no `gradle.properties`
