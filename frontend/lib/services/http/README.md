# Módulo HTTP e Sincronização (`lib/services/http/`)

Este diretório reúne o cliente HTTP compartilhado e as classes de sincronização e download de croquis, catálogo e atualizações.

---

## Arquivos

| Arquivo | Responsabilidade |
|---|---|
| `cliente_http_aresta.dart` | Cliente HTTP único do código de produção (`ClienteHttpAresta.instancia`, e `ClienteHttpAresta.paraTestes` em testes) com pool TCP/TLS Keep-Alive de 120s. `isolamento_cliente_http_test.dart` bloqueia uso direto de `package:http` fora deste arquivo. |
| `servico_croqui_online.dart` | Baixa croquis sob demanda com `?v=<sha256>`, valida o SHA-256 em memória, grava via `.tmp` em `/temp_cache/<picoId>/compilado.binarypb.<sha256>`, remove versões anteriores e executa polling de ETag (pausado quando o WebSocket de Live Reload está conectado). |
| `sync_service.dart` | Coordena a sincronização em duas fases: Fase 1 valida `indice.binarypb` e sincroniza `catalogo.db` (com intervalo mínimo de 30s em chamadas automáticas e compartilhamento de `Future` concorrente); Fase 2 baixa miniaturas, atualiza picos salvos via `Isolate`, efetiva arquivos `.tmp` e recarrega croquis online alterados. |
| `sync_isolate.dart` | Executa downloads em lote e verificação SHA-256 em `Isolate` separado, reaproveitando mídias já presentes em `temp_cache` e gravando o croqui como `compilado.binarypb`. |
| `sync_rede.dart` | Realiza chamadas HTTP de sincronização de índice, consultas incrementais do catálogo e validação de ETag (`304 Not Modified`). |
| `sync_armazenamento.dart` | Gerencia gravação temporária (`.tmp`), verificação de hash e renomeação para o caminho final em disco. |
| `servico_download_segundo_plano.dart` | Executa downloads de croquis acoplados ao serviço de notificações nativas. |
| `baixador_atualizacoes.dart` | Verifica e baixa atualizações de APK (OTA). |

---

## Ordem de Resolução de Croquis

1. **RAM**: Instância já carregada em `GerenciadorSessaoOnline` ou `activeDataset`.
2. **Downloads (`downloads/`)**: Arquivo local `compilado.binarypb`.
3. **Cache Temporário (`temp_cache/`)**: Arquivo `compilado.binarypb.<sha256>` correspondente ao hash do índice.
4. **Rede (CDN)**: Download via `ServicoCroquiOnline` com `?v=<sha256>`, gravação em `temp_cache/` e limpeza de hashes anteriores.
