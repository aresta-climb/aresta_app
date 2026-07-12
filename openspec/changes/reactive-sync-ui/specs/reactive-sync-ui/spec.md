## ADDED Requirements

### Requirement: Sincronização em Segundo Plano Não-Bloqueante
O sistema NÃO DEVE bloquear ou desativar a interação do usuário nos cartões de croqui (picos) se o croqui em questão já estiver baixado localmente, mesmo durante um processo ativo de download e sincronização em background. O usuário DEVE poder clicar e abrir a versão antiga do croqui enquanto a atualização acontece. A documentação (docstrings) para esses isolados DEVE ser abrangente e clara.

#### Scenario: Usuário clica em um croqui sendo atualizado
- **WHEN** um croqui recebe uma atualização de arquivos `.tmp` em background (o seu ID está na lista de `picos_baixando` / `downloadingCrags`) e já está baixado no sistema
- **THEN** o cartão correspondente na UI DEVE permanecer visualmente ativo e interativo
- **AND** tocar nele DEVE abrir a interface do croqui normalmente com base nos dados locais vigentes.

### Requirement: Limpeza Obrigatória de Estado Pós-Isolate
O sistema DEVE garantir a remoção imaculada do ID do croqui do dicionário/estado de progresso assim que a comunicação do Isolate for encerrada, independentemente de erros ou interrupções, suportado por 100% de cobertura de testes.

#### Scenario: Download de Isolate Concluído
- **WHEN** o isolate em segundo plano encerra e envia o objeto `DownloadIsolateResult` para a Main Isolate
- **THEN** o dicionário reativo que mapeia o progresso do pico DEVE, via um bloco de encerramento seguro (`finally` ou análogo lógico), obrigatoriamente eliminar o registro do progresso deste ID.

### Requirement: Recarregamento Atômico Reativo (Testes de Integração Obrigatórios)
O sistema DEVE proteger a engine de renderização de leitura contra trocas imprevistas de arquivos nativos em disco enquanto uma tela dependente estiver ativa, validado por amplos **Testes de Integração**. Se o usuário estiver ativamente navegando pelo mapa e o download da nova versão for finalizado e aprovado, o commit final da sincronização DEVE aguardar e solicitar a recarga explícita. 

#### Scenario: Atualização concluída com Croqui aberto em tela (Alvo de Integration Test)
- **WHEN** o download de fundo atinge 100% dos `.tmp`
- **AND** o usuário abre a tela deste respectivo croqui (ativando `pico_aberto_id`) DURANTE a sincronização e lá permanece até o término do download
- **THEN** o processo `applyAtomicFileUpdates` DEVE ser bloqueado e emitido um evento de pendência para a interface
- **AND** a interface de usuário em visualização DEVE lançar um Diálogo imperativo alertando da atualização pronta
- **AND** quando o usuário clicar na ação positiva "Recarregar", o commit atrasado é deferido e a navegação da página invoca o reload contextual completo.

#### Scenario: Atualização concluída silenciosamente (Alvo de Integration Test)
- **WHEN** o download atinge 100% dos seus `.tmp` em segundo plano
- **AND** o usuário navegou na Home mas não entrou no croqui sendo atualizado (`pico_aberto_id` atesta nulo ou aponta para um outro croqui qualquer)
- **THEN** a operação rotineira de substituição atômica no file system DEVE prosseguir invisivelmente no fundo, atualizando todos os dados do croqui alvo
- **AND** nenhum alerta, popup ou notificação intrusiva deve impedir a navegação do usuário na Home.
