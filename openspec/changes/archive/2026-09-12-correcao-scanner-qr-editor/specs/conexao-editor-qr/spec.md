## ADDED Requirements

### Requirement: Scanner de QR Code cobre completamente a tela e oculta o diálogo
O aplicativo DEVE abrir a tela de escaneamento de QR Code (`QRScannerPage`) no Root Navigator sobre o diálogo "Conectar Editor", garantindo que a visualização da câmera ocupe 100% da viewport e que a caixa de diálogo não fique visível nem sobreponha a câmera durante o escaneamento.

#### Scenario: Abertura do scanner a partir do diálogo
- **WHEN** o usuário toca no botão "ESCANEAR QR CODE" dentro do diálogo "Conectar Editor"
- **THEN** a tela de escaneamento é exibida em tela cheia no topo da pilha de rotas e a rota do diálogo deixa de ser a rota ativa (`isCurrent == false`)

### Requirement: Auto-conexão imediata após leitura de QR Code
Ao detectar uma URL válida através do escaneamento do QR Code, o sistema DEVE fechar a tela do scanner, preencher o campo de URL e iniciar automaticamente o processo de conexão com o editor (`conectarEditor`), exibindo o indicador de carregamento no diálogo.

#### Scenario: Leitura de QR Code com sucesso
- **WHEN** a câmera detecta um código QR com uma URL válida
- **THEN** o scanner fecha, a URL é atribuída ao campo de texto do diálogo e o processo de conexão é disparado automaticamente sem necessidade de clique manual em "CONECTAR"

#### Scenario: Sucesso na conexão automática
- **WHEN** a auto-conexão é disparada após o escaneamento e o servidor do editor responde com sucesso (código 200 e índice válido)
- **THEN** o diálogo é fechado e o aplicativo navega automaticamente para o croqui ou catálogo correspondente

#### Scenario: Falha na conexão automática
- **WHEN** a auto-conexão é disparada após o escaneamento mas o servidor falha ou a URL é inacessível
- **THEN** o diálogo permanece aberto exibindo mensagem de erro e a URL lida permanece no campo de texto para edição manual

### Requirement: Cancelamento do escaneamento
Se o usuário retornar da tela de escaneamento sem ler nenhum QR Code, o sistema DEVE retornar ao diálogo preservando seu estado anterior.

#### Scenario: Usuário cancela ou volta da câmera
- **WHEN** o usuário fecha a tela do scanner sem escanear nenhum código
- **THEN** o diálogo "Conectar Editor" volta a ser a rota ativa no topo e o conteúdo prévio do campo de texto não é alterado
