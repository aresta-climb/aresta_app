# Proposta: Suporte à Tag `<small>` no Markdown

## Motivação

Atualmente, autores e mantenedores de croquis precisam incluir notas secundárias, legendas, avisos e detalhes técnicos (como sugestões de graduação, observações de acesso e créditos) nas descrições em Markdown de picos, setores e vias. No entanto, o padrão Markdown CommonMark/GFM não possui sintaxe nativa para redução de fonte, e o visualizador `OfflineMarkdown` ignora tags HTML inline, renderizando-as como texto cru. O uso de `<sup>` ou `<sub>` desalinha a linha de base vertical, criando distorções visuais. A introdução de suporte à tag semântica `<small>` permite reduzir proporcionalmente a tipografia mantendo o alinhamento da linha de base intacto.

## O Que Muda

- **Suporte à Tag `<small>` no Visualizador Markdown**:
  - Implementação de sintaxe inline customizada (`InlineSyntax`) capaz de identificar `<small>(.*?)</small>` com suporte a marcações aninhadas (negrito, itálico).
  - Implementação de construtor de elemento (`MarkdownElementBuilder`) que aplica escala reduzida de fonte (80% do tamanho base) preservando a linha de base e a fluidez do `TextSpan`.
  - Integração no `OfflineMarkdown` e visualizadores correlatos do aplicativo móvel.
- **Inserção Facilitada no Editor Desktop (`aresta_db`)**:
  - Disponibilização de botão dedicado "🔤 Small" na barra de ferramentas do Markdown do editor de dados para envolver a seleção ou inserir a tag no cursor.

## Capacidades

### Novas Capacidades

- `renderizacao-markdown-enriquecido`: Cobre a extensão do parser e construtor visual de Markdown para suportar tags semânticas de formatação tipográfica, iniciando por `<small>`.

### Capacidades Modificadas

<!-- Nenhuma capacidade existente teve seus requisitos alterados diretamente. -->

## Impacto

- **Código Afetado**:
  - `frontend/lib/view/function_library/markdown_offline.dart` (e novos componentes de sintaxe/builder tipográfico).
  - `frontend/test/view/function_library/markdown_offline_test.dart` (novos testes de unidade e widget).
  - `aresta_db/editor/views/widget_editor_dados.py` (botão de atalho na interface desktop).
- **Dependências**: Nenhuma dependência externa adicional necessária; utiliza os pontos de extensão nativos de `package:markdown` e `package:flutter_markdown_plus`.
- **Compatibilidade**: Totalmente retrocompatível com conteúdos existentes em Markdown. Textos sem a tag continuam sendo renderizados normalmente.
