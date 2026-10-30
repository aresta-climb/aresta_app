# Design

## Context

Conforme motivado em `proposal.md`, precisamos de uma infraestrutura de testes exploratórios caóticos ("Robô Caótico") que encontre crashes de estado, ciclo de vida e layout antes do pré-lançamento no Google Play Console e na App Store, sem depender do legado Firebase Test Lab Robo Test (depreciado e ausente no novo Google Cloud Developer Device Platform `gcloud beta device-run`).

O aplicativo já conta com:
1. Inicialização desacoplada em `MyApp` e `TreeNavigationWrapper`, permitindo subir toda a árvore de navegação em memória dentro de `testWidgets` com Fakes determinísticos.
2. Centralização de erros e breadcrumbs em `AppLogger` (`frontend/lib/services/firebase/app_logger.dart`) e `TelemetryService` (`frontend/lib/services/firebase/telemetria.dart`).
3. O worker `aresta-alertas-worker` (`aresta_backend/cloudflare/alertas/src/index.ts`), que escuta webhooks de crashes fatais (`level: fatal`) do Sentry e cria automaticamente Issues no GitHub com o link `https://aresta-climb.sentry.io/issues/<id>/`.

## Goals / Non-Goals

**Goals:**
- Construir um motor de exploração caótica (`MotorRoboCaotico`) 100% em Dart puro sobre `WidgetTester`, sem dependências de binários externos, reutilizável tanto em `flutter test` (execução rápida com relógio virtual) quanto em `integration_test` (dispositivos físicos/emuladores Android e iOS).
- Fornecer seletores semânticos resilientes (`SeletorAlvoRobo`) para que os passos gravados na receita JSON não quebrem por pequenas variações de coordenadas `(x, y)` de layout.
- Implementar encolhimento automático de caminhos de crash via busca binária (*Delta Debugging* / `ddmin`) em `EncolhedorCaminhoCrash`.
- Criar a `FabricaDatasetCaos` com perfis `normal` e `toxico` cobrindo casos extremos reais dos Protobufs (`Indice`, `Croqui`, `Pico`, `Setor`, `Escalada`) e do banco SQLite da Caderneta.
- Integrar o envio opcional de crashes do robô ao Sentry via `AppLogger.logCrash(..., contextosExtras: {'receita_robo_caotico': ...})`, preservando os breadcrumbs normais do aplicativo e documentando o fluxo de investigação via MCP na skill `diagnosticar-issue-sentry` nos 4 repositórios conectados ao Sentry.

**Non-Goals:**
- Alterar o código do `aresta-alertas-worker` no Cloudflare (ele já abre a Issue no GitHub automaticamente para qualquer issue `fatal` criada no Sentry).
- Substituir os testes unitários e de widget comportamentais 1:1 exigidos pelo `AGENTS.md`.

## Decisions

### 1. Representação de Passos por Seletores Descritivos (`PassoRobo` e `SeletorAlvoRobo`)
- **Decisão**: Cada passo executado pelo robô (`PassoRobo`) é imutável e serializável em JSON, identificando o widget alvo através de uma hierarquia determinística de seletores (`SeletorAlvoRobo`):
  1. `key`: Quando o widget possui uma `ValueKey<String>` explícita.
  2. `tipoETexto`: Tipo do widget interativo (`FilledButton`, `TextButton`, `IconButton`, `InkWell`, `GestureDetector`, `ListTile`, `NavigationDestination`, `Tab`, etc.) + primeiro texto descendente visível + índice de desempate (`ocorrencia`).
  3. `tipoEIcone`: Tipo do widget + `IconData.codePoint` do primeiro `Icon` descendente + índice de desempate (`ocorrencia`).
  4. `tipoIndice`: Fallback pelo `runtimeType` do widget interativo + índice entre os candidatos `hitTestable()`.
  Além do alvo, cada `PassoRobo` registra o tipo de ação (`tap`, `scroll`, `digitarTexto`, `voltarSistema`, `voltarAppNav`, `dispararEventoSync`, `alternarConectividade`) e o modo de avanço de relógio (`pumpAndSettle: true` ou `pumpMs: 50..350`).
- **Racional**: Diferente do `adb shell monkey` (baseado em coordenadas de pixel), seletores por tipo/texto/ícone resistem a ajustes visuais de padding/margem e produzem arquivos `.json` autoexplicativos para leitura humana e diagnóstico de agentes.
- **Alternativas consideradas**:
  - *Coordenadas `(dx, dy)` na tela*: Rejeitado por fragilidade extrema a mudanças de resolução ou espaçamento e por ser ilegível no JSON de regressão.
  - *Apenas árvore de `Semantics`*: Rejeitado porque diversos containers clicáveis (`GestureDetector` / `InkWell` em cards customizados ou ícones decorativos) podem não expor rótulos semânticos únicos.

### 2. Algoritmo de Shrinking por Busca Binária (`EncolhedorCaminhoCrash`)
- **Decisão**: Implementar uma variante do algoritmo `ddmin` (*Delta Debugging* de Zeller):
  1. Dado um histórico `passos` de tamanho $N$ que resultou em falha ao ser executado sobre uma função `Future<FalhaCapturadaRobo?> Function(List<PassoRobo>) executarCaminho`:
  2. Começa com granularidade $n = 2$ (dividindo a lista em 2 blocos).
  3. Para cada bloco, testa o complemento (a lista de passos **sem** aquele bloco) em uma instância limpa do app.
  4. Se o complemento continuar produzindo uma falha (mesmo tipo de exceção), substitui a lista atual pelo complemento menor e mantém/reduz $n = \max(n - 1, 2)$.
  5. Se nenhum complemento falhar, dobra a granularidade $n = \min(2n, |passos|)$ até atingir o limite máximo de tentativas configurável (ex: `maxTentativas: 12` para manter o tempo de shrinking sob ~2 segundos).
