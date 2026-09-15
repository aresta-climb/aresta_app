# Proposal: deploy-producao-unificado

## Why

Atualmente, o lançamento de versões para iOS e Android pelo GitHub Actions requer intervenções manuais para levar o aplicativo aos usuários finais de produção: o iOS apenas sobe para o TestFlight sem submissão à loja, e o Android necessita de coordenação manual entre teste interno e produção pública. Além disso, as notas de versão precisam ser cadastradas separadamente em cada painel, aumentando a fricção e a chance de inconsistências em cada release.

## What Changes

- **Controle Unificado de Produção**: Substituição de seletores técnicos de tracks por um único parâmetro booleano de negócio `enviar_para_producao` no workflow `release_new_app_version.yml`.
- **Notas de Lançamento Centralizadas**: Adição do campo obrigatório `release_notes` no acionamento manual do workflow unificado, com validação precoce (*fail-early* em < 3 segundos) rejeitando textos vazios ou maiores que 500 caracteres (limite estrito da Google Play Store).
- **Publicação Automatizada no Android**: Envio dinâmico para as faixas `internal,production` (quando `enviar_para_producao: true`) ou apenas `internal` (quando `false`), injetando automaticamente o arquivo `whatsnew-pt-BR` com as notas de versão.
- **Divisão do Pipeline iOS em Dois Jobs Otimizados**:
  - **Job 1 (`build_ios` em macOS)**: Compilação do IPA e upload para o TestFlight via `altool`, consumindo apenas o tempo essencial do runner macOS.
  - **Job 2 (`submit_ios_review` em Linux `ubuntu-latest`)**: Disparado apenas se `enviar_para_producao: true`. Utiliza Fastlane (`deliver`) para aguardar o processamento da Apple sem custo de runner macOS, vincular a build, injetar as notas de versão em `pt-BR`, desativar rollout em fases (`phased_release: false`) e submeter para a Revisão da App Store com liberação automática (`automatic_release: true`).
- **Preservação dos Registros Git**: As notas de versão são manipuladas exclusivamente em memória/variáveis de CI, mantendo mensagens de commit e tags intactas para não interferir no bot existente de release notes.

## Capabilities

### New Capabilities
- `publicacao-producao-lojas`: Orquestração unificada de publicação para produção e teste interno no Google Play Console e Apple App Store, com validação e propagação centralizada de notas de versão e submissão automatizada para revisão.

### Modified Capabilities

## Impact

- Arquivos de workflow do GitHub Actions:
  - `.github/workflows/release_new_app_version.yml`
  - `.github/workflows/build_android.yml`
  - `.github/workflows/build_ios.yml` (e/ou novo sub-workflow para submissão App Store via Linux)
- Configuração do Fastlane na pasta `frontend/ios/` (`Fastfile`, `Appfile`, `Gemfile`).
- Requerimento do GitHub Environment `appstore-review` (pré-configurável com timer de 1 minuto).
