# badges-modalidades Specification

## Purpose

Fornece consolidação, formatação com regras gramaticais de concordância e exibição visual de badges de modalidades de escalada (esportiva, móvel, boulder, multienfiada, highline) e resumo quantitativo de grupos em listagens e visualizações do aplicativo.

## Requirements

### Requirement: Contagem e Formatação Gramatical de Modalidades
O sistema SHALL consolidar as escaladas de um setor ou grupo por modalidade e formatar o texto do badge com rigorosa concordância no singular para quantidade igual a 1 e no plural para quantidades maiores que 1.

#### Scenario: Setor com uma escalada esportiva
- **WHEN** um setor possui exatamente 1 escalada do tipo esportiva
- **THEN** o badge gerado exibe o texto "1 esportiva"

#### Scenario: Setor com múltiplas escaladas de tipos variados
- **WHEN** um setor possui 12 vias esportivas, 3 vias móveis e 1 boulder
- **THEN** são gerados os badges "12 esportivas", "3 móveis" e "1 boulder"

#### Scenario: Setor com escalada de múltiplas enfiadas
- **WHEN** um setor possui escaladas do tipo via de múltiplas enfiadas
- **THEN** o rótulo da modalidade utiliza o termo "multienfiada" no singular ou "multienfiadas" no plural (ex: "1 multienfiada" ou "2 multienfiadas")

#### Scenario: Setor com escalada do tipo highline
- **WHEN** um setor possui escaladas do tipo highline
- **THEN** o rótulo da modalidade utiliza o termo "highline" no singular ou "highlines" no plural (ex: "1 highline" ou "2 highlines")

#### Scenario: Setor sem escaladas cadastradas
- **WHEN** um setor não possui nenhuma escalada cadastrada
- **THEN** nenhum badge de modalidade é renderizado

### Requirement: Exibição de Badges na Listagem de Setores
A listagem de setores de um croqui ou grupo SHALL apresentar os badges informativos de modalidades no card de cada setor.

#### Scenario: Visualização de setor na lista de setores
- **WHEN** o usuário visualiza a lista de setores na `SetoresPage` ou dentro de uma `GrupoPage`
- **THEN** cada card de setor exibe seus respectivos badges de modalidades abaixo do nome do setor

### Requirement: Estruturação Visual de Grupos na Listagem
A listagem de setores ou grupos SHALL apresentar os grupos com distinção visual estruturada em duas linhas: resumo quantitativo e badges consolidados.

#### Scenario: Visualização de grupo com múltiplos setores e escaladas
- **WHEN** um grupo possui 5 setores e 42 escaladas no total
- **THEN** a primeira linha abaixo do nome exibe "5 setores • 42 escaladas" respeitando singular e plural
- **THEN** a segunda linha exibe as badges consolidadas por modalidade para todo o grupo

#### Scenario: Grupo com único setor ou única escalada
- **WHEN** um grupo possui 1 setor e 1 escalada
- **THEN** a primeira linha de resumo exibe "1 setor • 1 escalada"
