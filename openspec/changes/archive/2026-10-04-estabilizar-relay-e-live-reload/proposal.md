# Proposta: Estabilização do Relay e Live Reload

## Por que

Recentemente, o serviço de retransmissão de prévia na nuvem (`aresta-previa-relay` com Cloudflare Durable Objects) esgotou a cota máxima de 90.000 requisições diárias em poucas horas, e o banner de modo experimental passou a pulsar continuamente.

O design do relay foi concebido para consumir apenas 1 ou 2 requisições HTTP na conexão inicial e, a partir de então, manter uma conexão WebSocket durável e persistente (custo zero em requisições de Durable Object), recebendo eventos de recarga em tempo real (*push*). Contudo, a ausência de suporte a ETag/HTTP 304 no túnel Python desktop aliada ao vazamento de timers de polling em instâncias órfãs de `PicoViewModel` geradas repetidamente pelo `PageListenableBuilder` (intensificadas pela cadeia de re-sincronizações do commit `81920a6`) deflagrou um ciclo vicioso de requisições contínuas, sobrecarregando o relay e impedindo o funcionamento estável da prévia.

## O Que Mudará

- **Suporte a ETag e HTTP 304 no Túnel Retransmissor Desktop (`aresta_db`)**: Implementar cálculo de hash SHA-256 e validação do cabeçalho `If-None-Match` no método `_ler_arquivo_proxy` em `tunel_retransmissor.py`, devolvendo status HTTP 304 sem payload quando o arquivo em disco não for modificado.
- **Dormência do Polling durante WebSocket Conectado (`aresta_app`)**: Suspender e silenciar o timer periódico de polling HTTP de 30 segundos enquanto a conexão WebSocket de Live Reload estiver ativa e saudável, eliminando requisições redundantes de Durable Object.
- **Eliminação de Vazamento de Timers e Correção do Ciclo de Vida do `PicoViewModel`**:
  - Reutilizar a instância de `ServicoCroquiOnline` do `DatasetRepository` ou assegurar o cancelamento determinístico de timers prévios para o mesmo `picoId`.
  - Implementar `didUpdateWidget` e descarte correto do `PicoViewModel` em `PicoDetailsPage` para evitar acúmulo de timers zumbis em segundo plano.
- **Coalescência e Debounce de Sincronizações de Modo**: Evitar disparos concorrentes ou em cascata de `syncIndex()` ao alternar modos ou conectar ao editor experimental.

## Capacidades

### Novas Capacidades
*(Nenhuma nova capacidade necessária, a mudança aprimora capacidades existentes de transmissão e hot reload).*

### Capacidades Modificadas
- `transmissao-croqui-online`: O requisito de Polling Periódico com ETag passa a exigir dormência obrigatória enquanto o WebSocket de Live Reload estiver conectado, além de gerenciamento estrito de ciclo de vida para impedir a multiplicação de timers ao reconstruir telas.
- `hot-reload-experiencia-usuario`: O requisito de sincronização e recebimento de eventos passa a exigir coalescência e debounce na alternância de modos e no recebimento de eventos de Live Reload para impedir rajadas de requisições de sincronização.

## Impacto

- **Frontend Flutter (`aresta_app`)**:
  - `frontend/lib/services/http/servico_croqui_online.dart`: Adição de verificação de WebSocket ativo antes de engatilhar requisição HTTP e guarda global de timers.
  - `frontend/lib/view/view_models/pico_view_model.dart`: Reuso de serviço de polling gerenciado e cancelamento adequado de timers.
  - `frontend/lib/pages/pico.dart`: Implementação de `didUpdateWidget` e descarte de recursos do `PicoViewModel`.
  - `frontend/lib/main.dart` e `frontend/lib/services/inicializacao_app.dart`: Debounce e coalescência nas mudanças de modo e eventos push.
- **Editor Desktop Python (`aresta_db`)**:
  - `editor/core/tunel_retransmissor.py`: Leitura de cabeçalho `If-None-Match`, geração de cabeçalho `ETag` (SHA-256) e resposta com status 304 Not Modified.
- **Infraestrutura / Cloudflare Relay**:
  - Drástica redução de requisições na sessão do Durable Object, restaurando o consumo unitário de 1 a 2 requisições por sessão.
