## Why

Atualmente, o mecanismo de Hot Reload / Live Reload no Modo Experimental funciona exclusivamente para croquis que foram previamente baixados na pasta local `/downloads/`. Quando um usuário ou desenvolvedor explora um croqui acessado remotamente (em streaming sob demanda na sessão online, sem download prévio), as notificações de recarga via WebSocket do Editor Desktop são ignoradas pelo `SyncService`, pois este verifica apenas a existência de arquivos no disco físico. Como consequência, o `GerenciadorSessaoOnline` retém o objeto `Croqui` antigo em memória, o `PageListenableBuilder` re-renderiza com dados defasados e a tela não atualiza.

Além disso, o polling de ETag em `ServicoCroquiOnline` descarta os novos bytes recebidos ao obter HTTP 200 OK, não atualizando o croqui em memória e mantendo a notificação sem nenhum consumidor na interface. Faz-se necessário unificar a experiência: no Modo Experimental, o live reload deve pulsar o banner e atualizar a tela instantaneamente (seja o croqui local ou remoto); fora do Modo Experimental, a detecção de atualização deve atualizar a sessão e exibir um aviso amigável ao usuário, mantendo o padrão já estabelecido para croquis baixados.

## What Changes

- **Live Reload para Sessões Online no Modo Experimental**: Ao receber um evento push de Live Reload, o sistema verifica se há croquis abertos em sessão online (`GerenciadorSessaoOnline`), executa o re-fetch imediato do `.binarypb` com bypass de cache (`?t=timestamp`), atualiza o modelo em memória e a tabela SHA-256 de mídias no `DatasetRepository`, aciona o pulso luminoso no `BannerModoExperimental` e redesenha a tela de forma fluida e sem atritos.
- **Aproveitamento de Bytes no Polling de ETag**: Quando o polling de ETag receber status `200 OK`, os bytes do corpo da resposta são imediatamente aproveitados para desserializar o novo `Croqui`, atualizar o `GerenciadorSessaoOnline`, persistir no cache volátil (`/temp_cache`) e reindexar as mídias, eliminando requisições redundantes e descarte de dados.
- **Consistência de Notificação de Atualização**:
  - No **Modo Experimental**: atualização 100% automática e silenciosa com pulso visual no banner, sem popups intrusivos.
  - **Fora do Modo Experimental**: atualização automática da sessão online acompanhada de aviso visual não intrusivo (SnackBar / popup "O guia de [Pico] foi atualizado!"), em total simetria com a notificação de croquis baixados já existente.
- **Invalidação Reativa de Cache de Imagens em Streaming**: Ao atualizar o croqui em sessão online, as novas chaves e hashes SHA-256 de mídias são reindexadas no `DatasetRepository`, garantindo que o `ProvedorImagemAresta` resolva novas URLs com query parameters atualizados (`?v=<novo_sha256>`), forçando a decodificação da textura mais recente.

## Capabilities

### New Capabilities

*(Nenhuma nova capacidade adicionada; o comportamento estende as capacidades existentes).*

### Modified Capabilities

- `transmissao-croqui-online`: O polling periódico com ETag passa a consumir ativamente o buffer retornado em respostas HTTP `200 OK` para atualizar o `GerenciadorSessaoOnline`, reindexar mídias, renovar o cache volátil e notificar a interface (via popup/aviso fora do modo experimental, ou recarga imediata em modo experimental).
- `hot-reload-experiencia-usuario`: O manipulador de Live Reload passa a contemplar picos ativos em sessão online, garantindo que eventos push do Editor Desktop disparem re-fetch com cache-busting, atualização em memória e reconstrução imediata da interface com pulso luminoso no banner.

## Impact

- **Serviços**:
  - `ServicoCroquiOnline`: Métodos para re-fetch com cache-busting e processamento de corpo no 200 OK do ETag.
  - `EditorDeCroqui` & `registrarOuvintesLiveReload` em `main.dart`: Orquestração da atualização de sessões online durante eventos de Live Reload.
  - `DatasetRepository`: Reindexação reativa de mídias e propagação de notificações para `activeDataset` ao atualizar sessão online.
- **Interface e Navegação**:
  - `PageListenableBuilder`: Continua como consumidor reativo, recebendo as novas instâncias de `Croqui` vindas de `GerenciadorSessaoOnline`.
  - `main.dart` / `PicoDetailsPage`: Exibição do aviso visual quando o croqui online for atualizado fora do modo experimental.
- **Alinhamento Estrito com PRINCIPIOS.md**:
  - **I. Tudo em Português**: Identificadores, nomes de métodos (`recarregarCroquiOnline`, `verificarAtualizacaoEtag`), variáveis, testes e comentários estritamente em português brasileiro.
  - **II. Componentes Independentes**: Modularidade preservada entre serviços de rede, repositório de dados e interface.
  - **III. 100% de Test Coverage**: Cobertura integral de testes unitários e de widget em todos os arquivos modificados.
  - **IV. Imperativo do Teste em Primeiro Lugar (TDD)**: Ciclo Red-Green-Refactor estrito com testes escritos e validados em falha antes do código de produção.
  - **V. Testes de Widget em Primeiro Lugar**: Priorização de testes de fronteira na UI (`PageListenableBuilder`, `PicoDetailsPage`, `BannerModoExperimental`) para validar as interações do usuário.
  - **VI. Simplicidade e Anti-Abstração**: Extensão direta dos fluxos existentes sem camadas desnecessárias ou arquiteturas convolutas.
  - **VII. Documentação Contínua e Abrangente**: Docstrings `///` ricas explicando intenções técnicas e atualização imediata de `HOT_RELOAD.md` e `README.md`.
