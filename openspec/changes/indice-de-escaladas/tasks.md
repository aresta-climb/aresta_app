## 1. Modelos e Utilitários de Indexação

- [ ] 1.1 Criar testes unitários para a estrutura `ItemIndiceEscalada` e a função indexadora `indexarEscaladasDoPico` em `test/utils/indexador_escaladas_test.dart`
- [ ] 1.2 Implementar `ItemIndiceEscalada` e a função `indexarEscaladasDoPico` em `lib/utils/indexador_escaladas.dart`, verificando a passagem dos testes
- [ ] 1.3 Criar testes unitários para os filtros de faixa de grau (escala brasileira e escala V) em `test/utils/filtro_grau_escalada_test.dart`
- [ ] 1.4 Implementar os helpers de filtragem por grau, setor, conquistador e clássicas em `lib/utils/filtro_grau_escalada.dart`, verificando a passagem dos testes

## 2. Navegação em Árvore

- [ ] 2.1 Criar testes unitários para `IndiceEscaladasNode` em `test/navigation/arvore/indice_escaladas_node_test.dart`
- [ ] 2.2 Implementar `IndiceEscaladasNode` em `lib/navigation/arvore/pico_nodes.dart` e adicionar método `AppNav.toIndiceEscaladas` em `lib/navigation/navigation_functions.dart`, verificando a passagem dos testes
- [ ] 2.3 Registrar `IndiceEscaladasNode` no roteador do `lib/main.dart`, mapeando para a página do índice

## 3. Componentes e Widgets do Índice

- [ ] 3.1 Criar testes de widget para o card de escalada `CardIndiceEscalada` em `test/widgets/card_indice_escalada_test.dart`
- [ ] 3.2 Implementar `CardIndiceEscalada` em `lib/widgets/card_indice_escalada.dart`, garantindo destaque do grau, modalidade, proteções e identificador de setor
- [ ] 3.3 Criar testes de widget para o painel expansível `PainelFiltrosIndice` em `test/widgets/painel_filtros_indice_test.dart`
- [ ] 3.4 Implementar `PainelFiltrosIndice` em `lib/widgets/painel_filtros_indice.dart` com suporte a faixas rápidas, ajuste de limites, setor, autor e clássicas

## 4. Tela do Índice de Escaladas (`IndiceEscaladasPage`)

- [ ] 4.1 Criar testes de widget para a tela completa `IndiceEscaladasPage` em `test/pages/indice_escaladas_page_test.dart` cobrindo abas dinâmicas, busca textual e persistência de filtros por aba
- [ ] 4.2 Implementar `IndiceEscaladasPage` em `lib/pages/indice_escaladas_page.dart` conectando as abas por modalidade (`Esportivas`, `Boulders`, `Móveis`, `Multienfiadas`), painel de filtros e listagem rolável

## 5. Integração na Página Principal do Pico (`PicoDetailsPage`)

- [ ] 5.1 Atualizar testes de widget da `PicoDetailsPage` em `test/pages/pico_test.dart` para validar a grade de 2 colunas no topo com "SETORES" e "ÍNDICE DE ESCALADAS"
- [ ] 5.2 Modificar `lib/pages/pico.dart` para renderizar os cartões lado a lado no topo com textos objetivos e navegação funcional

## 6. Aprimoramento da `ViaPage` e Padronização Terminológica

- [ ] 6.1 Criar testes de widget para o componente de hierarquia geográfica (`Grupo > Setor`) em `test/widgets/linha_localizacao_setor_test.dart`
- [ ] 6.2 Implementar componente e atualizar `ViaPage` em `lib/pages/via.dart` e `lib/view_functions/via_functions.dart` exibindo a localização completa e atalho direto para o croqui do setor
- [ ] 6.3 Padronizar ocorrências residuais da terminologia na interface para **Multienfiada** em `lib/view_functions/via_functions.dart`, `lib/pages/pico.dart` e documentação

## 7. Verificação Integrada e Cobertura de Testes

- [ ] 7.1 Executar a suíte completa de testes (`flutter test`) e verificar conformidade de 100% de aprovação e ausência de regressões
- [ ] 7.2 Validar a consistência do fluxo completo de navegação (Pico ➔ Índice ➔ Via ➔ Voltar ao Índice com estado preservado e Salto para Setor)
