## Context

O build de produção do aplicativo para Android é gerado pelo GitHub Actions no workflow `build_android.yml` utilizando `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols`. A publicação no Google Play Console é executada de forma automatizada pela action `r0adkll/upload-google-play@v1`.

Atualmente, o Google Play Console reporta dois avisos de qualidade e diagnóstico:
1. Ausência de símbolos nativos de depuração para código C/C++ (`libapp.so`, `libflutter.so`, bibliotecas de plugins).
2. Baixa taxa de otimização (35%), ofuscação (36%) e redução (36%) calculada pelo Android Vitals decorrente de regras genéricas de ProGuard (`-keep class ... { *; }`).

## Goals / Non-Goals

**Goals:**
- Compactar as bibliotecas nativas geradas durante a compilação Android em `native-debug-symbols.zip` e fornecê-las ao Google Play Console via parâmetro `debugSymbols`.
- Preservar o artefato `native-debug-symbols.zip` no retention do GitHub Actions para auditoria e depuração retroativa.
- Limpar as regras manuais redundantes do `proguard-rules.pro`, delegando a otimização de bibliotecas externas (Firebase, Google Play Services, MLKit, WorkManager e Flutter) para suas respectivas Consumer Rules embutidas.
- Habilitar expressamente o R8 Full Mode no `gradle.properties` (`android.enableR8.fullMode=true`).
- Elevar a taxa de otimização/redução do R8 para o patamar padrão de 75% a 90%, reduzindo o tamanho do DEX e o consumo de memória RAM do app.

**Non-Goals:**
- Alterar o pipeline de símbolos Dart do Firebase Crashlytics (que já extrai de `build/symbols` e funciona como esperado).
- Modificar o pipeline de compilação ou regras do iOS (`build_ios.yml`).
- Criar regras ProGuard personalizadas e manuais classe a classe quando as Consumer Rules dos pacotes já cobrem o comportamento.

## Decisions

### Decisão 1: Empacotamento das bibliotecas nativas e upload via `r0adkll/upload-google-play`

- **Abordagem**: Após a execução de `flutter build appbundle`, adicionar um step no `build_android.yml` que localiza a pasta de bibliotecas compiladas intermediárias (`build/app/intermediates/merged_native_libs/release/.../lib`), compacta seu conteúdo em `frontend/build/native-debug-symbols/native-debug-symbols.zip` e configura `debugSymbols: frontend/build/native-debug-symbols/native-debug-symbols.zip` na action `r0adkll/upload-google-play@v1`.
- **Por que não depender só do `ndk.debugSymbolLevel` no Gradle?**: O compilador AOT do Flutter (`gen_snapshot`) e o motor do Flutter geram binários pré-limpos (*stripped*). Por isso, a extração padrão do Gradle falha em gerar tabelas válidas de símbolos nos metadados internos do bundle, exigindo o envio do pacote de símbolos nativos via API de desofuscação (`nativeCode`).
- **Alternativas descartadas**:
  - *Upload manual via console web*: Quebra a automação completa do pipeline de CI/CD.

### Decisão 2: Enxugamento do `proguard-rules.pro` em favor de Consumer Rules

- **Abordagem**: Remover os blocos que usam `-keep class <pacote>.** { *; }` para `io.flutter.**`, `androidx.work.**`, `com.google.protobuf.**`, `com.google.android.gms.**`, `com.google.firebase.**` e `com.google.mlkit.**`. Manter apenas:
  - Preservação de atributos fundamentais para stack traces e Crashlytics: `-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod,SourceFile,LineNumberTable`.
  - Supressão de warnings não-fatais com `-dontwarn`.
  - Preservação de reflexão em corrotinas Kotlin: `-keepclassmembers class kotlinx.coroutines.** { *; }`.
- **Por que?**: Todas as bibliotecas citadas são empacotadas em formato AAR moderno com arquivos `consumer-rules.pro` que já indicam exatamente quais classes e métodos necessitam de reflection. O uso de `{ *; }` desativa a poda de código morto em 65% do app, gerando o alerta de baixa taxa de otimização na Play Store.

### Decisão 3: Habilitação explícita do R8 Full Mode

- **Abordagem**: Adicionar `android.enableR8.fullMode=true` ao `frontend/android/gradle.properties`.
- **Por que?**: Garante que o R8 aplique agressivamente otimizações de escopo global (inlining mais profundo, mesclagem de classes e remoção de membros não invocados), prevenindo modos de compatibilidade legados.

## Risks / Trade-offs

- **[Risco] Remoção indevida de classes por reflexão no R8 Full Mode**  
  *Mitigação*: A preservação de atributos essenciais (`*Annotation*`, `Signature`, `InnerClasses`, etc.) e as Consumer Rules oficiais do Firebase, Play Services e WorkManager garantem que nenhuma classe acessada via JNI ou reflection crítica seja removida.
- **[Risco] Variação do caminho de bibliotecas nativas intermediárias no AGP**  
  *Mitigação*: O script no GitHub Actions verifica tanto `merged_native_libs/release/mergeReleaseNativeLibs/out/lib` quanto `merged_native_libs/release/out/lib` antes de gerar o arquivo zip.
