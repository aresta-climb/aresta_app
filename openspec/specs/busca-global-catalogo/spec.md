# busca-global-catalogo Specification

## Purpose

Fornece busca global instantânea e 100% offline desde a instalação sobre todos os picos, grupos, setores e escaladas do catálogo nacional utilizando o banco SQLite `catalogo.db`, pesquisa aproximada (`Fuzzy`), priorização de croquis salvos offline e navegação direta por UID.

## Requirements

### Requirement: Indexação Global Completa via `catalogo.db`
A Busca Global DEVE (MUST) carregar os registros de croquis (`catalogo_croquis`) e entidades (`catalogo_aresta` com tipos `escalada`, `setor` e `grupo`) a partir do `RepositorioCatalogo` (`catalogo.db`) utilizando junção relacional (`LEFT JOIN`) por UID para resolver nomes de setores pais, grupos pais, picos, cidades e estados, tornando 100% do acervo pesquisável mesmo para croquis que nunca foram baixados.

#### Scenario: Pesquisa por via de um croqui ainda não baixado
- **WHEN** o usuário abre a Busca Global recém-instalado (sem croquis baixados) e digita o nome de uma via catalogada no `catalogo.db`
- **THEN** a via é exibida nos resultados com sua modalidade, graduação, nome do setor, nome do pico e estado.

#### Scenario: Filtro por categoria e modalidade
- **WHEN** o usuário seleciona um filtro na Busca Global (`Todos`, `Picos`, `Setores`, `Esportivas`, `Móveis`, `Boulders`, `Highlines`)
- **THEN** a busca restringe os resultados às linhas correspondentes (`catalogo_croquis` para `Picos`, `tipo == 'setor'` ou `'grupo'` para `Setores`, e `escalada_tipo` correspondente para cada modalidade de escalada).

### Requirement: Pesquisa Aproximada (`Fuzzy`) com Priorização de Croquis Offline
A Busca Global DEVE (MUST) executar pesquisa aproximada (`Fuzzy`) tolerante a erros de digitação e acentuação sobre título e subtítulo dos itens do catálogo, e DEVE ordenar os resultados aplicando prioridade (boost de relevância) aos itens pertencentes a croquis já baixados offline (`isDownloaded == true`).

#### Scenario: Desempate e priorização de resultados salvos offline
- **WHEN** o usuário pesquisa um termo que coincide com entidades de relevância similar em um croqui baixado offline e em um croqui não baixado
- **THEN** as entidades pertencentes ao croqui baixado offline são posicionadas no topo da lista de resultados, antes das entidades disponíveis apenas online.

### Requirement: Badge Visual de Disponibilidade Offline
Cada item da lista de resultados da Busca Global pertencente a um croqui salvo localmente (`isDownloaded == true`) DEVE (MUST) exibir uma badge visual explícita indicando que o conteúdo está disponível **`Offline`**.

#### Scenario: Renderização de item salvo offline vs item do catálogo online
- **WHEN** a lista de resultados da Busca Global exibe um item de croqui já baixado e outro de croqui não baixado
- **THEN** o item baixado exibe a badge **`Offline`** destacada com ícone de confirmação, enquanto o item não baixado exibe o indicador de carregamento na nuvem.

### Requirement: Navegação Direta por UID a partir da Busca Global
Ao tocar em qualquer resultado da Busca Global (pico, grupo, setor ou escalada), o sistema DEVE (MUST) bloquear imediatamente toques subsequentes (`0 ms`) e exibir o feedback visual modal bloqueante de carregamento (`barrierDismissible: false`) caso a resolução ultrapasse o limiar visual de `150 ms` enquanto resolve e carrega a entidade através do seu `uid` e `id_slug` (utilizando o `LocalizadorDestinoUid` / carregamento sob demanda quando o croqui não estiver baixado localmente), fechando o modal de carregamento (se aberto) antes de navegar para o destino ou de exibir uma única instância do modal *bottom sheet* de ausência de conexão (`ModalCroquiSemConexao`). Caso a resolução conclua ou falhe em menos de `150 ms` (ex: croqui já em disco/cache ou falha imediata em Modo Avião), o sistema DEVE transicionar diretamente para o destino ou para o `ModalCroquiSemConexao` sem piscar o modal intermediário de carregamento. Caso o croqui não esteja salvo em `/downloads` nem no cache volátil `/temp_cache` e o dispositivo esteja sem conexão à internet, o sistema DEVE apresentar o modal *bottom sheet* contextual informando os dados da entidade e do croqui hospedeiro com a opção **"Tentar novamente"**, que ao restabelecer a conexão fecha o modal e navega diretamente para a entidade selecionada.

