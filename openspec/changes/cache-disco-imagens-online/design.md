## Context

O aplicativo Aresta adota uma abordagem híbrida para visualização de croquis: croquis baixados permanentemente residem em `/downloads/<picoId>/`, enquanto croquis abertos sob demanda são gerenciados via streaming de `.binarypb` na RAM e mídias remotas via CDN.

O `ProvedorImagemAresta` foi concebido para unificar essa resolução em três camadas (`/downloads` -> `/temp_cache` -> CDN). Contudo, a camada de persistência em `temp_cache` para imagens nunca foi implementada: a CDN simplesmente retorna uma instância de `NetworkImage` em memória. Adicionalmente, `OfflineMarkdown` expurga instâncias de imagem no `didUpdateWidget`, forçando downloads repetidos toda vez que o usuário navega entre telas. Por fim, telas como `browse_functions.dart` e `meus_croquis_functions.dart` ainda usam lógica manual de carregamento de miniaturas sem usufruir do provedor centralizado nem do cache volátil.

Para manter a base de código coesa e sustentável, este design é estritamente orientado pelas diretrizes de engenharia de `PRINCIPIOS.md`.

## Goals / Non-Goals

**Goals:**
- Implementar a escrita atômica de mídias transmitidas da CDN em disco sob o diretório volátil do SO (`temp_cache`), adotando a convenção content-addressable `<caminho>.<hash>`.
- Tratar miniaturas globais de forma padronizada sob `temp_cache/thumbnails/<picoId>.webp.<hash>`.
- Exigir `checksumSha256` estritamente para persistência no `temp_cache`; caso ausente, emitir log de erro e recorrer a streaming online sem cache.
- Expurgar versões antigas com hashes divergentes do mesmo arquivo após o término de um novo download, mantendo o caminho crítico de leitura em $O(1)$.
- Eliminar evicções cegas no `OfflineMarkdown.didUpdateWidget`, preservando a textura em memória RAM.
- Unificar o carregamento de miniaturas em `browse_functions.dart` e `meus_croquis_functions.dart` através de `ProvedorImagemAresta.resolver`.
- Reaproveitar mídias válidas já presentes no `temp_cache` durante o download permanente de croquis no `SyncService`/`DownloadIsolate`.
- Cumprir integralmente os preceitos de `PRINCIPIOS.md`: nomenclatura e documentação 100% em português brasileiro, 100% de cobertura de testes, ciclo TDD estrito com testes de widget e integração em primeiro lugar, paridade de arquivos de teste para `meus_croquis_functions.dart` e docstrings abrangentes explicando o porquê.

**Non-Goals:**
- Modificar a estrutura ou comportamento do armazenamento permanente offline (`/downloads/<picoId>/`).
- Criar daemons ou tarefas periódicas de varredura no `temp_cache` (o ciclo de vida de descarte sob pressão de disco é delegado ao sistema operacional).
- Introduzir bibliotecas de terceiros para cache de imagens (ex: `cached_network_image`), preservando a simplicidade e evitando abstrações desnecessárias conforme o Princípio VI.

## Decisions

### 1. Padrão Content-Addressable: `<caminho>.<hash>`
- **Decisão**: No `temp_cache`, cada mídia de croqui será salva como `temp_cache/<picoId>/<caminho>.<checksumSha256>`. Miniaturas globais serão salvas em `temp_cache/thumbnails/<picoId>.webp.<checksumSha256>`.
- **Racional**:
  - Teste de existência em $O(1)$ (`File.existsSync()`) que funciona como validação criptográfica de integridade sem ler o corpo do arquivo.
  - Se o hash mudar no servidor (Live Reload ou atualização de croqui), a busca pelo novo hash resulta imediatamente em cache miss, disparando a atualização sem exibir mídias defasadas.
  - A decodificação de imagem no Flutter (`ui.instantiateImageCodec`) lê os *magic bytes* do cabeçalho do arquivo e é agnóstica à extensão final.
- **Alternativas descartadas**:
  - *Nome de arquivo sem hash*: Exigiria calcular SHA-256 do arquivo em disco a cada renderização para checar obsolescência (alto custo de CPU/disco).
  - *`<hash>_<nome>`*: Dificulta a preservação da hierarquia de subpastas relativas do croqui (`setores/`, `mapas/`).

