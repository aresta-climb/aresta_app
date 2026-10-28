# Spec Delta

## MODIFIED Requirements

### Requirement: Expurgo de instâncias de sessão online obsoletas
O sistema DEVE (MUST) remover da sessão online em memória RAM qualquer croqui cujo checksum SHA-256 no índice mestre tenha divergido da versão carregada quando o pico não estiver aberto na tela. Caso o pico com checksum divergente esteja atualmente aberto em visualização online (`picoAbertoId`), a sincronização em segundo plano DEVE (MUST) baixar o novo `.binarypb`, atualizar a sessão online e o cache volátil, notificar a reconstrução reativa da tela e exibir aviso visual informando que o guia foi atualizado.

#### Scenario: Croqui online desatualizado após sincronização
- **WHEN** um novo índice mestre for recebido com checksum SHA-256 diferente para um pico que possui sessão em memória e o usuário está na tela inicial
- **THEN** o sistema DEVE remover a sessão antiga da memória RAM para garantir que a próxima abertura carregue o binário atualizado

#### Scenario: Pico atualmente em visualização durante a sincronização
- **WHEN** a sincronização em segundo plano detectar versão mais recente de um pico que está atualmente aberto na tela em sessão online ou carregado do `temp_cache` (`picoAbertoId`)
- **THEN** o sistema DEVE baixar o `.binarypb` atualizado em segundo plano, atualizar a sessão online e re-renderizar a página reativamente exibindo o aviso de que o guia foi atualizado
