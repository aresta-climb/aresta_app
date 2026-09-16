# Tarefas de Implementação: Tratamento de Imagens Offline sem SocketException

## 1. Provedor de Imagem Aresta e Telemetria Resiliente

- [x] 1.1 Escrever testes unitários em `frontend/test/widgets/provedor_imagem_aresta_test.dart` cobrindo falhas de download na rede (`SocketException`, timeout, status HTTP 404/500) para validar o retorno `null` e a emissão de `logAviso` sem invocação de `logError`.
- [x] 1.2 Atualizar `_baixarESalvarNoCache` em `frontend/lib/widgets/provedor_imagem_aresta.dart` para retornar `null` em falhas e classificar erros com `AppLogger.isFalhaConexaoOuTimeout`, emitindo `logAviso`.
- [x] 1.3 Executar os testes de `provedor_imagem_aresta_test.dart` via `flutter test test/widgets/provedor_imagem_aresta_test.dart` e verificar aprovação completa.

## 2. Salvaguarda Visual contra Exceções de Imagem na UI

- [x] 2.1 Escrever testes de widget em `frontend/test/widgets/mapa_thumbnail_test.dart` simulando falha assíncrona do `ImageProvider` e garantindo que o `errorBuilder` captura o erro sem renderizar `ErrorWidget` na árvore do Flutter.
- [x] 2.2 Adicionar `errorBuilder: (context, error, stackTrace) => const SizedBox.shrink()` ao componente `Image` do `MapaThumbnail` em `frontend/lib/widgets/mapa_thumbnail.dart`.
- [x] 2.3 Adicionar `errorBuilder: (context, error, stackTrace) => const SizedBox.shrink()` às imagens de capa em `frontend/lib/pages/setor.dart` e `frontend/lib/pages/grupo.dart`.
- [x] 2.4 Executar a suíte de testes de widget de `mapa_thumbnail_test.dart`, `setor_test.dart` e `grupo_test.dart` para verificar ausência de regressões.

## 3. Higiene no Polling de ETag do Croqui Online

- [x] 3.1 Escrever testes unitários em `frontend/test/services/http/servico_croqui_online_test.dart` cobrindo falha de rede (`SocketException`) no método `verificarAtualizacaoEtag`, validando que `logAviso` é chamado e `logError` não é emitido.
- [x] 3.2 Atualizar o tratamento de erro em `verificarAtualizacaoEtag` em `frontend/lib/services/http/servico_croqui_online.dart` utilizando `AppLogger.isFalhaConexaoOuTimeout`.
- [x] 3.3 Executar os testes de `servico_croqui_online_test.dart` via `flutter test test/services/http/servico_croqui_online_test.dart` e verificar aprovação completa.

## 4. Validação e Cobertura Integrada

- [x] 4.1 Executar a suíte completa de testes unitários e de widget relevantes via `flutter test test/widgets/provedor_imagem_aresta_test.dart test/widgets/mapa_thumbnail_test.dart test/services/http/servico_croqui_online_test.dart`.
- [x] 4.2 Executar o linter do projeto (`flutter analyze`) e garantir conformidade estrita sem nenhum aviso.
