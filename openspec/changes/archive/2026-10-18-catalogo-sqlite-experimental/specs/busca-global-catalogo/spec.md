# Spec Delta

## ADDED Requirements

### Requirement: Reatividade Automática da Busca Global a Atualizações do Catálogo e Troca de Modo
O widget `GlobalSearch` DEVE (MUST) escutar alterações em `RepositorioCatalogo.versaoNotificador` e `DatasetRepository.activeDataset`, invalidando o cache em memória e recarregando automaticamente as entidades do `catalogo.db` ativo sempre que o catálogo for atualizado (via sincronização em segundo plano ou Live Reload) ou quando o usuário alternar entre o Modo Oficial e o Modo Experimental.

#### Scenario: Atualização imediata da Busca Global após Live Reload no Modo Experimental
- **WHEN** o aplicativo está no Modo Experimental e uma nova versão do `catalogo.db` experimental é aplicada pelo `SyncService` (incrementando `RepositorioCatalogo.versaoNotificador`)
- **THEN** a `GlobalSearch` invalida seus dados carregados anteriormente e passa a exibir imediatamente as vias, setores, grupos e picos atualizados do `catalogo.db` experimental.

#### Scenario: Isolamento de resultados na Busca Global ao entrar ou sair do Modo Experimental
- **WHEN** o usuário alterna entre o Modo Oficial e o Modo Experimental
- **THEN** o `DatasetRepository` limpa as sessões online em memória do modo anterior e a `GlobalSearch` exibe exclusivamente as entidades pertencentes ao catálogo e índice do modo ativo.
