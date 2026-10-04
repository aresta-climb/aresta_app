# Spec Delta

## ADDED Requirements

### Requirement: Rota Unificada de Exploração de Setores e Escaladas
A árvore de navegação declarativa DEVE (MUST) manter uma rota unificada para a exploração de setores e escaladas de um pico (`SetoresNode`), capaz de receber opcionalmente uma modalidade ou aba inicial para exibição, garantindo retrocompatibilidade com links ou histórico que apontem para o índice de escaladas.

#### Scenario: Transição para a rota de exploração a partir do Hub
- **WHEN** o usuário seleciona o card de exploração no Hub do Pico
- **THEN** o controlador de navegação direciona para o nó unificado `SetoresNode`
- **AND** a árvore de navegação reflete o caminho `Início -> Pico (cragId) -> Setores`.

#### Scenario: Compatibilidade com requisição direta de índice de escaladas
- **WHEN** uma navegação ou deep link requisitar abertura direta do catálogo de escaladas (`IndiceEscaladasNode`)
- **THEN** o sistema resolve a navegação direcionando para a visualização correspondente na página de exploração unificada.
