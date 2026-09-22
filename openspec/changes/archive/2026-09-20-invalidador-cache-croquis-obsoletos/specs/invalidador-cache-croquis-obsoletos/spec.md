## Purpose

Garante que atualizações de catálogo e downloads de croquis invalidem imediatamente instâncias de Path e sessões online obsoletas em memória RAM, prevenindo inconsistências visuais e traçados vetoriais desalinhados.

## ADDED Requirements

### Requirement: Invalidação de cache de traçados gráficos na sincronização
O sistema DEVE (MUST) expurgar todos os caminhos nativos (Path) e traçados projetados de viewport mantidos em memória RAM sempre que a sincronização do catálogo e dos croquis for concluída com sucesso.

#### Scenario: Atualização de croquis com novos traçados vetoriais
- **WHEN** uma sincronização manual ou automática detectar novos binários de croqui e gravar as alterações em disco
- **THEN** o sistema DEVE invalidar o cache em memória de caminhos vetoriais para que a próxima renderização processe os novos SVGs

#### Scenario: Sincronização sem alterações em croquis
- **WHEN** o índice for verificado e nenhum croqui tiver sido modificado (304 Not Modified ou sem diferenças)
- **THEN** o sistema NÃO DEVE desnecessariamente descartar os caminhos cacheados para manter a performance de renderização

### Requirement: Expurgo de instâncias de sessão online obsoletas
O sistema DEVE (MUST) remover da sessão online em memória RAM qualquer croqui cujo checksum SHA-256 no índice mestre tenha divergido da versão carregada, desde que o pico não esteja atualmente com a visualização aberta pelo usuário.

#### Scenario: Croqui online desatualizado após sincronização
- **WHEN** um novo índice mestre for recebido com checksum SHA-256 diferente para um pico que possui sessão em memória e o usuário está na tela inicial
- **THEN** o sistema DEVE remover a sessão antiga da memória RAM para garantir que a próxima abertura carregue o binário atualizado

#### Scenario: Pico atualmente em visualização durante a sincronização
- **WHEN** a sincronização detectar versão mais recente de um pico que está com sua tela atualmente aberta pelo usuário
- **THEN** o sistema DEVE manter o croqui aberto sem interrupções abruptas e marcar a atualização como pendente para aplicação no fechamento ou retorno

### Requirement: Limpeza de memória gráfica no ciclo de vida de visualização
O sistema DEVE (MUST) limpar o cache de traçados vetoriais do viewport ao descartar a página de detalhes do pico ou quando o serviço online notificar recarga em tempo real via ETag.

#### Scenario: Fechamento da página do pico
- **WHEN** a página de detalhes do pico for descartada (dispose)
- **THEN** o sistema DEVE liberar as entradas de traçados do viewport para evitar acúmulo de memória entre diferentes picos

#### Scenario: Atualização de croqui em tempo real via ETag
- **WHEN** o serviço de croqui online receber um payload HTTP 200 com nova versão do croqui durante a navegação
- **THEN** o sistema DEVE invalidar o cache de traçados antes de notificar a interface sobre os novos dados
