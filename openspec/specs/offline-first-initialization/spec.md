## ADDED Requirements

### Requirement: Inicialização Local Instantânea
O sistema DEVE inicializar o app usando o `indice.binarypb` cacheado localmente ou pré-embutido antes de iniciar qualquer requisição de rede.

#### Scenario: App aberto com rede lenta
- **WHEN** o usuário abre o aplicativo em uma conexão lenta
- **THEN** a tela inicial renderiza instantaneamente com os dados locais enquanto a sincronização de rede roda silenciosamente em background

### Requirement: Descompactação de Primeiro Acesso
O sistema DEVE descompactar o índice e as thumbnails preloaded embutidos no diretório de documentos local no primeiro acesso.

#### Scenario: Instalação nova sem internet
- **WHEN** o usuário instala e abre o app pela primeira vez sem internet
- **THEN** o app copia os assets embutidos para o diretório de documentos e os carrega com sucesso
