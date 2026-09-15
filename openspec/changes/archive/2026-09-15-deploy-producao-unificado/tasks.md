## 1. Parametrização e Validação do Workflow Unificado

- [x] 1.1 Configurar inputs `release_notes` (obrigatório, sem default) e `enviar_para_producao` (booleano, default true) em `.github/workflows/release_new_app_version.yml`, removendo seletores técnicos de tracks
- [x] 1.2 Implementar etapa de validação fail-early no início do job `prepare_release` checando se `release_notes` possui entre 1 e 500 caracteres e abortando com erro antes de qualquer alteração
- [x] 1.3 Propagar `enviar_para_producao` e `release_notes` para os sub-workflows de Android e iOS

## 2. Publicação Automatizada do Android com Notas de Versão

- [x] 2.1 Atualizar `.github/workflows/build_android.yml` para receber os inputs `enviar_para_producao` e `release_notes`
- [x] 2.2 Implementar etapa no job Android que gera dinamicamente a pasta `whatsnew/` com o arquivo `whatsnew-pt-BR` contendo as notas de versão
- [x] 2.3 Atualizar o step `Upload to Google Play Console` para usar `tracks: internal,production` se `enviar_para_producao == true` ou `tracks: internal` se falso, apontando `whatsNewDirectory` para as notas geradas

## 3. Configuração do Fastlane e Submissão para a App Store

- [x] 3.1 Criar a estrutura do Fastlane em `frontend/ios/` (`Gemfile`, `Appfile` e `Fastfile`) configurada para autenticação via App Store Connect API Key (`is_key_content_base64: true`)
- [x] 3.2 Implementar a lane `submeter_revisao` no `Fastfile` com `skip_binary_upload: true`, polling de build com log de tempo, `release_notes` em `pt-BR`, `phased_release: false`, `automatic_release: true` e `submit_for_review: true`
- [x] 3.3 Criar sub-workflow ou job `submit_ios_review` em `ubuntu-latest` acionado quando `enviar_para_producao == true` com environment `appstore-review`

## 4. Validação e Verificação da Esteira

- [x] 4.1 Validar a sintaxe YAML de todos os workflows do GitHub Actions e integridade dos blocos condicionais
- [x] 4.2 Validar que commits e tags do Git continuam no padrão estrito sem inclusão das notas de lançamento
- [x] 4.3 Testar a sintaxe dos arquivos Fastlane e validar a interoperabilidade com os segredos configurados no repositório
