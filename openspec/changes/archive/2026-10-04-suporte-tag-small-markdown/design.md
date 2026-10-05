# Design: Suporte à Tag `<small>` no Markdown

## Context

O aplicativo utiliza `flutter_markdown_plus` (`^1.0.7` com lockfile em `1.0.12`) e `markdown` (`7.3.1`). No componente [`OfflineMarkdown`](file:///c:/Renato/Devel/aresta-climb/aresta_app/frontend/lib/view/function_library/markdown_offline.dart), o widget `MarkdownBody` é instanciado com o conjunto de extensões `md.ExtensionSet.gitHubFlavored`.

Por padrão, tags HTML inline não são transformadas em nós customizados pelo parser. No entanto, o `MarkdownBody` suporta a passagem de listas de sintaxes inline (`inlineSyntaxes`) e um mapa de construtores de elementos (`builders`).

Veja detalhes da motivação no arquivo [proposal.md](file:///c:/Renato/Devel/aresta-climb/aresta_app/openspec/changes/suporte-tag-small-markdown/proposal.md).

## Goals / Non-Goals

**Goals:**
- Implementar uma sintaxe inline (`SintaxeTagSmall`) em Dart extensível e desacoplada, em conformidade com o princípio de Tudo em Português e Feature-First.
- Implementar um construtor de elemento visual (`ConstrutorElementoSmall`) que processe os nós filhos aplicando escala reduzida de tipografia (~80% da fonte base).
- Integrar as sintaxes e construtores de forma transparente no `OfflineMarkdown` e visualizadores equivalentes.
- Suportar aninhamento de estilos Markdown (como negrito `**` e itálico `*`) dentro do conteúdo de `<small>`.
- Garantir 100% de cobertura de testes unitários e de widget seguindo estritamente TDD.
- Fornecer no editor desktop (`aresta_db`) a rotina de inserção facilitada via botão na interface gráfica.

**Non-Goals:**
- Não implementar sobrescrito (`<sup>`) ou subscrito (`<sub>`) nesta mudança, mantendo o escopo unificado e focado na redução semântica de fonte sem deslocamento vertical.
- Não introduzir dependências ou pacotes externos adicionais no projeto Flutter.

## Decisions

### 1. Utilização de `TextSpan` puro em vez de `WidgetSpan`
- **Decisão**: O `ConstrutorElementoSmall` deve devolver nós baseados em `TextSpan` (ou renderização rica de texto), em vez de envolver o texto em `WidgetSpan`.
- **Racional**: No `flutter_markdown_plus`, nós adjacentes de `TextSpan` são unificados em um único bloco de texto contínuo. Isso garante que a quebra de linha de parágrafo permaneça perfeitamente fluida, sem falhas de layout, e que a seleção de texto e a cópia para a área de transferência continuem 100% funcionais.
- **Alternativa descartada**: `WidgetSpan` foi descartado pois trata o texto reduzido como um widget embutido, o que pode quebrar a continuidade do parágrafo e prejudicar a seleção de texto em dispositivos móveis.

### 2. Processamento aninhado via `parser.document.parseInline`
- **Decisão**: Na sintaxe `SintaxeTagSmall.onMatch`, os nós filhos devem ser gerados chamando recursivamente `parser.document.parseInline(match[1]!)`, criando `md.Element('small', filhos)`.
- **Racional**: Permite que os usuários combinem formatações, como `<small>**Nota:** texto</small>`, gerando árvores AST válidas e bem tipadas.
- **Alternativa descartada**: Criar `md.Element.text('small', match[1]!)` apenas com texto cru foi descartada por restringir estilos compostos no Markdown.

### 3. Fator de escala tipográfica de 80% (0.8)
- **Decisão**: A fonte base do parágrafo no app é de 16px. A escala definida para `<small>` é de `0.8` (~12.8px), arredondada e consistente com a hierarquia do tema.
- **Racional**: Proporciona clara diferenciação visual para notas e notas de rodapé, mantendo total legibilidade e conformidade com diretrizes de acessibilidade em telas de diferentes densidades.

### 4. Integração no Editor Desktop (`aresta_db`)
- **Decisão**: No editor desktop em PySide6/Qt, o `QTextDocument.setMarkdown` já converte `<small>` para `<span style="font-size:small;">` nativamente na pré-visualização. Logo, apenas a adição do botão de atalho `btn_small` no `WidgetEditorMarkdown` é necessária no lado desktop, envolvendo a seleção ou inserindo as tags no cursor com registro na pilha de Undo/Redo.

## Risks / Trade-offs

- **[Tags incompletas ou não fechadas]** → Se o autor digitar `<small>` sem fechar com `</small>`, a expressão regular não casa com o padrão de fechamento e o texto bruto é mantido sem quebrar a renderização da tela.
- **[Aninhamento excessivo ou recursivo]** → Mitigado pelo uso de expressão não gulosa `(.*?)` e escopo inline estrito.
