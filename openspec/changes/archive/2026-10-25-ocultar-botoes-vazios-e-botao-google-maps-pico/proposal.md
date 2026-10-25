# Proposal

## Why

Atualmente, a página principal do pico (`PicoDetailsPage`) exibe incondicionalmente os cards de navegação **"Explorar Local"** e **"Comunidade"**, mesmo quando o croqui não possui nenhuma informação associada a essas seções, levando o usuário a telas completamente vazias (como reportado na issue `aresta_db#67` para `br_mg_caete_pedra_filha`). Além disso, o campo `url_google_maps` e as coordenadas `localizacao` do pico não estão sendo utilizados para disponibilizar um atalho de navegação para o Google Maps dentro de **"Explorar Local"**, e a tela **"Setores & Escaladas"** exibe uma mensagem de filtro vazio mesmo quando o pico não possui setores cadastrados na base.

## What Changes

- **Visibilidade Condicional no Hub do Pico (`PicoDetailsPage` e `PicoViewModel`)**:
  - Ocultar o card **"Explorar Local"** quando não houver nenhuma seção textual de exploração (`capa`, `introducao`, `sobre`, `pico.descricao`, `comoChegar`, `outros`) e também não houver link ou coordenadas para o Google Maps.
  - Ocultar o card **"Comunidade"** quando não houver nenhuma informação de comunidade cadastrada (`comunidadeInfo`, associação local com nome e URL de filiação, `comunidadeParceiros` ou `comunidadeComercio`).
  - Manter o card **"Regras e recomendações"** sempre visível, preservando a mensagem educativa padrão no modal quando não houver regras específicas no croqui.
- **Botão Automático do Google Maps em "Explorar Local" (`ExplorarLocalPage`)**:
  - Exibir um único card de ação para abrir a localização no Google Maps logo abaixo da seção **"Como chegar"** sempre que o pico possuir `url_google_maps` ou coordenadas válidas em `localizacao`.
  - Priorizar `pico.urlGoogleMaps` quando preenchido e utilizar as coordenadas `pico.localizacao` (convertidas do padrão `E7`) como fallback automático para gerar a URL universal do Google Maps (`https://www.google.com/maps/search/?api=1&query=<lat>,<lon>`).
- **Mensagem de Backup na Exploração de Setores & Escaladas (`SetoresPage`)**:
  - Exibir uma mensagem de estado vazio amigável e específica quando o pico não possuir nenhum setor ou grupo cadastrado (`pico.setoresOuGrupos.isEmpty`), diferenciando-a da mensagem de quando há setores no pico mas nenhum corresponde aos filtros selecionados.

## Capabilities

### New Capabilities
- `subpaginas-hub-pico`: Regras de visibilidade condicional dos cards de subpáginas no Hub do Pico (`Explorar Local`, `Comunidade`, `Regras e recomendações`, `Créditos`) e resolução/exibição do atalho automático para o Google Maps na página `ExplorarLocalPage`.

### Modified Capabilities
- `exploracao-setores-escaladas`: Inclusão do comportamento de mensagem de backup (estado vazio) na página `SetoresPage` quando o pico não possuir setores ou escaladas cadastrados, distinguindo-o do estado vazio por filtragem ativa.

## Impact

- **Modelos de Visão e Utilitários**:
  - `frontend/lib/utils/categorizacao_pico.dart` (e `frontend/test/utils/categorizacao_pico_test.dart`): resolução da URL do Google Maps (`url_google_maps` com fallback para `localizacao` em `E7`) e métodos auxiliares de verificação de conteúdo para `Explorar Local` e `Comunidade`.
  - `frontend/lib/view/view_models/pico_view_model.dart` (e `frontend/test/view/view_models/pico_view_model_test.dart`): exposição das propriedades reativas `temExplorarLocal`, `temComunidade` e `urlGoogleMaps`.
- **Páginas de Interface (UI)**:
  - `frontend/lib/pages/pico.dart` (e `frontend/test/pages/pico_test.dart`): renderização condicional dos cards `Explorar Local` e `Comunidade`.
  - `frontend/lib/pages/pico_subpages/explorar_local_page.dart` (e `frontend/test/pages/pico_subpages/explorar_local_page_test.dart`): inclusão do card de abertura do Google Maps posicionado logo abaixo de `Como chegar`.
  - `frontend/lib/pages/pico_subpages/setores_page.dart` (e `frontend/test/pages/pico_subpages/setores_page_test.dart`): tratamento visual diferenciado para pico sem setores cadastrados versus busca filtrada sem resultados.
- **Documentação**:
  - Atualização de `frontend/lib/pages/pico_subpages/README.md`.
