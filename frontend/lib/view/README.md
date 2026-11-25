# Camada de Apresentação (`lib/view/`)

Este diretório contém os construtores de interface (`function_library/`) e os ViewModels (`view_models/`) segundo o padrão **MVVM**. As páginas em `lib/pages/` delegam formatação, estado e comandos para esta camada.

---

## Estrutura

```text
lib/view/
├── function_library/                     - Funções e widgets declarativos por tela
│   ├── biblioteca_funcoes_comuns.dart    - AppBar padrão (com BotaoVoltarComRetornoInicio), barra inferior, busca e feedback
│   ├── funcoes_home.dart                 - Seções e abertura de croquis da Home
│   ├── funcoes_explorar.dart             - Lista, ordenação e progresso de download do Explorar
│   ├── pico_functions.dart               - Cabeçalhos, cartões e PicoSearchDelegate
│   ├── grupo_functions.dart              - Listagem de subsetores de um grupo
│   ├── setor_functions.dart              - Itens de vias e rótulos de setor
│   ├── via_functions.dart                - CorpoDetalhesVia e conversão de graus/proteções
│   ├── meus_croquis_functions.dart       - Lista de croquis baixados
│   ├── comunidade_functions.dart         - Cartões e links da aba Comunidade
│   ├── funcoes_hub_perfil_caderneta.dart - Cabeçalho com avatar/câmera, métricas e menu do Perfil
│   ├── funcoes_caderneta.dart            - Histórico de ascensões e confirmação de exclusão
│   ├── funcoes_configuracoes.dart        - Tema, preferências e conexão com Editor Desktop
│   ├── sobre_time_functions.dart         - Cartões e dados dos integrantes
│   ├── gps_functions.dart                - Auxiliares da tela de GPS
│   ├── markdown_offline.dart             - Renderizador Markdown com leitura de imagens em disco
│   ├── sintaxe_tag_small.dart            - Parser da tag <small> em Markdown
│   ├── construtor_elemento_small.dart    - Renderização da tag <small> (escala 80%)
│   └── mapa/
│       ├── mapa_global_functions.dart    - Marcadores, faixas de zoom e bottom sheet do Mapa Global
│       └── mapa_marker.dart              - Desenho via Canvas dos marcadores de mapa
└── view_models/                          - Gerenciamento de estado e comandos de tela
    ├── login_view_model.dart             - Fluxo sem senha (OTP de 6 dígitos por e-mail, Google e Apple)
    ├── hub_perfil_caderneta_view_model.dart - Estado do perfil, foto, métricas, saída e exclusão de conta
    ├── edicao_perfil_view_model.dart     - Estado do diálogo de edição de nome e foto
    ├── perfil_view_model.dart            - Estatísticas, histórico de cadenas e alertas do usuário na Caderneta
    ├── via_view_model.dart               - Estado da ViaPage, votação de grau, alertas com desfazer, Pix e compartilhamento
    ├── formulario_alerta_via_view_model.dart - Seleção de categoria (`Fauna` padrão) e formatação dos modais de alerta
    ├── alertas_mapa_interativo_view_model.dart - Projeção e confirmação de bolhas de alerta sobre o croqui interativo
    ├── secao_caderneta_via_view_model.dart - Resumo pessoal de ascensões dentro da ViaPage
    ├── registro_cadena_view_model.dart   - Registro/edição de cadena, voto de grau e nota pública opcional
    ├── home_view_model.dart              - Estado da Home e picos próximos
    ├── explorar_view_model.dart          - Busca, ordenação e downloads da aba Explorar
    ├── meus_croquis_view_model.dart      - Listagem e exclusão de croquis locais
    ├── pico_view_model.dart              - Estado online/offline, polling ETag e ações do Pico
    ├── mapa_global_view_model.dart       - Marcadores e estado do Mapa Global
    ├── mapa_pico_view_model.dart         - Coordenadas e título de pico para o Google Maps
    ├── card_croqui_view_model.dart       - Dados de apresentação de cartões de croqui
    ├── pico_proximo_view_model.dart      - Distância geográfica até o usuário e status offline
    ├── comunidade_view_model.dart        - Links comunitários
    └── configuracoes_view_model.dart     - Preferências e modo de desenvolvedor
```

---

## 1. `function_library/`

Os arquivos da `function_library` são coleções de funções e construtores de widgets (`build...`) que recebem dados fortemente tipados e o `BuildContext`, retornando a árvore de widgets correspondente:

- **Desacoplamento e Testabilidade**: Ao isolar construtores de UI em funções especializadas, os testes de widget podem ser executados isoladamente sem necessidade de instanciar scaffolds complexos ou navegação global.
- **Cabeçalho e Avatar do Hub de Perfil (`funcoes_hub_perfil_caderneta.dart`)**:
  - `construirProvedorAvatarPerfil`: Resolve tanto Data URIs em base64 (`data:image/...;base64,...` $\rightarrow$ `MemoryImage`) quanto URLs públicas do Supabase Storage ou Google (`http`/`https` $\rightarrow$ `NetworkImage`).
  - `buildCabecalhoHubPerfil`: Renderiza o avatar circular com anel de destaque, botão flutuante de câmera (`btn_alterar_foto_perfil_hub`) para troca rápida da foto, nome, função esportiva e botão cápsula `"Editar perfil"`.
