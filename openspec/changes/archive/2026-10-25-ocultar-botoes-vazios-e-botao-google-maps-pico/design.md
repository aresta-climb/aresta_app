# Design

## Context

Veja `proposal.md` para a motivação completa e `specs/` para os requisitos formais. Atualmente:
- `PicoDetailsPage` (`frontend/lib/pages/pico.dart`) renderiza os cards `Explorar Local`, `Regras e recomendações` e `Comunidade` de forma fixa, verificando apenas `_viewModel.creditos.isNotEmpty` para os cards de créditos.
- `PicoCategorizedData` (`frontend/lib/utils/categorizacao_pico.dart`) classifica os botões textuais (`Croqui.botoes`) em listas por categoria, mas não expõe métodos agregadores para saber se `ExplorarLocalPage` ou `ComunidadePicoPage` terão conteúdo a exibir, nem resolve a URL do Google Maps do `Pico`.
- `SetoresPage` (`frontend/lib/pages/pico_subpages/setores_page.dart`) exibe sempre a mensagem `'Nenhum setor encontrado com os filtros selecionados.'` quando `_obterSetoresOuGruposOrdenados()` está vazio, mesmo quando `widget.pico.setoresOuGrupos.isEmpty`.

## Goals / Non-Goals

**Goals:**
- Garantir que nenhum card no Hub do Pico (`PicoDetailsPage`) leve o usuário a uma tela completamente vazia (`ExplorarLocalPage` ou `ComunidadePicoPage`).
- Fornecer resolução determinística e testável da URL do Google Maps a partir de `Pico.urlGoogleMaps` com fallback automático para `Pico.localizacao` (coordenadas em `E7`).
- Posicionar o botão único do Google Maps na `ExplorarLocalPage` imediatamente abaixo da seção `"Como chegar"`.
- Diferenciar na `SetoresPage` o estado vazio estrutural do pico (`pico.setoresOuGrupos.isEmpty`) do estado vazio resultante de filtros ativos.
- Manter 100% de cobertura comportamental e espelhamento 1:1 de testes conforme o `AGENTS.md`.

**Non-Goals:**
- Alterar o schema Protobuf (`croqui.proto`), pois os campos `url_google_maps` e `localizacao` já existem em `Pico`.
- Ocultar os cards `"Setores & Escaladas"` ou `"Regras e recomendações"` do Hub do Pico (ambos permanecem sempre visíveis com mensagens de fallback adequadas).

## Decisions

### 1. Resolução Centralizada da URL do Google Maps e Verificadores de Conteúdo em `categorizacao_pico.dart`
- **Decisão**: Adicionar em `PicoCategorizedData` (ou funções puras coesas em `categorizacao_pico.dart`, consumidas por `PicoViewModel`, `ExplorarLocalPage` e `ComunidadePicoPage`):
  - `String? resolverUrlGoogleMapsPico(Pico pico)`:
    1. Se `pico.urlGoogleMaps.trim().isNotEmpty`, retorna `pico.urlGoogleMaps.trim()`.
    2. Caso contrário, se `pico.hasLocalizacao()` e `(pico.localizacao.latitude != 0 || pico.localizacao.longitude != 0)`, converte `lat = pico.localizacao.latitude / 10000000.0` e `lon = pico.localizacao.longitude / 10000000.0` e retorna `'https://www.google.com/maps/search/?api=1&query=$lat,$lon'`.
    3. Caso contrário, retorna `null`.
  - `bool temConteudoExplorarLocal(Pico pico)`: retorna `true` se `capa.isNotEmpty || introducao.isNotEmpty || sobre.isNotEmpty || pico.descricao.isNotEmpty || comoChegar.isNotEmpty || resolverUrlGoogleMapsPico(pico) != null || outros.isNotEmpty`.
  - `bool temConteudoComunidade(Pico pico)`: retorna `true` se `comunidadeInfo.isNotEmpty || (pico.nomeAssociacao.isNotEmpty && pico.urlFiliacaoAssociacao.isNotEmpty) || comunidadeParceiros.isNotEmpty || comunidadeComercio.isNotEmpty`.
- **Alternativas consideradas**: Calcular essas condições inline dentro de `PicoDetailsPage`. Rejeitado para respeitar a separação MVVM (`AGENTS.md` II) e garantir que a regra de visibilidade no Hub e a renderização nas subpáginas nunca divirjam.

### 2. Card Único do Google Maps em `ExplorarLocalPage`
- **Decisão**: Em `ExplorarLocalPage`, logo após o bloco `if (categories.comoChegar.isNotEmpty) ...` e antes de `if (categories.outros.isNotEmpty)`, verificar se `urlGoogleMaps != null`. Quando presente, renderizar um `PicoMenuCard` com:
  - Título: `'Abrir no Google Maps'`
  - Subtítulo: `'Ver localização e traçar rota até o pico.'`
  - Ícone: `Icons.map_outlined`
  - Ação: acionar `abrirLinkExterno(urlGoogleMaps, 'Google Maps')` (de `comunidade_functions.dart`), que já registra telemetria (`TelemetryService.instance.logLinkExterno`) e trata erros via `AppLogger` com `LaunchMode.externalApplication`.
- **Alternativas consideradas**: Mostrar dois botões separados quando houver `url_google_maps` e `localizacao`. Rejeitado conforme alinhado com o usuário: `url_google_maps` é a fonte primária e `localizacao` atua exclusivamente como fallback.

### 3. Estado Vazio de Backup em `SetoresPage`
- **Decisão**: Em `_buildSliverSetores` de `SetoresPage`, quando `setoresOuGruposOrdenados.isEmpty`, verificar `widget.pico.setoresOuGrupos.isEmpty`:
  - Se `widget.pico.setoresOuGrupos.isEmpty` for `true`, exibir ícone `Icons.landscape_outlined` e a mensagem `'Nenhum setor ou escalada cadastrado para este local no momento.'`.
  - Caso contrário (há setores no pico, mas os filtros ativos ocultaram todos), manter o ícone `Icons.filter_alt_off` e a mensagem `'Nenhum setor encontrado com os filtros selecionados.'`.

## Risks / Trade-offs

- **[Risk] Coordenadas `(0, 0)` padrão do Protobuf3** → Mitigação: Verificar explicitamente `pico.hasLocalizacao() && (pico.localizacao.latitude != 0 || pico.localizacao.longitude != 0)` antes de gerar a URL de fallback do Google Maps.
- **[Risk] Divergência futura entre condição de exibição do card no Hub e itens renderizados na subpágina** → Mitigação: Centralizar `temConteudoExplorarLocal(pico)` e `temConteudoComunidade(pico)` em `PicoCategorizedData` e expô-los via `PicoViewModel` (`temExplorarLocal` e `temComunidade`), cobrindo todos os ramos com testes unitários e de widget.
