## REMOVED Requirements

### Requirement: Escalonamento de Marcadores por Faixas de Zoom
**Reason**: Substituído pelo motor vetorial de 4 LODs contínuos da nova aba unificada `Explorar` (`exploracao-globo-e-clima`), após remoção integral de `MapaGlobalPage`.
**Migration**: Os marcadores geográficos globais passam a seguir as regras dos `LOD 0` a `LOD 3` em `exploracao-globo-e-clima`.

### Requirement: Resolução Resiliente de Marcadores no Mapa Global
**Reason**: A rota isolada `MapaGlobalPage` (`MapaGlobalNode` / `AppNav.toMapaGlobal`) foi unificada diretamente dentro da aba `Explorar`.
**Migration**: A aba `Explorar` consome diretamente `BrowseViewModel` sobre o catálogo ativo.

### Requirement: Consistência de Ações e Feedback na Barra Superior
**Reason**: A barra de aplicativo dedicada da antiga `MapaGlobalPage` deixa de existir com a remoção da tela.
**Migration**: A aba `Explorar` utiliza a barra flutuante unificada de busca e filtros.
