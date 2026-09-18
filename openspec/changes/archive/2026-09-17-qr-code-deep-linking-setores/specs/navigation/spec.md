## ADDED Requirements

### Requirement: Reconstrução de Linhagem Ascendente em Deep Links
O sistema DEVE (MUST) garantir que qualquer navegação disparada a partir de deep link externo monte a linhagem declarativa completa de ancestrais na árvore de nós (`NavNode`), de modo que o botão voltar ou o gesto de retorno do sistema transicione retroativamente pelos nós pais (`ViaNode -> SetorNode -> PicoNode -> HomeNode`) em vez de fechar o aplicativo ou desorientar o usuário.

#### Scenario: Retorno a partir de uma via aberta por deep link
- **WHEN** o usuário abre uma Via via deep link e aciona o comando voltar
- **THEN** a árvore de navegação retrocede para o Setor pai daquela via
- **AND** um acionamento subsequente retrocede para a página do Pico correspondente, até atingir a raiz (Home).

#### Scenario: Retorno a partir de um setor dentro de grupo aberto por deep link
- **WHEN** o usuário abre um Setor filho de um Grupo via deep link e aciona o comando voltar
- **THEN** a árvore de navegação retrocede para a visualização do Grupo pai
- **AND** o retorno subsequente alcança o Pico pai.
