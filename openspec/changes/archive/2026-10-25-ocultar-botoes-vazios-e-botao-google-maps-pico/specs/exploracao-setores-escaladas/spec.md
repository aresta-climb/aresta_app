# Spec Delta

## ADDED Requirements

### Requirement: Mensagem de Backup para Pico sem Setores ou Escaladas Cadastrados
Na página de exploração unificada ("Setores & Escaladas"), quando o pico não possuir nenhum setor ou grupo cadastrado na base de dados, o sistema DEVE (MUST) exibir uma mensagem de estado vazio informando que não há setores ou escaladas cadastrados para o local, diferenciando-a da mensagem exibida quando filtros ativos não encontram resultados.

#### Scenario: Pico sem setores cadastrados exibe mensagem de estado vazio do local
- **WHEN** o usuário abre "Setores & Escaladas" em um pico cuja lista de setores e grupos está vazia e sem filtros ativos
- **THEN** o sistema exibe uma mensagem informando que nenhum setor ou escalada foi cadastrado para este local
- **AND** não exibe a mensagem de que nenhum setor foi encontrado com os filtros selecionados.

#### Scenario: Pico com setores cadastrados mas sem correspondência no filtro mantém aviso de filtro
- **WHEN** o usuário aplica filtros em um pico que possui setores cadastrados e nenhum setor atende aos filtros
- **THEN** o sistema exibe a mensagem indicando que nenhum setor foi encontrado com os filtros selecionados.
