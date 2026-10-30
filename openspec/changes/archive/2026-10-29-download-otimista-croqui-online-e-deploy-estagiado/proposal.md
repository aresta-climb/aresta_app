# Proposal

## Why

Atualmente, sempre que um usuário abre um croqui em modo online que não está salvo em `/downloads` nem no cache volátil (`/temp_cache`), a etapa 4 de `DatasetRepository.getCroqui` obriga a execução bloqueante de `await syncIndex()` (`GET /indice.binarypb` + sincronização delta de `catalogo.db`) **antes** de iniciar o download do `compilado.binarypb`. Em regiões de escalada com conectividade móvel degradada (3G/Edge com alta latência), exigir dois *round-trips* sequenciais dobra o tempo de espera no caminho crítico para acessar os dados básicos de um croqui.

Além disso, como o cache da Cloudflare CDN (mesmo com *Smart Tiered Cache* e TTL de 1 ano) está sujeito a despejo por inatividade (*LRU eviction*) enquanto o bucket R2 sobrescreve os caminhos dos arquivos a cada deploy, uma requisição com `?v=<hash_antigo>` que sofra *cache miss* na CDN recebe do R2 o binário mais recente (`<hash_novo>`), exigindo que o aplicativo identifique o hash real recebido em memória e que o pipeline de deploy (`update_serving.py` no `aresta_db`) publique os arquivos na ordem correta (mídias ➔ croquis ➔ manifestos) para eliminar qualquer condição de corrida ou *cache poisoning* na CDN.

## What Changes

- **Download Otimista em 1 RTT na Abertura Online (`DatasetRepository.getCroqui`)**: Quando o `caminhoRelativo` do pico já é conhecido no índice local em memória, a etapa 4 baixa o `compilado.binarypb?v=<checksum_local>` imediatamente sem aguardar `syncIndex()`, e dispara `syncIndex()` de forma silenciosa e não-bloqueante em segundo plano (`unawaited`) para verificar atualizações e acionar *hot-reload* reativo caso haja nova versão. O `await syncIndex()` bloqueante fica restrito ao fallback em que o `id` ainda não existe no índice local.
- **Cálculo de SHA-256 em Memória na Chegada do HTTP (`ServicoCroquiOnline.carregarCroquiRemoto`)**: Ao receber `response.bodyBytes` (`200 OK`) do `compilado.binarypb` (~40 KB), o sistema calcula o SHA-256 diretamente em memória RAM (~0,3 ms) antes de gravar no disco, persistindo o arquivo atomicamente (via `.tmp` + `rename`) como `compilado.binarypb.<sha256_real>` no `temp_cache`, registrando `<sha256_real>` na sessão online e expurgando versões antigas apenas após a conclusão do `rename` atômico (com documentação explícita no código sobre o comportamento de *LRU eviction* da CDN + sobrescrita no R2).
- **Fallback Offline de Emergência no `temp_cache`**: Caso o `compilado.binarypb.<hash_esperado>` não exista no `temp_cache` e a requisição HTTP falhe (sem internet ou timeout na rocha), o `ServicoCroquiOnline` verifica se existe qualquer arquivo `compilado.binarypb.*` de uma versão anterior na pasta `temp_cache/<picoId>/` e o carrega como salva-vidas.
- **Hot-Reload sem Piscada para Croquis Baixados Offline (`DatasetRepository.loadIndiceToMemory`)**: Durante a Fase 1 do `syncIndex`, `loadIndiceToMemory` preserva em memória a instância já carregada de `existente.croqui` mesmo quando o checksum do pico no novo índice divergir, evitando que páginas abertas de croquis salvos offline pisquem uma tela de carregamento enquanto a Fase 2 baixa os novos arquivos em segundo plano, realizando a transição reativa (*hot-reload*) de uma só vez quando `_updatePicoMetadata` concluir o commit atômico.
- **Upload Estagiado em 3 Etapas no Deploy (`../aresta_db/serving/update_serving.py`)**: O deploy para o Cloudflare R2 passa a enviar os arquivos em três estágios sequenciais (cada um internamente paralelo): (1) mídias e imagens externas/thumbnails, (2) arquivos `compilado.binarypb` e (3) manifestos (`indice.binarypb`, `catalogo.db`, `arquivos_serving.yaml`) seguidos do `purge_manifests`, impedindo que um manifesto ou croqui novo seja servido antes de seus arquivos filhos existirem no R2.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capability isolada necessária; os requisitos estendem sincronizacao-cache-croquis. -->

### Modified Capabilities
- `sincronizacao-cache-croquis`: Atualiza a etapa 4 da hierarquia de resolução para download otimista em 1 RTT com `syncIndex` silencioso em background, exige cálculo do SHA-256 real em memória na chegada do HTTP do `compilado.binarypb` com gravação atômica via `.tmp` e fallback offline para versões anteriores no `temp_cache`, preserva a instância em memória de croquis baixados durante a Fase 1 do `syncIndex` para hot-reload contínuo na Fase 2, e estabelece o upload estagiado em 3 fases no deploy para a CDN/R2.

## Impact

- **`aresta_app`**:
  - `frontend/lib/services/repositorio_dataset.dart` (`getCroqui`, `loadIndiceToMemory`)
  - `frontend/lib/services/http/servico_croqui_online.dart` (`carregarCroquiRemoto`, `_salvarEmCacheVolatil`, fallback de `temp_cache` em falha de rede)
  - Testes espelhados correspondentes (`repositorio_dataset_test.dart`, `servico_croqui_online_test.dart`)
- **`aresta_db`**:
  - `serving/update_serving.py` (separação de `_upload_files_parallel` em 3 estágios: mídias ➔ `compilado.binarypb` ➔ manifestos) e `serving/update_serving_test.py`
