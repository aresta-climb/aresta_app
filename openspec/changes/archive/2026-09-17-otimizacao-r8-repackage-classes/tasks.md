## 1. Configuração do ProGuard e R8

- [x] 1.1 Atualizar `frontend/android/app/proguard-rules.pro` adicionando `-allowaccessmodification` e `-repackageclasses 'app.escalada.croquis.r8'` e verificar a sintaxe das regras
- [x] 1.2 Remover a diretiva redundante `-keepclassmembers class kotlinx.coroutines.** { *; }` de `frontend/android/app/proguard-rules.pro`, garantindo a ausência de qualquer supressão de checagens nulas do Kotlin (`-assumenosideeffects`)

## 2. Validação e Verificação da Compilação

- [x] 2.1 Executar a compilação de release do Android no frontend (`flutter build appbundle --release` ou `./gradlew assembleRelease`) e verificar que o R8 conclui com sucesso gerando o pacote sem erros de compilação
- [x] 2.2 Inspecionar o arquivo de mapeamento gerado (`build/app/outputs/mapping/release/mapping.txt`) e verificar que classes ofuscadas foram agrupadas no subpacote `app.escalada.croquis.r8`
- [x] 2.3 Rodar a suíte de testes unitários do Flutter (`flutter test`) e verificar que todos os testes continuam passando com 100% de sucesso
