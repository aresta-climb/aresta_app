# Proposal

## Why

Ao tocar em um resultado na Busca Global (`GlobalSearch`) cujo croqui precisa ser resolvido ou baixado sob demanda (especialmente em conexões móveis lentas ou quando o dispositivo está sem internet), a interface permanece sem feedback visual imediato e com a lista destravada enquanto a requisição ocorre em segundo plano. Isso induz o usuário a tocar repetidas vezes no item, disparando múltiplas resoluções concorrentes que empilham vários modais `ModalCroquiSemConexao` (exigindo fechá-los um por um), além de `DatasetRepository.getCroqui` disparar uma segunda requisição HTTP (`carregarCroquiRemoto`) mesmo quando a primeira requisição (`syncIndex`) já falhou por ausência de conexão.

## What Changes

- **Bloqueio de Toques Concorrentes e Modal/Overlay Intermediário de Carregamento na Busca Global (`GlobalSearch`)**:
  - Introduzir trava de concorrência (`_abrindoDestino`) em `GlobalSearch` para impedir cliques repetidos enquanto um destino está sendo resolvido.
  - Exibir imediatamente ao toque um diálogo/overlay modal bloqueante (`barrierDismissible: false`) com indicador de progresso e o nome do item sendo aberto (*"Abrindo `<nome>`..."*), recolhendo o teclado e bloqueando novas interações até a conclusão da resolução.
  - Fechar o overlay de carregamento de forma determinística antes de navegar para o destino ou de apresentar uma única instância do `ModalCroquiSemConexao`.
- **Curto-Circuito de Rede no Carregamento Sob Demanda (`DatasetRepository.getCroqui` e `LocalizadorDestinoUid`)**:
  - Quando a sincronização prévia do índice (`syncIndex()`) em `DatasetRepository.getCroqui` falhar por falta de conexão (`SyncStatus.offline`), abortar imediatamente retornando `null` sem disparar a segunda requisição HTTP (`servicoCroquiOnline.carregarCroquiRemoto`).
  - Em `LocalizadorDestinoUid.localizarComDiagnostico`, caso o `uid` não conste localmente e o `syncIndex()` resulte em `SyncStatus.offline`, encerrar imediatamente sem consultas redundantes.

## Capabilities

### New Capabilities

*(Nenhuma nova capability)*

### Modified Capabilities

- `busca-global-catalogo`: Atualiza o requisito de navegação direta por UID a partir da Busca Global para exigir bloqueio contra múltiplos toques e exibição imediata de feedback visual bloqueante de carregamento durante a resolução do destino.
- `transmissao-croqui-online`: Adiciona requisito de curto-circuito no carregamento sob demanda de `.binarypb` para não disparar a requisição do croqui remoto quando a sincronização prévia do índice já tiver falhado por ausência de conectividade (`SyncStatus.offline`).

## Impact

- **Frontend — Widgets (`lib/widgets/`)**:
  - `frontend/lib/widgets/busca_global.dart` e `frontend/test/widgets/busca_global_test.dart`: Trava `_abrindoDestino` e diálogo/overlay bloqueante durante `_abrirDestinoPorUid`.
- **Frontend — Serviços e Navegação (`lib/services/` e `lib/navigation/`)**:
  - `frontend/lib/services/repositorio_dataset.dart` e `frontend/test/services/repositorio_dataset_test.dart`: Curto-circuito após `syncIndex()` quando `syncStatus.value == SyncStatus.offline`.
  - `frontend/lib/navigation/localizador_destino_uid.dart` e `frontend/test/navigation/localizador_destino_uid_test.dart`: Curto-circuito quando `syncIndex()` terminar em `SyncStatus.offline`.