### 2. Hash Obrigatório com Fallback de Segurança
- **Decisão**: Se `checksumSha256` for nulo ou vazio, registrar erro explícito via `AppLogger.instance.logError` e realizar fallback para `NetworkImage` sem salvar no `temp_cache`.
- **Racional**: Não poluir o cache local com arquivos cuja versão e integridade não podem ser auditadas.
- **Alternativas descartadas**: Salvar com timestamp de modificação como hash (inadequado para streaming de CDN onde metadados de modificação local não existem).

### 3. Limpeza de Versões Defasadas na Conclusão da Escrita
- **Decisão**: A varredura por versões antigas da mesma mídia só ocorre após a conclusão bem-sucedida do download da nova versão (em background).
- **Racional**: O caminho crítico de leitura (renderização de frame a 60/120 fps) permanece estritamente $O(1)$, executando apenas um `stat` direto do arquivo. A remoção de versões anteriores só ocorre quando há alteração confirmada e I/O de rede já finalizado.

### 4. Escrita Atômica via Arquivo Temporário (`.tmp`)
- **Decisão**: O download salva inicialmente em `<caminho>.<hash>.tmp` e executa `rename` atômico após validação.
- **Racional**: Previne a existência de arquivos corrompidos ou incompletos no cache em caso de interrupção de rede ou encerramento abrupto do app.

### 5. Aproveitamento de Cache no Download Offline (`SyncService`)
- **Decisão**: Em `sync_isolate.dart`, a função `downloadAtomic` verifica a existência de `temp_cache/<picoId>/<caminho>.<hash>` antes de emitir a requisição HTTP. Caso exista, copia o arquivo para o destino `.tmp`.
- **Racional**: Se o usuário navegou pelo croqui online e depois clicou em "Baixar Croqui", todas as mídias já visualizadas são promovidas a permanentes instantaneamente com zero consumo de dados móveis.

### 6. Unificação do Carregamento de Miniaturas
- **Decisão**: Migrar `_CragBackgroundWidget` em `browse_functions.dart` e `meus_croquis_functions.dart` para chamar `ProvedorImagemAresta.resolver(picoId: id, caminho: 'thumbnails/$id.webp', larguraAlvo: 300)`. O provedor consultará `$docsDir/thumbnails/$id.webp` (camada 1) e `temp_cache/thumbnails/$id.webp.<hash>` (camada 2).
- **Racional**: Centralização em uma única arquitetura, eliminação de código duplicado e aplicação uniforme de downsampling de memória.

### 7. Estrutura de Testes e Conformidade com PRINCIPIOS.md
- **Decisão**: 
  - **Princípio V (Testes de Widget em Primeiro Lugar)**: O desenvolvimento inicia pela escrita de um teste de integração de fronteira que simula o fluxo do usuário em `ExplorarLocalPage` abrindo a capa, saindo e reabrindo (reproduzindo a falha em Red).
  - **Princípio IV (TDD & Espelhamento)**: Cada arquivo `.dart` modificado ou criado possui seu arquivo `_test.dart` correspondente na pasta `test/` espelhando a estrutura exata do `lib/`. Será criado `test/view_functions/meus_croquis_functions_test.dart` para sanar a ausência de cobertura nesse componente.
  - **Princípio I (Tudo em Português)**: Todas as docstrings, nomes de funções, comentários e documentação técnica estão em português brasileiro.
  - **Princípio III (100% de Cobertura)**: Todas as branches e cenários de sucesso, erro e ausência de hash serão cobertos com asserções rigorosas.
  - **Princípio VII (Documentação Contínua)**: Docstrings `///` em todos os métodos criados e atualizações no `README.md` de serviços e widgets.

## Risks / Trade-offs

- **[Risco] Limpeza prematura do `temp_cache` pelo sistema operacional**: Em dispositivos com armazenamento extremamente baixo, o Android ou iOS pode purgar a pasta `temp_cache`.
  - *Mitigação*: O sistema é resiliente por design. Na ausência do arquivo em disco, ocorre um cache miss natural e a mídia é rebaixada da CDN.
- **[Risco] Concorrência de downloads simultâneos para a mesma imagem**: Múltiplos widgets solicitando a mesma imagem não cacheada ao mesmo tempo.
  - *Mitigação*: Escrita com extensão `.tmp` e renomeação atômica, combinada com memoização de futures de download ativos no `ProvedorImagemAresta`.
