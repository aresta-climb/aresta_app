## MODIFIED Requirements

### Requirement: Navegação Direta por UID a partir da Busca Global
Ao tocar em qualquer resultado da Busca Global (pico, grupo, setor ou escalada), o sistema DEVE (MUST) bloquear imediatamente toques subsequentes e exibir um feedback visual modal bloqueante de carregamento (`barrierDismissible: false`) enquanto resolve e carrega a entidade através do seu `uid` e `id_slug` (utilizando o `LocalizadorDestinoUid` / carregamento sob demanda quando o croqui não estiver baixado localmente), fechando o modal de carregamento antes de navegar para o destino ou de exibir uma única instância do modal *bottom sheet* de ausência de conexão (`ModalCroquiSemConexao`). Caso o croqui não esteja salvo em `/downloads` nem no cache volátil `/temp_cache` e o dispositivo esteja sem conexão à internet, o sistema DEVE apresentar o modal *bottom sheet* contextual informando os dados da entidade e do croqui hospedeiro com a opção **"Tentar novamente"**, que ao restabelecer a conexão fecha o modal e navega diretamente para a entidade selecionada.

#### Scenario: Toque em via de um croqui não baixado na Busca Global
- **WHEN** o usuário toca em uma escalada nos resultados da Busca Global cujo croqui ainda não está salvo localmente e há conexão com a internet
- **THEN** o aplicativo exibe imediatamente o modal bloqueante de carregamento, carrega o croqui sob demanda na sessão online, fecha o modal de carregamento e abre diretamente a tela de detalhes daquela escalada com toda a sua hierarquia (`PicoNode -> SetorNode -> ViaNode`).

#### Scenario: Bloqueio de múltiplos toques concorrentes durante o carregamento na Busca Global
- **WHEN** o usuário toca repetidamente em um resultado da Busca Global enquanto a resolução ou requisição de rede ainda está em andamento
- **THEN** o modal bloqueante e a trava de concorrência impedem a abertura de resoluções duplicadas, garantindo que no máximo uma navegação ou um único modal de falta de conexão seja exibido.

#### Scenario: Toque em entidade de croqui presente no cache volátil sem internet
- **WHEN** o usuário está sem internet e toca em uma via, setor, grupo ou pico na Busca Global cujo croqui não está em `/downloads`, mas possui o `compilado.binarypb.<sha256>` salvo em `/temp_cache`
- **THEN** o aplicativo carrega o croqui a partir do `/temp_cache`, fecha o indicador de carregamento e abre diretamente a página da entidade sem exibir modal de falta de conexão.

#### Scenario: Toque em via, setor, grupo ou pico não baixado na Busca Global sem internet
- **WHEN** o usuário está sem internet e toca em um resultado da Busca Global cujo croqui não está salvo em `/downloads` nem em `/temp_cache`
- **THEN** o aplicativo fecha o modal de carregamento e exibe uma única instância do modal *bottom sheet* informando o nome da entidade, o croqui ao qual pertence e que o dispositivo está sem conexão, permitindo tocar em **"Tentar novamente"** para abrir o destino quando a conexão voltar.
