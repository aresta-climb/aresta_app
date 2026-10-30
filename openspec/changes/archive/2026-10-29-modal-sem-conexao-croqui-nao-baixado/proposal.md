# Proposal

## Why

Quando o usuário tenta abrir um Deep Link (no *Cold Start* ou *Warm Start*) ou toca em um resultado da Busca Global apontando para uma via, setor, grupo ou pico cujo `compilado.binarypb` não está salvo em `/downloads` nem no cache volátil `/temp_cache` e o dispositivo está sem conexão à internet, o `LocalizadorDestinoUid` descobre a entidade no banco SQLite local (`catalogo.db`), falha no download do croqui e descarta os metadados encontrados retornando apenas `null`. Como consequência, o `DeepLinkNavigatorService` exibe um erro genérico com o código NanoID bruto (registrando equivocadamente `uid_nao_encontrado_no_acervo` na telemetria) e a Busca Global falha silenciosamente sem dar nenhum feedback ao usuário, embora o aplicativo já possua localmente no `catalogo.db` e no `indice.binarypb` todos os dados sobre qual é a via/setor/grupo e a qual croqui pertence.

## What Changes

- **Consulta enriquecida por UID no `RepositorioCatalogo`**: Adição do método `obterItemPorUid(String uid)` em `RepositorioCatalogo` para recuperar em $O(1)$ os metadados enriquecidos (`ItemCatalogoBusca`: nome da entidade, categoria `escalada`/`setor`/`grupo`/`pico`, graduação, modalidade, nome do setor pai, nome do grupo pai, nome do pico, `idSlug`, cidade e estado) diretamente do `catalogo.db` local (com fallback no índice em memória em `LocalizadorDestinoUid`).
- **Diagnóstico estruturado no `LocalizadorDestinoUid`**: Evolução do `LocalizadorDestinoUid` com o método `diagnosticarOuLocalizar(String uid, {bool abrirMapa = false})` (mantendo compatibilidade em `localizar`), distinguindo três resultados claros:
  1. **Destino localizado e pronto para navegação** (`DestinoUidLocalizado`, quando o `compilado.binarypb` está em memória, em `/downloads`, no `/temp_cache` ou foi baixado da CDN com sucesso);
  2. **Entidade identificada localmente, porém croqui indisponível sem conexão** (`ItemCatalogoBusca` preenchido com os dados da via/setor/grupo/pico e do croqui hospedeiro quando `getCroqui` retorna `null` por falta de rede);
  3. **UID realmente inexistente no acervo** (quando não consta nem no `catalogo.db`/índice local nem após tentativa de sincronização).
- **Novo componente `ModalCroquiSemConexao` (Bottom Sheet)**: Criação de um modal *bottom sheet* reutilizável (`lib/widgets/bottom_sheets/modal_croqui_sem_conexao.dart` e `test/widgets/bottom_sheets/modal_croqui_sem_conexao_test.dart` espelhado 1:1) seguindo a identidade visual do app (`deepBasalt`, alça `graniteEdge`, ícone de nuvem sem sinal), informando claramente qual via/setor/grupo/pico o usuário tentou abrir, a qual croqui pertence (nome e cidade/UF) e que o croqui ainda não está salvo offline, com botão primário **"Tentar novamente"** (que tenta carregar o destino *in-place* com estado de loading e, ao obter conexão, fecha o modal e navega diretamente para o destino; ou informa se ainda estiver sem conexão sem fechar o modal) e botão **"Fechar"**.
- **Integração no Deep Link (*Cold Start* e *Warm Start*) e na Busca Global**:
  - Em `DeepLinkNavigatorService`, `inicializacao_app.dart` e `TreeNavigationWrapper`: quando um link falhar por falta de conexão para um croqui conhecido no catálogo, registra `AppLogger.instance.logAviso`, envia telemetria precisa (`motivoErro: 'croqui_offline_sem_conexao'`, `idCroqui: item.idSlug`, `destino: item.tipo`) e apresenta o `ModalCroquiSemConexao` (inclusive após a saída da splash no *Cold Start*). Quando o UID realmente não existir no acervo, registra `AppLogger.instance.logAviso` e mantém o `SnackBar` de código não encontrado.
  - Em `GlobalSearch` (`busca_global.dart`): quando o usuário tocar em uma via, setor, grupo ou pico não baixado estando sem internet (e ausente no `/temp_cache`), apresenta o mesmo `ModalCroquiSemConexao` com ação **"Tentar novamente"** funcional.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capability isolada; os requisitos expandem capabilities existentes. -->

### Modified Capabilities
- `qr-deep-linking`: Atualiza o tratamento de carregamento offline e telemetria para distinguir croquis não baixados sem conexão (exibindo o Bottom Sheet contextual `ModalCroquiSemConexao` com os dados da entidade e do croqui do `catalogo.db` e botão `"Tentar novamente"`) de UIDs inexistentes (mantendo aviso e registrando `logAviso`).
- `busca-global-catalogo`: Atualiza a navegação direta por UID na Busca Global para exibir o `ModalCroquiSemConexao` quando o usuário tocar em um item cujo croqui não esteja salvo em `/downloads` nem em `/temp_cache` e o dispositivo estiver sem internet.

## Impact

- **Banco SQLite do Catálogo (`frontend/lib/services/catalogo/repositorio_catalogo.dart`)**: Novo método `obterItemPorUid(String uid)` consultando `catalogo_aresta` e `catalogo_croquis`.
- **Resolução e Navegação de Deep Links (`frontend/lib/navigation/localizador_destino_uid.dart`, `frontend/lib/navigation/servico_navegacao_deep_link.dart`, `frontend/lib/services/inicializacao_app.dart`, `frontend/lib/navigation/wrapper_navegacao_arvore.dart`)**: Propagação do diagnóstico de entidade offline conhecida e exibição do `ModalCroquiSemConexao` tanto em *Cold Start* quanto em *Warm Start*.
- **UI e Busca Global (`frontend/lib/widgets/bottom_sheets/modal_croqui_sem_conexao.dart`, `frontend/lib/widgets/busca_global.dart`)**: Novo componente modular de Bottom Sheet e integração na Busca Global.
- **Testes Automatizados**: Novos testes espelhados 1:1 (`modal_croqui_sem_conexao_test.dart`) e atualização dos testes unitários e de widget de catálogo, localizador de UID, deep links, inicialização, wrapper de navegação e busca global com 100% de cobertura comportamental.
