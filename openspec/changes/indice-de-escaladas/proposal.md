## Why

Atualmente, o aplicativo organiza as escaladas estritamente sob uma ótica geográfica (Pico ➔ Grupos ➔ Setores ➔ Vias). Quando o escalador deseja encontrar seus próximos projetos por objetivo (ex: "quais são as vias esportivas entre 6º e 7º grau neste pico?"), ele precisa navegar setor por setor ou arriscar termos textuais na busca global.

O **Índice de Escaladas** resolve essa limitação introduzindo uma porta de entrada direta na página principal do pico, espelhando o clássico índice remissivo dos guias impressos, com navegação por abas dedicadas por modalidade, filtros de grau e estilo, e acesso rápido aos detalhes de cada via e respectivo setor.

## What Changes

- **Página Principal do Pico**:
  - Destaque em grade de 2 colunas no topo com `Setores` e `Índice de Escaladas`.
  - Texto objetivo sem redundância de contagens: "Todas as vias e boulders filtrados por grau e tipo".
- **Nova Tela: Índice de Escaladas**:
  - Abas dinâmicas por modalidade existente no pico (`Esportivas`, `Boulders`, `Móveis`, `Multienfiadas`).
  - Painel de filtros expansível (*expando*) contextual à modalidade selecionada.
  - Filtro por faixa de grau (chips de faixas rápidas e ajuste fino de/até).
  - Filtros adicionais: Setor, Conquistador e Apenas Clássicas (★).
  - Persistência independente do estado dos filtros ao alternar entre as abas de modalidade.
  - Cards de escalada com destaque visual do grau, modalidade, proteções, setor/grupo e ação de visualização.
- **Navegação e Detalhes da Via**:
  - Fluxo de retorno intuitivo: o botão voltar (`<-` da barra superior e gesto/botão do sistema) retorna diretamente ao Índice de Escaladas, preservando a posição de rolagem e os filtros aplicados.
  - Na tela de detalhes da via (`ViaPage`), exibição explícita da hierarquia geográfica (`Grupo > Setor`) com atalho direto e evidente para abrir o setor correspondente no croqui.
- **Padronização Terminológica**:
  - Padronização definitiva do termo **Multienfiada** em toda a interface e documentação, em conformidade com as diretrizes de idioma do projeto.

## Capabilities

### New Capabilities
- `indice-escaladas`: Catálogo e listagem de escaladas do pico filtradas por modalidade, faixa de grau, setor e autor.

### Modified Capabilities
- `detalhes-via`: Exibição da hierarquia completa de localização (Grupo e Setor) com ação clara de salto para o croqui do setor.

## Impact

- **Navegação (`navigation/arvore/`)**: Novo nó `IndiceEscaladasNode` integrado ao controlador de navegação em árvore e registro no `main.dart`.
- **Interface e Telas (`pages/`, `widgets/`)**: Nova tela `IndiceEscaladasPage`, atualização dos cards na `PicoDetailsPage` e melhoria do componente de localização na `ViaPage`.
- **Lógica e Helpers (`view_functions/`, `utils/`)**: Funções auxiliares para agrupamento, resolução de grupo/setor e filtragem por faixa de graus.
- **Testes (`test/`)**: Cobertura abrangente de 100% com testes de widget e de unidade para a nova tela, nós de navegação e componentes de filtro.
