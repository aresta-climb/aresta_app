## 1. Módulo e Utilitário de Consolidação de Modalidades (TDD)

- [x] 1.1 Criar testes unitários para consolidação e concordância gramatical de modalidades em `test/utils/consolidador_modalidades_test.dart` cobrindo singular (ex: "1 esportiva"), plural (ex: "12 esportivas", "3 móveis", "2 multienfiadas"), highlines, ausência de vias e fallback de precomputados.
- [x] 1.2 Implementar o utilitário `frontend/lib/utils/consolidador_modalidades.dart` e verificar que todos os testes unitários de consolidação passam com sucesso.

## 2. Componente Modular de Badges (TDD)

- [x] 2.1 Criar testes de widget para `BadgesModalidades` em `test/widgets/badges_modalidades_test.dart` validando renderização de chips com Wrap, formatação de texto e comportamento para lista vazia.
- [x] 2.2 Implementar o widget `frontend/lib/widgets/badges_modalidades.dart` com estilização compatível com o tema e verificar aprovação de todos os testes de widget.

## 3. Integração na Listagem de Setores e Grupos (TDD)

- [x] 3.1 Atualizar testes de widget em `test/view_functions/pico_functions_widget_test.dart` e testes de página para validar que `buildSectorTile` renderiza badges de modalidades e `buildGrupoTile` renderiza o resumo quantitativo em duas linhas.
- [x] 3.2 Atualizar `buildSectorTile` e `buildGrupoTile` em `frontend/lib/view_functions/pico_functions.dart` para incorporar `BadgesModalidades` e a linha descritiva de grupo, verificando aprovação nos testes.

## 4. Integração no Mapa Interativo (TDD)

- [x] 4.1 Atualizar os testes de widget em `test/pages/mapa_interativo_test.dart` (ou testes de cartões de referência do mapa) verificando a presença das badges em `_buildSetorCard` e do resumo com badges em `_buildGrupoCard`.
- [x] 4.2 Atualizar `_buildBaseCard`, `_buildSetorCard` e `_buildGrupoCard` em `frontend/lib/pages/mapa_interativo.dart` para exibir os badges informativos e verificar aprovação dos testes.

## 5. Validação e Qualidade

- [x] 5.1 Executar a suíte de testes completa do aplicativo (`flutter test`) e a análise estática (`flutter analyze`) garantindo conformidade com o `AGENTS.md` e ausência de regressões.
