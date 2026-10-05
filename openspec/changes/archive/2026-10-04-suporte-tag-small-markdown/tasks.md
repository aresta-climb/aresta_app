# Tasks

## 1. Sintaxe Inline e Parser de Markdown (TDD)

- [x] 1.1 Criar testes unitários para `SintaxeTagSmall` em `test/view/function_library/sintaxe_tag_small_test.dart` cobrindo identificação de tag `<small>`, insensibilidade a maiúsculas/minúsculas e parsing aninhado de markdown, validando falha inicial do teste via `flutter test`.
- [x] 1.2 Implementar a classe `SintaxeTagSmall` estendendo `md.InlineSyntax` com regex `<small>(.*?)</small>` e suporte recursivo a `parser.document.parseInline`, verificando que todos os testes unitários de sintaxe passam com 100% de cobertura.

## 2. Construtor Visual do Elemento Small (TDD)

- [x] 2.1 Criar testes de widget em `test/view/function_library/construtor_elemento_small_test.dart` verificando a redução proporcional de fonte (80%) com `TextSpan` e herança correta de negrito/itálico, validando a falha inicial do teste via `flutter test`.
- [x] 2.2 Implementar `ConstrutorElementoSmall` estendendo `MarkdownElementBuilder` aplicando `TextSpan` com escala proporcional reduzida (~80%) sobre o estilo pai, verificando que todos os testes passam com 100% de cobertura.

## 3. Integração no OfflineMarkdown e Validação Visual

- [x] 3.1 Adicionar teste de widget em `test/view/function_library/markdown_offline_test.dart` garantindo que `OfflineMarkdown` renderiza parágrafos com `<small>` corretamente dentro da árvore de widgets do app.
- [x] 3.2 Integrar `SintaxeTagSmall` e `ConstrutorElementoSmall` na chamada do `MarkdownBody` em `frontend/lib/view/function_library/markdown_offline.dart`, executando a suíte de testes de markdown com `flutter test`.
- [x] 3.3 Atualizar documentação e docstrings em `frontend/lib/view/README.md` e `frontend/lib/view/function_library/README.md`, descrevendo a capacidade de formatação tipográfica com `<small>`.

## 4. Botão de Inserção no Editor Desktop (aresta_db)

- [x] 4.1 Criar teste de integração para o editor desktop em `aresta_db/editor/views/inserir_tag_small_test.py` validando o encapsulamento de seleção e inserção no cursor com integração à pilha de Undo/Redo.
- [x] 4.2 Adicionar o botão `btn_small` ("🔤 Small") na barra de ferramentas de `WidgetEditorMarkdown` em `aresta_db/editor/views/widget_editor_dados.py` chamando `aplicar_tag_small`, verificando aprovação nos testes com `uv run pytest`.
