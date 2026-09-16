## MODIFIED Requirements

### Requirement: Polling Periódico com ETag para Atualizações Online
Enquanto o usuário estiver ativamente navegando nas telas de um croqui em modo online (não baixado), o sistema DEVE (MUST) executar verificações periódicas leves (a cada 30 a 60 segundos) enviando o cabeçalho `If-None-Match: <etag>` para a URL do `.binarypb`. Caso o servidor retorne status `304 Not Modified`, nenhum dado de corpo deve ser trafegado. Caso o servidor retorne status `200 OK`, o sistema DEVE consumir o buffer retornado no corpo da resposta para desserializar a nova instância de `Croqui`, atualizar o `GerenciadorSessaoOnline`, persistir a cópia atualizada no cache volátil (`/temp_cache`), reindexar os hashes SHA-256 de arquivos externos no `DatasetRepository` e emitir notificação para atualização da interface. Se a atualização ocorrer fora do modo experimental, a interface DEVE exibir uma notificação visual informando que o croqui foi atualizado. Se a atualização ocorrer em modo experimental, a recarga da tela DEVE ser imediata e silenciosa com pulso visual no banner. Em caso de perda de conexão com a internet ou timeout durante a verificação de ETag, o sistema DEVE tratar o evento como operacional esperado emitindo apenas `logAviso` (breadcrumb), abstendo-se de emitir `logError` para o Crashlytics. O timer de polling DEVE ser cancelado assim que o usuário sair das telas do referido pico.

#### Scenario: Nenhuma modificação no servidor remoto (304)
- **WHEN** o timer de polling dispara enquanto o croqui online está aberto
- **AND** o arquivo no servidor remoto não sofreu alterações
- **THEN** a requisição HTTP retorna `304 Not Modified`
- **AND** a UI permanece inalterada sem re-renderizações ou consumo de banda.

#### Scenario: Atualização detectada no servidor remoto fora do modo experimental (200)
- **WHEN** o timer de polling dispara fora do modo experimental e uma nova versão do `.binarypb` foi publicada no servidor
- **THEN** a requisição HTTP retorna status `200 OK` com os novos bytes e novo ETag
- **AND** o sistema desserializa o novo `Croqui`, atualiza o `GerenciadorSessaoOnline`, reindexa as mídias no repositório e grava no cache volátil
- **AND** a interface recarrega os dados e exibe um aviso visual amigável informando que o guia do pico foi atualizado.

#### Scenario: Atualização detectada no servidor remoto em modo experimental (200)
- **WHEN** o timer de polling dispara durante o modo experimental ativo e uma nova versão do `.binarypb` é recebida
- **THEN** o sistema atualiza o `GerenciadorSessaoOnline`, reindexa as mídias e atualiza a tela imediatamente sem exibir popups intrusivos
- **AND** o banner de modo experimental emite um pulso luminoso de recarga.

#### Scenario: Falha de conexão transitória durante a verificação de ETag
- **WHEN** o timer de polling dispara enquanto o dispositivo está em modo avião ou sem conectividade com a internet
- **THEN** o `ServicoCroquiOnline` DEVE classificar o erro via `AppLogger.isFalhaConexaoOuTimeout`
- **AND** registrar o aviso via `AppLogger.instance.logAviso`
- **AND** NÃO DEVE invocar `logError` para o Crashlytics.
