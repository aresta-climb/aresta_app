## Context

O aplicativo Aresta Climb adota os `PRINCIPIOS.md` de engenharia: Código 100% em Português, TDD obrigatório, Testes de Widget em primeiro lugar, 100% de cobertura nos ramos alterados, Simplicidade/Anti-Abstração e Documentação Contínua (`///`).

Atualmente, o aplicativo possui dois níveis de `Navigator`:
1. `Root Navigator`: Instanciado pelo `MaterialApp` (referenciado por `appNavigatorKey`), onde residem rotas globais e os diálogos abertos por `showDialog` (já que o Flutter utiliza `useRootNavigator: true` por padrão).
2. `Inner Navigator`: Gerenciado pelo `TreeNavigationWrapper`, responsável pelo empilhamento declarativo das abas e páginas internas (`SettingsPage`, `BrowsePage`, etc.).

Ao acionar o botão "ESCANEAR QR CODE" no diálogo "Conectar Editor", o código invocava `Navigator.push(context, MaterialPageRoute(...))`, onde `context` pertencia ao `Inner Navigator` (`SettingsPage`). Isso causava uma anomalia visual: a tela de câmera `QRScannerPage` era empilhada atrás do diálogo da rota raiz, deixando a caixa e a sombra do diálogo sobrepostas à câmera.

Adicionalmente, após a leitura do QR Code, o sistema apenas populava o campo e obrigava o usuário a pressionar "CONECTAR" manualmente.

## Goals / Non-Goals

**Goals:**
- Garantir que `QRScannerPage` seja empilhada no `Navigator` raiz a partir de `dialogContext`, cobrindo 100% da viewport e ocultando o diálogo durante a captura da câmera.
- Auto-conectar imediatamente assim que a URL for retornada pela câmera, acionando o estado `isLoading = true`, executando `conectarEditor` e navegando para o croqui se bem-sucedido.
- Se a auto-conexão falhar, manter o diálogo aberto exibindo a mensagem de erro (SnackBar) com a URL escaneada preservada no `TextField`.
- Tratar o cancelamento gracioso: se o usuário fechar a câmera sem escanear (retornando `null`), o diálogo permanece aberto sem alterar o campo de texto.
- Disponibilizar parâmetro opcional `WidgetBuilder? construtorScannerQr` em `mostrarDialogConexao` (100% em português brasileiro, conforme Princípio I) para viabilizar testes de widget (Princípio V) e cobertura completa (Princípio III).
- Adicionar docstrings abrangentes com `///` em português brasileiro (Princípio VII).

**Non-Goals:**
- Não alterar a lógica de negócio interna de `conectarEditor` ou `EditorDeCroqui`.
- Não substituir a biblioteca `mobile_scanner` nem alterar `QRScannerPage`.
- Não remover a possibilidade de conexão manual digitando a URL ou código de 8 caracteres.

## Decisions

### 1. Utilizar `Navigator.of(dialogContext).push` para abrir o Scanner
- **Decisão**: Utilizar `Navigator.of(dialogContext).push(...)`. Por estar dentro de `DialogRoute` no `Navigator` raiz, a rota opaca (`MaterialPageRoute`) empilha sobre o diálogo, cobrindo-o perfeitamente. Ao dar `pop`, o diálogo é restaurado.
- **Alternativa Descartada**: Fechar o diálogo prematuramente com `pop` e tentar reabri-lo. Descartada por violar o Princípio VI (Simplicidade e Anti-Abstração) ao introduzir controle de estado frágil e desnecessário.

### 2. Auto-conexão imediata pós-escaneamento
- **Decisão**: Ao retornar uma URL não vazia (`urlEscaneada.isNotEmpty`), preencher o `urlController.text` e chamar a rotina de conexão com `isLoading = true`, reutilizando a mesma lógica já validada do botão "CONECTAR". Se a conexão falhar ou o servidor estiver offline, o diálogo permanece aberto e a URL fica disponível no campo para edição.

### 3. Injeção simples `construtorScannerQr` (Anti-Abstração e Testabilidade)
- **Decisão**: Adicionar parâmetro nomeado opcional `WidgetBuilder? construtorScannerQr` em `mostrarDialogConexao`, cujo padrão é `(context) => const QRScannerPage()`.
- Respeita o Princípio I (nome em português) e o Princípio VI (simplicidade direta sem interfaces ou factories complexas). Permite que testes de widget injetem telas de simulação sem acionar canais nativos do Android/iOS.

### 4. Cobertura Abrangente via TDD
- Escrever testes em `settings_functions_test.dart` antes de qualquer alteração no código de produção (Princípio IV), validando:
  - Sobreposição da rota (`isCurrent == false` no diálogo enquanto scanner está aberto).
  - Cancelamento da leitura.
  - Auto-conexão com sucesso (navegando automaticamente para `PicoNode` ou `BrowseNode`).
  - Auto-conexão com falha HTTP/rede (diálogo permanece aberto com a URL).

## Risks / Trade-offs

- [Uso do contexto do diálogo após `await` na navegação] → Mitigação: Checagem estrita de `if (dialogContext.mounted)` antes de qualquer manipulação de estado (`setDialogState`) ou navegação subsequente.
- [URL inválida ou servidor inacessível escaneado] → Mitigação: `conectarEditor` captura exceções e exibe mensagens de erro padronizadas, restaurando `isLoading = false` e preservando a URL no diálogo.
