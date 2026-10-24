## MODIFIED Requirements

### Requirement: Resolução de UIDs no Cloudflare D1 e Renderização SSR com OpenGraph
Para requisições `GET /{uid}` ou `GET /{prefixo}/{uid}` com prefixo válido (`m`, `s`, `sm`, `ms`, `q`, `qm`, `mq`) e `uid` alfanumérico de 14 caracteres, o Worker DEVE (MUST) consultar `catalogo_croquis` e `catalogo_aresta` no Cloudflare D1 (`aresta-catalogo`) e retornar HTML (`200 OK`, `Cache-Control: public, max-age=3600, s-maxage=86400`) com meta tags OpenGraph (`og:title`, `og:description`, `og:image`), resumo da entidade e links para as lojas e para `aresta://aresta.cc/...`, ou `404 Not Found` se inexistente.

#### Scenario: Compartilhamento de Escalada no WhatsApp (`GET /s/<uid>`)
- **WHEN** o crawler do WhatsApp ou um navegador requisita `GET https://aresta.cc/s/<uid>` para um UID de escalada existente no D1 (ex.: via `"Aresta Clássica"`, grau `"6ºsup"`, modalidade `"esportiva"`, setor `"Setor Principal"`, croqui `"Pedra Grande"`, cidade `"Igarapé"`, estado `"MG"`, slug `"br_mg_igarape_pedra_grande"`)
- **THEN** o Worker responde `200 OK` com HTML contendo `og:title` com o nome e grau da via, `og:description` mencionando a modalidade capitalizada (`Modalidade: Esportiva`), o setor sem prefixo duplicado (`Setor: Principal`) e o croqui, `og:image` apontando para `https://serving.arestaclimb.com/v4/thumbnails/br_mg_igarape_pedra_grande.webp` e link `"Abrir no aplicativo"` apontando para `aresta://aresta.cc/s/<uid>`.

#### Scenario: Resolução de Croqui diretamente por `croqui_uid` (`GET /<uid>`)
- **WHEN** uma requisição `GET https://aresta.cc/<croqui_uid>` corresponde a um registro na tabela `catalogo_croquis`
- **THEN** o Worker responde `200 OK` com HTML resumindo o croqui (nome, cidade e estado), sua thumbnail em `og:image` e os botões das lojas.

#### Scenario: UID inexistente no banco D1
- **WHEN** uma requisição `GET https://aresta.cc/s/UidInexistente` não encontra correspondência em `catalogo_croquis` nem em `catalogo_aresta`
- **THEN** o Worker responde `404 Not Found` com HTML amigável seguindo o Design System do Aresta Climb e links para a App Store, Google Play e `https://arestaclimb.com`.

## ADDED Requirements

### Requirement: Design System Unificado Light e Dark Integrado ao Site Oficial
As páginas HTML SSR (`200 OK` e `404 Not Found`) do Worker `cloudflare/app-links` DEVEM (MUST) implementar o Design System do `arestaclimb.com` com variáveis CSS para tema claro (`light`) e escuro (`dark`), script de inicialização que respeita `localStorage('aresta-theme')` e `prefers-color-scheme: dark`, botão `#themeToggle`, cabeçalho com a logo oficial (`https://arestaclimb.com/assets/logo_app.png`) e rodapé institucional.

#### Scenario: Alternância e persistência de tema claro e escuro na página do link
- **WHEN** o usuário acessa `https://aresta.cc/s/<uid>` em um navegador com `prefers-color-scheme: dark` ou aciona o botão `#themeToggle` no cabeçalho
- **THEN** a página aplica o atributo `data-theme="dark"` ou `data-theme="light"` na tag `<html>`, exibe a logo do Aresta Climb no cabeçalho e persiste a preferência na chave `aresta-theme` do `localStorage`.

### Requirement: Layout Responsivo Mobile-First Estilo Aplicativo e Card de Duas Colunas no Desktop
A página da entidade DEVE (MUST) exibir a miniatura `600x600` (`1:1`) sem cortes (`aspect-ratio: 1 / 1`), utilizando no mobile um cabeçalho hero de largura total com gradiente inferior fundindo ao fundo, título sobreposto, subtítulo em verde-musgo, banner de download estilo `BannerModoOnline` e cards estilo `PicoMenuCard`, e adaptando-se no desktop (`min-width: 820px`) para um card de duas colunas com a imagem `1:1` à esquerda e os detalhes à direita.

#### Scenario: Visualização da miniatura quadrada sem corte vertical ou lateral
- **WHEN** a página de uma entidade com `id_slug` é renderizada no mobile ou no desktop
- **THEN** o contêiner da miniatura preserva a proporção `1:1` da imagem da CDN sem cortar o topo ou a base do croqui, exibindo o layout empilhado estilo `PicoPage` em telas móveis e o layout dividido em duas colunas em telas desktop.

### Requirement: Botões Clássicos das Lojas com Logotipo e Abertura Nativa Restrita ao Mobile
O banner de download DEVE (MUST) apresentar os botões `.store-badge` da Apple App Store e da Google Play contendo seus respectivos ícones vetoriais SVG oficiais, incluir a meta tag `<meta name="apple-itunes-app">` para o Smart App Banner no iOS e exibir o link secundário `"Já tem o Aresta instalado? Abrir no aplicativo →"` (`aresta://aresta.cc/...`) exclusivamente em viewports móveis, ocultando-o em viewports desktop.

#### Scenario: Exibição dos botões das lojas com SVG e ocultação do link nativo no desktop
- **WHEN** a página da entidade é renderizada
- **THEN** os botões da App Store e da Google Play contêm os ícones `<svg>` oficiais com os rótulos `"Disponível na / App Store"` e `"Disponível no / Google Play"`, e o bloco com o link `aresta://aresta.cc/...` possui regra responsiva que o oculta em telas desktop (`min-width: 820px`).

### Requirement: Normalização de Modalidade, Etiqueta de Tipo e Prefixos de Setor e Grupo
O renderizador SSR DEVE (MUST) formatar `escalada_tipo` com inicial maiúscula (`Boulder`, `Esportiva`, `Tradicional`, `Multienfiada`, `Highline`), exibir a etiqueta principal como `"Boulder"` quando `escalada_tipo === "boulder"` e `"Highline"` quando `escalada_tipo === "highline"`, e remover os prefixos redundantes `"Setor "` e `"Grupo "` (case-insensitive) dos valores exibidos em `Setor:` e `Grupo:` tanto no HTML quanto em `og:description`.

#### Scenario: Formatação de boulder em setor cujo nome já inicia com a palavra Setor
- **WHEN** o Worker renderiza uma escalada com `nome: "Sobe e desce"`, `escalada_grau: "VB"`, `escalada_tipo: "boulder"`, `setor_nome: "Setor Tramontina"` e `grupo_nome: "Grupo Sherpa"`
- **THEN** o HTML e a meta tag `og:description` exibem a etiqueta `"Boulder"`, a modalidade `"Modalidade: Boulder"`, o setor `"Setor: Tramontina"` (sem repetir `"Setor: Setor Tramontina"`) e o grupo `"Grupo: Sherpa"` (sem repetir `"Grupo: Grupo Sherpa"`).
