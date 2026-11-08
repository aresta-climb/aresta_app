# Design

## Context

Veja `proposal.md` para a motivação e o problema de experiência do usuário.
Atualmente, `EstadoFiltrosUnificado` (em `frontend/lib/utils/filtro_grau_escalada.dart`) armazena `modalidadesAtivas` e os mapas `minGrauPorModalidade` e `maxGrauPorModalidade` (indexados por `'Via'` ou `'Boulder'`).
Quando o usuário restringe apenas a faixa de grau de `'Via'`, `filtrarEscaladas` verifica os limites de cada item individualmente e, como `'Boulder'` não possui entrada nos mapas de grau, retorna `true` para todos os boulders. Além disso, em abas específicas de modalidade (`modalidadeEspecifica != null`), `filtrarEscaladas` retorna vazio se `modalidadesAtivas` não contiver a modalidade da aba, e `obterContadorModalidade` utiliza `temFiltrosAtivos` global (exibindo `(40/40)` na aba "Boulders" quando apenas o grau de via foi filtrado).
No `PainelFiltrosIndice` (`frontend/lib/widgets/painel_filtros_indice.dart`), `_obterCategoriasParaSliders` ocultava a régua de uma categoria quando sua modalidade era desmarcada, o que causaria salto de layout (*layout shift*) se a modalidade fosse desmarcada durante o arraste da régua inferior.

## Goals / Non-Goals

**Goals:**
- Garantir que restringir a faixa de grau de uma categoria (`Via` ou `Boulder`) oculte automaticamente as escaladas da outra categoria na visão agregada ("Setores") caso a outra categoria não possua filtro de grau ativo.
- Sincronizar visualmente os `FilterChip`s de modalidade no modal da aba "Setores" com as categorias de grau filtradas, mantendo todas as réguas do local sempre renderizadas e aplicando estado esmaecido (`Modalidade inativa`) às réguas inativas.
- Permitir reativar uma categoria inativa tanto tocando no seu chip de modalidade quanto arrastando diretamente sua régua esmaecida.
- Exibir na barra externa apenas o chip da faixa de grau (`[Vias: 7a a 8a ✕]`) quando a restrição de modalidade decorrer automaticamente do filtro de grau, permitindo limpeza completa em 1 clique.
- Isolar as abas específicas de modalidade (`Esportivas`, `Boulders`, `Móveis`, `Multienfiadas`) em `SetoresPage`, `GrupoPage` e `SetorPage` para que ignorem `modalidadesAtivas` e filtros de grau de outras categorias, tanto na listagem quanto no contador do rótulo da aba.

**Non-Goals:**
- Alterar a escala numérica de pesos ou a lógica de ordenação por mediana de setores.
- Modificar o comportamento de filtros transversais (localização, conquistador, clássicas e ordenação), que permanecem compartilhados entre todas as abas.

## Decisions

### 1. Derivação de Modalidades e Categorias Ativas na Aba "Setores" (`EstadoFiltrosUnificado`)
- **Decisão**: Introduzir em `EstadoFiltrosUnificado` o getter `Set<String> get categoriasComFiltroGrau` e os métodos `bool isModalidadeAtivaNosSetores(String modalidade)` e `bool isCategoriaAtivaNosSetores(String categoria, List<String> modalidadesDisponiveis)`:
  - Quando `modalidadesAtivas` estiver vazio e `categoriasComFiltroGrau` não estiver vazio (ex: usuário filtrou apenas `Vias: 7a a 8a`), `isModalidadeAtivaNosSetores` retorna `true` apenas para modalidades cuja categoria (`obterCategoriaGrau`) pertença a `categoriasComFiltroGrau`.
  - Quando `modalidadesAtivas` não estiver vazio (seleção manual de modalidades), `isModalidadeAtivaNosSetores` respeita `modalidadesAtivas.contains(modalidade)`.
  - Quando ambos estiverem vazios, todas as modalidades estão ativas.
