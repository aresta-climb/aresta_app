## Why

Ao tentar conectar ao Editor Desktop via escaneamento de QR Code a partir do diálogo "Conectar Editor", a tela da câmera (`QRScannerPage`) é empilhada no `Navigator` interno (`TreeNavigationWrapper`) enquanto o diálogo permanece no `Navigator` raiz (`MaterialApp`). Isso faz com que a caixa de diálogo e a sobreposição escura fiquem flutuando em cima da câmera, obstruindo a visão do usuário e impedindo o escaneamento adequado. Além disso, após ler o QR Code com sucesso, o usuário é forçado a clicar manualmente em "CONECTAR", gerando um passo de fricção desnecessário.

## What Changes

- **Correção da pilha de navegação ao escanear**: A tela do scanner passa a ser aberta a partir do contexto do diálogo (`dialogContext`) no `Navigator` raiz, cobrindo completamente a tela e ocultando o diálogo durante o escaneamento da câmera.
- **Auto-conexão ao escanear**: Quando a câmera lê com sucesso a URL do QR Code, a tela do scanner é fechada, a URL é preenchida no campo e o fluxo de conexão (`conectarEditor`) é disparado imediatamente sem exigir clique adicional no botão "CONECTAR".
- **Injetabilidade para testes TDD**: Parâmetro opcional `WidgetBuilder? construtorScannerQr` em `mostrarDialogConexao` permitindo simular a abertura e retorno do scanner em testes de widgets sem depender de canais nativos de câmera.
- **Tratamento de cancelamento**: Ao cancelar ou voltar do scanner sem ler o código, o diálogo permanece aberto e com o estado preservado.
- **Aderência rigorosa a PRINCIPIOS.md**:
  - *Princípio I (Tudo em Português)*: Nomenclatura 100% em português brasileiro para novos parâmetros (`construtorScannerQr`), variáveis e documentação.
  - *Princípio III (100% Test Coverage)* e *Princípio IV (TDD)*: Cobertura integral de todos os ramos da alteração (sucesso, erro, cancelamento e sobreposição) executados via ciclo Vermelho-Verde-Refatorar.
  - *Princípio V (Testes de Widget)*: Validação prioritária através de testes de widget com `WidgetTester`.
  - *Princípio VI (Simplicidade e Anti-Abstração)*: Solução direta e sem intermediários complexos.
  - *Princípio VII (Documentação Contínua)*: Docstrings completas em português (`///`) explicando a razão arquitetural da navegação.

## Capabilities

### New Capabilities
- `conexao-editor-qr`: Fluxo de conexão com o Editor Desktop via leitura de QR Code em tela cheia com auto-conexão imediata e suporte a cancelamento.

### Modified Capabilities

## Impact

- `frontend/lib/view_functions/settings_functions.dart`: Correção do contexto do Navigator em `mostrarDialogConexao`, adição do parâmetro `construtorScannerQr`, disparo automático de `conectarEditor` após escaneamento e documentação em docstrings.
- `frontend/test/view_functions/settings_functions_test.dart`: Bateria completa de testes de widget seguindo TDD e cobrindo 100% dos caminhos lógicos da funcionalidade.
