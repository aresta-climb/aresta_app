## 1. Testes de Unidade e Widget em Primeiro Lugar (TDD)

- [x] 1.1 Adicionar testes unitários em `frontend/test/widgets/provedor_imagem_aresta_test.dart` para `ProvedorImagemAresta.preCarregarNoDisco` validando persistência em `temp_cache`, idempotência com arquivos já existentes e não-inserção no `imageCache`
- [x] 1.2 Adicionar testes de widget em `frontend/test/widgets/mapa_thumbnail_test.dart` verificando o disparo do pré-download em disco para as páginas seguintes (`mapas.skip(1)`) ao exibir um setor com múltiplos mapas
- [x] 1.3 Adicionar testes de widget em `frontend/test/pages/mapas_carrossel_test.dart` verificando que o carrossel executa o pré-download de garantia para todas as páginas e se mantém resiliente a falhas de rede ou descarte (`dispose`)

## 2. Implementação

- [x] 2.1 Implementar método estático `ProvedorImagemAresta.preCarregarNoDisco` em `frontend/lib/widgets/provedor_imagem_aresta.dart` com tratamento de concorrência e retorno de `Future<File?>`
- [x] 2.2 Integrar chamada de pré-download em `frontend/lib/widgets/mapa_thumbnail.dart` para acionar `preCarregarNoDisco` para as páginas subsequentes no `initState` e `didUpdateWidget`
- [x] 2.3 Integrar chamada de pré-download complementar em `frontend/lib/pages/mapas_carrossel.dart` via `WidgetsBinding.instance.addPostFrameCallback`

## 3. Validação e Cobertura

- [x] 3.1 Executar a suíte de testes de `provedor_imagem_aresta_test.dart`, `mapa_thumbnail_test.dart` e `mapas_carrossel_test.dart` assegurando 100% de aprovação e cobertura total
- [x] 3.2 Executar a suíte geral do Flutter (`flutter test`) confirmando ausência de regressões



