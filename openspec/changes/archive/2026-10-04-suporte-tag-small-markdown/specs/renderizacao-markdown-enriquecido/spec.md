# Spec Delta

## Purpose

Define o comportamento de renderização de Markdown enriquecido no aplicativo, permitindo que textos anotados com tags tipográficas semânticas, como a tag `<small>`, sejam devidamente interpretados e renderizados com escala tipográfica reduzida sem desalinhar a linha de base.

## ADDED Requirements

### Requirement: Interpretacao de tag small em Markdown
O renderizador de Markdown SHALL reconhecer a tag HTML inline `<small>` e sua respectiva tag de fechamento `</small>` de forma insensível a maiúsculas e minúsculas dentro de blocos de texto e parágrafos.

#### Scenario: Texto envolvido em tag small reconhecido como elemento dedicado
- **WHEN** uma cadeia de texto Markdown contiver `<small>texto reduzido</small>`
- **THEN** o parser SHALL processar o conteúdo delimitado como um nó de elemento tipográfico reduzido em vez de exibir literalmente as tags brutas no corpo do texto.

### Requirement: Renderizacao tipografica reduzida com preservacao de alinhamento
O sistema SHALL renderizar o conteúdo interno da tag `<small>` com tamanho de fonte proporcionalmente reduzido em relação ao estilo do elemento pai, mantendo o alinhamento da linha de base vertical inalterado.

#### Scenario: Reducao de escala proporcional sem deslocamento de baseline
- **WHEN** o texto for renderizado em tela dentro de um parágrafo com tamanho de fonte padrão
- **THEN** o trecho contido na tag `<small>` SHALL ser apresentado com aproximadamente 80% do tamanho da fonte base do parágrafo, preservando a linha de base contínua com os caracteres adjacentes.

### Requirement: Suporte a formatacao aninhada na tag small
O renderizador SHALL permitir que marcações Markdown adicionais existentes no interior da tag `<small>` sejam avaliadas e aplicadas ao texto reduzido.

#### Scenario: Negrito ou italico dentro da tag small
- **WHEN** o Markdown contiver uma estrutura como `<small>**aviso importante**</small>` ou `<small>*nota*</small>`
- **THEN** o texto renderizado SHALL exibir a formatação de peso ou estilo correspondente combinada com a escala reduzida de fonte.
