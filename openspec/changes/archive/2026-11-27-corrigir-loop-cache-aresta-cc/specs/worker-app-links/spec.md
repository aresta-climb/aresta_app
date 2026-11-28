# Spec Delta

## MODIFIED Requirements

### Requirement: Redirecionamento da Raiz, de `www.aresta.cc` e Healthcheck Operacional
O Worker `cloudflare/app-links` DEVE (MUST) redirecionar requisições em `aresta.cc/` e `www.aresta.cc/` com status `301 Moved Permanently` diretamente para `https://arestaclimb.com/croquis` preservando eventual query string, resolver links curtos `www.aresta.cc/[<prefixo>/]<uid>` diretamente em um único salto `301` para `https://arestaclimb.com/croquis/<uid>/<slug>`, redirecionar acessos a `/croquis*` fora do domínio canônico `arestaclimb.com` (`www.arestaclimb.com`, `aresta.cc`, `www.aresta.cc`) com `Cache-Control: private, max-age=86400` para evitar colisão no cache compartilhado do Worker e responder `200 OK` em `GET /health` indicando disponibilidade operacional.

#### Scenario: Acesso direto à raiz `https://aresta.cc/`
- **WHEN** um navegador requisita `GET https://aresta.cc/` ou `GET https://www.aresta.cc/?utm_source=bio`
- **THEN** o Worker responde com status `301` (`Cache-Control: public, max-age=86400, s-maxage=31536000`) e cabeçalho `Location: https://arestaclimb.com/croquis` (preservando eventual query string, ex.: `https://arestaclimb.com/croquis?utm_source=bio`).

#### Scenario: Acesso via subdomínio `www.aresta.cc`
- **WHEN** um navegador requisita `GET https://www.aresta.cc/s/hv7YWgTBQGyWOX` para uma entidade existente no D1
- **THEN** o Worker resolve a entidade e responde em um único salto com status `301` redirecionando diretamente para `https://arestaclimb.com/croquis/hv7YWgTBQGyWOX/<slug>?utm_source=compartilhamento&utm_medium=social` (sem redirecionamento intermediário para `aresta.cc`).

#### Scenario: Consulta ao endpoint de saúde `GET /health`
- **WHEN** um monitor requisita `GET https://aresta.cc/health`
- **THEN** o Worker responde `200 OK` em texto plano informando que o serviço de App Links está operacional.

#### Scenario: Isolamento de cache em acesso por domínio não-canônico em `/croquis`
- **WHEN** um navegador ou crawler requisita `GET https://www.arestaclimb.com/croquis?uf=MG` ou `GET https://aresta.cc/croquis`
- **THEN** o Worker responde `301 Moved Permanently` para `https://arestaclimb.com/croquis` (preservando query string) com `Cache-Control: private, max-age=86400`, impedindo que o Workers Caching armazene redirecionamentos de mesmo caminho na chave de cache compartilhada.
