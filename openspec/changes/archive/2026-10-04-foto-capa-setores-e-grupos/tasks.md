# Tasks: Foto de Capa em Setores e Grupos com Header Adaptativo

## 1. Atualização do Submódulo Protobuf

- [x] 1.1 Atualizar o submódulo `frontend/lib/aresta_api` para integrar os stubs gerados com `caminhoImagemCapa` e verificar compilação Dart sem erros

## 2. Página de Setor (`SetorPage`)

- [x] 2.1 Adicionar testes de widget em `frontend/test/pages/setor_test.dart` validando cabeçalho expandido de 300px com imagem quando houver `caminhoImagemCapa` e cabeçalho compacto na ausência de capa
- [x] 2.2 Atualizar `SetorPage` em `frontend/lib/pages/setor.dart` com resolução direta de `caminhoImagemCapa`, layout adaptativo no `SliverAppBar` e remoção do fallback da foto do pico
- [x] 2.3 Executar `flutter test test/pages/setor_test.dart` e confirmar aprovação de todos os testes

## 3. Página de Grupo (`GrupoPage`)

- [x] 3.1 Adicionar testes de widget em `frontend/test/pages/grupo_test.dart` validando cabeçalho expandido de 300px com imagem quando houver `caminhoImagemCapa` e cabeçalho compacto na ausência de capa
- [x] 3.2 Atualizar `GrupoPage` em `frontend/lib/pages/grupo.dart` com resolução direta de `caminhoImagemCapa`, layout adaptativo no `SliverAppBar` e remoção de `_buildDefaultCover`
- [x] 3.3 Executar `flutter test test/pages/grupo_test.dart` e confirmar aprovação de todos os testes

## 4. Verificação de Integração e Análise Estática

- [x] 4.1 Executar `flutter analyze` na pasta `frontend/` e confirmar zero advertências e erros
- [x] 4.2 Executar a suíte de testes relevante via `flutter test` e confirmar 100% de aprovação
