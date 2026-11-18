# Spec Delta

## Purpose

Expor uma vitrine pública, rápida e indexável em `https://arestaclimb.com/croquis` alimentada pelo banco Cloudflare D1 (`aresta-catalogo`) e protegida por cache agressivo na borda da CDN, oferecendo Mapão nacional de picos, busca textual client-side, `sitemap.xml` e páginas SSR de teaser hierárquicas que convertem buscas no Google e planejamentos no computador diretamente para o aplicativo móvel Aresta Climb.

## ADDED Requirements

### Requirement: Página Índice da Vitrine (`/croquis`) com Mapão Nacional e Diretório por Estado
O serviço DEVE (MUST) responder em `GET https://arestaclimb.com/croquis` (e redirecionar `/croquis/` com `301` para `/croquis`) com uma página HTML SSR (`200 OK`, cacheável na CDN por 7 dias) exibindo o campo de busca rápida, o Mapão interativo leve com os picos que possuem `latitude_e7` e `longitude_e7` (sem uso de chaves pagas do Google Maps JS API) e o diretório de croquis agrupado por unidade federativa com links canônicos `/croquis/<croqui_uid>/<slug>`.

#### Scenario: Renderização do diretório de croquis e dados dos pinos do Mapão
- **WHEN** um visitante ou robô de busca requisita `GET https://arestaclimb.com/croquis`
- **THEN** o serviço retorna `200 OK` com HTML contendo os croquis agrupados por estado (com nome, cidade, miniatura e contagens de setores e escaladas), os dados geográficos (`latitude_e7 / 1e7` e `longitude_e7 / 1e7`) para plotagem dos pinos no mapa client-side com tiles gratuitos e links clicáveis para cada croqui.

#### Scenario: Normalização de barra final em `/croquis/`
- **WHEN** um navegador requisita `GET https://arestaclimb.com/croquis/?utm_source=menu`
- **THEN** o serviço responde `301 Moved Permanently` redirecionando para `https://arestaclimb.com/croquis?utm_source=menu`.

### Requirement: Índice JSON Compacto para Busca Client-Side Sob Demanda (`/croquis/busca.json`)
O serviço DEVE (MUST) expor em `GET https://arestaclimb.com/croquis/busca.json` um payload JSON compacto (`200 OK`, `Cache-Control: public, max-age=14400, s-maxage=604800, stale-while-revalidate=86400`) contendo os croquis, grupos, setores e escaladas do catálogo para filtragem instantânea no navegador ao focar o campo de pesquisa em `/croquis`, sem disparar requisições ao Worker a cada tecla digitada.

#### Scenario: Consulta ao JSON compacto de busca
- **WHEN** a página `/croquis` carrega `GET https://arestaclimb.com/croquis/busca.json` após interação do usuário na barra de pesquisa
- **THEN** o endpoint retorna `200 OK` com lista compacta contendo `uid`, `tipo`, `nome`, `grau`, `modalidade`, `croqui_nome`, `localizacao` e `slug` canônico de cada entidade pesquisável.

### Requirement: Sitemap XML Dinâmico do Catálogo (`/croquis/sitemap.xml`)
O serviço DEVE (MUST) servir em `GET https://arestaclimb.com/croquis/sitemap.xml` um documento XML válido (`application/xml; charset=utf-8`, cacheado na borda por 7 dias) listando `https://arestaclimb.com/croquis` e a URL canônica `https://arestaclimb.com/croquis/<uid>/<slug>` de todos os croquis, grupos, setores e escaladas presentes no D1.

#### Scenario: Rastreamento pelo Googlebot via `/croquis/sitemap.xml`
- **WHEN** um motor de busca requisita `GET https://arestaclimb.com/croquis/sitemap.xml`
- **THEN** o serviço retorna `200 OK` com `<urlset>` contendo `https://arestaclimb.com/croquis` e todas as entidades públicas (`croqui`, `grupo`, `setor` e `escalada`) em suas URLs canônicas sem parâmetros de query.

### Requirement: URLs Canônicas com UID Primeiro (`/croquis/<uid>/<slug>`) e Redirecionamento de Slugs
O serviço DEVE (MUST) resolver qualquer entidade pública (`croqui`, `grupo`, `setor` ou `escalada`) em `/croquis/<uid>/<slug>` exclusivamente pelos 14 caracteres de `<uid>`. Caso a requisição omita `<slug>` (`/croquis/<uid>`) ou informe um `<slug>` divergente do slug canônico atual derivado do banco D1, o serviço DEVE responder `301 Moved Permanently` para `/croquis/<uid>/<slug-canonico>` preservando integralmente a query string.

#### Scenario: Acesso com slug omitido ou antigo após renomeação de via
- **WHEN** um visitante requisita `GET https://arestaclimb.com/croquis/x8siJek3FiG3aB/nome-antigo?utm_source=blog` para uma entidade cujo slug canônico atual é `mg-pedra-rachada-feijao-com-linguica`
- **THEN** o serviço responde `301 Moved Permanently` com `Location: https://arestaclimb.com/croquis/x8siJek3FiG3aB/mg-pedra-rachada-feijao-com-linguica?utm_source=blog`.

#### Scenario: Acesso a UID inexistente em `/croquis/<uid>/<slug>`
- **WHEN** um visitante requisita `GET https://arestaclimb.com/croquis/UidInexistente/qualquer-slug`
- **THEN** o serviço responde `404 Not Found` com página HTML no Design System do Aresta Climb e atalho para explorar `/croquis`.

### Requirement: Teaser Hierárquico com Breadcrumbs, Filhos Clicáveis, Google Maps e Proteção do Acervo
A página `GET /croquis/<uid>/<slug>` DEVE (MUST) incluir `<link rel="canonical">` sem query string, JSON-LD `BreadcrumbList`, trilha de navegação clicável (`Croquis › Pico › Grupo › Setor`), botão externo para o Google Maps (quando o croqui possuir `url_google_maps` ou coordenadas `latitude_e7`/`longitude_e7`) e lista clicável das subentidades filhas (grupos/setores do pico ou escaladas do setor com grau e modalidade), omitindo fotos de paredes traçadas e textos de betas para direcionar a conversão ao aplicativo móvel.

#### Scenario: Visualização de teaser de um Setor no computador ou celular sem o app
- **WHEN** um usuário acessa `GET https://arestaclimb.com/croquis/<setor_uid>/<slug>`
- **THEN** a página exibe o breadcrumb clicável até o croqui pai, o botão de localização no Google Maps do pico (se disponível), a lista clicável das escaladas daquele setor com suas graduações e modalidades, os selos da App Store e Google Play e, no mobile, o link `aresta://arestaclimb.com/croquis/<setor_uid>/<slug>` repassando os parâmetros CGI da barra de endereços via JavaScript.
