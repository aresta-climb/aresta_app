# robo-caotico-testes-exploratorios Specification

## Purpose
Fornecer uma infraestrutura determinística de testes exploratórios caóticos em interface gráfica e estado reativo (compatível com `flutter_test` em memória e `integration_test` em dispositivos físicos/emuladores Android e iOS), capaz de exercitar o aplicativo com datasets realistas e tóxicos, encolher automaticamente sequências de ações que causam crashes por busca binária, acoplar receitas reproduzíveis aos alertas do Sentry e executar regressões permanentes em cada build.

## ADDED Requirements

### Requirement: Exploração Caótica Determinística Guiada por Semente
O motor de testes exploratórios SHALL executar sequências de interações sobre o aplicativo completo utilizando um gerador pseudo-aleatório inicializado por uma semente (`seed`) explícita, garantindo que duas execuções sob a mesma `seed` e mesmo dataset inicial selecionem exatamente a mesma sequência de ações e tempos de avanço de quadro.

#### Scenario: Reprodução determinística da mesma semente
- **WHEN** o robô caótico é executado duas vezes consecutivas com a mesma `seed` e o mesmo dataset inicial em `flutter_test`
- **THEN** ambas as execuções DEVEM produzir a mesma lista ordenada de passos (`PassoRobo`) e atingir o mesmo estado final na árvore de navegação.

#### Scenario: Descoberta e sorteio de ações interativas e assíncronas
- **WHEN** o robô caótico executa um passo da caminhada exploratória
- **THEN** o motor DEVE inspecionar os widgets visíveis e atingíveis (`hitTestable`) na tela atual e sortear entre ações de toque, rolagem, digitação de texto fuzz, acionamento de retorno (`AppNav.back` ou rota do sistema) e eventos externos simulados (atualização de sincronização ou mudança de conectividade).

### Requirement: Caos Temporal durante Transições e Animações
O motor de testes exploratórios SHALL alternar determinísticamente, com base na `seed`, entre aguardar a estabilização completa de quadros (`pumpAndSettle`) e avançar o relógio por durações parciais (`pump` de 50ms a 350ms), permitindo que ações subsequentes ocorram durante transições de rota, aberturas de modais e desmontagens de `State` (`dispose`).

#### Scenario: Interação disparada durante transição de rota declarativa ou modal
- **WHEN** o robô sorteia um avanço temporal parcial após acionar uma navegação ou botão voltar
- **THEN** o passo seguinte DEVE ser executado após a duração parcial sorteada sem aguardar `pumpAndSettle`, expondo eventuais acessos inválidos a `State.context` ou widgets desativados.

### Requirement: Alimentação por Dataset Normal e Dataset Tóxico de Estresse
A infraestrutura de caos SHALL disponibilizar dois perfis determinísticos de dados iniciais para o repositório e banco local: um **Dataset Normal** (representativo do catálogo de produção) e um **Dataset Tóxico** contendo valores limites e degenerados de domínio.

#### Scenario: Execução exploratória sob Dataset Tóxico
- **WHEN** o robô é inicializado com o perfil `TipoDatasetCaos.toxico`
- **THEN** o estado inicial DEVE incluir picos sem setores, setores sem escaladas ou sem imagens, textos longos (300+ caracteres) com emojis e sintaxe Markdown limite, graus de escalada exóticos ou vazios, picos com alto volume de vias e registros de cadenas órfãs na Caderneta.

### Requirement: Detecção de Falhas e Encolhimento por Busca Binária (Shrinking)
Ao detectar uma exceção não tratada, erro do framework (`FlutterError`) ou violação de invariante de árvore durante uma sessão exploratória, o sistema SHALL executar um algoritmo de encolhimento por busca binária (*Delta Debugging* / `ddmin`) que remove iterativamente subconjuntos de passos até encontrar a menor subsequência capaz de reproduzir a mesma falha.

#### Scenario: Redução automática de caminho longo para sequência mínima de crash
- **WHEN** uma sessão exploratória de 40 passos falha no último passo devido a uma sequência causada apenas pelos últimos 5 passos
- **THEN** o encolhedor por busca binária DEVE testar fatias reduzidas do histórico em novas instâncias limpas do cenário e produzir `passosMinimos` contendo apenas os passos necessários para reproduzir a mesma exceção, preservando também `passosOriginais` na receita.

