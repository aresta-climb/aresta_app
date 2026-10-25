# Tasks

## 1. Resolução de URL do Google Maps e Verificadores de Conteúdo (`categorizacao_pico.dart` e `pico_view_model.dart`)

- [x] 1.1 Escrever testes comportamentais em `frontend/test/utils/categorizacao_pico_test.dart` cobrindo `resolverUrlGoogleMapsPico` (prioridade para `urlGoogleMaps`, fallback para `localizacao` em `E7`, omissão quando vazio ou `(0,0)`), `temConteudoExplorarLocal` e `temConteudoComunidade`, verificando a falha inicial (Red)
- [x] 1.2 Implementar `resolverUrlGoogleMapsPico`, `temConteudoExplorarLocal` e `temConteudoComunidade` em `frontend/lib/utils/categorizacao_pico.dart` com docstrings em português e verificar que `flutter test test/utils/categorizacao_pico_test.dart` passa com 100% de cobertura (Green/Refactor)
- [x] 1.3 Escrever testes comportamentais em `frontend/test/view/view_models/pico_view_model_test.dart` validando as propriedades `temExplorarLocal`, `temComunidade` e `urlGoogleMaps` em `PicoViewModel`, verificando a falha inicial (Red)
- [x] 1.4 Expor `temExplorarLocal`, `temComunidade` e `urlGoogleMaps` em `frontend/lib/view/view_models/pico_view_model.dart` e verificar que `flutter test test/view/view_models/pico_view_model_test.dart` passa com 100% de cobertura (Green/Refactor)

## 2. Visibilidade Condicional no Hub do Pico e Botão do Google Maps em Explorar Local

- [x] 2.1 Escrever testes de widget em `frontend/test/pages/pico_test.dart` verificando que os cards `"Explorar Local"` e `"Comunidade"` são ocultados quando não possuem conteúdo, que `"Explorar Local"` aparece quando há apenas coordenadas/URL do Google Maps, e que `"Regras e recomendações"` permanece sempre visível com a mensagem padrão no modal (Red)
- [x] 2.2 Atualizar `frontend/lib/pages/pico.dart` para renderizar condicionalmente os cards `"Explorar Local"` (`_viewModel.temExplorarLocal`) e `"Comunidade"` (`_viewModel.temComunidade`), verificando que `flutter test test/pages/pico_test.dart` passa com 100% de cobertura (Green/Refactor)
- [x] 2.3 Escrever testes de widget em `frontend/test/pages/pico_subpages/explorar_local_page_test.dart` validando a exibição do card único `"Abrir no Google Maps"` logo abaixo de `"Como chegar"` (priorizando `urlGoogleMaps`, usando `localizacao` como fallback e omitindo quando ausentes), verificando a falha inicial (Red)
- [x] 2.4 Implementar o card `"Abrir no Google Maps"` em `frontend/lib/pages/pico_subpages/explorar_local_page.dart` posicionado abaixo de `"Como chegar"` e atualizar a documentação em `frontend/lib/pages/pico_subpages/README.md`, verificando que `flutter test test/pages/pico_subpages/explorar_local_page_test.dart` passa com 100% de cobertura (Green/Refactor)

## 3. Mensagem de Backup em Setores & Escaladas (`SetoresPage`)

- [x] 3.1 Escrever testes de widget em `frontend/test/pages/pico_subpages/setores_page_test.dart` verificando a mensagem de backup específica quando o pico não possui setores cadastrados (`pico.setoresOuGrupos.isEmpty`) versus a mensagem de filtro sem resultados quando há setores cadastrados, verificando a falha inicial (Red)
- [x] 3.2 Atualizar `_buildSliverSetores` em `frontend/lib/pages/pico_subpages/setores_page.dart` para diferenciar pico sem setores cadastrados de filtragem vazia e verificar que `flutter test test/pages/pico_subpages/setores_page_test.dart` passa com 100% de cobertura (Green/Refactor)
