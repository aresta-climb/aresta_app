# Proposta: Unificação de Setores e Escaladas em Menu Único

## Por que (Why)

Atualmente, o Hub de detalhes do pico (`PicoDetailsPage`) apresenta dois pontos de entrada separados para navegar pelas escaladas: o menu **Setores** (focado na estrutura geográfica e croquis) e o menu **Índice de Escaladas** (focado no catálogo de vias com filtros de grau e modalidade). 

O feedback dos usuários revelou que ter dois menus distintos para encontrar escaladas gera confusão e fricção cognitiva: o usuário hesita entre entrar em setores para ver os croquis ou ir ao índice para achar vias por dificuldade. Além disso, a separação impede que o usuário faça buscas combinadas poderosas, como filtrar quais setores possuem vias de determinados graus ou conquistadores.

Unificar essas duas visões em uma experiência coesa elimina a fragmentação do catálogo, reduz a complexidade da navegação e entrega uma ferramenta onde o escalador pode alternar instantaneamente entre a visão geográfica (setores) e a visão linear (vias e boulders), compartilhando um estado de filtros unificado e consistente.

## O que muda (What Changes)

- **Ponto de entrada unificado no Hub do Pico (`pico.dart`)**: Substituição dos cards lado a lado de "Setores" e "Índice de Escaladas" por um único card de destaque principal ("Setores & Escaladas").
- **Barra de navegação por abas dinâmicas**:
  - Primeira aba fixa: `Setores`.
  - Abas subsequentes dinâmicas: uma para cada modalidade presente no pico (ex: `Esportivas`, `Boulders`, `Móveis`, `Multienfiadas`).
  - Indicadores numéricos contextuais nas abas no formato dinâmico `(filtradas/total)` (ex: `Setores (4/13)`, `Esportivas (12/95)`), ou apenas `(total)` quando sem filtros ativos.
- **Painel de filtros unificado (Superset Reativo)**:
  - Na aba `Setores`, o painel exibe um superset completo de filtros: seleção de modalidades ativas, sliders de grau correspondentes a cada modalidade ativa, grupos, conquistadores e vias clássicas/estreladas.
  - Nas abas de modalidade (ex: `Esportivas`), o painel projeta apenas os controles pertinentes àquela modalidade (slider de grau específico, setores, grupos, conquistadores e clássicas).
  - Estado compartilhado: alterações em critérios comuns (ex: grau de vias, conquistadores) são sincronizadas e refletidas harmonicamente entre as visões.
- **Tríade padronizada de ordenação e alternador de direção**:
  - Barra de ordenação idêntica em todas as abas: `[ PADRÃO | GRAU | ALFABÉTICO ]` acompanhada de um botão de alternância de direção `[ ▲ / ▼ ]`.
  - Ordenação por `GRAU` na aba Setores: calcula e ordena pela **mediana** dos graus das vias do setor (normalizando graus de boulder e via através de uma régua comparativa unificada), sem poluir a interface.
  - Ordenação por `GRAU` nas abas de modalidade: ordena pela dificuldade da via (crescente/decrescente).
- **Cartões de Setor enriquecidos**:
  - Exibem a faixa de graus do setor (ex: `5º a 8a`) e a quantidade de vias correspondentes ao filtro ativo (`4 vias no filtro (de 18)`).
  - Setores sem nenhuma via correspondente aos filtros são automaticamente ocultados da listagem.
- **Thumbnail de Mapa Geral**: Mantido no topo da página de exploração quando houver mapa geral cadastrado.
- **Compatibilidade de Navegação**:
  - O nó `IndiceEscaladasNode` é unificado ou redirecionado para a nova experiência `SetoresPage` com parâmetro de aba inicial opcional, preservando histórico e deep links.

## Capacidades (Capabilities)

### Novas Capacidades
- `exploracao-setores-escaladas`: Define a experiência consolidada de navegação, visualização alternada por abas, filtros globais reativos com contadores dinâmicos `(X/Total)` e ordenação por mediana de grau em setores e dificuldade em vias.

### Capacidades Modificadas
- `navigation`: Atualização do fluxo de navegação do Hub do Pico (`PicoDetailsPage`) e redirecionamento de nós da árvore declarativa para a rota unificada de exploração de setores e escaladas.

## Impacto (Impact)

- **Frontend / UI**:
  - `frontend/lib/pages/pico.dart`: Atualização do menu principal do Hub para exibir card unificado.
  - `frontend/lib/pages/pico_subpages/setores_page.dart`: Transformação na tela integrada de exploração com suporte a abas de modalidades, integração de filtros e listagem mista.
  - `frontend/lib/pages/indice_escaladas_page.dart`: Consolidação de suas funcionalidades dentro da arquitetura unificada.
  - `frontend/lib/widgets/painel_filtros_indice.dart`: Evolução para painel adaptativo capaz de renderizar o modo superset (setores) e o modo contextual (modalidade específica).
  - `frontend/lib/widgets/card_indice_escalada.dart` e `pico_functions.dart`: Reutilização direta nos modos de exibição correspondentes.
- **Modelos e Utilitários**:
  - `frontend/lib/utils/filtro_grau_escalada.dart`: Criação do modelo de estado global de filtros e função de conversão/normalização de graus entre modalidades para cálculo de mediana de setor.
- **Navegação**:
  - `frontend/lib/navigation/arvore/pico_nodes.dart` e `frontend/lib/main.dart`: Sincronização dos nós de rota.
- **Testes**:
  - Adição de testes unitários para cálculo de mediana de setores, normalização de graus e estado de filtros.
  - Adição de testes de widget para a tela unificada, alternância de abas, painel de filtros e botão de ordenação com alternador de direção.
