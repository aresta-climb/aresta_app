# Design Técnico: Foto de Capa em Setores e Grupos com Header Adaptativo

## Context

Para motivação e objetivos de produto, consulte [proposal.md](proposal.md).

Atualmente, [`SetorPage`](../../frontend/lib/pages/setor.dart) e [`GrupoPage`](../../frontend/lib/pages/grupo.dart) resolvem a foto de cabeçalho através do método `_resolveCoverImage()`, que serializa a mensagem protobuf completa para JSON (`jsonEncode(widget.setor.toProto3Json())`) e executa uma expressão regular para capturar a primeira tag `![alt](caminho)`. Caso nenhuma tag seja encontrada, a tela recorre a `buildCragBackground`, renderizando a imagem de capa geral do pico. Adicionalmente, havia uma condição `widget.setor.mapas.isNotEmpty` que impedia setores sem mapas de exibir fotos de abertura.

Com a adição do campo nativo `string caminho_imagem_capa = 5` em `Setor` e `Grupo` no schema Protobuf (`aresta_api`), o aplicativo móvel pode consultar a foto de forma determinística e síncrona.

## Goals / Non-Goals

**Goals:**
- Atualizar o submódulo `frontend/lib/aresta_api` para integrar os stubs Dart contendo `caminhoImagemCapa`.
- Substituir o parsing de Markdown via regex em `SetorPage` e `GrupoPage` pela leitura direta de `caminhoImagemCapa`.
- Implementar cabeçalho dinâmico adaptativo:
  - `expandedHeight: 300.0` com `FlexibleSpaceBar` quando `_temCapa == true`.
  - `expandedHeight: null` (barra compacta padrão) com título integrado diretamente na AppBar quando `_temCapa == false`.
- Eliminar o fallback de imagem do pico (`buildCragBackground` / `_buildDefaultCover`) em setores e grupos.
- Adicionar testes de widget cobrindo visualizações com capa e sem capa em `SetorPage` e `GrupoPage`.

**Non-Goals:**
- Alterar o design ou layout dos cards na lista de setores ([`SetoresPage`](../../frontend/lib/pages/pico_subpages/setores_page.dart)).
- Modificar telas de picos ou croqui raiz.
- Realizar requisições remotas síncronas de imagens fora do pipeline existente de `resolveImagePathProvider` / `ProvedorImagemAresta`.

## Decisions

### Decisão 1: Propriedade Computada Síncrona `_temCapa`
- **Escolha:** Definir um getter síncrono `bool get _temCapa => widget.setor.hasCaminhoImagemCapa() && widget.setor.caminhoImagemCapa.isNotEmpty;` (e equivalente para `Grupo`).
- **Justificativa:** Como a presença do campo é verificada diretamente na mensagem Protobuf já em memória, a decisão de layout entre o `SliverAppBar` expandido (300px) e o compacto pode ser tomada imediatamente na construção do widget, sem telas piscando ou delays de `FutureBuilder`.
- **Alternativas consideradas:** Manter 300px fixo com cor sólida quando sem foto. Rejeitado pelo usuário por gerar 300px de espaço vazio escuro inútil antes das informações e vias.

### Decisão 2: Remoção Definitiva do Parsing de Markdown
- **Escolha:** Em `_resolveCoverImage()`, ler exclusivamente `widget.setor.caminhoImagemCapa` (ou `widget.grupo.caminhoImagemCapa`).
- **Justificativa:** Todos os croquis da base de dados foram migrados e recompilados, com as tags de capa removidas do corpo Markdown. Eliminar o `jsonEncode` e o `RegExp` economiza ciclos de CPU e alocações de memória na navegação de tela.

### Decisão 3: Eliminação do Fallback de Foto do Pico
- **Escolha:** Remover `buildCragBackground` e `_buildDefaultCover` de `SetorPage` e `GrupoPage`.
- **Justificativa:** Exibir a imagem da montanha inteira ao entrar em um setor específico causava confusão visual e sensação de que a foto pertencia ao setor.

### Decisão 4: Estrutura do Header Compacto
- **Escolha:** Quando `_temCapa == false`:
  - `SliverAppBar` sem `flexibleSpace` complexo.
  - `title: Text(widget.setor.nome.toUpperCase(), style: TextStyle(fontFamily: 'BebasNeue', ...))`.
  - Altura padrão de AppBar (compacta), com botão de voltar e botão de feedback alinhados naturalmente.
  - O conteúdo (`buildSetorBody` / `buildGrupoBody`) inicia imediatamente abaixo da AppBar.

## Risks / Trade-offs

- **[Risco: Imagem local não encontrada em disco no modo offline]**  
  *Mitigação:* `ProvedorImagemAresta.resolver` e o `errorBuilder` da imagem já possuem salvaguarda que preserva o fundo escuro (`deepBasalt`) sem travar a interface.
- **[Risco: Compatibilidade com croquis em desenvolvimento no editor local]**  
  *Mitigação:* O editor do repositório `aresta_db` já salva `caminho_imagem_capa` tanto no `.binarypb` quanto no Frontmatter Markdown, garantindo sincronia completa com o `aresta_app`.
