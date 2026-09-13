## Why

Os lançamentos de release para Android na Google Play Store apresentaram dois alertas no Google Play Console:
1. "Este App Bundle contém código nativo, e você não fez upload dos símbolos de depuração", decorrente da ausência do upload de símbolos nativos descompactados (`native-debug-symbols.zip`) na ação do GitHub Actions (`r0adkll/upload-google-play`).
2. "Melhore a memória e o desempenho do seu app com a otimização do R8", alertando para baixas taxas de otimização (35%), ofuscação (36%) e redução (36%), provocadas por regras genéricas e redundantes de `-keep class ... { *; }` no `proguard-rules.pro` que paralisaram o trabalho do R8 em mais de 60% do bytecode externo.

Esta mudança visa eliminar ambos os avisos, restabelecendo a alta performance de execução e inicialização do app no Android e garantindo diagnóstico completo de falhas nativas e ANRs.

## What Changes

- **Empacotamento e Upload de Símbolos Nativos no CI/CD**:
  - No workflow `build_android.yml`, compactar o diretório de bibliotecas nativas intermediárias do Gradle (`merged_native_libs/release/.../lib`) em um arquivo `native-debug-symbols.zip`.
  - Passar o arquivo `native-debug-symbols.zip` para a action `r0adkll/upload-google-play@v1` via parâmetro `debugSymbols`.
  - Incluir `native-debug-symbols.zip` entre os artefatos preservados pelo `actions/upload-artifact`.
- **Enxugamento do ProGuard / R8 e Ativação do R8 Full Mode**:
  - Remover regras manuais excessivas com wildcards `{ *; }` para `io.flutter.**`, `com.google.firebase.**`, `com.google.android.gms.**`, `com.google.mlkit.**`, `com.google.protobuf.**` e `androidx.work.**`, permitindo que as regras de consumidor (*consumer rules*) nativas de cada biblioteca façam a preservação cirúrgica.
  - Manter apenas as regras essenciais de stack traces (`-keepattributes`), supressão de avisos não críticos (`-dontwarn`) e preservação de membros de corrotinas.
  - Garantir a ativação explícita de `android.enableR8.fullMode=true` no `gradle.properties`.

## Capabilities

### New Capabilities

*(Nenhuma nova capacidade introduzida)*

### Modified Capabilities

- `pipeline-simbolos-e-artefatos-release`: Adiciona requisitos para empacotamento, arquivamento e upload automatizado dos símbolos nativos NDK (`native-debug-symbols.zip`) para a Google Play Store via GitHub Actions.
- `otimizacao-compilacao-build`: Atualiza os requisitos de minificação e ofuscação do R8, refinando as regras do ProGuard para eliminar wildcards excessivos e garantir R8 Full Mode com alta taxa de otimização de bytecode.

## Impact

- **CI/CD (`.github/workflows/build_android.yml`)**: Inclusão de step de compactação de símbolos nativos e envio no step `Upload to Google Play Console`.
- **Configuração Android (`frontend/android/app/proguard-rules.pro` e `frontend/android/gradle.properties`)**: Limpeza das regras do R8 e habilitação explícita do `android.enableR8.fullMode`.
- **Tamanho e Performance**: Redução do tamanho final do `.dex` e economia de memória RAM na inicialização do app Android.
