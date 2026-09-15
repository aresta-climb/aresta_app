## 1. Padronização de Armazenamento Permanente (`downloads`) e Migração Transparente

- [x] 1.1 [TDD] Atualizar testes em `frontend/test/services/dataset/gerenciador_arquivos_locais_test.dart` cobrindo carregamento canônico de `compilado.binarypb`, migração transparente (*lazy rename*) de `<picoId>.binarypb` e verificação de existência.
- [x] 1.2 Implementar a resolução com migração transparente (*lazy rename*) e suporte a `compilado.binarypb` em `GerenciadorArquivosLocais.carregarCroqui` e `verificarPicoBaixado`.
- [x] 1.3 [TDD] Atualizar testes em `frontend/test/services/http/sync_isolate_test.dart` e `frontend/test/services/http/sync_service_test.dart` cobrindo gravação de `compilado.binarypb` e remoção de arquivo legado `<picoId>.binarypb` no commit atômico.
- [x] 1.4 Atualizar `SyncIsolate`, `SyncService` e `ExtratorMetadadosCroqui` para utilizar o caminho `compilado.binarypb` e limpar resíduos de arquivos legados após a sincronização atômica.

## 2. Cache-Busting e Endereçamento por Conteúdo no `temp_cache`

- [x] 2.1 [TDD] Atualizar testes em `frontend/test/services/http/servico_croqui_online_test.dart` cobrindo requisições com `?v=<sha256>`, gravação como `compilado.binarypb.<sha256>`, leitura de cache volátil e expurgo de versões irmãs antigas.
- [x] 2.2 Implementar em `ServicoCroquiOnline` o carregamento com cache-busting mandatório, leitura/escrita em `temp_cache` indexado por hash e a rotina de expurgo de versões antigas.
- [x] 2.3 [TDD] Atualizar testes em `frontend/test/services/dataset_repository_test.dart` garantindo a construção da URL do pico com `?v=<checksumSha256Croqui>` e a resolução na ordem: RAM ➔ Downloads ➔ Temp Cache ➔ Rede.
- [x] 2.4 Atualizar `DatasetRepository` para construir URLs com o hash mandatório e integrar a hierarquia de resolução de croquis em 4 etapas sem recálculo de hash em runtime.

## 3. Auditoria Criptográfica de Integridade nos Metadados de Feedback

- [x] 3.1 [TDD] Criar testes unitários em `frontend/test/services/feedback/feedback_metadata_collector_test.dart` cobrindo o cálculo e inclusão dos campos de auditoria de hash para índice, croqui e miniatura (`INTEGRO`, `DIVERGENTE` ou `NAO_BAIXADO`).
- [x] 3.2 Implementar no `FeedbackMetadataCollector` a leitura e cálculo de SHA-256 do `indice.binarypb` local, da miniatura e do croqui visualizado, comparando com o índice mestre.
- [x] 3.3 Atualizar a entidade de domínio `FeedbackMetadata` e o DTO `FeedbackMetadataDto` com os novos campos e verificar conformidade com `flutter test test/data/dtos/feedback_metadata_dto_test.dart`.

## 4. Anexação de Binários e Repasse no Backend Supabase / Discord

- [x] 4.1 [TDD] Atualizar testes em `frontend/test/services/feedback/feedback_network_service_test.dart` cobrindo a anexação multipart dos arquivos `indice_file` e `croqui_file` quando disponíveis.
- [x] 4.2 Atualizar `FeedbackNetworkService` e a camada de orquestração de feedback para enviar os arquivos `indice.binarypb` e `compilado.binarypb` no formulário multipart.
- [x] 4.3 Atualizar a Edge Function do Supabase em `../aresta_backend/supabase/functions/app-feedback/handler.ts` para receber `indice_file` e `croqui_file` e anexá-los ao `discordFormData` para download no Discord.
- [x] 4.4 [TDD] Atualizar e executar os testes da Edge Function em `../aresta_backend/supabase/functions/app-feedback/handler_test.ts` cobrindo o repasse dos binários adicionais ao webhook do Discord.

## 5. Validação Integrada e Documentação

- [x] 5.1 Executar a suíte completa de testes com `flutter test` garantindo 100% de aprovação e zero regressões.
- [x] 5.2 Atualizar os arquivos `README.md` pertinentes em `frontend/lib/services/` e `frontend/lib/services/http/` documentando a padronização de nomenclatura e o pipeline hierárquico de cache.
