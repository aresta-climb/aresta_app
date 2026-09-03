## 1. Atualização do Workflow iOS (`build_ios.yml`)

- [x] 1.1 Atualizar o comando de build em `build_ios.yml` para extrair símbolos Dart com `--split-debug-info=build/symbols`
- [x] 1.2 Adicionar etapa em `build_ios.yml` para upload dos `dSYMs` nativos e dos símbolos Dart para o Firebase Crashlytics utilizando a Service Account
- [x] 1.3 Adicionar etapa em `build_ios.yml` de upload de artefatos da release (IPA, dSYMs e símbolos Dart) com `actions/upload-artifact@v4`

## 2. Atualização do Workflow Android (`build_android.yml`)

- [x] 2.1 Atualizar o comando de build em `build_android.yml` para extrair símbolos Dart com `--split-debug-info=build/symbols`
- [x] 2.2 Adicionar etapa em `build_android.yml` para upload dos símbolos Dart para o Firebase Crashlytics utilizando a Service Account
- [x] 2.3 Adicionar etapa em `build_android.yml` de upload de artefatos da release (AAB, mapeamentos ProGuard/R8 e símbolos Dart) com `actions/upload-artifact@v4`

## 3. Orquestração e Repasse de Segredos (`release_new_app_version.yml`)

- [x] 3.1 Verificar e assegurar o repasse de segredos nos jobs do workflow orquestrador `release_new_app_version.yml`

## 4. Documentação e Validação

- [x] 4.1 Documentar o procedimento de configuração do secret `FIREBASE_SERVICE_ACCOUNT_JSON` no `README.md` do repositório
- [x] 4.2 Validar a sintaxe e integridade dos arquivos YAML de workflow modificados
