# Testes da Camada de Apresentação (`test/view/`)

Esta pasta contém os testes unitários e de widget dedicados à camada de apresentação do Aresta Climb, espelhando a estrutura de `lib/view/`.

---

## Estrutura de Diretórios

```text
test/view/
├── function_library/             - Testes de funções auxiliares, formatações e builders de UI
│   ├── funcoes_explorar_test.dart - Testes da interface e ações de exploração
│   ├── biblioteca_funcoes_comuns_test.dart - Testes de funções comuns, normalização e busca
│   ├── comunidade_functions_test.dart - Testes do hub de comunidade
│   ├── funcoes_caderneta_test.dart - Testes da seção de histórico e cards da caderneta
│   ├── funcoes_hub_perfil_caderneta_test.dart - Testes do cabeçalho, avatar/câmera, cartões de métricas e menu do Hub de Perfil
│   ├── fuzzy_search_test.dart     - Testes do algoritmo de busca tolerante a erros
│   ├── grupo_functions_test.dart  - Testes de visualização de grupos de setores
│   ├── funcoes_home_test.dart     - Testes de layout e listas da tela inicial
│   ├── meus_croquis_functions_test.dart - Testes do gerenciamento de croquis baixados
│   ├── markdown_offline_test.dart - Testes de renderização offline de Markdown
│   ├── pico_functions_test.dart   - Testes de funções de apoio da tela do Pico
│   ├── pico_functions_widget_test.dart - Testes de widget da página do Pico
│   ├── pico_search_online_test.dart - Testes da busca e carregamento de picos online
│   ├── setor_functions_test.dart  - Testes de resolução de rótulos e itens de setor
│   ├── funcoes_configuracoes_test.dart - Testes de conexão de editor e configurações
│   ├── sobre_time_functions_test.dart - Testes de carregamento e cartões da equipe
│   ├── via_functions_test.dart    - Testes de conversão e extração de graus de vias
│   ├── via_functions_widget_test.dart - Testes de widget para exibição de vias
│   └── mapa/
│       ├── mapa_global_functions_test.dart - Testes de montagem do mapa global e zoom
│       └── mapa_marker_test.dart  - Testes de geração de bitmaps customizados via Canvas
└── view_models/                  - Testes unitários dos modelos de apresentação
    ├── login_view_model_test.dart - Testes de entrada, criação de conta, Google OAuth e tratamento de erros
    ├── hub_perfil_caderneta_view_model_test.dart - Testes do estado reativo do perfil, atualização de nome/foto e métricas da caderneta
    ├── perfil_view_model_test.dart - Testes de estatísticas e histórico da caderneta esportiva
    ├── explorar_view_model_test.dart - Testes do estado reativo do Explorar
    ├── card_croqui_view_model_test.dart - Testes dos metadados e contagens de cartões de croqui
    ├── comunidade_view_model_test.dart - Testes de estado do hub comunitário
    ├── home_view_model_test.dart  - Testes do catálogo e carrossel da Home
    ├── mapa_global_view_model_test.dart - Testes de pontos e marcadores do mapa global
    ├── mapa_pico_view_model_test.dart - Testes de coordenadas e projeção de picos no mapa
    ├── meus_croquis_view_model_test.dart - Testes de ordenação e filtros de croquis salvos
    ├── pico_proximo_view_model_test.dart - Testes de cálculo de distância GPS e proximidade
    ├── pico_view_model_test.dart  - Testes de estado de subpáginas e setores do pico
    └── configuracoes_view_model_test.dart - Testes de preferências e modo de desenvolvedor
```

---

## Como Executar

```bash
# Executar todos os testes da camada de apresentação
flutter test test/view/

# Executar apenas testes de funções utilitárias e builders
flutter test test/view/function_library/

# Executar apenas testes dos view models
flutter test test/view/view_models/

# Executar um teste específico de view model
flutter test test/view/view_models/hub_perfil_caderneta_view_model_test.dart
```

---

## Convenções de Teste

- **Isolamento**: Testes em `view_models/` validam a lógica de apresentação e estado sem acoplamento a Scaffolds, enquanto `function_library/` combina testes de unidade e testes com `testWidgets`.
- **Nomenclatura Descritiva**: Todos os nomes de suítes (`group`) e casos de teste (`test` / `testWidgets`) são redigidos em português brasileiro claro, expressando o comportamento esperado.
- **Resiliência a Mudanças**: Testes de View Models validam o desacoplamento de entidades Protobuf e garantem que cálculos como distâncias e estatísticas tratem valores nulos ou vazios de forma segura.
