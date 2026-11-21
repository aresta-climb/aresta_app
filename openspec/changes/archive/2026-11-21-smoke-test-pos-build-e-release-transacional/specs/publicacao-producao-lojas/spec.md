# Spec Delta

## ADDED Requirements

### Requirement: Corte Transacional de Versão Pós-Aprovação dos Smoke Tests
O workflow unificado de release DEVE (MUST) executar a compilação dos pacotes móveis, a auditoria binária e os smoke tests em todas as plataformas selecionadas antes de registrar commits de versão, criar tags Git ou enviar artefatos para Google Play, App Store Connect, Sentry e Crashlytics.

#### Scenario: Corte atômico após aprovação simultânea de Android e iOS
- **WHEN** `publicar_nas_lojas` é `true` e os jobs de compilação e smoke test das plataformas selecionadas concluem com sucesso
- **THEN** o pipeline aplica o pacote candidato preparado, cria o commit de release, a tag oficial e o commit do próximo ciclo `-dev`, envia tudo em transação única (`git push --atomic`) e publica os artefatos aprovados sem recompilar

#### Scenario: Bloqueio total de commits, tags e lojas em falha pós-build
- **WHEN** a compilação, a auditoria binária ou o smoke test falha em Android ou em iOS
- **THEN** nenhum commit ou tag é enviado à branch remota e nenhum upload é realizado para Google Play ou App Store Connect

### Requirement: Modo de Validação Interna sem Publicação nas Lojas
O workflow unificado DEVE (MUST) oferecer uma opção booleana `publicar_nas_lojas` (com valor padrão `true`) que permita executar toda a esteira de compilação oficial e smoke test pós-build sem cortar versão no Git nem publicar nas lojas.

#### Scenario: Disparo de teste interno completo com publicar_nas_lojas desativado
- **WHEN** o operador acionar o workflow com `publicar_nas_lojas` definido como `false`
- **THEN** o pipeline executa integralmente os testes, as compilações `.aab` e `.ipa` oficiais, a auditoria binária e os smoke tests em Android Emulator KVM e iOS Simulator salvando as evidências como artefatos do GitHub Actions, e suprime o corte de versão Git e o envio às lojas e serviços de símbolos
