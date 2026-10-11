# Proposal

## Why

Atualmente, na página de exploração de setores e escaladas, o botão "Filtros e Ordenação" na barra externa só responde ao toque na pequena área onde estão o ícone e o texto; quando não há filtros ativos, mais da metade da largura da barra é "área morta" não clicável, frustrando a expectativa ergonômica do usuário. Além disso, ao abrir o modal de filtros, o slider de "Faixa de Grau" exibe uma régua genérica fixa de ponta a ponta (ex: de 1º a 12a para vias), sem indicar onde começam e terminam os graus cadastrados naquele pico específico, forçando o escalador a adivinhar e arrastar o slider em trechos vazios que não filtram nada.

Tornar a barra 100% clicável e introduzir uma régua adaptativa elimina a fricção de toque e oferece visibilidade imediata da amplitude real de graduações do pico.

## What Changes

- **Barra de Controles 100% Clicável**: Quando nenhum filtro estiver ativo, o botão "Filtros e Ordenação" ocupa toda a largura da barra externa com efeito de toque (*ripple*) de ponta a ponta e indicador sutil de abertura (`▾`), permitindo tocar em qualquer ponto para abrir o modal.
- **Área Neutra dos Chips Clicável**: Quando houver chips ativos, o espaço restante à direita do último chip na barra também aciona a abertura do modal de filtros, sem interferir no toque nos chips ou no botão `✕`.
- **Régua Adaptativa de Grau**: O `RangeSlider` de grau no modal passa a ter escala adaptativa que se recorta dinamicamente entre o menor e o maior grau das escaladas válidas existentes no pico/setor para a categoria ativa (Vias ou Boulders).
- **Rótulos de Extremidade e Indicador de Amplitude**: Exibição dos rótulos dos graus mínimo e máximo nas pontas da régua adaptada e no badge superior (ex: `Todos os graus (4º a 9a)`), informando com clareza os limites reais cadastrados.
- **Tratamento de Grau Único ou Sem Vias**: Se houver apenas um grau cadastrado no local, a régua é expandida com margem de segurança de ±1 grau vizinho para garantir a usabilidade do `RangeSlider` no Flutter.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capability introduzida. -->

### Modified Capabilities
- `exploracao-setores-escaladas`: Atualiza os requisitos do painel de filtros para exigir área de toque integral na barra de controles externa e régua adaptativa de grau baseada na amplitude das escaladas do pico/setor.

## Impact

- `frontend/lib/widgets/painel_filtros_indice.dart`: Atualização do layout da barra externa com `InkWell` expandido, e adaptação do `_buildSliderParaCategoria` para suportar régua adaptada com rótulos nas pontas.
- `frontend/lib/pages/pico_subpages/setores_page.dart`: Cálculo da amplitude de graus por categoria a partir de `_todasEscaladas` e repasse para o `PainelFiltrosIndice`.
- `frontend/lib/pages/grupo.dart`: Repasse da amplitude de graus no contexto do grupo para o `PainelFiltrosIndice`.
- `frontend/test/widgets/painel_filtros_indice_test.dart`: Novos testes de widget e de integração para toque integral e régua adaptativa.
