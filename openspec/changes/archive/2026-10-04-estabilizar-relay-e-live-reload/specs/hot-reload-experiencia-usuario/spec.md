# Spec Delta

## ADDED Requirements

### Requirement: Coalescência e Debounce de Sincronizações de Modo
O sistema DEVE (MUST) coordenar a sincronização de dados (`SyncService.syncIndex()`) em transições de modo experimental ou produção aplicando debounce e proteção contra reentrância, garantindo que alterações concorrentes ou sequenciais imediatas nas variáveis de estado (`isExperimentalMode` e `editorUrl`) não disparem múltiplas requisições HTTP redundantes para o servidor ou retransmissor.

#### Scenario: Transição atômica para o modo experimental sem rajadas de sincronização
- **WHEN** o aplicativo ativa o modo experimental e atualiza simultaneamente ou em sequência imediata o estado de ativação e a URL do editor
- **THEN** o sistema DEVE coalescer os disparos de sincronização em uma única execução consolidada
- **AND** NÃO DEVE emitir requisições HTTP repetidas para o mesmo índice no retransmissor.

#### Scenario: Coalescência de eventos de Live Reload em intervalo curto
- **WHEN** o aplicativo receber múltiplos eventos push de Live Reload em rápida sucessão (menor que 300ms)
- **THEN** o sistema DEVE coalescer as atualizações pendentes
- **AND** executar apenas uma rotina de sincronização e atualização de telas para o lote recebido.
