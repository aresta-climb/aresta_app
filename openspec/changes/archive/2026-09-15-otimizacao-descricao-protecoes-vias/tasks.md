## 1. Funções Utilitárias e Resolução de Modalidade/Proteções

- [x] 1.1 Criar testes unitários em `frontend/test/view_functions/via_functions_test.dart` cobrindo `getModalidadeEscalada` e `getProtecoesString` para vias esportivas, móveis puras, móveis mistas (com fixas intermediárias), boulders, multipitches (comum e misto) e highlines.
- [x] 1.2 Implementar os helpers `getModalidadeEscalada` e `getProtecoesString` em `frontend/lib/view_functions/via_functions.dart`, e verificar aprovação com `flutter test test/view_functions/via_functions_test.dart`.

## 2. Unificação de Proteções e Reordenação na Página de Detalhes da Via

- [x] 2.1 Adicionar testes de widget em `frontend/test/view_functions/via_functions_widget_test.dart` validando a presença do cartão unificado "Proteções" na notação `X+Y` (e ausência do cartão isolado "Paradas"), a precedência da "Descrição" logo após os *stat cards*, e a permanência dos botões secundários no rodapé.
- [x] 2.2 Atualizar `buildOutlineStatCard` em `frontend/lib/view_functions/common_functions.dart` para suportar `maxLines: 2` no título, garantindo quebra suave sem reticências prematuras em telas pequenas.
- [x] 2.3 Refatorar os builders de via (`_buildViaEsportiva`, `_buildViaMovel`, `_buildBoulder`, `_buildMultipitch` e `_buildHighline`) em `frontend/lib/view_functions/via_functions.dart` com a nova ordenação e o cartão unificado de proteções `X+Y`, verificando com `flutter test test/view_functions/via_functions_widget_test.dart`.

## 3. Otimização do Cartão Flutuante no Mapa Interativo

- [x] 3.1 Adicionar testes de widget em `frontend/test/pages/mapa_interativo_test.dart` verificando:
  - Subtítulo com `Modalidade | Grau | Intermediárias+Parada` (ex: `Mista | 6°sup | 3+2`).
  - Presença de prévia da descrição higienizada limitada a 2 linhas (`maxLines: 2, overflow: TextOverflow.ellipsis`).
  - Omissão da prévia quando a via não tiver descrição cadastrada.
- [x] 3.2 Atualizar `_buildBaseCard` e `_buildEscaladaCard` em `frontend/lib/pages/mapa_interativo.dart` para receber a prévia higienizada via `stripMarkdownForSubtitle` e o subtítulo enriquecido com modalidade e proteções, verificando com `flutter test test/pages/mapa_interativo_test.dart`.

## 4. Consistência Global e Validação

- [x] 4.1 Integrar `getModalidadeEscalada` na listagem de vias em `frontend/lib/view_functions/setor_functions.dart` e na busca em `frontend/lib/widgets/global_search.dart`, atualizando testes existentes e verificando com `flutter test test/view_functions/` e `flutter test test/widgets/global_search_test.dart`.
- [x] 4.2 Executar a suíte de testes completa do app (`flutter test`) e análise estática (`flutter analyze`) para certificar que nenhum teste regrediu e o código segue os padrões do repositório.
