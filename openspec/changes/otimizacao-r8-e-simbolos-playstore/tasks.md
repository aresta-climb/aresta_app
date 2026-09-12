## 1. Otimização do R8 e Limpeza do ProGuard

- [ ] 1.1 Atualizar `frontend/android/app/proguard-rules.pro` removendo wildcards amplos (`io.flutter.**`, `androidx.work.**`, `com.google.protobuf.**`, `com.google.android.gms.**`, `com.google.firebase.**` e `com.google.mlkit.**`), mantendo atributos de stacktrace, reflexão de corrotinas e supressões `-dontwarn`, e verificar que as regras atendem às Consumer Rules oficiais
- [ ] 1.2 Habilitar expressamente `android.enableR8.fullMode=true` em `frontend/android/gradle.properties` e verificar a configuração
- [ ] 1.3 Validar sintaxe das regras do ProGuard e compilação Gradle localmente ou via análise estática

## 2. Pipeline de Símbolos Nativos no GitHub Actions

- [ ] 2.1 Adicionar step no `.github/workflows/build_android.yml` que localiza as bibliotecas compiladas em `merged_native_libs/release/.../lib` e gera o arquivo `native-debug-symbols.zip`
- [ ] 2.2 Configurar o parâmetro `debugSymbols` apontando para `native-debug-symbols.zip` na action `r0adkll/upload-google-play@v1` no workflow `build_android.yml`
- [ ] 2.3 Incluir `native-debug-symbols.zip` na lista de caminhos do step `Upload Android Release Artifacts` no `build_android.yml` com retenção de 90 dias

## 3. Validação e Qualidade

- [ ] 3.1 Executar a suíte completa de testes automatizados com `flutter test` e verificar 100% de sucesso
- [ ] 3.2 Executar `flutter analyze --fatal-infos --fatal-warnings` no frontend e verificar conformidade estrita sem warnings
