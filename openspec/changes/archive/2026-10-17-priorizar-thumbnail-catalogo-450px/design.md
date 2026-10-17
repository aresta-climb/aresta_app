# Design Técnico: Priorização da Thumbnail de Catálogo e Aumento de Resolução para 450px

## Contexto

Consulte o [proposal.md](proposal.md) para a motivação e justificativa.

O aplicativo Aresta possui um mecanismo de pré-carregamento (`ExtratorAssetsPreload`) que desempacota o `indice.binarypb` e miniaturas de catálogo em `$downloadsRoot/thumbnails/<picoId>.webp` no primeiro acesso. O pipeline de build (`aresta_db`) passará a gerar essas miniaturas na resolução de 450px de largura em WebP (mantendo `caminho_thumbnail` apontando para `imagens/thumbnail.webp` e preservando o arquivo em `arquivos_externos` para compatibilidade com clientes legados).

Ao abrir um croqui em modo online, o aplicativo cliente deve preferir a miniatura de catálogo existente localmente, evitando requisições HTTP desnecessárias e garantindo renderização imediata do cabeçalho.

## Metas / Não-Metas

**Metas:**
- Permitir que a abertura de croquis em modo online sirva instantaneamente a miniatura local do catálogo (`thumbnails/<picoId>.webp`), sem requisições de rede.
- Manter fallback transparente para `imagens/thumbnail.webp` quando a miniatura do catálogo não estiver presente localmente.
- Ajustar a `larguraAlvo` de 300px para 450px em `buildCragBackground` em `card_pico.dart`.
- Manter compatibilidade total com croquis existentes, clientes legados e croquis salvos offline.

**Não-Metas:**
- Não alterar as dimensões de layout de tela, proporções ou estrutura visual de `CragCard` ou `PicoDetailsPage`.
- Não remover `imagens/thumbnail.webp` do `arquivos_externos` do Protobuf no backend (preservado para compatibilidade retroativa).
- Não alterar a lógica de cartões da lista de croquis offline (`OfflineCragCard`), que já leem miniaturas baixadas.

## Decisões Técnicas

### 1. Fallback Local Inteligente em `ProvedorImagemAresta.resolver`
Ao resolver caminhos que representem a capa do croqui (ex: `imagens/thumbnail.webp` ou caminho correspondente a `croqui.caminhoThumbnail`):
- O provedor verifica primeiro o arquivo local do croqui: `$downloadsRoot/<picoId>/imagens/thumbnail.webp`. Se o croqui estiver baixado offline, esse arquivo é retornado diretamente.
- Caso o arquivo local do croqui não exista (cenário online):
  - O provedor verifica se `$downloadsRoot/thumbnails/<picoId>.webp` existe no armazenamento local permanente.
  - Se existir, retorna imediatamente `ImagemArquivoAresta` apontando para esse arquivo (usando o hash pré-indexado do catálogo).
  - Dessa forma, nenhum download redundante ocorre na CDN ao abrir croquis online.
- Se nem o arquivo interno nem a miniatura de catálogo existirem, o provedor prossegue normalmente para o streaming remoto de `imagens/thumbnail.webp` da CDN salvando em `temp_cache`.

*Alternativa considerada*: Alterar o campo `caminho_thumbnail` no Protobuf gerado pelo backend para `thumbnails/<picoId>.webp`.
*Motivo da rejeição*: Quebraria versões legadas do aplicativo em circulação que esperam caminhos relativos ao diretório do croqui (`$downloadsRoot/<picoId>/`).

### 2. Aumento de `larguraAlvo` para 450px no `buildCragBackground`
Em `card_pico.dart`, o método `_CragBackgroundWidgetState._inicializarProvedor()` passa `larguraAlvo: 450` para `ProvedorImagemAresta.resolver`. O downsampling do Flutter decodificará a imagem em até 450px de largura, aproveitando a nitidez do novo asset de 450px gerado pelo pipeline de dados, mantendo consumo de memória RAM proporcional.

*Alternativa considerada*: Não especificar `larguraAlvo` (usar tamanho natural).
*Motivo da rejeição*: Manter um limite explícito de 450px previne consumo excessivo de memória em dispositivos modestos caso imagens legadas de alta resolução sejam fornecidas.

## Riscos / Trade-offs

- **[Risco] Divergência de aspecto ou enquadramento entre `thumbnails/<picoId>.webp` e `imagens/thumbnail.webp`**
  → *Mitigação*: Ambas as imagens são derivadas pelo pipeline da mesma fonte original com recorte centralizado (*cover*).
- **[Risco] Falta de hash para a thumbnail de catálogo ao usar como fallback**
  → *Mitigação*: O `DatasetRepository` já possui a rota `thumbnails/<picoId>.webp` indexada em $O(1)$ a partir de `ResumoCroqui.checksumSha256Thumbnail` no `indice.binarypb`.
