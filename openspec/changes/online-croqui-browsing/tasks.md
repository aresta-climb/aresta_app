## 1. Atualização do Protobuf e Modelos de Dados

- [ ] 1.1 Escrever teste unitário para o formatador de tamanho de download (`test/utils/formatador_tamanho_test.dart`) seguindo TDD
- [ ] 1.2 Adicionar campo `tamanho_download_bytes` em `PrecomputadosResumoCroqui` no `indice.proto` e compilar os protobufs
- [ ] 1.3 Implementar utilitário `FormatadorTamanho` em `lib/utils/formatador_tamanho.dart` e integrá-lo ao `DatasetRepository` com docstrings completas

## 2. Serviço de Transmissão Online e Polling de ETag (TDD)

- [ ] 2.1 Escrever testes unitários para `ServicoCroquiOnline` (`test/services/http/servico_croqui_online_test.dart`) cobrindo carregamento, ETag 304, ETag 200 e erros de rede
- [ ] 2.2 Implementar `ServicoCroquiOnline` em `lib/services/http/servico_croqui_online.dart` com suporte a ETag, cache volátil e cancelamento no descarte
- [ ] 2.3 Integrar o `ServicoCroquiOnline` com o `DatasetRepository` para gerenciar croquis ativos em sessão online
- [ ] 2.4 Documentar o fluxo de transmissão online e verificação de ETag no `frontend/lib/services/README.md`

## 3. Provedor Unificado de Imagens em Camadas (TDD)

- [ ] 3.1 Escrever testes unitários e de widget para `ProvedorImagemAresta` (`test/widgets/provedor_imagem_aresta_test.dart`)
- [ ] 3.2 Implementar `ProvedorImagemAresta` em `lib/widgets/provedor_imagem_aresta.dart` com busca em `/downloads` -> `/temp_cache` -> CDN com quebra de cache
- [ ] 3.3 Refatorar `OfflineMarkdown`, `MapaThumbnail`, `MapaInterativo` e `SetorPage` para consumir o novo provedor
- [ ] 3.4 Validar 100% de cobertura de testes na camada de resolução de imagens e adicionar docstrings abrangentes

## 4. Componentes de UI: Banner Online e Guardião de Saída (Testes de Widget Primeiro)

- [ ] 4.1 Escrever testes de widget para o `BannerModoOnline` (`test/widgets/banner_modo_online_test.dart`)
- [ ] 4.2 Implementar o widget `BannerModoOnline` em `lib/widgets/banner_modo_online.dart` com feedback de progresso e transição de estado
- [ ] 4.3 Escrever testes de widget para o `ModalConfirmacaoSaida` (`test/widgets/modal_confirmacao_saida_test.dart`)
- [ ] 4.4 Implementar `ModalConfirmacaoSaida` em `lib/widgets/modal_confirmacao_saida.dart` e integrá-lo via `PopScope` na `PicoDetailsPage`

## 5. Navegação Direta a partir das Telas de Exploração

- [ ] 5.1 Escrever testes de navegação de fluxo para abertura direta de picos não baixados (`test/navigation/fluxo_navegacao_online_test.dart`)
- [ ] 5.2 Atualizar `browse.dart` (`CragCard`), `home.dart` e `mapa_global.dart` para navegar diretamente para `AppNav.toPico` em modo online
- [ ] 5.3 Atualizar `PageListenableBuilder` para resolver picos em modo online sem depender exclusivamente de `downloadedPicos`
- [ ] 5.4 Atualizar `frontend/lib/navigation/README.md` documentando o suporte a nós em sessão online

## 6. Serviço de Download em Segundo Plano com Notificação do SO (TDD)

- [ ] 6.1 Escrever testes unitários e de integração para `ServicoDownloadSegundoPlano` (`test/services/http/servico_download_segundo_plano_test.dart`)
- [ ] 6.2 Implementar `ServicoDownloadSegundoPlano` em `lib/services/http/servico_download_segundo_plano.dart` com Foreground Service e notificação contínua (`ongoing: true`)
- [ ] 6.3 Conectar a finalização do download com atualização atômica para `/downloads`, notificação de sucesso e atualização de estado no `DatasetRepository`
- [ ] 6.4 Validar 100% de cobertura de testes, garantir conformidade com `PRINCIPIOS.md` e atualizar o `README.md` geral
