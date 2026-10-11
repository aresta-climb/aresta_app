# Tasks

## 1. Modelo de Domínio e Card de Escalada do Setor

- [x] 1.1 Escrever testes unitários em `test/utils/indexador_escaladas_test.dart` validando `indexarEscaladasDoSetor` com mapeamento de setor, grupo opcional e propriedades de escalada.
- [x] 1.2 Implementar a função `indexarEscaladasDoSetor` em `lib/utils/indexador_escaladas.dart` e verificar que todos os testes unitários passam.
- [x] 1.3 Escrever testes de widget para o card de escalada do setor validando a renderização do rótulo de croqui no badge à esquerda, grau e proteções no subtítulo e realce de foco (`isTarget`).
- [x] 1.4 Implementar o suporte a rótulos de croqui e modo de setor no card de escalada em `lib/widgets/card_indice_escalada.dart` (ou widget equivalente) e validar a passagem dos testes de widget.

## 2. Abas por Volume e Integração do Painel de Filtros na SetorPage

- [x] 2.1 Escrever testes de widget em `test/pages/setor_test.dart` cobrindo abas ordenadas por volume decrescente, ocultação da barra de abas quando houver apenas uma modalidade, herança reativa dos filtros do `cragId` e seleção de aba contextual para `scrollToEscalada`.
- [x] 2.2 Atualizar `SetorPage` em `lib/pages/setor.dart` integrando o `GerenciadorFiltrosCroqui`, `PainelFiltrosIndice`, cálculo de modalidades ordenadas por volume e seleção automática de aba para `scrollToEscalada`.
- [x] 2.3 Executar `test/pages/setor_test.dart` e verificar que todos os testes de widget passam com sucesso.

## 3. Limpeza de Código Legado, Documentação e Validação Final

- [x] 3.1 Remover o código legado de ordenação (`EscaladaSortMode`, `buildEscaladaSortGrid`, `_buildEscaladaSortCard`) em `lib/view/function_library/setor_functions.dart` e atualizar chamadas residuais.
- [x] 3.2 Atualizar a documentação técnica em `lib/pages/README.md` e `lib/widgets/README.md` documentando a arquitetura unificada da `SetorPage`.
- [x] 3.3 Executar `flutter analyze` e a suíte completa de testes (`flutter test`), garantindo 0 warnings e 100% de cobertura nos módulos modificados.