- **Racional**: Ao derivar a desmarcação automática a partir de `categoriasComFiltroGrau` sem poluir `modalidadesAtivas`, obtemos gratuitamente três propriedades desejadas:
  1. Os chips de `Modalidades` dentro do modal refletem imediatamente a desmarcação de `Boulder` ao filtrar grau de `Via`;
  2. A barra externa de chips verifica `modalidadesAtivas.isNotEmpty`, exibindo apenas `[Vias: 7a a 8a ✕]` (1 filtro ativo) sem chips redundantes de modalidade;
  3. Ao clicar no `✕` de `[Vias: 7a a 8a ✕]` (ou retornar a régua para "Todos os graus"), `categoriasComFiltroGrau` esvazia e todas as modalidades voltam a ficar ativas em 1 clique.
- **Alternativas consideradas**: Gravar diretamente as modalidades em `modalidadesAtivas` ao mover o slider e criar uma flag booleana `modalidadeDerivadaDoGrau`. Descartado por introduzir estado mutável redundante propenso a dessincronização.

### 2. Réguas Sempre Renderizadas com Esmaecimento Visual (*Sub-opção 1A*)
- **Decisão**: Em `PainelFiltrosIndice._obterCategoriasParaSliders()`, considerar sempre todas as categorias existentes em `widget.modalidadesDisponiveis` na aba "Setores", independentemente de quais modalidades estejam desmarcadas. Em `_buildSliderParaCategoria()`, verificar `isCategoriaAtivaNosSetores`:
  - Quando inativa, envolver a seção da régua em `Opacity(opacity: 0.45)` e exibir no badge superior o texto `'Modalidade inativa'`.
  - Manter o `RangeSlider` interativo: se o usuário arrastar uma régua que estava inativa, atualizar os limites de grau daquela categoria e, caso `modalidadesAtivas` estivesse restringindo manualmente aquela categoria, incluir suas modalidades em `modalidadesAtivas` (ou limpar `modalidadesAtivas` se todas as disponíveis passarem a ficar ativas).
- **Racional**: Evita que a régua superior (`Faixa de Grau (Vias)`) desapareça da árvore de widgets enquanto o usuário arrasta a régua inferior (`Faixa de Grau (Boulders)`), eliminando saltos bruscos de coordenada Y sob o dedo do usuário.

### 3. Isolamento de Abas de Modalidade Específica e Contadores Contextuais
- **Decisão**:
  - Em `EstadoFiltrosUnificado.filtrarEscaladas(itens, {String? modalidadeEspecifica})`:
    - Se `modalidadeEspecifica != null`: filtrar por `item.modalidade == modalidadeEspecifica` (ignorando `modalidadesAtivas`) e aplicar apenas o limite de grau correspondente a `obterCategoriaGrau(modalidadeEspecifica)` (ignorando limites de grau da outra categoria), mantendo os filtros transversais (localização, conquistador, clássicas, busca e ordenação).
    - Se `modalidadeEspecifica == null` (usado na aba "Setores"): filtrar primeiro por `isModalidadeAtivaNosSetores(item.modalidade)` e em seguida aplicar os limites de grau de cada categoria ativa e os filtros transversais.
  - Adicionar `bool temFiltrosAtivosParaModalidade(String modalidade)` em `EstadoFiltrosUnificado`, que verifica se há filtro de grau para a categoria daquela modalidade ou algum filtro transversal ativo.
  - Atualizar `obterContadorModalidade` e `SetorPage._formatarRotuloAba` para usar `temFiltrosAtivosParaModalidade(modalidade)` em vez de `temFiltrosAtivos` global.
- **Racional**: Garante que a aba `Boulders` mostre `Boulders (40)` e liste todos os 40 boulders mesmo quando o usuário filtrou `Vias: 7a a 8a` na aba `Setores` ou `Esportivas`, e vice-versa.

## Risks / Trade-offs

- **[Risk] Desmarcação manual de uma modalidade que já possuía filtro de grau ativo** → **Mitigação**: Quando o usuário desmarcar manualmente nos chips de `Modalidades` todas as modalidades de uma categoria (ex: desmarcar `Boulder` após ter definido `Boulders: V2 a V4`), o handler do `FilterChip` limpará concomitantemente os limites de grau daquela categoria em `minGrauPorModalidade`/`maxGrauPorModalidade`, garantindo que a régua fique esmaecida e sem filtro órfão.
- **[Risk] Limpeza de filtros dentro de uma aba específica vs aba Setores** → **Mitigação**: O botão "Limpar" em uma aba específica já remove os limites de grau da categoria da aba ativa e redefine os filtros transversais, preservando a previsibilidade.
