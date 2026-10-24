# worker-app-links Specification

## Purpose
Definir o contrato OpenAPI (`openapi/app_links.yaml`) e o comportamento de borda do Cloudflare Worker `cloudflare/app-links` (`https://aresta.cc`) para verificação nativa de App Links / Universal Links, resolução de UIDs no banco Cloudflare D1 (`aresta-catalogo`), renderização de página HTML SSR com metadados OpenGraph (para preview no WhatsApp e redes sociais), links para download do aplicativo e telemetria Umami com suporte a prefixos compactos (`/s/`, `/q/`, `/m/`, `/sm/`, `/ms/`, `/qm/`, `/mq/`) e parâmetros UTM.

## Requirements

### Requirement: Especificação OpenAPI do Serviço de App Links (`aresta.cc`)
O repositório `aresta_api` DEVE (MUST) manter o contrato OpenAPI 3.1 em `openapi/app_links.yaml` descrevendo os endpoints servidos por `https://aresta.cc` (`/health`, `/.well-known/assetlinks.json`, `/.well-known/apple-app-site-association`, `/{uid}` e `/{prefixo}/{uid}`) e seus schemas estruturais, gerando automaticamente as constantes de rota e tipos para TypeScript, Python e Dart via `python build.py`.

#### Scenario: Geração dos stubs de `app_links.yaml` em `aresta_api`
- **WHEN** `python build.py` é executado no `aresta_api`
- **THEN** o gerador valida `openapi/app_links.yaml` contra o schema OpenAPI 3.1 e emite os artefatos `openapi/generated/ts/app_links.ts`, `openapi/generated/python/app_links.py` e `openapi/generated/dart/app_links.dart` com todas as constantes de rota e tipos do contrato.

### Requirement: Verificação de Domínio para Android App Links e iOS Universal Links
O Worker `cloudflare/app-links` DEVE (MUST) responder com `200 OK` e `Content-Type: application/json; charset=utf-8` aos endpoints `GET /.well-known/assetlinks.json` (declarando `delegate_permission/common.handle_all_urls` para `app.escalada.croquis` e suas impressões digitais SHA-256) e `GET /.well-known/apple-app-site-association` (declarando `applinks` para `Z74K7R3WU7.app.escalada.croquis` cobrindo `/*`).

#### Scenario: Verificação automática pelo sistema operacional Android
- **WHEN** o Android requisita `GET https://aresta.cc/.well-known/assetlinks.json`
- **THEN** o Worker responde `200 OK` com JSON válido contendo `package_name: "app.escalada.croquis"` e os fingerprints SHA-256 de produção/debug, além de `Cache-Control: public, max-age=86400, s-maxage=86400`.

#### Scenario: Verificação automática pelo sistema operacional iOS
- **WHEN** o iOS requisita `GET https://aresta.cc/.well-known/apple-app-site-association`
- **THEN** o Worker responde `200 OK` com JSON válido contendo `appIDs: ["Z74K7R3WU7.app.escalada.croquis"]` e `paths: ["/*"]`, além de `Cache-Control: public, max-age=86400, s-maxage=86400`.

### Requirement: Redirecionamento da Raiz, de `www.aresta.cc` e Healthcheck Operacional
O Worker `cloudflare/app-links` DEVE (MUST) redirecionar requisições em `www.aresta.cc` com status `301 Moved Permanently` para `https://aresta.cc` preservando caminho e query string, redirecionar acessos à raiz `GET /` com status `302 Found` para `https://arestaclimb.com` e responder `200 OK` em `GET /health` indicando disponibilidade operacional.

#### Scenario: Acesso direto à raiz `https://aresta.cc/`
- **WHEN** um navegador requisita `GET https://aresta.cc/`
- **THEN** o Worker responde com status `302` e cabeçalho `Location: https://arestaclimb.com`.

#### Scenario: Acesso via subdomínio `www.aresta.cc`
- **WHEN** um navegador requisita `GET https://www.aresta.cc/s/hv7YWgTBQGyWOX`
- **THEN** o Worker responde com status `301` e cabeçalho `Location: https://aresta.cc/s/hv7YWgTBQGyWOX`.

#### Scenario: Consulta ao endpoint de saúde `GET /health`
- **WHEN** um monitor requisita `GET https://aresta.cc/health`
- **THEN** o Worker responde `200 OK` em texto plano informando que o serviço de App Links está operacional.

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

### Requirement: Telemetria Umami Client-Side com Extração de Prefixos e Parâmetros UTM
A página HTML renderizada pelo Worker DEVE (MUST) incluir o script do Umami (`https://analytics.arestaclimb.com/script.js`, `data-website-id="3ba79f5e-e49f-42d4-9283-586976189124"`) e despachar no navegador o evento `app-link-acesso` com `uid`, `tipo`, `abrir_mapa`, `utm_source` e `utm_medium` (priorizando query params explícitos e usando como fallback os valores derivados de `/s/`, `/sm/`, `/ms/` para `compartilhamento`/`social` e `/q/`, `/qm/`, `/mq/` para `placa_rocha`/`qrcode`).

#### Scenario: Acesso no navegador via link de compartilhamento `/s/<uid>`
- **WHEN** um usuário abre `https://aresta.cc/s/hv7YWgTBQGyWOX` no navegador
- **THEN** o script da página registra o acesso no Umami com `uid: "hv7YWgTBQGyWOX"`, `utm_source: "compartilhamento"` e `utm_medium: "social"` (mesmo que o HTML tenha sido servido pelo cache da CDN da Cloudflare).

#### Scenario: Acesso no navegador com parâmetros `utm_source` e `utm_medium` explícitos
- **WHEN** um usuário abre `https://aresta.cc/q/hv7YWgTBQGyWOX?utm_source=setor_igarameca&utm_medium=qrcode_placa` no navegador
- **THEN** o script da página registra o evento no Umami preservando `utm_source: "setor_igarameca"` e `utm_medium: "qrcode_placa"`.

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
