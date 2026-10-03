# Design Técnico: Unificação de Setores e Escaladas

## Contexto

Conforme detalhado no `proposal.md`, atualmente a navegação de um pico divide a exploração em duas telas desacopladas (`SetoresPage` e `IndiceEscaladasPage`). Ambas operam sobre a mesma árvore de dados de um `Pico` e suas entidades `Setor`, `Grupo` e `Escalada`. A unificação requer uma camada de estado integrada que filtre e ordene tanto coleções de setores quanto coleções de vias sob as mesmas premissas de UX.

## Objetivos e Não-Objetivos

**Objetivos:**
- Centralizar a experiência de exploração na tela unificada de setores e escaladas (`SetoresPage`), com abas dinâmicas: `Setores` fixa em primeiro lugar, seguida das modalidades disponíveis no pico (`Esportivas`, `Boulders`, etc.).
- Compartilhar um estado reativo global de filtros (`EstadoFiltrosUnificado`), onde a aba Setores atua como superset e as abas de modalidade atuam como projeções contextuais.
- Fornecer ordenação consistente através da tríade `[ PADRÃO | GRAU | ALFABÉTICO ]` acompanhada de alternador de direção `[ ▲ / ▼ ]`.
- Normalizar graus de vias e boulders em uma régua de peso comparativa contínua para viabilizar o cálculo da mediana de dificuldade por setor.
- Ocultar dinamicamente setores sem vias correspondentes e enriquecer os cartões de setores com faixa de graus e contagem de vias filtradas.

**Não-Objetivos:**
- Não alterar as telas de detalhe de vias (`via.dart`), setores individuais (`setor.dart`) ou mapas interativos.
- Não modificar os contratos de mensagens do Protobuf (`croqui.pb.dart`).
- Não alterar a lógica de download ou persistência offline do pico.

## Decisões Técnicas

### 1. Modelo de Estado Global de Filtros (`EstadoFiltrosUnificado`)
- **Decisão**: Substituir o mapa de estados isolados `_filtrosPorModalidade` por uma classe imutável `EstadoFiltrosUnificado` que consolida:
  - `modalidadesAtivas`: `Set<String>` com as modalidades habilitadas no filtro de setores.
  - `faixasGrauPorModalidade`: `Map<String, FaixaGrau>` (com valores numéricos mínimo e máximo para cada modalidade).
  - `setoresSelecionados`: `Set<String>` (aplicável nas abas de modalidade).
  - `gruposSelecionados`: `Set<String>` (aplicável em setores e modalidades).
  - `conquistadoresSelecionados`: `Set<String>`.
  - `apenasClassicas`: `bool`.
  - `ordenacao`: enum `TipoOrdenacaoExploracao { padrao, grau, alfabetico }`.
  - `direcaoCrescente`: `bool`.
- **Alternativa rejeitada**: Manter filtros separados por aba. Essa abordagem quebraria a fluidez de ver um setor com determinado grau e querer listar diretamente aquelas vias ao trocar para a aba da modalidade.

### 2. Normalização e Tabela de Pesos Unificada (`obterPesoDificuldadeUnificado`)
- **Decisão**: Implementar em `frontend/lib/utils/filtro_grau_escalada.dart` uma função determinística que converte a graduação de qualquer tipo de escalada para uma escala normalizada (0 a 2000):
  - Vias brasileiras: 4º (~500), 5º (~600), 6a (~700), 7a (~800), 7c (~900), 8a (~1000), 9a (~1200), 10a (~1500), etc.
  - Boulders (Escala V): V0 (~500), V1 (~600), V2 (~700), V3 (~800), V4 (~900), V5 (~1000), V7 (~1200), V10 (~1500), etc.
- **Alternativa rejeitada**: Utilizar diretamente `getGradeSortWeight`. Ele extrai apenas o número da string (ex: V4 gera 500, o mesmo que 4º grau de via), distorcendo totalmente a comparação entre falésias e blocos de boulder.

### 3. Ordenação de Setores por Mediana de Grau
- **Decisão**: Na ordenação por `GRAU` na aba Setores, ordenar cada setor calculando a **mediana** dos pesos unificados das suas vias (considerando as vias que passaram no filtro ativo).
  - Cálculo: ordenar a lista de pesos das vias do setor e tomar o valor central (ou média dos dois valores centrais).
- **Alternativa rejeitada**: Média aritmética simples. Foi descartada porque um único projeto difícil isolado (outlier) distorceria para cima um setor predominantemente escola/fácil.

### 4. Componente de Ordenação Padronizado com Alternador de Direção
- **Decisão**: Renderizar uma linha horizontal com 3 botões seletores (`PADRÃO`, `GRAU`, `ALFABÉTICO`) e um botão lateral com ícone de seta (`Icons.arrow_upward` / `Icons.arrow_downward`).
  - O estado de direção (`direcaoCrescente`) inverte a ordenação para qualquer um dos três modos selecionados.
- **Alternativa rejeitada**: Dois cliques no mesmo botão para inverter direção sem indicador visual. A seta explícita oferece visibilidade imediata do estado atual para o usuário.

### 5. Apresentação do Cartão de Setor Enriquecido
- **Decisão**: Quando filtros estiverem aplicados, o cartão de setor exibe:
  - Faixa de graduação formatada: menor grau até maior grau das vias do setor (ex: `5º a 8a`).
  - Contador contextual: `X vias no filtro (de Total)`.
  - Setores com 0 vias no filtro não são renderizados.
- **Alternativa rejeitada**: Renderizar setores com opacidade reduzida ou desabilitados. Ocultar mantém a lista compacta e foca a atenção apenas nos setores relevantes para a busca.

## Riscos e Mitigações

- **[Risco] Sobrecarga de processamento em picos com muitas vias ao recalcular mediana**:
  - *Mitigação*: A indexação de vias do pico com `indexarEscaladasDoPico` é executada uma única vez no carregamento. As filtragens e cálculos de mediana operam sobre listas em memória e são altamente otimizados (geralmente menos de 500 vias por pico).
- **[Risco] Compatibilidade com histórico e deep links que referenciam `IndiceEscaladasNode`**:
  - *Mitigação*: Manter `IndiceEscaladasNode` no roteamento direcionando para `SetoresPage` configurada para abrir na aba de escaladas correspondente, assegurando que nenhum link quebre.
