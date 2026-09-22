## Context

Atualmente, o Aresta App organiza a navegação em um modelo de árvore (`TreeNavigationController`, `NavNode`) ancorado na hierarquia geográfica: `PicoNode` ➔ `SetoresNode` ➔ `SetorNode` ➔ `ViaNode`. O hub principal do pico (`PicoDetailsPage`) renderiza cartões verticais em largura total (`PicoMenuCard`) direcionando o usuário prioritariamente para os setores.

Os dados de todas as escaladas já são mantidos em memória no modelo de domínio protobuf (`Croqui`, `Pico`, `Setor`, `Escalada`), existindo utilitários como `getAllEscaladasFromPico`, `getGrauValue`, `getProtecoesValue` e `getModalidadeEscalada`.

Para viabilizar a busca de projetos por objetivo (faixa de grau, modalidade, autor), este design detalha a arquitetura do **Índice de Escaladas**.

## Goals / Non-Goals

**Goals:**
- Implementar `IndiceEscaladasNode` e `IndiceEscaladasPage` com abas dinâmicas por modalidade existente no pico (`Esportivas`, `Boulders`, `Móveis`, `Multienfiadas`).
- Desenvolver o painel de filtros expansível (*expando*) contextual à modalidade ativa, permitindo atalhos rápidos e ajuste de limites inicial e final.
- Reter o estado dos filtros e rolagem em memória de forma independente por aba.
- Ajustar o layout do topo da `PicoDetailsPage` com dois cartões em destaque lado a lado: `SETORES` e `ÍNDICE DE ESCALADAS`.
- Aprimorar o cabeçalho de contexto na `ViaPage` para exibir a hierarquia geográfica completa (`Grupo > Setor`) com atalho direto ao croqui.
- Padronizar toda a interface e documentação no termo **Multienfiada**.

**Non-Goals:**
- Não alterar o schema do `.proto` nem APIs de rede (a padronização para "Multienfiada" atua na camada de apresentação e helpers Dart).
- Não criar listagens híbridas que misturem Boulders (escala V) e Vias com corda (escala brasileira) no mesmo filtro de grau.

## Decisions

### Decisão 1: Abas dinâmicas por modalidade em vez de lista unificada única
- **Decisão**: Cada modalidade presente no pico (`Esportivas`, `Boulders`, `Móveis`, `Multienfiadas`) terá sua própria aba dedicada. Se um pico não possuir determinada modalidade (ex: sem boulders), aquela aba não é exibida.
- **Racional**: As modalidades possuem sistemas de graduação e metadados distintos. Boulders utilizam a escala V (`V0` a `V16`), enquanto multienfiadas possuem exposição (`E1` a `E5`), duração (`D1` a `D6`) e contagem de enfiadas. A separação por abas garante que os controles de filtro sejam 100% relevantes para o tipo de escalada exibido.
- **Alternativas consideradas**: Lista única com chips de multi-seleção de modalidade; descartada devido ao conflito conceitual entre filtros de grau (escala V vs numérica brasileira) na mesma tela.

### Decisão 2: Painel expansível (Expando) integrado ao topo da lista
- **Decisão**: Os filtros residem em um contêiner colapsável no topo da página. Quando aberto, oferece faixas rápidas de grau, seletores de limite, setor, conquistador e clássicas. Quando fechado, contrai-se em uma barra compacta exibindo chips dos filtros ativos.
- **Racional**: Permite que o escalador ajuste os parâmetros vendo a lista reagir imediatamente, sem a necessidade de modais ou telas extras que bloqueiam o contexto.
- **Alternativas consideradas**: Modal BottomSheet; rejeitada por exigir múltiplos toques de abrir/fechar para verificar a quantidade de vias resultantes.

### Decisão 3: Contrato estrito de navegação reversa (AppBar `<-` e Back do sistema)
- **Decisão**: Tanto o botão `<-` da barra superior quanto o botão/gesto de retorno do sistema na `ViaPage` sempre retornam para o `IndiceEscaladasPage` com scroll e filtros intactos. O acesso ao setor é feito por um atalho visual explícito e destacado dentro da página da via.
- **Racional**: No iOS não existe botão físico de voltar — o botão da barra e o gesto de borda compartilham a mesma pilha. Alterar o comportamento da seta superior quebraria o fluxo de retorno para usuários de iPhone e violaria as diretrizes de experiência de usuário.
- **Alternativas consideradas**: Fazer a seta superior voltar ao setor e o back do sistema voltar ao índice; descartada pela impossibilidade no iOS e risco grave de desorientação.

### Decisão 4: Modelo de visualização indexado `ItemIndiceEscalada`
- **Decisão**: Criar um modelo leve ou tupla que encapsula `(Escalada escalada, Setor setor, Grupo? grupo)` gerado no momento da carga inicial da página.
- **Racional**: Evita chamadas repetidas a `findSetorForEscalada` dentro do método de renderização de cada card durante a rolagem rápida do `ListView.builder`.

## Risks / Trade-offs

- **[Performance com centenas de vias]** → Mitigado pelo uso de `ItemIndiceEscalada` pré-indexado e `ListView.builder`. Como a base de dados de um pico típico tem entre 20 e 300 vias, a filtragem local em memória é executada em submilissegundos no Dart.
- **[Graus não numéricos como 'PROJETO' ou 'INDEFINIDO']** → Mitigado utilizando a lógica existente de pesos `getGradeSortWeight` que posiciona essas vias no final da ordenação por dificuldade.
