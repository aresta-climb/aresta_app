# Spec Delta: caderneta-pessoal

## Purpose

Fornece a modelagem de domínio imutável da Caderneta (`Cadena`, `TipoAscensao`, `TipoEscalada`), o repositório local reativo (`RepositorioCaderneta`) operando offline-first associado a `escalada_uid` (NanoID 14c), e o motor de agregação estatística esportiva (pirâmides de graduação para vias e boulders, distribuição de estilos e melhor ascensão).

## ADDED Requirements

### Requirement: Entidade Cadena e Validação de Domínio
O sistema MUST fornecer a entidade imutável `Cadena` para representar uma ascensão esportiva ou tentativa em uma via de escalada identificada por seu `escalada_uid`.

#### Scenario: Criação de cadena válida
- **WHEN** uma `Cadena` é instanciada com `id` (UUID v4), `escaladaUid` (NanoID 14c válido), `dataAscensao`, `tipoAscensao`, `tipoEscalada`, `tentativas >= 1` e `notasPrivadas` com até 200 caracteres
- **THEN** a instância é criada com sucesso e preserva todos os campos de forma imutável

#### Scenario: Validação de tamanho máximo de notas privadas
- **WHEN** uma `Cadena` é criada com `notasPrivadas` excedendo 200 caracteres
- **THEN** o sistema trunca ou rejeita a entrada com validação explícita de domínio

#### Scenario: Serialização e Deserialização
- **WHEN** uma `Cadena` é convertida para `Map<String, dynamic>` ou JSON e reconstruída
- **THEN** todos os campos e enums são perfeitamente restaurados sem perda de precisão ou fuso horário

### Requirement: Enums de Domínio Esportivo em Português
O sistema MUST disponibilizar os enums `TipoAscensao` e `TipoEscalada` com nomenclatura em português brasileiro, propriedades computadas e regras de prioridade esportiva.

#### Scenario: Propriedades de TipoAscensao
- **WHEN** o valor é `TipoAscensao.aVista`, `TipoAscensao.flash` ou `TipoAscensao.trabalhado`
- **THEN** `isCadena` retorna `true`
- **WHEN** o valor é `TipoAscensao.tentativa`
- **THEN** `isCadena` retorna `false`

#### Scenario: Prioridade visual de ascensão
- **WHEN** múltiplas ascensões de diferentes tipos ocorrem na mesma via
- **THEN** `prioridadeVisual` classifica `flash` (3) > `aVista` (2) > `trabalhado` (1) > `tentativa` (0)

### Requirement: Repositório Reativo Local de Cadenas
O sistema MUST prover uma interface e implementação `RepositorioCaderneta` operando local-first com persistência atômica no dispositivo e notificação reativa instantânea para a UI.

#### Scenario: Persistência e Notificação Reativa
- **WHEN** `salvarCadena` é invocado com uma nova ascensão
- **THEN** a cadena é persistida localmente de forma atômica
- **AND** o `cadenasNotifier` emite a lista atualizada para todos os ouvintes registrados

#### Scenario: Remoção de Cadena
- **WHEN** `excluirCadena` é invocado com o `id` da ascensão
- **THEN** o registro é removido do armazenamento local e a UI reativa é notificada

#### Scenario: Consulta por Via
- **WHEN** `obterCadenasPorEscalada` é invocado com um `escaladaUid`
- **THEN** o repositório retorna todas as ascensões registradas para aquela via em ordem decrescente de data

#### Scenario: Determinação da Melhor Ascensão
- **WHEN** `obterMelhorAscensao` é consultado para uma via
- **THEN** retorna a cadeia com maior `prioridadeVisual` e, em caso de empate, a data mais recente

### Requirement: Motor de Agregação e Pirâmide de Graduação
O sistema MUST calcular estatísticas esportivas consolidadas a partir do histórico de cadenas do atleta.

#### Scenario: Cálculo de Pirâmide e Totais
- **WHEN** `calcularEstatisticas` é chamado no repositório
- **THEN** retorna `EstatisticasCaderneta` contendo `totalAscensoes`, `totalCadenas`, contagem por estilo, pirâmide de graduação de vias e pirâmide de boulders agrupadas por grau
