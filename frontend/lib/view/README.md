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
    ├── explorar_view_model.dart          - Busca, ordenação, clima/incêndios e downloads da aba Explorar
    ├── cena_globo_explorar_view_model.dart - Estado interativo do Globo/Mapa (hidratação de assets, memoização de instância da rede viária Aresta, luz viária bidirecional, sonar e foco de câmera)
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

Funções e widgets sem acesso direto a `services/` nos módulos migrados:
- **`biblioteca_funcoes_comuns.dart`**: Constrói a `AppBar` padrão (`buildCommonAppBar`) com `BotaoVoltarComRetornoInicio` e botão de feedback, além da barra de navegação principal (`buildPrimaryBottomNav`) e utilitários de normalização de texto.
- **`via_functions.dart`**: Expõe `CorpoDetalhesVia` e funções puras de formatação de graus e proteções.
- **`funcoes_hub_perfil_caderneta.dart`**: Resolve avatares em base64 (`MemoryImage`) ou URL (`NetworkImage`) e monta o cabeçalho, métricas e opções do Hub de Perfil.
- **`markdown_offline.dart`**: Carrega imagens referenciadas em Markdown a partir do armazenamento local e suporta a tag `<small>`.

---

## 2. `view_models/`

Classes que preparam os dados de domínio para exibição e tratam ações da interface:
- **`LoginViewModel`**: Controla o envio e validação do código OTP de 6 dígitos (limite de 6 envios por 60s), login com Google e Apple, cancelamento pelo usuário e mensagens de erro.
- **`HubPerfilCadernetaViewModel` e `PerfilViewModel`**: Sincronizam nome e foto de perfil, expõem contadores e pirâmides de grau e coordenam a resolução com desfazer dos alertas listados na `CadernetaPage`.
- **`ViaViewModel` e `AlertasMapaInterativoViewModel`**: Gerenciam consenso de grau, criação e confirmação (`+1` único por perfil ou resolução com janela de desfazer) dos 4 tipos de alerta de segurança na `ViaPage` e no `MapaInterativoPage`.
- **ViewModels de Catálogo e Mapas**: Calculam distâncias GPS, filtram listas e acompanham progresso de download.

---

## Convenções

1. **Idioma**: Identificadores, comentários e textos em português brasileiro.
2. **Testes 1:1**: Cada arquivo em `lib/view/` possui teste correspondente em `test/view/`.
3. **Separação MVVM**: Arquivos de UI declarativa não importam `lib/services/`.
