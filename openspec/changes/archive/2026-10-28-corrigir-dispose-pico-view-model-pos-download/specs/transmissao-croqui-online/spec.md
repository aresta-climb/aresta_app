## ADDED Requirements

### Requirement: Segurança de Ciclo de Vida em Operações Assíncronas do Guia do Pico
O gerenciador de estado da tela de detalhes do pico DEVE (MUST) rastrear seu descarte e abster-se de emitir notificações de ouvintes após ter sido descartado (`dispose`), mesmo quando operações assíncronas em andamento (download para armazenamento offline, exclusão do guia local ou atualização reativa do conjunto de dados) concluírem após a reconstrução da página ou navegação de saída.

#### Scenario: Conclusão de download offline após reconstrução reativa da página
- **WHEN** o usuário inicia o download offline de um croqui na página do pico
- **AND** o serviço de sincronização atualiza o conjunto de dados ativo antes do término da notificação de conclusão, provocando a reconstrução da página com um novo gerenciador de estado e o descarte da instância anterior
- **THEN** a operação de download conclui com sucesso retornando `true`
- **AND** a instância descartada NÃO DEVE invocar `notifyListeners()` nem lançar `FlutterError`
- **AND** a interface atualizada reflete o estado salvo offline e exibe a `SnackBar` de confirmação.

#### Scenario: Conclusão de download em segundo plano após optar por Salvar e Sair no Guardião de Saída
- **WHEN** o usuário aciona o retorno a partir de um croqui online, escolhe salvar no modal de confirmação de saída e a página é desmontada imediatamente
- **AND** o download em segundo plano finaliza após o descarte do gerenciador de estado da página
- **THEN** o download conclui normalmente sem lançar exceção de uso de `ChangeNotifier` descartado.

#### Scenario: Exclusão de guia concluída após descarte do gerenciador de estado
- **WHEN** o usuário inicia a exclusão do guia offline e o gerenciador de estado da página é descartado antes do retorno da remoção no repositório
- **THEN** a operação finaliza sem invocar `notifyListeners()` na instância descartada.
