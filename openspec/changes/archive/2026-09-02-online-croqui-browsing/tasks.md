## 1. Atualização do Protobuf e Modelos de Dados

- [x] 1.1 Escrever teste unitário para o formatador de tamanho de download (`test/utils/formatador_tamanho_test.dart`) seguindo TDD
- [x] 1.2 Implementar utilitário `FormatadorTamanho` em `lib/utils/formatador_tamanho.dart` e integrá-lo ao `DatasetRepository` com docstrings completas
- [x] 1.3 Preparar parser no `DatasetRepository` com fallback gracioso enquanto `tamanho_download_bytes` aguarda compilação upstream no `aresta_db` (transferido para proposta dedicada)

## 2. Serviço de Transmissão Online e Polling de ETag (TDD)

- [x] 2.1 Escrever testes unitários para `ServicoCroquiOnline` (`test/services/http/servico_croqui_online_test.dart`) cobrindo carregamento, ETag 304, ETag 200 e erros de rede
- [x] 2.2 Implementar `ServicoCroquiOnline` em `lib/services/http/servico_croqui_online.dart` com suporte a ETag, cache volátil e cancelamento no descarte
- [x] 2.3 Integrar o `ServicoCroquiOnline` com o `DatasetRepository` para gerenciar croquis ativos em sessão online
- [x] 2.4 Documentar o fluxo de transmissão online e verificação de ETag no `frontend/lib/services/README.md`

## 3. Provedor Unificado de Imagens em Camadas (TDD)

- [x] 3.1 Escrever testes unitários e de widget para `ProvedorImagemAresta` (`test/widgets/provedor_imagem_aresta_test.dart`)
- [x] 3.2 Implementar `ProvedorImagemAresta` em `lib/widgets/provedor_imagem_aresta.dart` com busca em `/downloads` -> `/temp_cache` -> CDN com quebra de cache
- [x] 3.3 Refatorar `OfflineMarkdown`, `MapaThumbnail`, `MapaInterativo` e `SetorPage` para consumir o novo provedor
- [x] 3.4 Validar 100% de cobertura de testes na camada de resolução de imagens e adicionar docstrings abrangentes

## 4. Componentes de UI: Banner Online e Guardião de Saída (Testes de Widget Primeiro)

- [x] 4.1 Escrever testes de widget para o `BannerModoOnline` (`test/widgets/banner_modo_online_test.dart`)
- [x] 4.2 Implementar o widget `BannerModoOnline` em `lib/widgets/banner_modo_online.dart` com feedback de progresso e transição de estado
- [x] 4.3 Escrever testes de widget para o `ModalConfirmacaoSaida` (`test/widgets/modal_confirmacao_saida_test.dart`)
- [x] 4.4 Implementar `ModalConfirmacaoSaida` em `lib/widgets/modal_confirmacao_saida.dart` e integrá-lo via interceptor de saída na `PicoDetailsPage`

## 5. Navegação Direta a partir das Telas de Exploração

- [x] 5.1 Escrever testes de navegação de fluxo para abertura direta de picos não baixados
- [x] 5.2 Atualizar `browse.dart` (`CragCard`), `home.dart` e `mapa_global.dart` para navegar diretamente para `AppNav.toPico` em modo online
- [x] 5.3 Atualizar `PageListenableBuilder` para resolver picos em modo online sem depender exclusivamente de `downloadedPicos`
- [x] 5.4 Atualizar `frontend/lib/navigation/README.md` documentando o suporte a nós em sessão online

## 6. Serviço de Download e Finalização (TDD)

- [x] 6.1 Escrever testes unitários e de integração para `ServicoDownloadSegundoPlano` (`test/services/http/servico_download_segundo_plano_test.dart`)
- [x] 6.2 Implementar orquestrador base `ServicoDownloadSegundoPlano` em `lib/services/http/servico_download_segundo_plano.dart` (Foreground Service nativo com notificação do SO isolado em proposta dedicada)
- [x] 6.3 Conectar a finalização do download com atualização atômica para `/downloads`, notificação de sucesso e atualização de estado no `DatasetRepository`
- [x] 6.4 Validar 100% de cobertura de testes, garantir conformidade com `PRINCIPIOS.md` e atualizar o `README.md` geral