#### Scenario: Toque em via de um croqui não baixado na Busca Global
- **WHEN** o usuário toca em uma escalada nos resultados da Busca Global cujo croqui ainda não está salvo localmente, há conexão com a internet e o download sob demanda leva mais de `150 ms`
- **THEN** o aplicativo exibe o modal bloqueante de carregamento (`"Abrindo <título>..."`), carrega o croqui sob demanda na sessão online, fecha o modal de carregamento e abre diretamente a tela de detalhes daquela escalada com toda a sua hierarquia (`PicoNode -> SetorNode -> ViaNode`).

#### Scenario: Bloqueio de múltiplos toques concorrentes durante o carregamento na Busca Global
- **WHEN** o usuário toca repetidamente em um resultado da Busca Global enquanto a resolução ou requisição de rede ainda está em andamento (mesmo antes dos `150 ms` iniciais)
- **THEN** a trava de concorrência e o modal bloqueante impedem a abertura de resoluções duplicadas, garantindo que no máximo uma navegação ou um único modal de falta de conexão seja exibido.

#### Scenario: Resolução ou falha instantânea (< 150 ms) sem piscar modal de carregamento
- **WHEN** o usuário toca em um resultado da Busca Global e a resolução conclui ou falha em menos de `150 ms` (ex: croqui salvo localmente ou falha imediata de socket em Modo Avião)
- **THEN** o aplicativo cancela a abertura do modal `"Abrindo..."` e abre diretamente a página de destino ou o `ModalCroquiSemConexao` sem piscar um diálogo intermediário na tela.

#### Scenario: Toque em entidade de croqui presente no cache volátil sem internet
- **WHEN** o usuário está sem internet e toca em uma via, setor, grupo ou pico na Busca Global cujo croqui não está em `/downloads`, mas possui o `compilado.binarypb.<sha256>` salvo em `/temp_cache`
- **THEN** o aplicativo carrega o croqui a partir do `/temp_cache` e abre diretamente a página da entidade sem exibir modal de falta de conexão.

#### Scenario: Toque em via, setor, grupo ou pico não baixado na Busca Global sem internet
- **WHEN** o usuário está sem internet e toca em um resultado da Busca Global cujo croqui não está salvo em `/downloads` nem em `/temp_cache`
- **THEN** o aplicativo fecha o modal de carregamento (caso tenha sido exibido) e apresenta uma única instância do modal *bottom sheet* informando o nome da entidade, o croqui ao qual pertence e que o dispositivo está sem conexão, permitindo tocar em **"Tentar novamente"** para abrir o destino quando a conexão voltar.

### Requirement: Reatividade Automática da Busca Global a Atualizações do Catálogo e Troca de Modo
O widget `GlobalSearch` DEVE (MUST) escutar alterações em `RepositorioCatalogo.versaoNotificador` e `DatasetRepository.activeDataset`, invalidando o cache em memória e recarregando automaticamente as entidades do `catalogo.db` ativo sempre que o catálogo for atualizado (via sincronização em segundo plano ou Live Reload) ou quando o usuário alternar entre o Modo Oficial e o Modo Experimental. Quando já houver dados carregados em memória (`_allData` não vazio), a recarga reativa DEVE (MUST) ocorrer de forma silenciosa em segundo plano sem desmontar a lista de resultados visível para exibir indicador de carregamento.

#### Scenario: Atualização imediata da Busca Global após Live Reload no Modo Experimental
- **WHEN** o aplicativo está no Modo Experimental e uma nova versão do `catalogo.db` experimental é aplicada pelo `SyncService` (incrementando `RepositorioCatalogo.versaoNotificador`) ou `activeDataset` é atualizado com a `GlobalSearch` expandida
- **THEN** a `GlobalSearch` recarrega silenciosamente em segundo plano sem substituir a `ListView` por um `CircularProgressIndicator` e passa a exibir imediatamente as vias, setores, grupos e picos atualizados.

#### Scenario: Isolamento de resultados na Busca Global ao entrar ou sair do Modo Experimental
- **WHEN** o usuário alterna entre o Modo Oficial e o Modo Experimental
- **THEN** o `DatasetRepository` limpa as sessões online em memória do modo anterior e a `GlobalSearch` exibe exclusivamente as entidades pertencentes ao catálogo e índice do modo ativo.
