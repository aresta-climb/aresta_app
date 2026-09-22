## Why

Atualmente, na listagem de setores e grupos de um croqui (e na seleção desses elementos no mapa interativo), o usuário visualiza apenas o nome e o total genérico de vias. Ao planejar um dia de escalada ou buscar uma modalidade específica (como esportiva, tradicional/móvel, boulder ou multienfiada), o escalador precisa abrir setor por setor para descobrir quais tipos de escalada estão presentes. 

A inclusão de badges informativos com contagem precisa por tipo de escalada e a diferenciação visual de grupos agregadores resolve esse problema de usabilidade, proporcionando visibilidade imediata das modalidades disponíveis na rocha.

## What Changes

- **Badges de Modalidades com Concordância Gramatical**: Introdução de badges visuais que indicam a quantidade e o tipo de escalada existente no setor/grupo (ex: `[ 1 esportiva ]`, `[ 12 esportivas ]`, `[ 3 móveis ]`, `[ 5 boulders ]`, `[ 2 multienfiadas ]`, `[ 1 highline ]`), respeitando a concordância no singular ($= 1$) e plural ($> 1$).
- **Estruturação Visual de Grupos**: Exibição em duas linhas para grupos agregadores na listagem:
  - Linha 1: resumo quantitativo (`X setores • Y escaladas`, com concordância singular/plural).
  - Linha 2: badges com o total consolidado por modalidade presente em todos os setores do grupo.
- **Enriquecimento dos Cards do Mapa Interativo**: Atualização dos cartões flutuantes de Setor e Grupo no mapa interativo (`MapaInterativoPage`), substituindo o subtítulo simplificado pela mesma estrutura visual de badges informativos e resumo de grupos.
- **Componente Modular Autônomo**: Criação do componente reutilizável `BadgesModalidades` seguindo os princípios de engenharia do projeto (isolado, testável, documentado e 100% em português).

## Capabilities

### New Capabilities
- `badges-modalidades`: Gerencia a consolidação, formatação com regras gramaticais de pluralização (singular/plural) e renderização visual dos badges de modalidades de escalada (esportiva, móvel, boulder, multienfiada, highline) e o cabeçalho quantitativo para grupos agregadores.

### Modified Capabilities
- `interactive-map`: O cartão flutuante de seleção de Setores e Grupos no mapa interativo passa a exibir os badges informativos de modalidades e resumo de grupo em vez de apenas o texto de contagem simples.

## Impact

- **UI / Frontend**:
  - Novo widget modular em `frontend/lib/widgets/badges_modalidades.dart` (ou pasta temática de widgets).
  - `frontend/lib/view_functions/pico_functions.dart` (`buildSectorTile` e `buildGrupoTile`).
  - `frontend/lib/pages/mapa_interativo.dart` (`_buildSetorCard`, `_buildGrupoCard` e `_buildBaseCard`).
  - `frontend/lib/pages/pico_subpages/setores_page.dart` e `frontend/lib/pages/grupo.dart`.
- **Testes**:
  - Testes unitários para o cálculo e regras gramaticais de pluralização de modalidades.
  - Testes de widget para o componente `BadgesModalidades`.
  - Testes de widget atualizados para `pico_functions`, `mapa_interativo` e telas associadas mantendo 100% de cobertura.
