## ADDED Requirements

### Requirement: Feedback Contextual de Sincronização
O sistema DEVE informar visualmente ao usuário o resultado preciso da última verificação de atualizações no servidor.

#### Scenario: Sincronização encontrou novos dados
- **WHEN** o aplicativo sincroniza com o servidor e novos dados são recebidos (HTTP 200)
- **THEN** a interface de usuário DEVE exibir um feedback indicando "Foram atualizados"

#### Scenario: Sincronização sem novos dados
- **WHEN** o aplicativo verifica com o servidor e não existem novos dados (HTTP 304)
- **THEN** a interface de usuário DEVE exibir um feedback distinto indicando "Já atualizado" ou "Sem atualizações"
