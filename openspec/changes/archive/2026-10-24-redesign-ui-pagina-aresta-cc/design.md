# Design

## Context

O Worker `cloudflare/app-links` (`../aresta_backend/cloudflare/app-links/src/renderizador_pagina_link.ts`) gera no servidor (SSR na borda da Cloudflare) o HTML retornado para links curtos `https://aresta.cc/{uid}` e `https://aresta.cc/{prefixo}/{uid}`, além da página `404 Not Found`.

Consulte `proposal.md` para a motivação completa. Em resumo, o HTML atual utiliza estilos genéricos em modo escuro fixo (`#0f172a`), corta verticalmente as miniaturas quadradas (`600x600`) da CDN ao forçá-las em uma caixa `460x220` (`object-fit: cover`), não compartilha o Design System do `arestaclimb.com` nem a linguagem visual da `PicoPage` do aplicativo móvel, e apresenta falhas de formatação nos metadados (`Modalidade: boulder` em minúsculo, etiqueta `"VIA DE ESCALADA"` para boulders e repetição `"Setor: Setor Tramontina"`).

## Goals / Non-Goals

**Goals:**
- Unificar o CSS inline do SSR em `renderizador_pagina_link.ts` com os tokens de cor, tipografia, cabeçalho, botão de tema (`#themeToggle`), rodapé e `.store-badge` de `../arestaclimb.com`, funcionando sem dependências externas bloqueantes e com suporte completo a Light Mode e Dark Mode.
- Construir um layout **Mobile-First** fiel à tela `PicoPage` do aplicativo (`aresta_app`), onde a miniatura `600x600` (`1:1`) aparece em largura total no topo com gradiente inferior e título sobreposto, expandindo em `@media (min-width: 820px)` para um **Card de 2 Colunas** com a imagem `1:1` à esquerda e o conteúdo à direita, garantindo corte zero em qualquer resolução.
- Apresentar um banner de download inspirado no `BannerModoOnline` do app com os botões clássicos da App Store e Google Play (com ícones SVG oficiais) e um link complementar discreto (`"Já tem o Aresta instalado? Abrir no aplicativo →"`) visível exclusivamente em dispositivos móveis, acompanhado da meta tag nativa `apple-itunes-app`.
- Exibir os metadados da entidade (Croqui, Grupo, Setor, Modalidade/Graduação, Localização) em cards estruturados inspirados no `PicoMenuCard` do aplicativo, com normalização pura de textos (capitalização de modalidade, etiqueta específica para `Boulder`/`Highline` e remoção de prefixos redundantes `"Setor "` e `"Grupo "`).

**Non-Goals:**
- Alterar o pipeline de geração de thumbnails `600x600` no `aresta_db`.
- Introduzir bundles JS externos ou frameworks client-side no Worker `aresta-app-links` (toda a página deve continuar autocontida em uma única resposta HTML SSR cacheável na borda da Cloudflare).
- Modificar o esquema do banco Cloudflare D1 (`catalogo_croquis` / `catalogo_aresta`) ou o contrato OpenAPI (`openapi/app_links.yaml`).

## Decisions

### 1. Tokens Visuais e Sincronização de Tema Claro/Escuro com `arestaclimb.com`
- **Decisão**: Definir no `<style>` do SSR as mesmas variáveis CSS de `../arestaclimb.com/src/landing.css`:
  - `:root` (`data-theme="light"`): `--bg: #f4f1e9`, `--bg-soft: #ece7dd`, `--surface: #faf8f2`, `--surface-2: #e6e0d5`, `--text: #1d1c19`, `--muted: #6c675f`, `--line: #d6cfc2`, `--accent: #b53e29`, `--accent-2: #9d2e1b`, `--sage: #90a989`, `--sage-deep: #596e55`.
  - `html[data-theme="dark"]`: `--bg: #11120f`, `--bg-soft: #171813`, `--surface: #1c1d18`, `--surface-2: #24251f`, `--text: #f3f0e8`, `--muted: #aaa69c`, `--line: #35362e`, `--accent: #cf563d`, `--accent-2: #b53e29`, `--sage: #90a989`, `--sage-deep: #71876d`.
  - Incluir no `<head>` o script síncrono anti-FOUC idêntico ao de `arestaclimb.com` (`localStorage.getItem('aresta-theme') || prefers-color-scheme`) e vincular o clique no botão `#themeToggle` no cabeçalho.
- **Alternativas consideradas**:
  - *Importar `https://arestaclimb.com/src/landing.css` remotamente*: Descartado porque no Vite do `arestaclimb.com` os arquivos CSS de build recebem hash no nome (`/assets/landing-XXXX.css`), e o CSS inline garante renderização instantânea no primeiro pacote TCP sem round-trip extra.

