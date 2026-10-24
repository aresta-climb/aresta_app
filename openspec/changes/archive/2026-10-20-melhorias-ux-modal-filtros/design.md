# Design

## Context

Veja `proposal.md` para a motivação detalhada das issues `aresta_db#65` e `aresta_db#66`.
Atualmente, o componente `PainelFiltrosIndice` (`frontend/lib/widgets/painel_filtros_indice.dart`) renderiza um `ModalBottomSheet` reativo acionado nas páginas `SetoresPage`, `GrupoPage` e `SetorPage`. Toda alteração de filtro ou ordenação dispara imediatamente o callback `onFiltrosUnificadosChanged`, atualizando o estado da página hospedeira e notificando o modal via `ValueNotifier<int> _versaoNotificador` dentro de `didUpdateWidget`.

Dois pontos da UI atual prejudicam a experiência:
1. Os `DropdownButton<String>` em `_buildSeletorLocalizacao` e `_buildSeletorConquistadores` não definem `menuMaxHeight`, fazendo com que listas extensas ocupem 100% da altura da tela e bloqueiem o toque externo para fechar no iOS.
2. O modal não possui um rodapé com botão de ação afirmativa (`Aplicar (X resultados)`), deixando apenas o ícone `✕` no cabeçalho e ocultando a contagem de resultados filtrados atrás do próprio Bottom Sheet.

## Goals / Non-Goals

**Goals:**
- Garantir que os menus suspensos de localização e conquistadores nunca ocupem a tela inteira, permitindo cancelamento por toque fora em qualquer plataforma (especialmente iOS).
- Exibir um botão de ação primária fixo no rodapé do modal com o texto dinâmico `Aplicar (X resultados)` (ou singular `Aplicar (1 resultado)`), mantendo 100% do comportamento auto-aplicado e reativo.
- Fornecer a contagem atualizada de resultados filtrados (`totalResultados`) da aba ativa em `SetoresPage`, `GrupoPage` e `SetorPage`.

**Non-Goals:**
- Transformar os filtros em estado transacional/rascunho (qualquer forma de fechar o modal — botão `Aplicar`, `✕`, toque externo ou botão Voltar — deve preservar os filtros que já foram aplicados reativamente).
- Substituir o `DropdownButton` por um novo modal secundário ou seletor multi-escolha complexo.

## Decisions

### 1. Limite `menuMaxHeight: 280` nos `DropdownButton`s
- **Decisão**: Configurar `menuMaxHeight: 280` tanto em `_buildSeletorLocalizacao` quanto em `_buildSeletorConquistadores`.
- **Racional**: `280px` exibe cerca de 5 a 6 itens simultaneamente com rolagem interna suave e garante que, mesmo em telas compactas, mais de 60% da tela permaneça livre para que um simples toque fora feche o popup sem exigir seleção.
- **Alternativas consideradas**: Criar um sub-modal com busca e checkboxes foi descartado por adicionar complexidade desnecessária para um caso em que quase sempre se filtra por um único conquistador ou setor.

### 2. Rodapé fixo reativo com `Aplicar (X resultados)` em `PainelFiltrosIndice`
- **Decisão**: Adicionar o parâmetro opcional `final int? totalResultados` ao `PainelFiltrosIndice`. Abaixo do `Flexible(child: SingleChildScrollView(...))` de `_buildModalControlesConteudo`, adicionar um rodapé fixo separado por `Divider` com um `SizedBox(width: double.infinity)` contendo um `ElevatedButton` (ou `FilledButton`) estilizado com `colors.rustIron` e `colors.chalkWhite`.
- **Formatação do rótulo**:
  - Se `totalResultados == null`: `'Aplicar'`
  - Se `totalResultados == 1`: `'Aplicar (1 resultado)'`
  - Caso contrário: `'Aplicar ($totalResultados resultados)'`
- **Ação do botão**: Chama `Navigator.of(context).pop()`, exatamente como o botão `✕`, pois os filtros já são aplicados em tempo real a cada interação.
- **Cálculo nas páginas hospedeiras**:
  - `SetoresPage`: na aba `'Setores'`, passa `_obterSetoresOuGruposOrdenados().length`; nas abas de modalidade, passa `_estadoFiltros.filtrarEscaladas(_todasEscaladas, modalidadeEspecifica: abaAtual).length`.
  - `GrupoPage`: na aba `'Setores'`, passa `_obterSetoresFiltrados().length`; nas abas de modalidade, passa `_estadoFiltros.filtrarEscaladas(_todasEscaladas, modalidadeEspecifica: abaAtual).length`.
  - `SetorPage`: passa `_estadoFiltros.filtrarEscaladas(_todasEscaladas, modalidadeEspecifica: abaAtual).length`.

## Risks / Trade-offs

- **[Espaço vertical em telas pequenas]** → O botão fica no rodapé fixo fora do `SingleChildScrollView`, enquanto o conteúdo interno dos filtros rola normalmente dentro do `Flexible`, evitando qualquer `RenderFlex overflow`.
