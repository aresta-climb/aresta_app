## 1. Testes de Widget em Primeiro Lugar (TDD - Fase Vermelha)

- [x] 1.1 Criar testes de widget em `frontend/test/pages/mapas_carrossel_test.dart` verificando que uma tela aberta de `MapasCarrosselPage` com `MapaInterativoPage` atualiza e re-renderiza a imagem exibida quando o widget recebe atualização no `didUpdateWidget` (Falha inicial - Red)
- [x] 1.2 Criar testes de widget e integração em `frontend/test/main_test.dart` validando que `registrarOuvintesLiveReload` executa a purgação completa de `PaintingBinding.instance.imageCache` (`clear()` e `clearLiveImages()`) tanto para croquis baixados quanto para croquis em sessão online (Falha inicial - Red)
- [x] 1.3 Criar testes unitários em `frontend/test/services/dataset_repository_test.dart` espelhando `lib/services/` para validar indexação automática de `arquivosExternos` para croquis online e normalização de caminhos com `./`, `/` e `\` em `obterSha256DaMidia` (Falha inicial - Red)

## 2. Implementação no Repositório e Provedor de Imagem (Fase Verde)

- [x] 2.1 Corrigir a rotina `obterSha256DaMidia` em `DatasetRepository` para remover a guarda restritiva `mapaPico.isEmpty`, permitindo indexação sob demanda para croquis online com caminhos normalizados
- [x] 2.2 Assegurar que `indexarMidiasDoCroqui` normalize caminhos com `./`, `/` e `\` e seja invocado no registro e na notificação de sessão online (`notificarAtualizacaoSessaoOnline` e `registrarCroquiOnline`)
- [x] 2.3 Implementar fallback dinâmico de timestamp (`lastModifiedSync`) no `ProvedorImagemAresta.resolver` para arquivos locais sem hash explícito, assegurando geração de chave distinta em `ImagemArquivoAresta`

## 3. Implementação da Invalidação de Cache e Reatividade de Interface (Fase Verde)

- [x] 3.1 Adicionar purgação explícita de `PaintingBinding.instance.imageCache.clear()` e `clearLiveImages()` em `registrarOuvintesLiveReload` (`frontend/lib/main.dart`)
- [x] 3.2 Atualizar `MapasCarrosselPage.didUpdateWidget` chamando `setState()` e vinculando chave de reatividade aos filhos `MapaInterativoPage` para forçar remontagem da imagem em tela aberta
- [x] 3.3 Garantir que o parâmetro de cache-busting `?v=<checksumSha256>` seja anexado a URLs remotas de streaming no `ProvedorImagemAresta` para croquis online

## 4. Refatoração, Cobertura Integral e Documentação (PRINCIPIOS.md)

- [x] 4.1 Executar a suíte completa de testes (`flutter test`) garantindo que todos os testes passem (Fase Verde/Refactor)
- [x] 4.2 Validar 100% de cobertura de testes nos arquivos criados e modificados (`DatasetRepository`, `main.dart`, `MapasCarrosselPage`, `ProvedorImagemAresta`)
- [x] 4.3 Garantir que todo o código, identificadores, comentários e docstrings (`///`) estejam 100% em português brasileiro
- [x] 4.4 Atualizar a documentação técnica no `frontend/lib/services/README.md` refletindo o comportamento reativo de Live Reload e purgação de cache de imagens
