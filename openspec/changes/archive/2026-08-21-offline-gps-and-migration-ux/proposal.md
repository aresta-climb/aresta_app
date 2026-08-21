## Why

O aplicativo de escalada precisa funcionar perfeitamente em ambientes sem conectividade ou com rede instável (montanhas, desfiladeiros e cavernas). Atualmente:
1. O carrossel de picos próximos (`NearbyCragsCarousel`) utiliza uma requisição HTTP não-criptografada (`http://ip-api.com/json/`) quando o GPS demora a responder ou está desativado, gerando tentativas externas desnecessárias, falhas de segurança do Android (cleartext) e atrasos de até 8 segundos no modo offline.
2. A tela de migração de base de dados (`DatabaseMigrationScreen`), acionada em atualizações estruturais de versão dos dados (`kDataVersion`), possui apenas um indicador giratório simples sem barra de progresso, diagnóstico claro do motivo da migração, nem retentativa automática (auto-retry) quando a internet é restabelecida.

## What Changes

- **Localização 100% Local e Cache no SharedPreferences**: Remoção definitiva da consulta externa por IP (`ip-api.com`). O `NearbyCragsCarousel` passa a salvar a última coordenada de GPS válida no armazenamento local (`SharedPreferences`), utilizando-a para ordenação offline instantânea e exibindo estado elegante sem travar nem efetuar chamadas de rede.
- **Tela de Migração com Progresso e Auto-Retry Reativo**: Reformulação da `DatabaseMigrationScreen` para apresentar etapas claras de progresso (ex: *"Verificando conexão..."*, *"Baixando novo catálogo..."*, *"Concluído!"*), diagnóstico transparente ao usuário explicando a atualização e auto-retry reativo via `connectivity_plus` assim que a internet voltar.
- **Aderência aos Princípios (PRINCIPIOS.md)**: Código, comentários e documentação 100% em português brasileiro, desenvolvimento orientado a testes (TDD), priorização de Widget Tests e garantia de 100% de cobertura de testes nos arquivos modificados.

## Capabilities

### New Capabilities
<!-- Nenhuma -->

### Modified Capabilities
- `offline-first-initialization`: Adição de requisitos para resolução de localização puramente local/persistida e experiência de migração resiliente com etapas visuais e auto-retry reativo.

## Impact

- `frontend/lib/widgets/nearby_crags_carousel.dart`: Remoção de chamada HTTP por IP e persistência/leitura de coordenadas locais em `SharedPreferences`.
- `frontend/lib/pages/database_migration_screen.dart`: Adição de fases de progresso, auto-retry via `Connectivity` e mensagem explicativa clara.
- `frontend/test/pages/database_migration_screen_test.dart` e `frontend/test/widgets/nearby_crags_carousel_test.dart`: Testes de widget e unidade com 100% de cobertura.
