## Why

Usuários enfrentam travamentos críticos na inicialização do aplicativo (tela preta/cinza escura permanente) ao abrir o app em redes instáveis, de alta latência, em túneis/VPNs ou portais cativos sem o modo avião ativado. Isso ocorre porque o `AppVersionChecker` aguarda de forma síncrona (`await`) a execução de `RemoteConfigService.initialize()` — que realiza uma requisição HTTP via `fetchAndActivate()` com `minimumFetchInterval: Duration.zero` — antes de renderizar a interface (`child`). Como o Aresta é estritamente *offline-first*, nenhuma requisição de rede pode bloquear a inicialização ou a renderização da tela sob qualquer condição de conectividade.

## What Changes

- **`AppVersionChecker` Não-Bloqueante**: O widget `AppVersionChecker` passa a renderizar imediatamente a interface filha (`child`), utilizando as configurações locais/padrão já existentes no dispositivo, sem aguardar respostas de rede.
- **Atualização do Firebase Remote Config em Segundo Plano**: O `RemoteConfigService.initialize()` e o `fetchAndActivate()` passam a rodar de forma 100% assíncrona em segundo plano. Caso uma nova versão mínima ou recomendada seja detectada, o `AppVersionChecker` atualiza seu estado de forma reativa.
- **Intervalo de Cache Sensato no Remote Config**: Remoção da imposição de `Duration.zero` na inicialização, respeitando os caches locais para evitar conexões repetitivas desnecessárias a cada abertura a frio.
- **Eliminação da Tela Preta Bloqueante**: Remoção do placeholder `ColoredBox(color: Colors.black)` bloqueante, garantindo que o primeiro frame exiba a tela inicial (Home) ou de Termos de Uso.
- **Aderência aos Princípios (PRINCIPIOS.md)**: Código, comentários e docstrings 100% em português brasileiro, desenvolvimento orientado a testes (TDD) com Widget Tests em primeiro lugar e 100% de cobertura.

## Capabilities

### New Capabilities
<!-- Nenhuma -->

### Modified Capabilities
- `offline-first-initialization`: Adição do requisito formal de que a validação de versão e o Firebase Remote Config nunca devem bloquear o primeiro frame da interface de usuário, mantendo o fallback local imediato.

## Impact

- `frontend/lib/widgets/app_version_checker.dart`: Refatorado para renderização imediata e atualização reativa.
- `frontend/lib/services/firebase/remote_config_service.dart`: Ajustado para inicialização não-bloqueante e notificação assíncrona.
- `frontend/test/widgets/app_version_checker_test.dart` e `frontend/test/services/firebase/remote_config_service_test.dart`: Testes de widget e de unidade cobrindo cenários com atraso de rede, offline e 100% de cobertura.
