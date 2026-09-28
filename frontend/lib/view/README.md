# Camada de Apresentação e Visualização (`lib/view/`)

Este diretório concentra a camada de apresentação e visualização da aplicação Aresta Climb, organizada segundo o padrão de arquitetura **MVVM (Model-View-ViewModel)** e o princípio **Feature-First** (Diretriz II do `AGENTS.md`).

A finalidade desta camada é manter os arquivos de telas (`lib/pages/`) enxutos e focados estritamente na composição do Scaffold, ciclo de vida do Flutter e integração com o sistema de navegação reativa (`PageListenableBuilder`). Todo o trabalho pesado de montagem de componentes visuais, callbacks, cálculo de dados derivados de tela e formatação é delegado a este módulo.

---

## Estrutura de Diretórios

```text
lib/view/
├── function_library/             - Biblioteca de funções construtoras de UI e callbacks
│   ├── common_functions.dart     - Componentes base, menus suspensos e barras de navegação
│   ├── browse_functions.dart     - Construtores de tela e lógica da página Explorar
│   ├── home_functions.dart       - Renderizadores da tela inicial e carrossel
│   ├── pico_functions.dart       - Cabeçalho, botões e seções da página do Pico
│   ├── setor_functions.dart      - Listagem de vias, badges FEMEMG e itens de setor
│   ├── via_functions.dart        - Visualizador de beta, croquis e formatação de graus
│   ├── comunidade_functions.dart - Links e ações do hub comunitário
│   ├── grupo_functions.dart      - Resumo e listagem de subsetores
│   ├── meus_croquis_functions.dart - Gerenciamento e listagem de downloads locais
│   ├── settings_functions.dart   - Conexão com Editor Desktop, QR Code e temas
│   ├── sobre_time_functions.dart - Listagem tipada de membros e colaboradores
│   ├── offline_markdown.dart     - Renderização de Markdown com imagens em disco
│   ├── gps_functions.dart        - Utilitários de geolocalização e mapas
│   └── mapa/
│       ├── mapa_global_functions.dart - Marcadores, bottom sheet e zoom do Mapa Global
│       └── mapa_marker.dart      - Desenho via Canvas do pino vetorial da marca
└── view_models/                  - Modelos de apresentação e gerenciamento de estado de tela
    ├── browse_view_model.dart    - Estado reativo de filtros, downloads e busca no Explorar
    ├── card_croqui_view_model.dart - Modelo de apresentação para cartões de croqui
    ├── comunidade_view_model.dart- Estado de links e mídias sociais comunitárias
    ├── home_view_model.dart      - Estado do carrossel principal e listas locais
    ├── mapa_global_view_model.dart - Estado dos marcadores e coordenadas do mapa global
    ├── mapa_pico_view_model.dart - Apresentação e coordenadas de picos para o Google Maps
    ├── meus_croquis_view_model.dart - Estado de filtragem e remoção de croquis baixados
    ├── pico_proximo_view_model.dart - Cálculo de distâncias e proximidade do usuário
    ├── pico_view_model.dart      - Estado de subpáginas e estatísticas do pico ativo
    └── settings_view_model.dart  - Estado do modo de desenvolvedor e preferências
```

---

## 1. Biblioteca de Funções (`function_library/`)

Os arquivos da `function_library` são coleções de funções puras e construtores de widgets (`build...`) que recebem dados fortemente tipados e o `BuildContext`, retornando a árvore de widgets correspondente:

- **Desacoplamento e Testabilidade**: Ao isolar construtores de UI em funções especializadas, os testes de widget podem ser executados isoladamente sem necessidade de instanciar scaffolds complexos ou navegação global.
- **Formatação de Domínio**: Utilitários como `getGrauString` e `getGrauValue` (em `via_functions.dart`) realizam a conversão limpa dos enums Protobuf para a notação de graduação brasileira (esportiva, boulder, móvel).
- **Marcadores Customizados**: O módulo `mapa/mapa_marker.dart` utiliza a API do `Canvas` e `Path` nativos do Flutter para gerar mapas de bits (`BitmapDescriptor`) com o logotipo do Aresta, adaptando o tamanho dinamicamente conforme a densidade de pixels do dispositivo.
- **Suporte Offline**: O componente `offline_markdown.dart` garante que qualquer imagem referenciada em textos Markdown seja carregada diretamente do disco (`FileImage`), mantendo o compromisso de funcionamento 100% offline.

---

## 2. Modelos de Apresentação (`view_models/`)

A camada de View Models encapsula toda a lógica de exibição, regras de ordenação e valores computados necessários para a interface:

### Por que View Models em vez de DTOs de Apresentação?
Em versões anteriores, utilizavam-se estruturas denominadas DTOs para carregar dados de tela. No entanto, na camada de apresentação, o padrão mais adequado é o **View Model**:
- **Responsabilidade Clara**: Um View Model possui a responsabilidade explícita de preparar, formatar e expor os dados para a UI, calculando valores derivados (como distâncias euclidianas em quilômetros ou rótulos compostos).
- **Sem Cópias Redundantes**: Os View Models acessam diretamente as entidades e mensagens Protobuf através de getters organizados, sem duplicar estruturas em memória.
- **Isolamento e Segurança de Tipos**: Protegem a interface de variações na estrutura de dados subjacente, fornecendo contratos claros e testáveis.

### Principais View Models
- **`CardCroquiViewModel`**: Unifica a apresentação de picos em formato de card (usado tanto na tela inicial quanto na busca global e catálogo). Expõe contagem de vias, autores, setores e status de download.
- **`MapaPicoViewModel`**: Fornece os pontos geográficos (latitude e longitude), título e identificador de picos para renderização nativa de marcadores no Google Maps.
- **`PicoProximoViewModel`**: Computa a distância geográfica em quilômetros entre a localização GPS do dispositivo e as coordenadas do pico, ordenando o carrossel de picos mais próximos.
- **View Models de Páginas**: Coordenam o ciclo de vida reativo e filtros de páginas como `BrowsePage`, `HomePage`, `PicoPage` e `MeusCroquisPage`.

---

## Diretrizes de Contribuição

1. **Tudo em Português**: Nomes de classes, métodos, variáveis e documentação devem ser integralmente em português brasileiro (`pt-BR`).
2. **Espelhamento de Testes**: Qualquer novo arquivo criado em `lib/view/` deve ter seu teste correspondente em `test/view/` (`function_library/` ou `view_models/`).
3. **Simplicidade**: Evite heranças complexas ou abstrações prematuras. Prefira funções puras e classes imutáveis com construtores `const`.