- **Racional**: Reduz drasticamente o ruído de passeios aleatórios anteriores ao crash sem exigir análise estática do grafo de páginas, e o teto de `maxTentativas` garante tempo previsível em CI.

### 3. Captura de Exceções e Invariantes Durante a Execução
- **Decisão**: Em cada passo da execução no `MotorRoboCaotico`, interceptar:
  1. `tester.takeException()` (captura erros de build, layout, `RenderFlex overflow`, `TypeError` em callbacks e `StateError`).
  2. Hook temporário em `FlutterError.onError` e captura de exceções assíncronas durante o passo.
  3. Invariante estrutural: verificar se `find.byType(MaterialApp)` e `find.byType(TreeNavigationWrapper)` (quando os termos legais já foram aceitos e não está em migração) continuam presentes na árvore e se há ao menos uma página renderizada.
  Se a flag `--dart-define=REPORTAR_SENTRY_CAOS=true` estiver ativa (ou quando solicitado via `reportarAoSentry: true`), ao concluir o shrinking da falha, o motor invoca `AppLogger.instance.logCrash` passando `contextosExtras: {'receita_robo_caotico': receita.toJson()}`.

### 4. Arquitetura Compartilhada `flutter_test` + `integration_test`
- **Decisão**: Manter toda a lógica do robô (`motor_robo_caotico.dart`, `fabrica_dataset_caos.dart`, `encolhedor_caminho_crash.dart`, `receita_crash_robo.dart`) sem depender de `package:integration_test`, recebendo apenas `WidgetTester`.
  - Na suíte rápida (`frontend/test/caos/`), os testes instanciam `MyApp` em memória com diretórios temporários (`Directory.systemTemp`) e Fakes determinísticos. As bibliotecas de caos seguem 100% os princípios do `AGENTS.md`.
  - No entrypoint de dispositivo (`frontend/integration_test/robo_caotico_dispositivo_test.dart`), o teste inicializa `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`, sobe o app real e aciona o mesmo `MotorRoboCaotico`.

### 5. Campanha por Orçamento de Tempo (5 Minutos) com Deduplicação no Pipeline de Release
- **Decisão**: Implementar o executor `executarCampanhaPorTempo` em `MotorRoboCaotico` utilizando um `Stopwatch` real (`wall-clock`):
  1. Enquanto `stopwatch.elapsed < duracaoMaxima` (configurável via `--dart-define=DURACAO_CAMPANHA_CAOS_SEGUNDOS=300`, sendo 5 minutos no `release_new_app_version.yml`), o robô sorteia novas `seeds` alternando entre `TipoDatasetCaos.normal` e `TipoDatasetCaos.toxico`.
  2. Como `flutter test` opera em relógio virtual (`FakeAsync`), 5 minutos de relógio real equivalem a centenas de sessões completas (~15.000+ passos de interação e transições).
  3. Quando uma `seed` encontra um crash, o motor extrai uma **Assinatura de Deduplicação** (`"${excecao.runtimeType}|${primeiroFrameRelevante(stackTrace)}"`).
  4. Se a assinatura for **inédita** na campanha atual:
     - Executa o `EncolhedorCaminhoCrash` (busca binária `ddmin`, ~2s);
     - Salva o JSON em `frontend/test/caos/caminhos_regressao/crash_<seed>.json`;
     - Envia para o Sentry via `AppLogger.instance.logCrash` acoplando `receita_robo_caotico`;
     - Registra na lista de `falhasUnicas` da campanha.
  5. Se a assinatura **já tiver sido encontrada** na mesma campanha: apenas incrementa o contador `ocorrencias` daquela falha (evitando gastar tempo repetindo shrinking do mesmo bug ou abrindo alertas duplicados) e passa imediatamente para a próxima `seed` até encerrar os 5 minutos!
  6. Ao término dos 5 minutos, se `falhasUnicas.isNotEmpty`, imprime o relatório consolidado com todas as falhas encontradas e falha o teste (`fail(...)`), interrompendo o job `prepare_release` em `.github/workflows/release_new_app_version.yml` **antes** do commit/tag da versão e fazendo upload dos JSONs gerados como artefato do GitHub Actions.

## Risks / Trade-offs

- **[Risco] Passo removido pelo Shrinking deixar um passo seguinte inválido (ex: remover "Abrir Pico" deixa "Clicar em Excluir Croqui" sem o botão na tela)** → **Mitigação**: Durante o replay no `EncolhedorCaminhoCrash`, se um passo intermediário não encontrar seu widget alvo na tela atual, ele é tratado como *no-op* (ignorado silenciosamente) e o replay segue para os próximos passos; se ao final a mesma exceção de crash ainda ocorrer, os passos ignorados também são podados da receita mínima!
- **[Risco] Tempo de execução da suíte `flutter test` aumentar se rodarmos muitas seeds em todo commit** → **Mitigação**: A suíte padrão de PR roda instantaneamente todos os caminhos salvos em `regressao_caminhos_test.dart` + um número enxuto de seeds rápidas (ex: 5 seeds de 25 passos = ~2 segundos), enquanto a quantidade de seeds e passos pode ser escalada via `--dart-define=QUANTIDADE_SEEDS_CAOS=50` em execuções exploratórias de pré-release.
