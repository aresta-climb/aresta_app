## Why

Durante a navegação em croquis no modo online (sem download prévio para o armazenamento permanente), imagens como capas em Markdown, mapas e miniaturas são baixadas repetidamente pela rede sempre que o usuário navega entre telas ou fecha e reabre o aplicativo. Isso ocorre porque o `ProvedorImagemAresta` atualmente apenas consulta o `temp_cache`, mas nunca persiste nele os bytes baixados da CDN, delegando a exibição a um `NetworkImage` efêmero em RAM. Além disso, o widget `OfflineMarkdown` purga o cache de memória em qualquer reconstrução (`didUpdateWidget`), agravando o consumo de rede, bateria e frustrando escaladores que consultam o croqui antes da trilha e perdem o acesso visual ao chegar na base da rocha sem sinal de celular.

Esta proposta resolve a persistência volátil e a unificação do ecossistema de imagens sob os princípios inegociáveis de engenharia estabelecidos em `AGENTS.md`: desenvolvimento estritamente guiado por testes (TDD), testes de widget/integração em primeiro lugar, 100% de cobertura, simplicidade sem abstrações prematuras, tudo em português brasileiro e documentação contínua abrangente.

## What Changes

- **Gravação Atômica no `temp_cache` pelo `ProvedorImagemAresta`**: Ao realizar o download de imagens remotas da CDN, o provedor persiste os bytes em disco sob o diretório volátil do SO (`temp_cache`) utilizando a convenção content-addressable `<caminho>.<hash>`.
- **Exigência Estrita de Hash**: A presença do `checksumSha256` torna-se pré-requisito mandatório para gravação no `temp_cache`. A ausência de hash emite registro de erro via telemetria (`AppLogger.instance.logError`) e realiza fallback para streaming direto sem poluir o cache local.
- **Limpeza de Hashes Anteriores em Background**: Ao concluir o download de uma nova versão de imagem com hash atualizado, versões anteriores do mesmo arquivo com hashes defasados no `temp_cache` são removidas sem onerar o caminho crítico de leitura.
- **Deduplicação de Downloads Concorrentes**: Memoização de downloads em andamento em memória para evitar requisições de rede duplicadas para o mesmo arquivo quando múltiplos widgets requisitam a mesma mídia ao mesmo tempo.
- **Suporte a Thumbnails Globais e Unificação de UI**: Extensão do `ProvedorImagemAresta` para resolver e cachear miniaturas globais sob `temp_cache/thumbnails/<picoId>.webp.<hash>`, migrando `browse_functions.dart` (`_CragBackgroundWidget`) e `meus_croquis_functions.dart` para o provedor centralizado com downsampling via `larguraAlvo`.
- **Remoção de Evicção Incondicional no `OfflineMarkdown`**: Eliminação da chamada cega a `provider.evict()` em `OfflineMarkdown.didUpdateWidget`, delegando a invalidação reativa estritamente à variação do hash e conteúdo (`data` ou `cragId`).
- **Aproveitamento de Cache no Download Offline (`SyncService`)**: O fluxo de download de croqui (`sync_isolate.dart`) passa a verificar se mídias já foram cacheadas no `temp_cache` com o hash esperado antes de realizar requisições HTTP, copiando-as diretamente para o armazenamento permanente.
- **Conformidade Estrita com `AGENTS.md`**:
  - *Princípio I (Tudo em Português)*: Nomenclatura, documentação e parâmetros (`caminhoCacheVolatil`, métodos auxiliares) 100% em português brasileiro.
  - *Princípio II (Componentes Independentes)*: Separação nítida de responsabilidades entre UI, provedor de mídia e serviço de sincronização.
  - *Princípio III (100% Test Coverage)*: Cobertura integral e testes rigorosos para todos os cenários e caminhos de exceção.
  - *Princípio IV (TDD)*: Ciclo Red-Green-Refactor estrito com criação de `test/view_functions/meus_croquis_functions_test.dart` para garantir espelhamento exato com `lib/`.
  - *Princípio V (Testes de Widget em Primeiro Lugar)*: Priorização de testes de integração ponta a ponta e widget tests antes de rotinas de baixo nível.
  - *Princípio VI (Simplicidade e Anti-Abstração)*: Uso direto de `dart:io`, verificação SHA-256 em $O(1)$ pelo nome do arquivo, sem dependências externas pesadas como `cached_network_image`.
  - *Princípio VII (Documentação Contínua)*: Docstrings `///` em português em todas as rotinas explicando o porquê e atualização dos `README.md` pertinentes.

## Capabilities

### New Capabilities
<!-- Nenhuma capacidade inteiramente nova; o comportamento aprimora as capacidades existentes de invalidacao de imagem e transmissao online -->

### Modified Capabilities
- `invalidacao-reativa-cache-imagens`: O `ProvedorImagemAresta` passa a persistir imagens baixadas no `temp_cache` no padrão `<caminho>.<hash>`, exigir hash para cache volátil, expurgar versões de hash antigo após gravação, suportar thumbnails em `temp_cache/thumbnails/<picoId>.webp.<hash>` e cessar evicção indiscriminada de RAM no `OfflineMarkdown`.
- `transmissao-croqui-online`: O fluxo de download e sincronização passa a checar o `temp_cache` para reaproveitar arquivos já baixados em sessões online antes de iniciar downloads remotos.

## Impact

- **Código Afetado**:
  - `frontend/lib/widgets/provedor_imagem_aresta.dart`: Lógica de download atômico, verificação e gravação em `temp_cache`, expurgo de hash antigo e suporte a thumbnails.
  - `frontend/lib/view_functions/offline_markdown.dart`: Limpeza e preservação do cache no ciclo de vida de widget.
  - `frontend/lib/view_functions/browse_functions.dart` e `frontend/lib/view_functions/meus_croquis_functions.dart`: Adoção do `ProvedorImagemAresta.resolver` com `larguraAlvo: 300`.
  - `frontend/lib/services/http/sync_isolate.dart` e `sync_service.dart`: Verificação de mídias prévias no `temp_cache`.
  - Testes unitários, de widget e de integração em:
    - `frontend/test/widgets/provedor_imagem_aresta_test.dart`
    - `frontend/test/view_functions/offline_markdown_test.dart`
    - `frontend/test/view_functions/browse_functions_test.dart`
    - `frontend/test/view_functions/meus_croquis_functions_test.dart` (novo arquivo para paridade com `lib/`)
    - `frontend/test/services/http/sync_isolate_test.dart`
    - `frontend/test/integration/cache_imagens_online_test.dart` (novo teste de integração ponta a ponta)
  - Documentação em `frontend/lib/services/README.md` e `frontend/lib/widgets/README.md`.
- **Dependências**: Nenhuma dependência externa nova adicionada (utiliza bibliotecas padrão `dart:io` e `http`).
