## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: Reutilização e Propagação de DatasetResolver por Instância de Croqui
O sistema DEVE (MUST) manter e reutilizar uma única instância indexada de `DatasetResolver` associada ao ciclo de vida de cada `Croqui`/`Pico` em memória, propagando-a para todas as páginas da hierarquia do croqui sem reindexar a árvore de entidades a cada transição de página ou consulta de referência.

#### Scenario: Reutilização do resolvedor entre páginas do mesmo croqui e referências de mapa
- **WHEN** o usuário navega entre páginas de um mesmo croqui (ex: `Pico`, `Setor`, `Via` e `MapaInterativo`) ou resolve múltiplas referências de um mapa
- **THEN** o sistema reutiliza a mesma instância de `DatasetResolver` já indexada para aquele `Pico`/`Croqui` sem executar nova indexação O(N)
- **AND** se o croqui receber uma nova instância por atualização ou Live Reload, um novo `DatasetResolver` é construído para a nova instância
