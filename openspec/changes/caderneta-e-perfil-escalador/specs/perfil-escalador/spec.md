# Spec Delta: perfil-escalador

## Purpose

Fornece a tela de Perfil do Escalador (`PerfilPage`) com arquitetura MVVM (`PerfilViewModel`), integrando cabeçalho com identificador público permanente (`autor_id_publico`), cartões de resumo estatístico, visualização em pirâmide de graduação (vias e boulders) e histórico cronológico interativo de ascensões com exclusão segura.

## ADDED Requirements

### Requirement: Entidade de Perfil do Escalador
O sistema MUST gerenciar os dados do perfil do atleta através da entidade imutável `PerfilEscalador`.

#### Scenario: Identificador público persistente
- **WHEN** o perfil é inicializado pela primeira vez no dispositivo
- **THEN** um `autorIdPublico` estável de 14 caracteres em Base62 (NanoID) é gerado e persistido
- **AND** um apelido padrão esportivo é atribuído se o usuário ainda não houver customizado

### Requirement: Cabeçalho do Perfil e Cópia de Identificador
A tela de perfil MUST apresentar o cabeçalho esportivo com avatar, nome de exibição e o chip do identificador público.

#### Scenario: Cópia do autorIdPublico
- **WHEN** o usuário toca no chip do `autorIdPublico`
- **THEN** o identificador é copiado para a área de transferência do dispositivo
- **AND** um feedback visual informa que o ID foi copiado com sucesso

### Requirement: Painel de Métricas e Resumo Esportivo
A tela de perfil MUST exibir cartões com as principais métricas de evolução do atleta.

#### Scenario: Atualização reativa de métricas
- **WHEN** uma nova cadena é registrada ou excluída
- **THEN** os cartões de "Total de Cadenas", "Maior Grau (Vias)", "Maior Grau (Boulders)" e "Taxa À Vista/Flash" são atualizados reativamente sem necessidade de recarregar a tela

### Requirement: Visualização da Pirâmide de Graduação
A tela de perfil MUST renderizar a pirâmide de graduação com barras horizontais proporcionais para cada grau encadenado.

#### Scenario: Alternância entre Vias e Boulders
- **WHEN** o usuário alterna o seletor entre "Vias" e "Boulders"
- **THEN** a pirâmide recalcula e renderiza exclusivamente as cadenas da modalidade selecionada em ordem crescente de graduação

### Requirement: Histórico Cronológico e Exclusão de Cadena
A tela de perfil MUST listar o histórico completo de ascensões em ordem cronológica reversa, permitindo remoção controlada.

#### Scenario: Exclusão de cadena com confirmação
- **WHEN** o usuário solicita a exclusão de um registro no histórico
- **THEN** um diálogo de confirmação é exibido
- **AND** ao confirmar, o registro é removido do repositório e o histórico e as estatísticas são reprocessados imediatamente
