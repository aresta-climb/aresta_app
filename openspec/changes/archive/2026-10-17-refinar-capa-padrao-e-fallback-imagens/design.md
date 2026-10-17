# Design

## Context

Veja `proposal.md` para a motivação. Atualmente:
1. Em `frontend/lib/widgets/card_pico.dart` (`_CragBackgroundWidget`), o método `_buildPlaceholder(BuildContext context)` é chamado tanto quando `_provedorImagemFuture == null` (ausência de `capaPath` e `thumbnailUrl` no Protobuf) quanto dentro do `FutureBuilder` quando `ConnectionState.waiting`, `snapshot.data == null` ou no `errorBuilder` do `Image`.
2. Em `frontend/lib/view/function_library/meus_croquis_functions.dart` (`OfflineCragCard`), o método `_construirPlaceholderLogo()` também é reutilizado tanto para `dados.caminhoMiniatura.trim().isEmpty` quanto para os estados de carregamento/erro/ausência do `FutureBuilder`.
3. Nos demais componentes de mídia do aplicativo (`OfflineMarkdown` em `markdown_offline.dart` e `MapaInterativoPage` em `mapa_interativo.dart`), uma mídia referenciada no Protobuf que não pôde ser resolvida (`snapshot.data == null` ou `errorBuilder`) exibe `const Icon(Icons.broken_image, color: Colors.grey)`.

## Goals / Non-Goals

**Goals:**
- Distinguir visualmente nos cartões e cabeçalhos de croqui os dois estados semânticos:
  1. **Sem capa declarada no Protobuf**: exibir a capa padrão do Aresta (`assets/logo_in_app.jpg`) cobrindo 100% da área disponível com fundo `Colors.black` ao redor.
  2. **Com capa declarada no Protobuf, porém ainda não baixada ou indisponível**: exibir o ícone `Icons.broken_image` (`color: Colors.grey`) sobre o fundo escuro, sem exibir a logo do Aresta.
- Evitar cintilação (flash) da logo do Aresta ou do ícone de imagem quebrada enquanto o `FutureBuilder` está em `ConnectionState.waiting`.

**Non-Goals:**
- Alterar a lógica de resolução ou download no `ProvedorImagemAresta` ou `DatasetRepository`.
- Modificar `OfflineMarkdown` ou `MapaInterativoPage`, que já utilizam `Icons.broken_image`.

## Decisions

### 1. Separação explícita de métodos auxiliares de UI nos componentes de capa
- **Decisão**:
  - Em `_CragBackgroundWidget` (`card_pico.dart`):
    - `_construirCapaPadraoAresta()`: retorna um `Container(width: double.infinity, height: double.infinity, color: Colors.black, child: Image.asset('assets/logo_in_app.jpg', fit: BoxFit.contain, width: double.infinity, height: double.infinity))` (com `Overlay Escuro` mantido pela `Stack` pai). É utilizado **apenas** quando `_provedorImagemFuture == null`.
    - `_construirImagemIndisponivel(BuildContext context)`: retorna um `Container(width: double.infinity, height: double.infinity, color: context.colors.graniteEdge, child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50)))`. É utilizado quando o `FutureBuilder` finaliza com `snapshot.data == null`, `snapshot.hasError` ou no `errorBuilder` do `Image`.
    - Durante `ConnectionState.waiting`, retorna apenas `Container(width: double.infinity, height: double.infinity, color: context.colors.graniteEdge)` para uma transição limpa.
  - Em `OfflineCragCard` (`meus_croquis_functions.dart`):
    - `_construirCapaPadraoAresta()`: retorna `Container(width: 60, height: 60, color: Colors.black, child: Image.asset('assets/logo_in_app.jpg', fit: BoxFit.contain, width: 60, height: 60))`. É utilizado **apenas** quando `dados.caminhoMiniatura.trim().isEmpty`.
    - `_construirImagemIndisponivel()`: retorna `Container(width: 60, height: 60, color: const Color(0xFF2C332A), child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 24)))`. É utilizado quando `snapshot.data == null`, `snapshot.hasError` ou no `errorBuilder`.
    - Durante `ConnectionState.waiting`, retorna `Container(width: 60, height: 60, color: const Color(0xFF2C332A))`.
- **Alternativas consideradas**:
  - Usar `BoxFit.cover` em `assets/logo_in_app.jpg` nos cartões retangulares largos (`340x220` ou `double.infinity x 200`): descartado porque cortaria o topo e a base da montanha laranja em proporções widescreen; usar um `Container` com `color: Colors.black` ocupando 100% da área e `Image.asset('assets/logo_in_app.jpg', fit: BoxFit.contain, width: double.infinity, height: double.infinity)` sem `Padding` faz a imagem quadrada tocar 100% da altura disponível e preenche as laterais com preto puro contíguo ao fundo escuro da imagem.

## Risks / Trade-offs

- **[Contraste do fundo preto com textos e tags nos cartões]** → O `CragCard` e a `PicoPage` já aplicam gradientes escuros e textos brancos sobre a imagem de fundo (`_CragBackgroundWidget`), portanto o fundo preto ao redor da `logo_in_app.jpg` garante excelente legibilidade das tags e do título do pico.
