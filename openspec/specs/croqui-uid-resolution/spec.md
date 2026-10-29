# croqui-uid-resolution Specification

## Purpose

Fornece normalização in-place de croquis legados no carregamento e um catálogo relacional unificado em tempo constante O(1) no DatasetResolver para resolução de Botões, Grupos, Setores e Escaladas por UIDs permanentes com mapeamento direto de ocorrências visuais.

## Requirements

### Requirement: Normalização In-Place de Croquis no Carregamento
O sistema MUST normalizar qualquer instância de `Croqui` ou `Pico` uma única vez na entrada de dados (carregamento local ou download), convertendo dados legados in-place de forma idempotente para que o restante da aplicação consuma unicamente os campos v5 sem repetir varreduras de normalização em transições de tela.

#### Scenario: Normalização de entidades estruturais legadas
- **WHEN** um `Pico` legado é carregado onde `Grupo`, `Setor` ou `Escalada` não possuem `uid` preenchido
- **THEN** o normalizador popula o campo `uid` com um identificador sintético determinístico baseado em seu tipo e caminho hierárquico
- **AND** os botões legados mantêm seu estado sem obrigatoriedade de UID sintético

#### Scenario: Normalização de referências e pontos de interesse legados
- **WHEN** um mapa possui pontos de interesse com `label` ou referências com `ids`/`escalada`/`setor`/`grupo`
- **THEN** o normalizador preenche `ponto.rotulo` com o valor de `label`, `ponto.uid` com `id`, `ref.pontosUids` com `ref.ids` e `ref.alvoUid` com o UID correspondente da entidade alvo

#### Scenario: Idempotência em chamadas subsequentes de normalização na mesma instância
- **WHEN** `NormalizadorCroqui.normalizarCroqui` ou `NormalizadorCroqui.normalizarPico` for invocado para uma instância de `Croqui` ou `Pico` que já foi normalizada em memória
- **THEN** o sistema reconhece que a instância já está normalizada e retorna em tempo constante O(1) sem percorrer novamente a árvore de grupos, setores, escaladas e mapas

### Requirement: Indexação e Resolução O(1) por UID de Entidades Estruturais
O sistema MUST indexar em uma única passada O(N) durante o carregamento do `Pico` todas as entidades estruturais portadoras de identificadores únicos (`Botao`, `Grupo`, `Setor` e `Escalada`), disponibilizando consultas em tempo constante O(1) por UID através do `DatasetResolver`.

#### Scenario: Resolução direta de Escalada por UID
- **WHEN** o `DatasetResolver` consulta um UID correspondente a uma `Escalada`
- **THEN** ele retorna imediatamente o `ResolvedDataset` contendo a `Escalada`, o `tipo` igual a `escalada`, seu `Setor` pai e seu `Grupo` pai (se houver)

#### Scenario: Resolução direta de Setor por UID
- **WHEN** o `DatasetResolver` consulta um UID correspondente a um `Setor`
- **THEN** ele retorna imediatamente o `ResolvedDataset` com o `Setor`, o `tipo` igual a `setor` e seu `Grupo` pai (se houver)

#### Scenario: Resolução direta de Grupo por UID
- **WHEN** o `DatasetResolver` consulta um UID correspondente a um `Grupo`
- **THEN** ele retorna imediatamente o `ResolvedDataset` com o `Grupo` e o `tipo` igual a `grupo`

#### Scenario: Resolução direta de Botão por UID
- **WHEN** o `DatasetResolver` consulta um UID correspondente a um `Botao`
- **THEN** ele retorna imediatamente o `ResolvedDataset` com o `Botao` e o `tipo` igual a `botao`

### Requirement: Associação Direta de Ocorrências em Mapas ao ResolvedDataset
O `DatasetResolver` MUST associar a cada `ResolvedDataset` uma lista de referências em mapas (`ReferenciaNoMapa`) onde a entidade foi desenhada, populada na carga inicial do croqui.

#### Scenario: Escalada desenhada em mapas de setor
- **WHEN** uma `Escalada` possui referências visuais em um ou mais mapas de setor
- **THEN** o `ResolvedDataset` da escalada contém a lista exata de pares de mapa e referência correspondentes em sua propriedade `referencias`

### Requirement: Reutilização e Propagação de DatasetResolver por Instância de Croqui
O sistema DEVE (MUST) manter e reutilizar uma única instância indexada de `DatasetResolver` associada ao ciclo de vida de cada `Croqui`/`Pico` em memória, propagando-a para todas as páginas da hierarquia do croqui sem reindexar a árvore de entidades a cada transição de página ou consulta de referência.

#### Scenario: Reutilização do resolvedor entre páginas do mesmo croqui e referências de mapa
- **WHEN** o usuário navega entre páginas de um mesmo croqui (ex: `Pico`, `Setor`, `Via` e `MapaInterativo`) ou resolve múltiplas referências de um mapa
- **THEN** o sistema reutiliza a mesma instância de `DatasetResolver` já indexada para aquele `Pico`/`Croqui` sem executar nova indexação O(N)
- **AND** se o croqui receber uma nova instância por atualização ou Live Reload, um novo `DatasetResolver` é construído para a nova instância
