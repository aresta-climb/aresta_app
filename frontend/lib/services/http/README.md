# Módulo HTTP e de Sincronização — Aresta Climb

Este diretório isola todas as responsabilidades que lidam com rede, comunicação remota (ou simulação dela) e sincronização de dados persistentes do aplicativo.

---

## Arquivos e Responsabilidades

| Arquivo | Descrição |
|---|---|
| `servico_croqui_online.dart` | Gerencia o carregamento sob demanda de croquis com cache-busting mandatório (`?v=<sha256>`), escrita atômica em disco em `/temp_cache/<picoId>/compilado.binarypb.<sha256>`, expurgo de versões anteriores divergentes e polling de ETag para atualizações em tempo real. Implementa dormência automática de polling HTTP quando o canal WebSocket de Live Reload está ativo, prevenindo consumo excessivo de cotas. |
| `sync_service.dart` | O cérebro da sincronização em duas fases. Em `syncIndex()`, aguarda na Fase 1 apenas a validação condicional de `indice.binarypb` e a sincronização delta de `catalogo.db`, retornando imediatamente (com *cooldown* de 30s para chamadas automáticas) e disparando na Fase 2 (`tarefaMidiasEmSegundoPlano`) a sincronização de *thumbnails*, atualização de picos na `Isolate`, renomeação atômica de `.tmp` antes de publicar `activeDataset` e recarga reativa de croquis abertos em sessão online cujo SHA-256 mudou. Implementa coalescência de requisições concorrentes (*in-flight request sharing*) via `_activeSyncFuture`. |
| `sync_isolate.dart` | A verdadeira força motriz por trás do processo de download atômico dos crags. Executa as validações pesadas (como o processamento criptográfico SHA256 em centenas de arquivos das Delta Syncs) em uma thread secundária (`Isolate`) para evitar que a UI "lague" durante os cálculos. Persiste os croquis baixados padronizados como `compilado.binarypb` e remove arquivos legados `<picoId>.binarypb`. |
| `sync_rede.dart` | Camada puramente de rede. Abstrai a busca do `indice.binarypb` lidando com ETags (304 Not Modified), tratamento de erros, reconexão e download bruto de bytes. |
| `sync_armazenamento.dart` | Camada de persistência em disco. Trata atualizações atômicas (usando extensões `.tmp` e renomeando arquivos depois que o download e o checksum dão certo), garantindo que dados nunca se corrompam na memória em caso de queda de luz/rede. Suporta lazy migration de `<picoId>.binarypb` para `compilado.binarypb`. |
| `baixador_atualizacoes.dart` | Serviço focado na verificação OTA (Over The Air) do próprio aplicativo, baixando novas versões de APK e instalando no dispositivo. |

## Fluxo de Arquitetura Limpa e Hierarquia de Resolução

- Toda a inteligência da "interface de rede" está encapsulada neste pacote.
- Outras partes do sistema (como a camada de View e o `DatasetRepository`) não precisam lidar com lógica de ETag, timeouts, HTTP 304, ou validação atômica de arquivos no disco.
- Ao solicitar o download de um Pico, a classe `SyncService` usa um mix de `SyncNetwork` (para puxar dados) e `SyncStorage` (para validação criptográfica do `.tmp` e troca atômica para `compilado.binarypb`).

### Hierarquia Estrita de Resolução de Croquis
Para eliminar divergências entre os modos online e offline e evitar cálculos redundantes de hash em tempo de execução:
1. **Memória RAM**: Checa se a instância `Croqui` já está carregada no `GerenciadorSessaoOnline`.
2. **Armazenamento Permanente (`downloads`)**: Verifica a existência de `compilado.binarypb` (com suporte a lazy rename de `<picoId>.binarypb` legado).
3. **Cache Temporário Volátil (`temp_cache`)**: Procura por `compilado.binarypb.<sha256>` indexado pelo hash esperado do índice.
4. **Rede (CDN)**: Sincroniza previamente o índice rápido via `SyncService.instance?.syncIndex()` (garantindo que o `caminhoRelativo` e o hash esperado estejam atualizados antes do download remoto) e baixa o binário via `ServicoCroquiOnline` com parâmetro de cache-busting mandatório (`?v=<sha256>`), salvando-o no `temp_cache` e expurgando versões divergentes de execuções anteriores.
