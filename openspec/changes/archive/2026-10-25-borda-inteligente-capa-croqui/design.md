# Design

## Context

Conforme detalhado em `proposal.md`, a exibição da capa do croqui na `PicoDetailsPage` (`SliverAppBar` com `expandedHeight: 300.0`) utilizava `BoxFit.cover` com `larguraAlvo: 450`, o que provocava dois problemas:
1. **Cortes indesejados na arte da capa**: Capas horizontais (ex.: `4:3` como *Ouroboulder*) tinham as laterais cortadas em telas de smartphones (`~390x340 dp`), enquanto capas verticais (ex.: `A4`) ou visualizações em tablets tinham o topo e a base severamente cortados.
2. **Acoplamento indevido e baixa resolução no cabeçalho**: Uma regra especial em `ProvedorImagemAresta.resolver` interceptava apenas caminhos terminados literalmente em `'thumbnail.webp'` para redirecioná-los a `$downloadsRoot/thumbnails/<picoId>.webp` (`600x600 px`), ignorando 41 dos 43 croquis (que usam nomes como `imagens/capa_p0_i0.webp`) e degradando a nitidez em celulares modernos (`1080p+`) e tablets.

## Goals / Non-Goals

**Goals:**
- Garantir que 100% da imagem configurada em `croqui.caminhoThumbnail` apareça sem cortes no cabeçalho de `300 dp` da `PicoDetailsPage` em qualquer proporção de imagem e largura de tela (smartphones e tablets).
- Preencher eventuais sobras laterais ou verticais do cabeçalho com uma borda inteligente gerada em tempo real a partir das próprias cores das bordas da capa (`BoxFit.cover` desfocado ao fundo + `BoxFit.contain` à frente, Opção A).
- Elevar a nitidez da capa na `PicoDetailsPage` decodificando `croqui.caminhoThumbnail` com `larguraAlvo: 1200`.
- Eliminar o tratamento especial para `'imagens/thumbnail.webp'` em `ProvedorImagemAresta.resolver`.
- Assegurar que cards de listagem (`CragCard` e `OfflineCragCard`) utilizem prioritariamente `thumbnails/<picoId>.webp` e tenham `croqui.caminhoThumbnail` como fallback.

**Non-Goals:**
- Alterar o pipeline Python de geração de `thumbnails/<picoId>.webp` no repositório `aresta_db`.
- Modificar a altura `expandedHeight: 300.0` da `SliverAppBar` em `PicoDetailsPage`.
- Adicionar recuo interno extra para a barra de status/gradiente (Opção B descartada em favor da Opção A, que utiliza 100% da caixa da `FlexibleSpaceBar`).

## Decisions

### 1. Borda Inteligente em Duas Camadas (`Stack`) Compartilhando o Mesmo `ImageProvider` (Opção A)
- **Decisão**: Estender `buildCragBackground` (e `_CragBackgroundWidget` em `frontend/lib/widgets/card_pico.dart`) com os parâmetros opcionais `int larguraAlvo = 450` e `bool usarBordaInteligente = false`. Quando `usarBordaInteligente == true` (usado por `PicoDetailsPage`), o widget constrói uma `Stack` (`StackFit.expand`) usando a **mesma instância** de `ImageProvider` já resolvida pelo `FutureBuilder`:
  1. **Camada de fundo (Borda Inteligente)**: `ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0, tileMode: TileMode.clamp))` envolvendo `Image(image: provider, fit: BoxFit.cover)` seguido de um `ColoredBox(color: Colors.black.withValues(alpha: 0.25))` para suavizar o contraste nas bordas estendidas.
  2. **Camada principal (Arte Integral — Opção A)**: `Image(image: provider, fit: BoxFit.contain, alignment: Alignment.center)` ocupando 100% da área disponível da `FlexibleSpaceBar`, sem recuos verticais artificiais.
