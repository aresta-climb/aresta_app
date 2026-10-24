# Proposal

## Why

Atualmente, a página SSR de compartilhamento e fallback de links curtos servida pelo Worker `aresta-app-links` (`https://aresta.cc`) utiliza um layout genérico em cores azul-ardósia (`#0f172a`) e âmbar (`#f59e0b`) desconectado da identidade visual do ecossistema Aresta Climb. Além disso, a miniatura quadrada (`600x600`) do croqui sofre corte vertical severo por estar forçada em um contêiner retangular (`460x220`) com `object-fit: cover`, a modalidade é exibida em letras minúsculas (`boulder`), a etiqueta superior exibe `"VIA DE ESCALADA"` mesmo para boulders, nomes de setores e grupos com prefixo próprio geram repetição (`"Setor: Setor Tramontina"`), os botões das lojas não possuem os selos clássicos com logotipos oficiais e o botão `"Abrir no App Aresta"` aparece com destaque excessivo até mesmo no desktop (onde o protocolo `aresta://` não funciona).

## What Changes

- **Integração Visual com `arestaclimb.com` (Light Mode e Dark Mode)**:
  - Adotar o Design System unificado do `arestaclimb.com` (paleta mineral Arenito, Terracota, Sálvia e Obsidian) nas páginas de entidade (`200 OK`) e de não encontrado (`404 Not Found`) do `aresta.cc`.
  - Suportar alternância entre tema claro (`light`) e escuro (`dark`), respeitando `prefers-color-scheme: dark` e persistência em `localStorage('aresta-theme')`, com botão de alternância (`#themeToggle`) no cabeçalho.
  - Adicionar cabeçalho institucional com a logo oficial do Aresta Climb (`https://arestaclimb.com/assets/logo_app.png`), nome da marca e link para `https://arestaclimb.com`, além de rodapé institucional integrado ao site principal.
- **Layout Responsivo Mobile-First (Estilo App no Celular e Card de 2 Colunas no Desktop)**:
  - **No Mobile (Mobile-First)**: Exibir a miniatura do croqui (`600x600`, proporção `1:1`) tomando toda a largura da tela sem cortes, com gradiente suave na base fundindo com o fundo da página e título/etiqueta sobrepostos na base da imagem (inspirado diretamente na `PicoPage` do aplicativo móvel), seguidos pelo subtítulo em verde-musgo (`--sage`), banner de download estilo `BannerModoOnline` e cards de contexto estilo `PicoMenuCard`.
  - **No Desktop (`@media (min-width: 820px)`)**: Transformar a apresentação em um Card de 2 Colunas com a miniatura `1:1` integralmente visível à esquerda (sem cortes) e as informações, cards de contexto e ações de download à direita.
- **Botões Clássicos das Lojas com Logotipo e Abertura Nativa Discreta no Mobile**:
  - Substituir os links simples de texto pelos botões clássicos `.store-badge` (idênticos ao `arestaclimb.com`) com os ícones SVG oficiais da **Apple App Store** e da **Google Play** e tipografia em duas linhas (`Disponível na / App Store` e `Disponível no / Google Play`).
  - Substituir o botão primário gigante `"Abrir no App Aresta"` por um link complementar discreto (`"Já tem o Aresta instalado? Abrir no aplicativo →"` apontando para `aresta://aresta.cc/...`) exibido **exclusivamente em dispositivos móveis** (oculto no desktop) e adicionar a meta tag `<meta name="apple-itunes-app" content="app-id=6776467893, app-argument=...">` para ativar o Smart App Banner nativo no Safari/iOS.
- **Normalização e Polimento dos Dados Exibidos (HTML e OpenGraph)**:
  - Formatar a modalidade (`escalada_tipo`) sempre com inicial maiúscula (`Boulder`, `Esportiva`, `Tradicional`, `Multienfiada`, `Highline`) tanto na página HTML quanto na descrição OpenGraph (`og:description`).
  - Ajustar a etiqueta superior da entidade para exibir **`Boulder`** quando `tipo === "escalada"` e `escalada_tipo === "boulder"` (e **`Highline`** quando `escalada_tipo === "highline"`), mantendo **`Via de Escalada`** para as demais modalidades de via.
  - Remover prefixos redundantes `"Setor "` e `"Grupo "` (case-insensitive) ao exibir os campos `Setor:` e `Grupo:` (ex.: `"Setor Tramontina"` passa a ser exibido como **`Setor: Tramontina`**, e `"Grupo Sherpa"` como **`Grupo: Sherpa`**) tanto no HTML quanto nas meta tags OpenGraph.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capability isolada; os requisitos pertencem a worker-app-links -->

### Modified Capabilities
- `worker-app-links`: Atualiza os requisitos de renderização HTML SSR e OpenGraph do Worker `cloudflare/app-links` (`aresta.cc`) para contemplar o Design System Light/Dark integrado ao `arestaclimb.com`, layout Mobile-First estilo aplicativo com Card de 2 Colunas no desktop e imagem `1:1` sem cortes, selos clássicos da App Store e Google Play com logos SVG, ação `"Abrir no aplicativo"` restrita ao mobile + Smart App Banner iOS, capitalização da modalidade, etiqueta específica para `Boulder`/`Highline` e desduplicação dos prefixos `"Setor"` e `"Grupo"`.

## Impact

- **`../aresta_backend/cloudflare/app-links/src/renderizador_pagina_link.ts`**: Refatoração do template HTML/CSS SSR (`renderizarPaginaEntidade` e `renderizarPaginaNaoEncontrada`) e adição das funções puras de formatação de modalidade, etiqueta de tipo e limpeza de prefixos redundantes de setor/grupo.
- **`../aresta_backend/cloudflare/app-links/test/renderizador_pagina_link_test.ts`** e **`worker_test.ts`**: Atualização e ampliação dos testes orientados a comportamento validando 100% de cobertura das novas regras de UI e formatação de metadados.
- **`../aresta_backend/cloudflare/app-links/README.md`**: Atualização da documentação do Worker refletindo o novo design e comportamento responsivo.
