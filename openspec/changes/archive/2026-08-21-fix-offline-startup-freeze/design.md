## Context

Em uma aplicação estritamente *offline-first*, todo o ciclo de vida da abertura do aplicativo deve ser completado sem depender de conectividade de rede. Atualmente, o `AppVersionChecker` encapsula o `MaterialApp.builder` e retorna um contêiner preto bloqueante (`ColoredBox(color: Colors.black)`) enquanto `_loadPackageInfo()` é executado. O método `_loadPackageInfo()` executava um `await` direto em `RemoteConfigService.instance.initialize()`, que por sua vez aguardava `await _remoteConfig.fetchAndActivate()` com `minimumFetchInterval: Duration.zero`.

Quando o dispositivo do usuário se encontra em uma rede com alta latência, instabilidade, túnel VPN/proxy ou portal cativo sem envio de RST, essa chamada de rede fica pendurada por tempo indeterminado até atingir timeouts longos do SO, mantendo o aplicativo congelado na tela preta/cinza antes de renderizar a página inicial.

## Goals / Non-Goals

**Objetivos (Goals):**
- Garantir a renderização imediata da interface visual (`Home`, `TermsOfUsePage`, etc.) no primeiríssimo frame, independentemente do estado ou qualidade da conexão de rede.
- Executar todas as requisições de rede do Firebase Remote Config 100% em segundo plano (background), sem bloquear a thread principal nem o ciclo de inicialização da UI.
- Prover atualização reativa da interface: caso a busca em segundo plano do Remote Config retorne uma nova versão mínima (`hard_min_version`), intermediária (`soft_min_version`) ou recomendada (`recommended_version`), o `AppVersionChecker` atualiza o estado reativamente sem exigir reinício do app.
- Aderir integralmente aos **Princípios de Engenharia (`PRINCIPIOS.md`)**:
  - Código, testes e documentação 100% em português brasileiro.
  - TDD obrigatório (Red-Green-Refactor).
  - Testes de Widget em primeiro lugar.
  - 100% de cobertura de testes (`test coverage`).
  - Simplicidade sem abstrações desnecessárias.

**Não-Objetivos (Non-Goals):**
- Alterar as chaves ou regras de negócio dos parâmetros do Firebase Remote Config (`hard_min_version`, `soft_min_version`, `recommended_version`, `store_url_ios`).
- Modificar o funcionamento da tela de migração de banco local (`DatabaseMigrationScreen`).

## Decisions

### 1. Eliminação do Estado Bloqueante no `AppVersionChecker`
- **Decisão**: Remover o `ColoredBox(color: Colors.black)` quando `_isLoading == true`. Renderizar `widget.child` imediatamente no primeiro build, utilizando valores locais padrão e em cache.
- **Justificativa**: A chamada de `PackageInfo.fromPlatform()` é local via platform channel e dura milissegundos. Ao renderizar `widget.child` imediatamente, evitamos qualquer piscar ou tela preta temporária.
- **Alternativas consideradas**: Exibir um `CircularProgressIndicator` de tela inteira — rejeitado porque a premissa do app é *offline-first* com base local já descompactada; exibir indicador de carregamento prejudica a experiência e bloqueia o usuário sem necessidade.

### 2. `RemoteConfigService` Assíncrono com Notificação Reativa
- **Decisão**: `RemoteConfigService.initialize()` define os defaults locais de forma instantânea e dispara `fetchAndActivate()` em segundo plano sem travar a chamada inicial. O serviço expõe um `Listenable` (como `ChangeNotifier` ou `ValueNotifier`) que notifica quando novas configurações forem baixadas e ativadas do servidor.
- **Justificativa**: Desacopla a renderização da interface do tempo de resposta da rede, permitindo que a tela responda reativamente quando os dados remotos chegarem.
- **Alternativas consideradas**: Polling periódico com `Timer` — rejeitado para evitar complexidade desnecessária e consumo de bateria.

### 3. Configuração Saudável de Cache no Remote Config
- **Decisão**: Não forçar `minimumFetchInterval: Duration.zero` na inicialização padrão em produção, utilizando os tempos de cache recomendados para evitar tentativas repetitivas de socket a cada abertura a frio.
- **Justificativa**: Evita sobrecarga de rede e conexões penduradas desnecessárias quando o usuário reabre o app seguidas vezes em locais sem conectividade adequada.

## Risks / Trade-offs

- **[Risco]** Um usuário com versão obsoleta que necessite de bloqueio duro (*hard block*) pode visualizar a tela Home por uma fração de segundo antes do Remote Config responder.
  - **Mitigação**: Se o app já baixou a configuração de bloqueio em uma sessão anterior, ela estará no cache local e será lida instantaneamente no primeiro frame. Em instalações novas via loja, a versão instalada já é a mais recente.

- **[Risco]** Quebra de testes de widget que supunham timing síncrono.
  - **Mitigação**: Atualizar o `FakeRemoteConfigService` e os testes de widget para validar tanto o estado inicial imediato quanto a atualização reativa após o retorno do mock.
