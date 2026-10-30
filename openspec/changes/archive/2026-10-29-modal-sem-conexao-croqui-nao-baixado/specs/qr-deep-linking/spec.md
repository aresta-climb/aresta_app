## MODIFIED Requirements

### Requirement: Carregamento Resiliente Online e Offline
O sistema DEVE (MUST) resolver qualquer `uid` (de croqui, grupo, setor ou escalada) consultando primeiramente os croquis em memória/baixados (`/downloads`), o cache volátil (`/temp_cache`) e o banco SQLite local `catalogo.db` (`RepositorioCatalogo`) para identificar o `id_slug` e os metadados da entidade e do croqui hospedeiro. Se o croqui já estiver baixado em `/downloads` ou presente no cache volátil `/temp_cache` do dispositivo, o elemento DEVE ser aberto imediatamente sem aguardar requisições de rede, disparando a sincronização do índice em segundo plano. Caso o `uid` não seja encontrado no `catalogo.db` local ou o croqui não esteja em `/downloads` nem em `/temp_cache`, o sistema DEVE sincronizar rapidamente o índice e o catálogo (`syncIndex`) antes de carregar o croqui na sessão online e exibir o elemento. Se não houver internet nem croqui disponível em `/downloads` ou `/temp_cache`, mas o `uid` for conhecido no catálogo ou índice local, o sistema DEVE registrar um aviso operacional (`logAviso`) e apresentar um modal *bottom sheet* contextual informando o nome da entidade (via/setor/grupo/pico), a qual croqui pertence e que o usuário está sem conexão, oferecendo um botão **"Tentar novamente"** para reexecutar a abertura assim que a conexão for restabelecida. Caso o `uid` realmente não exista no acervo local mesmo após tentativa de sincronização, o sistema DEVE registrar um aviso (`logAviso`) e exibir o aviso de código não encontrado.

#### Scenario: Acesso com croqui já baixado em ambiente offline
- **WHEN** o usuário escaneia um QR Code `https://aresta.cc/q/<uid>` na rocha sem sinal de operadora, mas o pico já está salvo em `/downloads` ou no cache volátil `/temp_cache` do dispositivo
- **THEN** o aplicativo abre o setor ou via instantaneamente sem exibir erros de rede e dispara a sincronização em segundo plano

#### Scenario: Acesso a via ou croqui recém-publicado ausente no catálogo local
- **WHEN** o usuário clica em `https://aresta.cc/s/<uid>` de uma entidade publicada recentemente que ainda não consta no `catalogo.db` local e há conexão ativa com a internet
- **THEN** o sistema executa a sincronização do índice e do delta do `catalogo.db`, localiza o `uid` na segunda tentativa, baixa o `.binarypb` do croqui e abre a tela correspondente

#### Scenario: Acesso com croqui não baixado em ambiente online
- **WHEN** o usuário clica em `https://aresta.cc/s/<uid>` de uma via ou setor pertencente a um croqui que ainda não está em `/downloads` nem em `/temp_cache`, mas possui conexão ativa com a internet
- **THEN** o sistema sincroniza o `indice.binarypb` e o `catalogo.db`, carrega o `.binarypb` atualizado do croqui na sessão online e renderiza a tela correspondente

#### Scenario: Acesso com croqui não baixado em ambiente offline
- **WHEN** o usuário abre um link `https://aresta.cc/<uid>` (em *Cold Start* ou *Warm Start*) correspondente a uma via, setor, grupo ou pico catalogado localmente em `catalogo.db` (ou no índice), mas o `.binarypb` do croqui não está em `/downloads` nem em `/temp_cache` e o dispositivo está sem conexão à internet
- **THEN** o sistema registra `logAviso` no logger e apresenta um modal *bottom sheet* informando o nome da entidade, o nome e localização do croqui hospedeiro e a ausência de conexão, com ação **"Tentar novamente"** que recarrega e navega diretamente para o destino assim que houver internet

#### Scenario: Acesso a UID inexistente no acervo
- **WHEN** o usuário abre um link `https://aresta.cc/<uid>` cujo código não existe nem no `catalogo.db` local nem após tentativa de sincronização
- **THEN** o sistema registra `logAviso` informando o código não localizado e exibe o aviso de código não encontrado sem crashar a interface

### Requirement: Telemetria de Abertura via Deep Link e QR Code
O sistema DEVE (MUST) registrar um evento estruturado de telemetria (`deep_link_aberto`) e uma trace de performance (`cold_start_deep_link` ou `warm_start_deep_link`) sempre que um deep link for interceptado e processado pelo aplicativo, identificando o tipo de inicialização (Cold Start vs Warm Start), o destino alcançado (`pico`, `grupo`, `setor`, `via`), se abriu direto no mapa (`abrir_mapa`), a camada de resolução de dados (`modo_acesso`: `memoria`, `offline`, `temp_cache` ou `cdn_online`), o tempo total até a página estar renderizada e interativa (`duracao_ms`), a origem do link (`qrcode`, `compartilhamento` ou parâmetros UTM) e o resultado do carregamento (`sucesso: true/false`).

#### Scenario: Registro bem-sucedido de abertura de via via QR code físico
- **WHEN** o usuário escaneia um QR code físico (`https://aresta.cc/qm/<uid>` ou `https://aresta.cc/q/<uid>`) na rocha que abre uma via com o aplicativo previamente fechado (Cold Start)
- **THEN** após o primeiro frame da tela de destino ser renderizado, o sistema despacha a trace `cold_start_deep_link` e o evento `deep_link_aberto` contendo `tipo_start: cold_start`, `destino: via`, `sucesso: true`, `modo_acesso`, `duracao_ms`, `origem_link: qrcode` e eventuais parâmetros `utm_source` e `utm_medium`.

#### Scenario: Registro de falha no carregamento de deep link sem internet
- **WHEN** um link externo é acionado para uma entidade conhecida no catálogo cujo croqui não está baixado nem em `/temp_cache` e o dispositivo está sem conexão com a internet
- **THEN** o sistema despacha evento de telemetria registrando `idCroqui` do croqui identificado, o tipo de destino correspondente, `sucesso: false`, `duracao_ms` e `motivoErro: 'croqui_offline_sem_conexao'` antes de exibir o *bottom sheet* ao usuário.
