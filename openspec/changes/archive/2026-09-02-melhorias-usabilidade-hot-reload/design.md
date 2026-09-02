## Context

O aplicativo Aresta Climb conta com uma arquitetura de navegação em árvore imutável (TreeNavigationWrapper / NavNode), um repositório reativo de dados (DatasetRepository) e um serviço de sincronização (SyncService). Recentemente, adicionamos suporte a conexão com o Editor Desktop via LAN ou Túnel Cloudflare Relay com WebSocket push para Live Reload.

Em conformidade com as diretrizes do PRINCIPIOS.md, toda a arquitetura desenhada abaixo adota:
- **Tudo em Português**: Nomenclaturas de classes, métodos, campos e testes em português brasileiro.
- **Componentes Independentes (Feature-First)**: Extração do banner superior para um widget desacoplado e autossuficiente (BannerModoExperimental).
- **TDD e Testes de Widget em Primeiro Lugar**: Criação prévia de testes de widget e unitários com 100% de cobertura.
- **Documentação Contínua**: Docstrings com /// em todos os membros e atualização do README.md.

## Goals / Non-Goals

**Goals:**
- **Zero Friction Pairing**: Ao escanear o QR Code ou digitar o código de prévia, o app conecta, baixa o índice e o croqui experimental, e navega diretamente para a página do Pico (PicoNode) se houver apenas 1 croqui no índice.
- **Silent & Reactive Hot Reload**: Durante a edição no desktop, cada salvamento recarrega a UI instantaneamente em tela preservando a rolagem (scroll) e aciona um pulso visual luminoso no banner superior em vez de SnackBars textuais.
- **Informativo e Transparente em Produção**: Atualizações em segundo plano na versão oficial aplicam o hot-reload imediatamente e exibem uma notificação discreta.
- **Quick Exit**: Botão de saída rápida no banner global para desativar o modo experimental e retornar imediatamente para a tela inicial oficial (HomeNode).
- **Arquitetura Modular**: Isolar a apresentação do banner e sua animação de pulso no widget BannerModoExperimental.

**Non-Goals:**
- Edição de dados no celular (o app atua estritamente como visualizador/leitor).
- Alteração no protocolo binário protobuf ou nos endpoints do Cloudflare Relay / Servidor Celular.

## Decisions

### 1. Auto-Download Imediato na Conexão (FuncoesConfiguracoes.conectarEditor)
- **Decisão**: Após obter o indice.binarypb, se indice.croquis.length == 1, a rotina dispara imediatamente syncService.downloadCroqui(croquiId) e aguarda a conclusão antes de fechar o diálogo.
- **Alternativa Considerada**: Apenas salvar a URL e deixar para baixar quando o usuário clicar no card no catálogo.
- **Justificativa**: Em 99% dos casos de prévia do editor há exatamente 1 croqui sendo trabalhado. Baixar na conexão permite abrir a tela do croqui já pronta e interativa, eliminando 4 toques manuais.

### 2. Navegação Inteligente Pós-Pareamento
- **Decisão**:
  - Se indice.croquis.length == 1: 	reeController.navigateTo(PicoNode(croquiId)).
  - Se indice.croquis.length > 1: 	reeController.navigateTo(BrowseNode(HomeNode())).
- **Justificativa**: Evita deixar o usuário preso na tela de Configurações onde realizou o pareamento.

### 3. Componente Modular BannerModoExperimental e Pulso Luminoso
- **Decisão**: Criar o widget BannerModoExperimental em rontend/lib/widgets/banner_modo_experimental.dart. O widget escuta o notificador 
otificadorGatilhoRecarregamento do EditorDeCroquiService e aciona uma animação suave de brilho/pulso (transição de cor e opacidade por 400ms) sem bloquear a UI.
- **Alternativa Considerada**: Deixar o código do banner inline dentro de main.dart com SnackBars.
- **Justificativa**: Respeita o princípio de Componentes Independentes (Feature-First) e viabiliza testes de widget isolados em anner_modo_experimental_test.dart.

### 4. Botão de Saída Rápida no Banner Global
- **Decisão**: Inserir um botão compacto [ Sair ✕ ] no BannerModoExperimental. Ao ser clicado, executa 
ukeExperimentalData() e redefine a árvore para HomeNode().

## Risks / Trade-offs

- **[Falha de download na conexão]** → Se a conexão falhar no download do croqui, o app captura o erro, exibe feedback no diálogo e navega para a aba de navegação com o banner ativo para permitir retentativa manual.
- **[Exclusão de Setor/Via no Desktop com tela aberta no celular]** → Se o Hot Reload chegar e o ID do setor ou via atualmente aberto não existir mais no novo compilado.binarypb, a navegação faz fallback seguro para o PicoNode pai sem lançar exceções.
