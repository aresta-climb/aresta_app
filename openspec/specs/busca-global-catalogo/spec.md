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
Ao tocar em qualquer resultado da Busca Global (pico, grupo, setor ou escalada), o sistema DEVE (MUST) resolver e navegar para a entidade através do seu `uid` e `id_slug` (utilizando o `LocalizadorDestinoUid` / carregamento sob demanda quando o croqui não estiver baixado localmente).

#### Scenario: Toque em via de um croqui não baixado na Busca Global
- **WHEN** o usuário toca em uma escalada nos resultados da Busca Global cujo croqui ainda não está salvo localmente e há conexão com a internet
- **THEN** o aplicativo carrega o croqui sob demanda na sessão online e abre diretamente a tela de detalhes daquela escalada com toda a sua hierarquia (`PicoNode -> SetorNode -> ViaNode`).
