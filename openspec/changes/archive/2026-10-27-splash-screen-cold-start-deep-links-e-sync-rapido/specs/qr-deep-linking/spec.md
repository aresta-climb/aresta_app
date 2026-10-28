# Spec Delta

## ADDED Requirements

### Requirement: Transição Direta no Cold Start Sem Pulo Pela Tela Inicial
Quando o aplicativo for iniciado a frio (*Cold Start*) a partir de um deep link válido, o sistema DEVE (MUST) resolver o nó de destino antes de exibir a árvore de navegação principal, abrindo diretamente na tela da entidade (via, setor, grupo, pico ou mapa) com a tela inicial na base da pilha de retorno, sem exibir ou piscar a Home intermediariamente.

#### Scenario: Abertura direta em via a partir de Cold Start
- **WHEN** o aplicativo é iniciado a frio por um link válido de via (`https://aresta.cc/s/<uid>`)
- **THEN** a transição sai da splash screen diretamente para a tela de detalhes da via, mantendo a hieriaquia pai (`Setor` -> `Pico` -> `Home`) na pilha para navegação de retorno

## MODIFIED Requirements

### Requirement: Carregamento Resiliente Online e Offline
O sistema DEVE (MUST) resolver qualquer `uid` (de croqui, grupo, setor ou escalada) consultando primeiramente os croquis em memória/baixados (`/downloads`), o cache volátil (`/temp_cache`) e o banco SQLite local `catalogo.db` (`RepositorioCatalogo`) para identificar o `id_slug` do croqui hospedeiro. Se o croqui já estiver baixado em `/downloads` ou presente no cache volátil `/temp_cache` do dispositivo, o elemento DEVE ser aberto imediatamente sem aguardar requisições de rede, disparando a sincronização do índice em segundo plano. Caso o `uid` não seja encontrado no `catalogo.db` local ou o croqui não esteja em `/downloads` nem em `/temp_cache`, o sistema DEVE sincronizar rapidamente o índice e o catálogo (`syncIndex`) antes de carregar o croqui na sessão online e exibir o elemento. Se não houver internet nem croqui disponível localmente, o sistema DEVE apresentar uma notificação amigável e instrutiva.

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
- **WHEN** o usuário clica em um link `https://aresta.cc/<uid>` de um pico não disponível em `/downloads` nem em `/temp_cache` e o dispositivo está sem conexão à internet
- **THEN** o sistema exibe uma mensagem informando que o croqui precisa ser baixado previamente quando houver sinal de rede, sem crashar a interface