- **Racional**: Como ambas as camadas consomem exatamente o mesmo `ImageProvider` (`ResizeImage` com `width: 1200`), o Flutter decodifica a textura uma única vez na GPU e reutiliza o mesmo frame no cache de imagens, entregando transição imediata, zero custo extra de rede/disco e adaptação automática a qualquer aspect ratio (paisagem, quadrado ou retrato) em celulares e tablets.
- **Alternativas consideradas**:
  - *Opção B (Recuar a camada `BoxFit.contain` entre a status bar e o título)*: Descartada pelo usuário por reduzir a área útil da capa para `~190 dp`.
  - *Pré-processar bordas desfocadas estáticas no backend*: Descartado porque uma proporção fixa pré-renderizada não se adapta simultaneamente a telas estreitas de celulares e telas largas de tablets em orientação paisagem.

### 2. Resolução Alvo de `1200px` no Cabeçalho vs `450px` / `300px` nos Cards
- **Decisão**: Em `PicoDetailsPage`, invocar `buildCragBackground(widget.croqui.id, widget.croqui.caminhoThumbnail, larguraAlvo: 1200, usarBordaInteligente: true)`. Nos cards de catálogo (`CragCard`), manter o padrão `larguraAlvo: 450` e `usarBordaInteligente: false` (`BoxFit.cover`). No `OfflineCragCard` (`80x80 dp`), manter `larguraAlvo: 300`.
- **Racional**: As imagens de capa em `croqui.caminho_thumbnail` têm até `1200px–2048px` no lado maior. Decodificar com `larguraAlvo: 1200` mantém excelente definição em telas `1080p`/`1440p` e tablets sem desperdiçar memória de textura nos cards compactos de listagem.

### 3. Remoção de Caso Especial para `thumbnail.webp` no `ProvedorImagemAresta`
- **Decisão**: Remover o bloco em `ProvedorImagemAresta.resolver` (`frontend/lib/widgets/provedor_imagem_aresta.dart`) que verificava `cleanPath == 'imagens/thumbnail.webp' || cleanPath.endsWith('/thumbnail.webp') || cleanPath == 'thumbnail.webp'` para retornar `$downloadsRoot/thumbnails/$picoId.webp`.
- **Racional**: `thumbnails/<picoId>.webp` é exclusivamente a miniatura quadrada de catálogo.Qualquer arquivo referenciado por `croqui.caminhoThumbnail` pertence a `croqui.arquivosExternos` e deve ser resolvido de forma determinística e uniforme (`$downloadsRoot/<picoId>/<caminho>` quando baixado offline, ou `$temp_cache/<picoId>/<caminho>.<sha256>` quando online).

### 4. Priorização de `thumbnails/<picoId>.webp` no `CardCroquiViewModel.deCroqui` com Fallback para `croqui.caminhoThumbnail`
- **Decisão**: Em `_CardCroquiCroqui.caminhoMiniatura` (`frontend/lib/view/view_models/card_croqui_view_model.dart`), verificar primeiro se o repositório possui hash indexado para `'thumbnails/${_croqui.id}.webp'`; se existir, retornar `'thumbnails/${_croqui.id}.webp'`. Caso contrário, usar `_croqui.caminhoThumbnail` (se não vazio e com hash disponível) como fallback.
- **Racional**: Garante que tanto os cards da aba Explorar/Home (`_CardCroquiMetadados`) quanto os cards gerados a partir de um `Croqui` completo (`_CardCroquiCroqui`, como em *Meus Croquis*) utilizem a miniatura leve de catálogo (`thumbnails/<id>.webp`) por padrão e caiam graciosamente para `croqui.caminhoThumbnail` caso a miniatura de catálogo não exista.

## Risks / Trade-offs

- **[Risco] Custo de GPU do `ImageFilter.blur` durante a rolagem da `SliverAppBar`** → Mitigação: Aplicar `RepaintBoundary` ao redor do plano de fundo quando `usarBordaInteligente` estiver ativo para isolar a composição da textura desfocada durante o colapso da `SliverAppBar`.
- **[Risco] Capas com falha de decodificação na camada `Image` duplicarem ícone de erro** → Mitigação: Na camada de fundo borrada, o `errorBuilder` deve retornar `const SizedBox.shrink()`, deixando apenas a camada frontal exibir o `_buildBrokenImagePlaceholder(context)` centralizado.