### Requirement: Empacotamento de Receita JSON e Suíte Permanente de Regressão
Toda falha capturada pelo robô SHALL ser serializada em uma estrutura JSON legível (`ReceitaCrashRobo`) contendo `seed`, `dataset`, `resumoErro`, `passosMinimos`, `passosOriginais` e `instrucoesRegressao`. A suíte de testes automatizados (`test/caos/regressao_caminhos_test.dart`) SHALL carregar e reexecutar automaticamente todos os arquivos `.json` presentes em `test/caos/caminhos_regressao/`, falhando se qualquer passo lançar exceção.

#### Scenario: Reprodução e validação de correção via arquivo de receita JSON
- **WHEN** um arquivo `.json` de receita de crash é adicionado em `frontend/test/caos/caminhos_regressao/`
- **THEN** a execução de `flutter test test/caos/regressao_caminhos_test.dart` DEVE reexecutar os `passosMinimos` da receita e falhar enquanto o defeito existir no código de produção, passando a suceder em menos de 1 segundo após a correção do defeito.

### Requirement: Compatibilidade Dual entre VM Local e Dispositivos Físicos (Android e iOS)
O motor do robô caótico SHALL operar exclusivamente sobre o contrato `WidgetTester`, permitindo sua execução tanto via `flutter test` em memória quanto via `integration_test` (`frontend/integration_test/robo_caotico_dispositivo_test.dart`) compilado para aparelhos ou emuladores Android e iOS (incluindo execuções pré-release no Google Cloud Developer Device Platform).

#### Scenario: Execução da mesma semente em modo de teste de widget e integração
- **WHEN** o motor do robô caótico é invocado a partir da suíte `flutter test` ou do entrypoint `integration_test`
- **THEN** o motor DEVE executar o ciclo de exploração utilizando a instância de `WidgetTester` fornecida sem exigir duplicação da lógica de descoberta de widgets ou de avaliação de invariantes.

### Requirement: Campanha Exploratória por Orçamento de Tempo com Deduplicação e Gate de Release
O executor de campanha caótica SHALL suportar execução contínua por um orçamento de tempo configurável (`DURACAO_CAMPANHA_CAOS_SEGUNDOS`, padrão de 300 segundos / 5 minutos no pipeline de release) sem interromper na primeira falha. Durante a janela de tempo, o sistema SHALL deduplicar falhas por assinatura (`tipoExcecao + framePrincipal`), executar o shrinking e o envio ao Sentry apenas para falhas inéditas, e ao término do período reportar todas as falhas encontradas e interromper o workflow de release (`release_new_app_version.yml`) antes da criação de commits ou tags.

#### Scenario: Campanha de 5 minutos encontra múltiplas falhas durante o job de release
- **WHEN** a campanha do robô caótico roda no job `prepare_release` por 5 minutos e encontra falhas em múltiplas sementes
- **THEN** o executor DEVE continuar explorando até completar o orçamento de tempo, encolher e salvar a receita JSON de cada falha única, reportar cada falha inédita ao Sentry e, ao final, emitir o resumo consolidado de todas as falhas e falhar o job impedindo a criação da tag de release e o deploy nas lojas.

### Requirement: Documentação de Diagnóstico Sentry via MCP em Todos os Repositórios
Os repositórios conectados ao Sentry (`aresta_app`, `aresta_db`, `aresta_backend` e `arestaclimb.com`) SHALL incluir a skill `diagnosticar-issue-sentry` documentando como agentes de IA devem extrair o identificador da issue do Sentry a partir de uma Issue do GitHub, inspecionar o evento via servidor MCP do Sentry (incluindo instruções de configuração caso não esteja ativo) e, no `aresta_app`, converter o contexto `receita_robo_caotico` em teste de regressão permanente.

#### Scenario: Diagnóstico de issue do GitHub originada pelo Sentry
- **WHEN** um desenvolvedor solicita ao agente investigar uma Issue do GitHub que contém um link `https://aresta-climb.sentry.io/issues/<id>/`
- **THEN** a skill `diagnosticar-issue-sentry` DEVE guiar o agente a consultar a issue e o evento correspondente no Sentry via MCP, ler os breadcrumbs normais e contextos anexados e, se houver `receita_robo_caotico`, salvar o JSON em `frontend/test/caos/caminhos_regressao/` para reproduzir e validar a correção.
