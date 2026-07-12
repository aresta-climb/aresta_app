## 1. Testes e Modelo de Dados (TDD)

- [x] 1.1 Escrever testes unitários em `navigation_tree_test.dart` garantindo que `CarrosselItemData` armazena e repassa `escaladaContextNome`.
- [x] 1.2 Implementar a propriedade `escaladaContextNome` em `CarrosselItemData` e adicionar **docstrings** detalhadas explicando a função de cada propriedade de contexto (`setorContextNome`, `grupoContextNome`, `escaladaContextNome`).
- [x] 1.3 Escrever testes verificando que a atualização do estado mantém o 100% de cobertura no modelo.

## 2. Testes e Propagação de Contexto de Navegação

- [x] 2.1 Escrever/Atualizar testes de widget para `via_functions.dart` (`via_functions_widget_test.dart`) garantindo que ao disparar "Ver nos mapas", a ação gere um `CarrosselItemData` com o `grupoContextNome` e `escaladaContextNome` corretos.
- [x] 2.2 Implementar a correção em `frontend/lib/view_functions/via_functions.dart`, substituindo `grupoContextNome: null` e repassando `escaladaContextNome`. Adicionar comentários no código (docstrings) justificando o repasse.
- [x] 2.3 Escrever/Atualizar testes de widget para `mapa_interativo.dart` garantindo que o clique secundário em `_buildEscaladaCard` forme corretamente o contexto com Grupo e Escalada para o Carrossel.
- [x] 2.4 Implementar a correção em `frontend/lib/pages/mapa_interativo.dart` (`_buildEscaladaCard`), preenchendo os contextos ausentes e adicionando as devidas docstrings.
- [x] 2.5 Validar/Corrigir eventuais repasses nulos remanescentes em `_buildSetorCard` e `_buildGrupoCard` e garantir seus respectivos testes (cobertura 100%).

## 3. Verificação de Cobertura Final

- [x] 3.1 Executar a suíte de testes com ferramenta de coverage e confirmar 100% de cobertura nos arquivos modificados (`navigation_tree.dart`, `via_functions.dart`, `mapa_interativo.dart`).
