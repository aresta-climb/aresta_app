# Tarefas de Implementação

## 1. Modelos e Utilitários de Graduação e Mediana (TDD)

- [x] 1.1 Criar testes unitários para a função `obterPesoDificuldadeUnificado` e para o cálculo de mediana de grau por setor em `frontend/test/utils/filtro_grau_escalada_test.dart`, validando conversão entre vias e boulders e resiliência a outliers.
- [x] 1.2 Implementar `obterPesoDificuldadeUnificado` e o algoritmo de mediana de setor em `frontend/lib/utils/filtro_grau_escalada.dart`, verificando a passagem de todos os testes unitários.
- [x] 1.3 Criar testes unitários para `EstadoFiltrosUnificado` em `frontend/test/utils/filtro_grau_escalada_test.dart`, cobrindo filtragem de setores, projeção contextual de modalidades e formatação de contadores `(filtradas/total)`.
- [x] 1.4 Implementar `EstadoFiltrosUnificado` em `frontend/lib/utils/filtro_grau_escalada.dart` e garantir que os testes rodem e passem com 100% de cobertura.

## 2. Componentes de UI: Barra de Ordenação e Cartão de Setor Enriquecido

- [x] 2.1 Criar testes de widget em `frontend/test/widgets/barra_ordenacao_exploracao_test.dart` validando os botões PADRÃO, GRAU e ALFABÉTICO e a alternância de direção com ícone de seta.
- [x] 2.2 Implementar o widget `BarraOrdenacaoExploracao` em `frontend/lib/widgets/barra_ordenacao_exploracao.dart` com docstrings completas em português e assegurar aprovação nos testes de widget.
- [x] 2.3 Criar testes de widget em `frontend/test/view/function_library/pico_functions_test.dart` verificando a renderização de faixa de grau (`5º a 8a`) e contador de vias filtradas no cartão de setor.
- [x] 2.4 Atualizar `buildSectorTile` em `frontend/lib/view/function_library/pico_functions.dart` para exibir os metadados contextuais quando houver filtros aplicados.

## 3. Painel de Filtros Unificado (Superset e Projeção Contextual)

- [x] 3.1 Criar testes de widget em `frontend/test/widgets/painel_filtros_indice_test.dart` validando o modo Superset na aba Setores (com seleção de modalidades ativas e sliders múltiplos) e o modo contextual nas modalidades individuais.
- [x] 3.2 Atualizar `PainelFiltrosIndice` em `frontend/lib/widgets/painel_filtros_indice.dart` para operar sobre `EstadoFiltrosUnificado` e renderizar os controles adequados conforme a aba ativa.

## 4. Tela Unificada de Exploração com Abas Dinâmicas (`SetoresPage`)

- [x] 4.1 Criar testes de widget completos em `frontend/test/pages/pico_subpages/setores_page_test.dart` cobrindo renderização de abas dinâmicas, contadores `(filtradas/total)`, ocultação de setores vazios, alternância de listas e ordenação por mediana.
- [x] 4.2 Refatorar `SetoresPage` em `frontend/lib/pages/pico_subpages/setores_page.dart` integrando o `TabController` (com aba Setores e abas de modalidades), o painel de filtros e a listagem dinâmica de setores ou vias.

## 5. Hub do Pico e Navegação Declarativa

- [x] 5.1 Criar testes de widget em `frontend/test/pages/pico_test.dart` verificando a substituição dos cards antigos pelo card unificado "Setores & Escaladas" e o disparo da navegação.
- [x] 5.2 Atualizar `PicoDetailsPage` em `frontend/lib/pages/pico.dart` para exibir o card hero unificado "Setores & Escaladas" em largura total.
- [x] 5.3 Atualizar `frontend/lib/navigation/arvore/pico_nodes.dart` e `frontend/lib/main.dart` para rotear requisições de exploração para a nova `SetoresPage`, mantendo retrocompatibilidade com `IndiceEscaladasNode`.

## 6. Validação Integrada, Documentação e Cobertura

- [x] 6.1 Executar a suíte de testes do projeto via `flutter test` garantindo que todos os testes passem com 100% de cobertura nos componentes introduzidos ou modificados.
- [x] 6.2 Atualizar a documentação técnica nos arquivos `README.md` pertinentes em `frontend/lib/pages/`, `frontend/lib/widgets/` e `frontend/lib/utils/` descrevendo a arquitetura unificada de exploração.
