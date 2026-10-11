# Design

## Context

Atualmente, o `PainelFiltrosIndice` atua como painel de filtros unificado para a `SetoresPage` e para a `GrupoPage`. Ambas as páginas mantêm em memória a lista das escaladas pertencentes ao pico/grupo (`_todasEscaladas` como instâncias de `ItemIndiceEscalada`).

No estado atual:
1. A barra externa de controles encapsula o `InkWell` apenas na `Row` de tamanho mínimo do texto e ícone. Quando não há chips ativos, todo o restante do `Container` é um espaço não interativo.
2. O `RangeSlider` em `_buildSliderParaCategoria` usa a lista estática integral de `OpcoesGrau` (24 graus para vias e 19 para boulders), gerando uma régua esticada onde o escalador precisa adivinhar onde começam e terminam as vias do pico atual.

## Goals / Non-Goals

**Goals:**
- Proporcionar área de toque integral (100% da largura) na barra de controles externa quando não houver chips ativos, com ripple em todo o `Container` e ícone sutil de expansão (`▾`).
- Permitir que toques na área neutra/vazia da trilha de chips também abram o modal de filtros.
- Implementar a função utilitária `calcularFaixasGrauDisponiveis(List<ItemIndiceEscalada>)` para extrair de forma eficiente `O(N)` o menor e maior `grauValor` para cada categoria (`Via` e `Boulder`).
- Recortar a lista de opções de grau em `_buildSliderParaCategoria` com base na amplitude real do local, garantindo rótulos legíveis nas extremidades da régua (ex: `4º` na esquerda e `9a` na direita).
- Exibir badge com a amplitude quando nenhum filtro de grau estiver ativo (ex: `Todos os graus (4º a 9a)`).
- Tratar com robustez casos de borda: picos com grau único (expandindo ±1 grau vizinho) e picos sem graduação cadastrada (fallback para escala completa).

**Non-Goals:**
- Não alterar os modelos protobuf de dados nem a camada de persistência/sincronização de croquis.
- Não alterar a mecânica dos filtros de localização, conquistadores ou clássicas.
- Não alterar as regras de ordenação ou telemetria existentes.

## Decisions

### 1. Estrutura de Dados da Amplitude de Graus (`FaixaGrauDisponivel`)
- **Decisão**: Criar a classe simples imutável `FaixaGrauDisponivel` em `filtro_grau_escalada.dart`:
  ```dart
  class FaixaGrauDisponivel {
    final int minValor;
    final int maxValor;
    const FaixaGrauDisponivel({required this.minValor, required this.maxValor});
  }
  ```
  O `PainelFiltrosIndice` receberá o parâmetro opcional:
  ```dart
  final Map<String, FaixaGrauDisponivel>? faixasGrauDisponiveis;
  ```
- **Alternativa Considerada**: Passar a lista completa de `ItemIndiceEscalada` para dentro do `PainelFiltrosIndice`.
  - *Por que não*: Viola o princípio de separação de responsabilidades (Princípio II do AGENTS.md), acoplando o componente de UI à entidade inteira de dados em vez de um modelo mínimo e tipado de apresentação.

### 2. Recorte Dinâmico e Tratamento de Grau Único
- **Decisão**: Ao montar o slider para uma `categoria`, busca-se a `FaixaGrauDisponivel` correspondente no mapa.
  - Localiza o índice em `OpcoesGrau` para `minValor` e `maxValor`.
  - Se `startIdx == endIdx` (todas as vias do pico têm exatamente o mesmo grau): expande a régua para `startIdx = max(0, startIdx - 1)` e `endIdx = min(opcoes.length - 1, endIdx + 1)`.
  - A sublista `opcoesAdaptadas = opcoes.sublist(startIdx, endIdx + 1)` é usada como fonte de verdade do `RangeSlider`.
- **Alternativa Considerada**: Desabilitar o `RangeSlider` e exibir texto estático quando houver grau único.
  - *Por que não*: Quebra a previsibilidade da interface e impede o usuário de interagir normalmente com o modal.

### 3. Preservação do Conceito de "Sem Restrição" nos Extremos
- **Decisão**: Quando o polegar esquerdo está no índice 0 da régua adaptada, o valor `minGrauValor` emitido para o estado é `null`. Quando o polegar direito está no último índice da régua adaptada, o valor `maxGrauValor` emitido é `null`.
- **Rationale**: Garante total compatibilidade com o sistema de filtragem existente (`EstadoFiltrosUnificado`), sem introduzir valores "mágicos". Quando ambos estão nas pontas, `cobreTudo` é `true` e o badge exibe `Todos os graus (<min> a <max>)`.

### 4. Layout da Barra Externa de Controles
- **Decisão**:
  - Se `chips.isEmpty`: O `InkWell` envolve uma `Row` com `Expanded` que preenche 100% da largura, posicionando `Icons.tune_rounded` e `Filtros e Ordenação` à esquerda e um `Icon(Icons.keyboard_arrow_down_rounded)` sutil à direita.
  - Se `chips.isNotEmpty`: A área esquerda do botão mantém seu `InkWell` próprio. A área direita do `SingleChildScrollView` de chips é encapsulada em um `GestureDetector(behavior: HitTestBehavior.translucent, onTap: () => _abrirModalControles(context))` para capturar toques no espaço livre além do último chip.

## Risks / Trade-offs

- **[Risco: Pico ou modalidade sem nenhuma escalada com grau válido]** → **Mitigação**: Fallback automático para a lista integral de `OpcoesGrau` padrão, sem quebrar a renderização.
- **[Risco: Conflito de toque entre a área neutra dos chips e o botão ✕]** → **Mitigação**: O `Chip` consome seu próprio evento de toque no `onDeleted`. O `GestureDetector` com `HitTestBehavior.translucent` só reage quando o evento não for consumido por um filho.
