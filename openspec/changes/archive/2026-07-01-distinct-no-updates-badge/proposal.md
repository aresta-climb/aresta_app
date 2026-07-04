## Why

Atualmente, quando o aplicativo verifica por atualizações e recebe um status 304 (Not Modified), a interface de usuário informa que as atualizações "foram atualizadas". Isso confunde o usuário e cria uma experiência frustrante, pois não houve alteração real nos dados. É necessário separar visualmente o cenário onde não há novos dados ("dado mais recente", "já atualizado") do cenário onde dados reais foram baixados, melhorando a clareza e a experiência do usuário.

## What Changes

- Adição de lógica para diferenciar a resposta 304 (Sem modificações) de uma resposta de sucesso com novos dados durante a sincronização de atualizações.
- Introdução de uma notificação/badge distinta na interface informando que os dados já estão atualizados ou que não há atualizações disponíveis (ex: "Sem atualizações" ou "Já está atualizado").
- Atualização da notificação/badge existente ("foram atualizadas") para aparecer apenas quando a atualização trouxer, de fato, novos dados.
- **Implementação com TDD e 100% de Unit Test Coverage:** Todo o código deste fluxo será desenvolvido guiado por testes, garantindo que as novas regras de negócio e transições de UI possuam cobertura total por testes unitários.

## Capabilities

### New Capabilities
- `data-sync-feedback`: Capacidade de prover feedback contextual e distinto na interface de usuário durante processos de sincronização de dados (ex: indicando se houve download de novos dados ou se o cache já estava atualizado).

### Modified Capabilities
<!-- No modified capabilities -->

## Impact

- Fluxo de atualização do `indice.binarypb` e recursos relacionados.
- Componentes de UI responsáveis por exibir os badges/notificações de atualização na tela inicial ou menu de configurações.
- Camada de comunicação entre o serviço de sincronização (API/Network) e a UI (Providers/Controllers) para propagar o status correto (304 vs 200).
