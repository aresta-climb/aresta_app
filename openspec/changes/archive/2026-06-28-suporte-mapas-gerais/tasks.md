## 1. Atualizar UI do Pico para Renderizar Mapas Gerais

- [x] 1.1 Em `frontend/lib/view_functions/pico_functions.dart` (`buildPicoBody`), adicionar suporte para ler `pico.mapasGerais.conteudo.mapas`.
- [x] 1.2 Renderizar um `_buildHeader('Mapas Gerais')` logo acima da listagem de setores, apenas se a lista de mapas gerais não estiver vazia.
- [x] 1.3 Mapear cada mapa geral e renderizar o componente `MapaThumbnail` (sem passar `setorContext` ou `grupoContext`).
- [x] 1.4 Associar a variável legada `_mapaKey` (usada pelo `scrollToMapaGeral`) ao container dos novos mapas gerais para que o scroll automático continue funcionando perfeitamente.

## 2. Limpeza de Código Legado

- [x] 2.1 Em `frontend/lib/view_functions/pico_functions.dart` (`buildPicoBody`), remover a lógica antiga que filtrava e extraía `capaBotoes` (ex: `getSecaoBotoes`, `getCapaBotoes` caso não sejam usados em outros lugares) e a exibição de botões markdown de capa com mapa.
- [x] 2.2 Excluir o arquivo `frontend/lib/pages/mapa_geral_pico.dart`.
- [x] 2.3 Excluir o arquivo `frontend/lib/view_functions/mapa_geral_pico_functions.dart`.
- [x] 2.4 Remover qualquer referência/import associado aos arquivos deletados.

## 3. Melhoria na Navegação (Modais do Mapa Interativo)

- [x] 3.1 Em `frontend/lib/pages/mapa_interativo.dart`, localizar a função `_buildGrupoCard`.
- [x] 3.2 Substituir a chamada legada `AppNav.back(context)` pela navegação correta `AppNav.toGrupo(context, grupo: grupo)`.
