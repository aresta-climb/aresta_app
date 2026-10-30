# Tasks

## 1. SHA-256 em Memória, Escrita Atômica `.tmp` e Fallback Offline em `ServicoCroquiOnline`

- [x] 1.1 Escrever testes de comportamento em `frontend/test/services/http/servico_croqui_online_test.dart` cobrindo: (a) cálculo do SHA-256 real em memória a partir de `response.bodyBytes` e gravação atômica via `.tmp` para `compilado.binarypb.<sha256_real>` mesmo quando a URL requisitada continha `?v=<hash_antigo>`, (b) expurgo de versões antigas apenas após o rename atômico e (c) fallback de emergência carregando um `compilado.binarypb.<hash_antigo>` existente em `temp_cache` quando a requisição HTTP falhar por ausência de conexão (verificando falha inicial *Red*).
- [x] 1.2 Implementar em `frontend/lib/services/http/servico_croqui_online.dart` o cálculo de `sha256.convert(bytes)` em memória na chegada do HTTP (com comentário arquitetural explícito sobre *LRU eviction* da Cloudflare CDN e sobrescrita no R2), a gravação atômica via `.tmp` antes do expurgo e o fallback de emergência para versões anteriores no `temp_cache` em falhas de rede, validando com `flutter test test/services/http/servico_croqui_online_test.dart --coverage` (100% de cobertura).

## 2. Download Otimista em 1 RTT e Hot-Reload sem Piscada em `DatasetRepository`

- [x] 2.1 Escrever/atualizar testes de comportamento em `frontend/test/services/repositorio_dataset_test.dart` cobrindo: (a) download imediato de `compilado.binarypb` na etapa 4 de `getCroqui` em 1 RTT sem aguardar `syncIndex()` quando `caminhoRelativo` já consta no índice local, disparando `syncIndex()` silenciosamente em background, (b) fallback aguardando `syncIndex()` quando o pico ainda não existe no índice local, e (c) preservação da instância `existente.croqui` em memória durante `loadIndiceToMemory` (Fase 1) mesmo quando o checksum mudar no novo índice até o commit atômico da Fase 2 (verificando falha inicial *Red*).
- [x] 2.2 Implementar em `frontend/lib/services/repositorio_dataset.dart` o fluxo otimista na etapa 4 de `getCroqui` (com `unawaited(syncAtivo.syncIndex())` em background) e a preservação de `existente.croqui` em `loadIndiceToMemory`, validando com `flutter test test/services/repositorio_dataset_test.dart --coverage` e os testes de integração de `sync_service_test.dart` e `localizador_destino_uid_test.dart` (100% de cobertura nos arquivos alterados).

## 3. Upload Estagiado em 3 Fases no Deploy (`../aresta_db/serving/update_serving.py`)

- [x] 3.1 Escrever testes em `../aresta_db/serving/update_serving_test.py` validando que o deploy envia os arquivos em 3 estágios sequenciais (1º mídias/imagens, 2º `compilado.binarypb`, 3º manifestos `indice.binarypb`, `indice.yaml`, `catalogo.db` e `arquivos_serving.yaml` seguidos do purge), verificando falha inicial *Red*.
- [x] 3.2 Implementar o upload estagiado em 3 fases em `../aresta_db/serving/update_serving.py` e validar que toda a suíte de testes de `update_serving_test.py` passa com 100% de cobertura.
