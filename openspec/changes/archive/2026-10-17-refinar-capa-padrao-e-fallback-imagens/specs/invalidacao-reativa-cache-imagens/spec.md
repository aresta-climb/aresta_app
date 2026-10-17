# Spec Delta

## MODIFIED Requirements

### Requirement: Fallback Visual com Logo da Splash Screen para Croquis sem Miniatura ou Capa
Quando um croqui não possuir miniatura de catálogo (`checksumSha256Thumbnail` vazio no `ResumoCroqui`) ou imagem de capa (`caminhoThumbnail` vazio no `Croqui`), os ViewModels e componentes de interface NÃO DEVEM (MUST NOT) sintetizar um caminho fallback `thumbnails/<picoId>.webp` nem invocar o `ProvedorImagemAresta.resolver`. Em vez disso, os cartões de croquis (`OfflineCragCard`, `CardPico`) e o cabeçalho da página de pico (`PicoPage` / `buildCragBackground`) DEVEM exibir exclusivamente o asset `assets/logo_in_app.jpg` sem espaçamento interno (`Padding`), preenchendo 100% da área disponível sobre um fundo preto (`Colors.black`) ao redor. Por outro lado, quando o croqui possuir miniatura ou capa declarada no Protobuf (`caminhoMiniatura`, `capaPath` ou `thumbnailUrl` não vazios), o componente DEVE invocar o `ProvedorImagemAresta.resolver`; caso a imagem ainda não tenha sido baixada, esteja indisponível offline (`snapshot.data == null`) ou falhe na decodificação (`errorBuilder`), o componente NÃO DEVE exibir a logo do Aresta, devendo exibir o ícone padrão de imagem indisponível (`Icons.broken_image` na cor `Colors.grey`) centralizado sobre o fundo escuro, de forma consistente com `OfflineMarkdown` e `MapaInterativoPage`. Enquanto a resolução assíncrona estiver aguardando (`ConnectionState.waiting`), o componente DEVE exibir apenas o container de fundo escuro neutro.

#### Scenario: Renderização de cartão ou cabeçalho de croqui sem thumbnail definida
- **WHEN** um croqui sem `checksumSha256Thumbnail` ou sem `caminhoThumbnail` for renderizado em `OfflineCragCard`, `CardPico` ou `PicoPage`
- **THEN** o componente NÃO DEVE disparar resolução no `ProvedorImagemAresta` nem requisições HTTP
- **AND** DEVE exibir o asset `assets/logo_in_app.jpg` ocupando toda a área disponível sobre um container com cor de fundo `Colors.black` sem `Padding` interno.

#### Scenario: Renderização de cartão ou cabeçalho com capa declarada no Protobuf mas ainda não baixada ou indisponível
- **WHEN** um croqui possuir `checksumSha256Thumbnail` ou `caminhoThumbnail` declarado no Protobuf
- **AND** o `ProvedorImagemAresta.resolver` retornar `null` (ex: sem conexão e fora do cache) ou o `Image.errorBuilder` for acionado
- **THEN** o componente NÃO DEVE exibir `assets/logo_in_app.jpg`
- **AND** DEVE exibir o ícone `Icons.broken_image` com `color: Colors.grey` centralizado sobre o fundo escuro do componente.