- **Formatação de Domínio**: Utilitários como `getGrauString` e `getGrauValue` (em `via_functions.dart`) realizam a conversão limpa dos enums Protobuf para a notação de graduação brasileira (esportiva, boulder, móvel).
- **Marcadores Customizados**: O módulo `mapa/mapa_marker.dart` utiliza a API do `Canvas` e `Path` nativos do Flutter para gerar mapas de bits (`BitmapDescriptor`) com o logotipo do Aresta, adaptando o tamanho dinamicamente conforme a densidade de pixels do dispositivo.
- **Suporte Offline e Markdown Enriquecido**: O componente `markdown_offline.dart` garante que qualquer imagem referenciada em textos Markdown seja carregada diretamente do disco (`FileImage`). Além disso, com os módulos `sintaxe_tag_small.dart` e `construtor_elemento_small.dart`, o aplicativo suporta nativamente a tag HTML semântica `<small>` para textos e notas com escala reduzida (80%), preservando alinhamento de linha de base e formatação aninhada.
- **Abertura Resiliente de Croquis (`handlePicoSelection`)**: A função central de seleção de picos em `funcoes_home.dart` diferencia falhas de conectividade em croquis ainda não baixados (`!isBaixado` — registrando apenas breadcrumb via `AppLogger.logAviso` e exibindo `SnackBar` contextualizada com ícone `cloud_off_outlined` e ação `"Tentar novamente"`) de falhas de integridade em croquis que já constam como salvos localmente (`isBaixado` — reportando erro rastreável via `AppLogger.logError`).

---

## 2. Modelos de Apresentação (`view_models/`)

A camada de View Models encapsula toda a lógica de exibição, regras de ordenação e valores computados necessários para a interface:

### Por que View Models em vez de DTOs de Apresentação?
Em versões anteriores, utilizavam-se estruturas denominadas DTOs para carregar dados de tela. No entanto, na camada de apresentação, o padrão mais adequado é o **View Model**:
- **Responsabilidade Clara**: Um View Model possui a responsabilidade explícita de preparar, formatar e expor os dados para a UI, calculando valores derivados (como distâncias euclidianas em quilômetros ou rótulos compostos).
- **Sem Cópias Redundantes**: Os View Models acessam diretamente as entidades e mensagens Protobuf através de getters organizados, sem duplicar estruturas em memória.
- **Isolamento e Segurança de Tipos**: Protegem a interface de variações na estrutura de dados subjacente, fornecendo contratos claros e testáveis.

### Principais View Models
- **`LoginViewModel`**: Coordena o fluxo sem senha em duas etapas de código OTP de 6 dígitos por e-mail (com janela deslizante de 6 envios por 60 segundos), autenticação in-app com Google e Apple, tratamento silencioso de cancelamento voluntário, roteamento de falhas reais ao `AppLogger` e proteção contra notificações pós-`dispose`.
- **`HubPerfilCadernetaViewModel`**: Expõe reativamente os dados do `PerfilEscalador` (`nomeAtleta`, `fotoUrl`, `autorIdPublico`, `estaAutenticado`), métricas rápidas (`totalCadenas`, `totalTentativas`, `totalPicos`, `totalVias`) e comandos de atualização de nome e foto (`atualizarNome`, `atualizarFotoPerfil`, `selecionarEAtualizarFoto`, `selecionarEObterNovaFoto`, `copiarIdPublico`, `encerrarSessao`).
- **`ViaViewModel`**: Centraliza a extração sem duplicação das cinco modalidades Protobuf (`ViaEsportiva`, `ViaMovel`, `Boulder`, `ViaMultiplasEnfiadas`, `Highline`), unificando grau oficial do conquistador + consenso comunitário, bolhas flutuantes de alerta estilo Waze (`reportarAlerta`, `confirmarAlerta`), atributos técnicos, linha do tempo de enfiadas (`ResumoEnfiadaVia`), mídias externas (`escalada.betas` + `urlVideoBeta`), cópia funcional de chave Pix e ocultação reativa atrás de `ControladorInteracoesUsuario.exibirElementosInterativos`.
- **`CardCroquiViewModel`**: Unifica a apresentação de picos em formato de card (usado tanto na tela inicial quanto na busca global e catálogo). Expõe contagem de vias, autores, setores e status de download.
- **`MapaPicoViewModel`**: Fornece os pontos geográficos (latitude e longitude), título e identificador de picos para renderização nativa de marcadores no Google Maps.
- **`MapaGlobalViewModel`**: Gerencia a conversão de identificadores de picos e cartões (`CardCroquiViewModel`) em marcadores geográficos com coordenadas (`MapaPicoViewModel`), provendo fallback transparente para o catálogo completo e monitoramento reativo de downloads.
- **`PicoProximoViewModel`**: Computa a distância geográfica em quilômetros entre a localização GPS do dispositivo e as coordenadas do pico, ordenando o carrossel de picos mais próximos.
- **View Models de Páginas**: Coordenam o ciclo de vida reativo e filtros de páginas como `ExplorarPage`, `HomePage`, `PicoPage` e `MeusCroquisPage`.

---

## Diretrizes de Contribuição

1. **Tudo em Português**: Nomes de classes, métodos, variáveis e documentação devem ser integralmente em português brasileiro (`pt-BR`).
2. **Espelhamento de Testes**: Qualquer novo arquivo criado em `lib/view/` deve ter seu teste correspondente em `test/view/` (`function_library/` ou `view_models/`).
3. **Simplicidade**: Evite heranças complexas ou abstrações prematuras. Prefira funções diretas e classes imutáveis com construtores `const`.
