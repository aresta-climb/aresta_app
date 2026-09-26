## 1. Telemetria e Reporte de Erros em Links Externos e Comunidade

- [x] 1.1 [TDD] Atualizar testes em `frontend/test/view_functions/comunidade_functions_test.dart` e `frontend/test/view_functions/sobre_time_functions_test.dart` cobrindo a verificação de retorno `false` de `launchUrl` com registro de erro no `AppLogger`, e telemetria nos novos fluxos de navegação e termos.
- [x] 1.2 Atualizar `abrirLinkExterno` e `abrirLinkSobreTime` para validar o retorno booleano `if (!await launchUrl(...))` registrando `AppLogger.instance.logError` imediatamente quando o SO falhar, e adicionar try/catch resiliente.
- [x] 1.3 [TDD] Atualizar testes de widget em `frontend/test/pages/comunidade_test.dart` e `frontend/test/pages/sobre_time_test.dart` cobrindo telemetria declarativa ao tocar no card "Sobre o Time", termos de privacidade e links sociais.
- [x] 1.4 Instrumentar eventos analíticos de telemetria no `TelemetryService` para o card "Sobre o Time" (`acao: 'navegar_sobre_time'`) e exibição de termos em `comunidade.dart`, garantindo observabilidade total.

## 2. Resolução Canônica de Croquis e Capas no Extrator de Metadados

- [x] 2.1 [TDD] Atualizar testes em `frontend/test/services/dataset/extrator_metadados_croqui_test.dart` cobrindo carregamento canônico de `compilado.binarypb`, fallback para `temp_cache` e rede via `DatasetRepository.getCroqui`.
- [x] 2.2 Refatorar `ExtratorMetadadosCroqui.carregarMetadadosLocais` e `atualizarMetadadosPico` para delegar a resolução do binário ao `DatasetRepository.getCroqui`, removendo leituras manuais de arquivos com nomes legados.
- [x] 2.3 Refatorar `_resolverCapaPath` em `ExtratorMetadadosCroqui` para delegar a busca de imagem ao `ProvedorImagemAresta.resolver`, removendo o método `buscarImagemRecursivamente` de busca direta em disco.

## 3. Desacoplamento de Hitbox e Rótulo Flutuante no Mapa Global

- [x] 3.1 [TDD] Criar testes unitários em `frontend/test/view_functions/mapa/mapa_marker_test.dart` para a geração do bitmap exclusivo do pino compacto (`createCustomMarkerBitmap`) e do bitmap exclusivo do balão de texto (`createCustomMarkerLabelBitmap`).
- [x] 3.2 Implementar a função `createCustomMarkerLabelBitmap` em `mapa_marker.dart` renderizando apenas o balão de texto contido com cantos arredondados sem desenhar o pino nem criar asas laterais transparentes.
- [x] 3.3 [TDD] Atualizar testes em `frontend/test/view_functions/mapa/mapa_global_functions_test.dart` e `frontend/test/pages/mapa_global_test.dart` cobrindo a divisão em dois marcadores (pino com `onTap` e rótulo com `consumeTapEvents: false`) na faixa de zoom local.
- [x] 3.4 Atualizar `buildMapMarkers` em `mapa_global_functions.dart` para desacoplar a renderização na `FaixaZoomMapa.local`: marcador do pino com hitbox cirúrgica de 85px, âncora exata na agulha e `zIndex: 2.0`, e marcador do rótulo textual flutuante com `consumeTapEvents: false` e `zIndex: 1.0`.

## 4. Resolução de Imagens em Camadas no CragCard

- [x] 4.1 [TDD] Atualizar testes de widget em `frontend/test/widgets/crag_card_test.dart` cobrindo a exibição de fundo com `capaPath` local prioritário, fallback para `thumbnailUrl` e consumo correto de `checksumSha256`.
- [x] 4.2 Refatorar `_CragBackgroundWidget` em `crag_card.dart` para extrair e repassar `capaPath`, `thumbnailUrl` e `checksumSha256` para `ProvedorImagemAresta.resolver` com largura de 300px.
- [x] 4.3 Eliminar qualquer bypass para `NetworkImage` sem cache em `_CragBackgroundWidget`, assegurando que todas as imagens sigam a hierarquia permanente ➔ volátil ➔ CDN remoto com gravação atômica.

## 5. Verificação Integrada e Conformidade da Suíte de Testes

- [x] 5.1 Executar a suíte completa de testes unitários e de widget com `flutter test` garantindo 100% de testes passando e zero regressões.
- [x] 5.2 Executar a análise estática com `flutter analyze` garantindo conformidade total de lints e boas práticas de código limpo.
