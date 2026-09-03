## 1. Testes de Widget e UI em Primeiro Lugar (TDD - Princípio V)

- [x] 1.1 Escrever testes de widget em `test/navigation/page_listenable_builder_test.dart` validando que a tela é reconstruída com novos dados quando um croqui em sessão online é atualizado em memória (Red).
- [x] 1.2 Escrever testes de widget em `test/main_test.dart` e `test/pages/pico_test.dart` validando a exibição do aviso visual amigável (SnackBar / popup) quando um croqui online for atualizado fora do modo experimental (Red).
- [x] 1.3 Escrever testes de widget em `test/widgets/banner_modo_experimental_test.dart` e `test/main_test.dart` garantindo que no Modo Experimental a recarga seja silenciosa (sem SnackBar/popups intrusivos) e acione o pulso luminoso no banner (Red).

## 2. Camada de Serviços HTTP e Sessão Online (TDD - Princípio IV e I)

- [x] 2.1 Escrever testes unitários em `test/services/http/servico_croqui_online_test.dart` cobrindo o processamento de `response.bodyBytes` no status 200 OK do ETag e re-fetch com bypass de cache `?t=` (Red).
- [x] 2.2 Implementar em `ServicoCroquiOnline.verificarAtualizacaoEtag` o consumo de `response.bodyBytes`, desserialização do `Croqui`, persistência em `/temp_cache` e registro no `GerenciadorSessaoOnline` (Green).
- [x] 2.3 Implementar `ServicoCroquiOnline.recarregarCroquiOnline` com bypass de cache HTTP e integração com `DatasetRepository.indexarMidiasDoCroqui` (Green).

## 3. Orquestração de Live Reload e Repositório (TDD - Princípio IV e II)

- [x] 3.1 Escrever testes unitários em `test/services/dataset_repository_test.dart` para reindexação de mídias e notificação de ouvintes ao atualizar sessão online (Red).
- [x] 3.2 Implementar método no `DatasetRepository` para notificar a interface e atualizar tabelas de dispersão de hashes SHA-256 após atualização de sessão online (Green).
- [x] 3.3 Escrever testes unitários em `test/main_test.dart` para `registrarOuvintesLiveReload` cobrindo evento de Live Reload com pico ativo em sessão online (Red).
- [x] 3.4 Atualizar `registrarOuvintesLiveReload` em `main.dart` para iterar sobre picos ativos em `GerenciadorSessaoOnline`, recarregar os dados, acionar `dispararPulsoRecarregamento()` e disparar o hot reload da tela (Green).

## 4. Integração da UI e Notificações (TDD - Princípio I e V)

- [x] 4.1 Implementar notificador reativo na UI (`main.dart` / `PicoDetailsPage`) para apresentar o aviso amigável quando o croqui for atualizado pelo ETag fora do modo experimental (Green).
- [x] 4.2 Conectar os ouvintes garantindo que no Modo Experimental a recarga seja 100% silenciosa e imediata (Green).

## 5. Qualidade, 100% de Cobertura e Documentação (Princípios I, III, VI e VII)

- [x] 5.1 Executar a suíte de testes (`flutter test`) e verificar 100% de cobertura nos arquivos modificados (Princípio III).
- [x] 5.2 Garantir que todo o código, identificadores, variáveis e comentários estejam estritamente em português brasileiro (Princípio I).
- [x] 5.3 Validar que todas as classes, métodos e membros contenham docstrings `///` explicativas destacando a intenção técnica (Princípio VII).
- [x] 5.4 Atualizar a documentação técnica em `HOT_RELOAD.md` e nos arquivos `README.md` pertinentes com o novo fluxo de hot reload para sessões online (Princípio VII).