### 2. Arquitetura Responsiva Mobile-First (`PicoPage`) $\rightarrow$ Desktop 2 Colunas
- **Decisão**:
  - **Em telas móveis (`< 820px`)**:
    - O contêiner `.hero-midia` ocupa `width: 100%; aspect-ratio: 1 / 1; position: relative;` exibindo a `<img class="miniatura">` (`600x600`) em `1:1` sem qualquer corte.
    - Uma camada `.hero-gradiente` aplica `linear-gradient(to bottom, transparent 45%, color-mix(in srgb, var(--bg) 82%, transparent) 80%, var(--bg) 100%)` sobre a base da imagem, onde ficam posicionados a `.etiqueta` e o título `<h1>` da entidade (fiel à `PicoPage` do app).
    - Logo abaixo do hero, o corpo exibe o subtítulo resumo em tom sálvia (`var(--sage-deep)`), o card `.banner-app` (inspirado no `BannerModoOnline` do app) e a grade `.lista-cards-contexto` (inspirada nos `PicoMenuCard` do app, com ícone vetorial em caixa `44x44px` à esquerda).
  - **Em telas desktop (`@media (min-width: 820px)`)**:
    - O elemento `<main class="cartao-entidade">` assume `display: grid; grid-template-columns: 380px 1fr; max-width: 900px;` com `background: var(--surface)`, `border: 1px solid var(--line)`, `border-radius: 28px` e `box-shadow: var(--shadow)`.
    - A coluna esquerda mantém `.hero-midia` em proporção `1:1` (preenchendo a lateral com `object-fit: cover` / `aspect-ratio: 1 / 1` sem cortar a miniatura), enquanto a etiqueta e o `<h1>` passam a ser exibidos no topo da coluna direita junto ao subtítulo, cards de contexto e banner das lojas.

### 3. Hierarquia de Ações: Botões Clássicos das Lojas vs. Abrir no Aplicativo
- **Decisão**:
  - Dentro do `.banner-app`, os botões `.store-badge` da **App Store** e da **Google Play** (com os ícones `<svg>` oficiais da Apple e Google Play e textos `"Disponível na / App Store"` e `"Disponível no / Google Play"`) são a ação primária tanto no mobile quanto no desktop.
  - Abaixo dos `.store-badge`, o bloco `.acao-abrir-app-mobile` (`Já tem o Aresta instalado? <a class="link-abrir-app" href="aresta://aresta.cc/...">Abrir no aplicativo →</a>`) é exibido no mobile e ocultado no desktop via `@media (min-width: 820px) { .acao-abrir-app-mobile { display: none; } }`.
  - No `<head>`, incluir `<meta name="apple-itunes-app" content="app-id=6776467893, app-argument=${urlCanonico}">` para apresentar o banner nativo do Safari no iOS.

### 4. Funções Puras de Normalização de Metadados
- **Decisão**: Extrair funções determinísticas e exportadas em `renderizador_pagina_link.ts`:
  - `formatarModalidade(modalidade: string | null): string | null`: mapeia `boulder` $\rightarrow$ `"Boulder"`, `esportiva` $\rightarrow$ `"Esportiva"`, `tradicional` $\rightarrow$ `"Tradicional"`, `multienfiada` $\rightarrow$ `"Multienfiada"`, `highline` $\rightarrow$ `"Highline"` (e capitaliza a primeira letra para qualquer valor futuro).
  - `obterRotuloTipoEntidade(entidade: ResumoEntidadeLink): string`: retorna `"Boulder"` quando `entidade.tipo === "escalada"` e `entidade.escalada_tipo?.toLowerCase() === "boulder"`, `"Highline"` quando `"highline"`, e mantém `ROTULO_TIPO[entidade.tipo]` nos demais casos.
  - `removerPrefixoRedundante(nome: string, prefixo: "Setor" | "Grupo"): string`: remove `/^setor\s+/i` ou `/^grupo\s+/i` do início do nome (quando houver conteúdo após o prefixo), evitando `"Setor: Setor Tramontina"` e `"Grupo: Grupo Sherpa"` tanto no HTML quanto em `construirDescricaoOpenGraph`.

## Risks / Trade-offs

- **[Contraste do título sobreposto à imagem no Mobile em Light Mode]** $\rightarrow$ **Mitigação**: Na versão mobile, se o gradiente da base da imagem fundir diretamente com `--bg` claro (`#f4f1e9`), textos claros ficariam ilegíveis e textos escuros poderiam colidir com áreas escuras da foto. Para garantir legibilidade 100% determinística em Light e Dark Mode (e transicionar sem duplicação de DOM para o layout de 2 colunas no desktop), posicionar a sobreposição da base do hero no mobile como um bloco com gradiente escuro sutil ou posicionar o cabeçalho do título imediatamente na transição inferior do hero com contraste garantido pelos tokens `--text` sobre `--bg`/`--surface`.
- **[Cache de borda da Cloudflare (`s-maxage=86400`)]** $\rightarrow$ **Mitigação**: Como o HTML é cacheado por até 24h na borda, toda a alternância de tema Light/Dark e a adaptação Mobile/Desktop ocorrem no cliente via CSS (`@media` e `html[data-theme]`) e script inline, sem depender de `User-Agent` na geração do HTML cacheado.
