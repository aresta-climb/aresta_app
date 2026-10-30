# otimizacao-compilacao-build Specification

## Purpose

Define os requisitos de otimização de compilação em release para Android e iOS, cobrindo minificação R8, ofuscação Dart, geração de símbolos de depuração e redução de recursos.

## Requirements

### Requirement: Android R8 e Redução de Recursos (Resource Shrinking)
O sistema de build do Android DEVE (MUST) compilar o aplicativo em modo release com minificação de código (R8), otimização de bytecode em R8 Full Mode, reempacotamento de classes (`-repackageclasses`) e permissão de modificação de acesso (`-allowaccessmodification`) habilitados, mantendo o encolhimento de recursos (`isShrinkResources`) desativado para preservar a integridade estrutural de todos os blocos `ResTable_typeSpec` na tabela `resources.arsc` em APKs divididos de App Bundles.

#### Scenario: Compilação de Release do Android
- **WHEN** o Gradle compilar a variante de `release` do Android
- **THEN** `isMinifyEnabled = true` e `isShrinkResources = false` são aplicados com as regras do `proguard-android-optimize.txt`, `proguard-rules.pro` com `-repackageclasses 'app.escalada.croquis.r8'` e `-allowaccessmodification`, e `android.enableR8.fullMode=true` no `gradle.properties`

### Requirement: Regras de Preservação do ProGuard
O arquivo de regras ProGuard DEVE preservar atributos essenciais para stacktraces e membros críticos sem utilizar regras genéricas de preservação total em bibliotecas que possuem suas próprias Consumer ProGuard Rules, preservando asserções defensivas de runtime e delegando a poda de corrotinas do Kotlin ao consumidor nativo.

#### Scenario: Execução de Tarefas em Segundo Plano e Serialização
- **WHEN** o app compilar em modo release com R8
- **THEN** o `proguard-rules.pro` preserva atributos de anotação e depuração (`*Annotation*`, `Signature`, `InnerClasses`, `EnclosingMethod`, `SourceFile`, `LineNumberTable`), delega a otimização de Firebase, Google Play Services, AndroidX WorkManager, MLKit e Kotlin Coroutines às suas respectivas Consumer Rules, suprime warnings não críticos com `-dontwarn`, e mantém todas as asserções e verificações de parâmetros do Kotlin sem supressão por `-assumenosideeffects`

### Requirement: Ofuscação do Código Dart e Geração de Símbolos
O build de produção para Android e iOS DEVE compilar o código Dart com ofuscação habilitada e extração de tabelas de símbolos de depuração para diretório externo.

#### Scenario: Build de Release via CI/CD
- **WHEN** a GitHub Action executa `flutter build appbundle` ou `flutter build ipa`
- **THEN** as flags `--obfuscate` e `--split-debug-info=<diretório>` são fornecidas e os arquivos `.symbols` são gerados

### Requirement: Upload de Símbolos e Mapping para Desofuscação
O pipeline de CI/CD DEVE fazer o upload do arquivo `mapping.txt` do R8, dos arquivos `.symbols` de Dart e dos `dSYMs` da Apple para o Google Play Console e Firebase Crashlytics.

#### Scenario: Deploy automatizado no GitHub Actions
- **WHEN** a release é construída no GitHub Actions
- **THEN** o `mapping.txt` é enviado ao Google Play Console no step de upload do bundle, e os símbolos Dart e dSYMs nativos são enviados ao Firebase Crashlytics
