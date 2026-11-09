# Tasks

## 1. Contratos SQL e OpenAPI da Malha Rodoviária (`aresta_api`)

- [x] 1.1 Escrever testes de paridade e geração em `frontend/lib/aresta_api/src/validador_paridade_test.py` e `frontend/lib/aresta_api/build_test.py` validando a presença das tabelas `catalogo_nos_estrada` e `catalogo_distancias_estrada` e seus schemas correspondentes (`CatalogoNoEstrada` e `CatalogoDistanciaEstrada`), verificando a falha inicial (Red) via `pytest`
- [x] 1.2 Adicionar as tabelas `catalogo_nos_estrada` e `catalogo_distancias_estrada` (com índice `idx_catalogo_distancias_estrada_no`) em `frontend/lib/aresta_api/sql/catalogo.sql` e os schemas/listas de `upserts` correspondentes em `frontend/lib/aresta_api/openapi/catalogo.yaml`, atualizar `MAPEAMENTO_PARIDADE_CATALOGO` em `validador_paridade.py`, executar `build.py` e verificar que todos os testes do `aresta_api` passam com 100% de cobertura

## 2. Motor de Busca Espacial 2D (KD-Tree) e Calculadora de Distância Rodoviária

- [x] 2.1 Criar a suíte de testes orientados a comportamento em `frontend/test/utils/calculadora_distancia_estrada_test.dart` cobrindo: busca $O(\log N)$ dos 3 vizinhos mais próximos na KD-Tree dentro do raio de 15 km, escolha do nó na direção favorável, nó do próprio estacionamento com distância zero, cálculo para picos distantes ($> 180\text{ km}$) via portais de borda (`na_borda = 1`) evitando barreiras geográficas, e fallback geodésico ($\times 1{,}25$ ou direto), verificando a falha inicial (Red)
- [x] 2.2 Implementar `NoEstrada`, `PortalBordaPico`, `ArvoreKdNosEstrada` e `CalculadoraDistanciaEstrada` em `frontend/lib/utils/calculadora_distancia_estrada.dart` com docstrings em português e verificar que `flutter test test/utils/calculadora_distancia_estrada_test.dart --coverage` passa com 100% de cobertura das linhas do arquivo

## 3. Persistência, Delta Sync e Carregamento da Malha no `RepositorioCatalogo` e `DatasetRepository`

- [x] 3.1 Adicionar testes em `frontend/test/services/catalogo/repositorio_catalogo_test.dart` e `frontend/test/services/catalogo/repositorio_dataset_test.dart` validando a aplicação transacional de `upserts`/`deletes` de `catalogo_nos_estrada` e `catalogo_distancias_estrada` em `aplicarDelta`, a limpeza em cascata ao remover um `croqui_uid`, e a construção reativa de `CalculadoraDistanciaEstrada` via `carregarMalhaEstrada()`, verificando a falha inicial (Red)
- [x] 3.2 Implementar o suporte às novas tabelas em `RepositorioCatalogo.aplicarDelta`, o método `RepositorioCatalogo.carregarMalhaEstrada()` (resolvendo tanto `croqui_uid` quanto `id_slug`) e a sincronização reativa da instância de `CalculadoraDistanciaEstrada` no `DatasetRepository`, verificando que os testes de `repositorio_catalogo_test.dart` e `repositorio_dataset_test.dart` passam com 100% de cobertura

## 4. Integração com `calcularPicosMaisProximos`, `HomeViewModel` e `BrowseViewModel`

- [x] 4.1 Adicionar testes comportamentais em `frontend/test/view/function_library/funcoes_home_test.dart`, `frontend/test/view/view_models/home_view_model_test.dart` e `frontend/test/view/view_models/explorar_view_model_test.dart` verificando que a ordenação por proximidade e as *badges* de distância na Home e na aba Explorar utilizam a distância rodoviária da malha do catálogo (invertendo picos atrás de serras em relação à linha reta) e mantêm o cache por coordenada do usuário, confirmando a falha inicial (Red)
- [x] 4.2 Atualizar `calcularPicosMaisProximos` em `frontend/lib/view/function_library/funcoes_home.dart`, `HomeViewModel` (`frontend/lib/view/view_models/home_view_model.dart`) e `BrowseViewModel` (`frontend/lib/view/view_models/explorar_view_model.dart`) para utilizar `CalculadoraDistanciaEstrada` do `DatasetRepository` (ou recebida por parâmetro) com cache em memória e atualizar a documentação pertinente, verificando que todos os testes unitários e de widget passam com 100% de cobertura nos arquivos alterados
