# Módulo HTTP e de Sincronização — Aresta Climb

Este diretório isola todas as responsabilidades que lidam com rede, comunicação remota (ou simulação dela) e sincronização de dados persistentes do aplicativo.

---

## Arquivos e Responsabilidades

| Arquivo | Descrição |
|---|---|
| `sync_service.dart` | O cérebro da sincronização. Orquestra a requisição de downloads e gere as comunicações assíncronas com a Isolate, convertendo atualizações em eventos para as barras de progresso lineares (`LinearProgressIndicator`). |
| `sync_isolate.dart` | A verdadeira força motriz por trás do processo de download atômico dos crags. Executa as validações pesadas (como o processamento criptográfico SHA256 em centenas de arquivos das Delta Syncs) em uma thread secundária (`Isolate`) para evitar que a UI "lague" durante os cálculos. |
| `sync_network.dart` | Camada puramente de rede. Abstrai a busca do `indice.binarypb` lidando com ETags (304 Not Modified), tratamento de erros, reconexão e download bruto de bytes. |
| `sync_storage.dart` | Camada de persistência em disco. Trata atualizações atômicas (usando extensões `.tmp` e renomeando arquivos depois que o download e o checksum dão certo), garantindo que dados nunca se corrompam na memória em caso de queda de luz/rede. |
| `update_downloader.dart` | Serviço focado na verificação OTA (Over The Air) do próprio aplicativo, baixando novas versões de APK e instalando no dispositivo. |

## Fluxo de Arquitetura Limpa

- Toda a inteligência da "interface de rede" agora está oculta neste pacote.
- Outras partes do sistema (como a camada de View e o `DatasetRepository`) não precisam lidar com lógica de ETag, timeouts, HTTP 304, ou validação atômica de arquivos no disco.
- Ao solicitar o download de um Pico, a classe `SyncService` usa um mix de `SyncNetwork` (para puxar dados) e `SyncStorage` (para validação criptográfica do `.tmp` e troca atômica do `.binarypb`).
