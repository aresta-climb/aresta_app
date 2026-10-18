# Tasks

## 1. Dependências, Preload e Repositório SQLite do Catálogo (`catalogo.db`)

- [x] 1.1 Adicionar `sqflite`, `share_plus` (em `dependencies`) e `sqflite_common_ffi` (em `dev_dependencies`) no `frontend/pubspec.yaml`, copiar o `catalogo.db` inicial para `frontend/assets/preload/catalogo.db` e verificar que `flutter pub get` conclui sem erros.
- [x] 1.2 Atualizar `frontend/tool/sync_preload.dart` e `frontend/lib/services/dataset/armazenamento/extrator_assets_preload.dart` (com seus respectivos testes 1:1 em `test/tool/sync_preload_test.dart` e `test/services/dataset/armazenamento/extrator_assets_preload_test.dart`) para baixar e descompactar `catalogo.db` junto ao `indice.binarypb`, verificando a aprovação com `flutter test`.
- [x] 1.3 Implementar `frontend/lib/services/catalogo/repositorio_catalogo.dart` seguindo TDD com `frontend/test/services/catalogo/repositorio_catalogo_test.dart` (usando `sqflite_common_ffi` em diretórios temporários reais), cobrindo leitura de `versao_catalogo` em `catalogo_meta`, aplicação atômica de `RespostaSyncCatalogo` (`apply_delta` com `batch` de `deletes`, `upserts` e `catalogo_meta`), substituição de arquivo em `full_download`, resolução de `id_slug` por `uid` e listagem relacional (`LEFT JOIN`) para a Busca Global, verificando 100% de cobertura no arquivo.

## 2. Sincronização Assíncrona do Catálogo (`catalogo.arestaclimb.com/sync`)

- [x] 2.1 Adicionar em `frontend/lib/services/http/sync_rede.dart` (e testar em `frontend/test/services/http/sync_rede_test.dart` com servidor HTTP local) os métodos para consultar `GET /sync?versao_local=...&versao_destino=...` (retornando `RespostaSyncCatalogo`) e baixar `$baseUrl/catalogo.db` em caso de `full_download`, verificando 100% de cobertura.
- [x] 2.2 Integrar a sincronização assíncrona e não-bloqueante do `catalogo.db` em `frontend/lib/services/http/sync_service.dart` e `frontend/lib/services/repositorio_dataset.dart` (tanto em `IndiceUpdated` quanto na validação de `versao_catalogo` em `IndiceUnchanged`), garantindo com testes em `frontend/test/services/http/sync_service_test.dart` que o catálogo é atualizado por delta ou full download sem bloquear a atualização de croquis.

## 3. Resolução Universal de UIDs e Protocolo Compacto `aresta.cc` (35 chars)

- [x] 3.1 Atualizar `frontend/lib/navigation/analisador_rotas_deep_link.dart` e `frontend/test/navigation/analisador_rotas_deep_link_test.dart` para suportar os prefixos compactos de `aresta.cc` (`/<uid>`, `/m/<uid>`, `/s/<uid>`, `/sm/<uid>`, `/ms/<uid>`, `/q/<uid>`, `/qm/<uid>`, `/mq/<uid>`), mapear estaticamente as 8 URLs de placas físicas legadas de `app.arestaclimb.com/br_mg_igarape_pedra_grande/...` para seus UIDs e remover o suporte a slugs arbitrários legados, verificando 100% de cobertura.
- [x] 3.2 Evoluir `frontend/lib/navigation/localizador_destino_uid.dart` e `frontend/test/navigation/localizador_destino_uid_test.dart` para consultar o `RepositorioCatalogo` quando o `uid` pertencer a um croqui ainda não carregado em memória (carregando-o sob demanda via cache local ou `servicoCroquiOnline`) e para construir o `MapasCarrosselNode` focado na entidade quando `abrirMapa: true` (com fallback gracioso para o nó principal caso não haja mapa), verificando 100% de cobertura.
- [x] 3.3 Simplificar `frontend/lib/navigation/servico_navegacao_deep_link.dart` e atualizar `frontend/test/navigation/servico_navegacao_deep_link_test.dart` removendo `_processarRotaHierarquica` e unificando o fluxo de navegação exclusivamente por UID com envio de `origem_link` (`'qrcode'`, `'compartilhamento'`), `abrir_mapa` e parâmetros UTM para `TelemetryService.logDeepLinkAberto`, verificando 100% de cobertura.

## 4. Busca Global via `catalogo.db` com `Fuzzy`, Prioridade Offline e Badge

- [x] 4.1 Refatorar `frontend/lib/widgets/busca_global.dart` e `frontend/test/widgets/busca_global_test.dart` para carregar todas as entidades e picos a partir do `RepositorioCatalogo` (mesclando com croquis locais/sessão quando aplicável), manter a busca aproximada `Fuzzy`, ordenar priorizando itens com `isDownloaded == true`, renderizar a badge visual **`Offline`** e navegar via `LocalizadorDestinoUid` ao tocar em qualquer resultado, verificando 100% de cobertura.

## 5. Botões de Compartilhamento Nativo (`share_plus`) e Telemetria

- [x] 5.1 Implementar `frontend/lib/services/compartilhamento/servico_compartilhamento.dart` (e seu teste espelhado `frontend/test/services/compartilhamento/servico_compartilhamento_test.dart`) formatando mensagens amigáveis + links `https://aresta.cc/s/<uid>` (páginas) e `https://aresta.cc/sm/<uid>` (mapas) e registrando telemetria em `TelemetryService` (`frontend/lib/services/firebase/telemetria.dart` e `telemetria_test.dart`), verificando 100% de cobertura.
- [x] 5.2 Adicionar os botões de compartilhamento na AppBar de `frontend/lib/view/tela_pico.dart`, `frontend/lib/view/tela_grupo.dart`, `frontend/lib/view/tela_setor.dart`, `frontend/lib/view/tela_via.dart` e no `frontend/lib/widgets/mapa_interativo.dart`, atualizando os respectivos arquivos `_test.dart` espelhados e verificando 100% de cobertura.

## 6. Validação Final e Documentação

- [x] 6.1 Atualizar a documentação pertinente (`README.md` / comentários de arquitetura) e executar a suíte completa de testes e cobertura (`flutter analyze` e `flutter test --coverage`), confirmando zero avisos de lint, espelhamento 1:1 de arquivos de teste e 100% de cobertura nos módulos criados/modificados.
