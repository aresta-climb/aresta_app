# Módulo HTTP e de Sincronização — Aresta Climb

Este diretório isola todas as responsabilidades que lidam com rede, comunicação remota (ou simulação dela) e sincronização de dados persistentes do aplicativo.

---

## Arquivos e Responsabilidades

| Arquivo | Descrição |
|---|---|
| `sync_service.dart` | O cérebro da sincronização. Gerencia a sincronização em segundo plano do índice, verifica checksums SHA-256 e coordena o download inteligente de imagens recém modificadas sem travar a interface (comunicação reativa). |
| `sync_network.dart` | Camada puramente de rede. Abstrai a busca do `indice.binarypb` lidando com ETags (304 Not Modified), tratamento de erros, reconexão e download bruto de bytes. |
| `sync_storage.dart` | Camada de persistência em disco. Trata atualizações atômicas (usando extensões `.tmp` e renomeando arquivos depois que o download e o checksum dão certo), garantindo que dados nunca se corrompam na memória em caso de queda de luz/rede. |
| `zip_interceptor_client.dart` | Interceptor HTTP crucial para o "Ghost Protocol". Intercepta todas as requisições `aresta-zip://` e lê arquivos do interior de um `.croqui` local criptografado (XOR) como se fosse uma resposta HTTP normal vinda da internet. |
| `update_downloader.dart` | Serviço focado na verificação OTA (Over The Air) do próprio aplicativo, baixando novas versões de APK e instalando no dispositivo. |

## Fluxo de Arquitetura Limpa

- Toda a inteligência da "interface de rede" agora está oculta neste pacote.
- Outras partes do sistema (como a camada de View e o `DatasetRepository`) não precisam lidar com lógica de ETag, timeouts, HTTP 304, ou validação atômica de arquivos no disco.
- Ao solicitar o download de um Pico, a classe `SyncService` usa um mix de `SyncNetwork` (para puxar dados) e `SyncStorage` (para validação criptográfica do `.tmp` e troca atômica do `.binarypb`).
