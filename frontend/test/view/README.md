# Testes da Camada de Apresentação (`test/view/`)

Este diretório contém os testes unitários e de widget que espelham `lib/view/`.

---

## Estrutura

```text
test/view/
├── function_library/                          - Testes dos construtores de UI e funções auxiliares
│   ├── biblioteca_funcoes_comuns_test.dart    - buildCommonAppBar (com retorno por toque/segurar), busca e normalização
│   ├── funcoes_home_test.dart                 - Seções da Home e abertura de picos
│   ├── funcoes_explorar_test.dart             - Lista do Explorar e barra de progresso
│   ├── pico_functions_test.dart               - Extração de botões e metadados do Pico
│   ├── pico_functions_widget_test.dart        - Renderização de componentes do Pico
│   ├── pico_search_online_test.dart           - Busca de vias e setores no Pico
│   ├── grupo_functions_test.dart              - Listagem de grupos
│   ├── setor_functions_test.dart              - Rótulos e itens de lista de setor
│   ├── via_functions_test.dart                - Conversão de graus, modalidades e proteções
│   ├── via_functions_widget_test.dart         - Renderização de CorpoDetalhesVia
│   ├── meus_croquis_functions_test.dart       - Gerenciamento de croquis baixados
│   ├── comunidade_functions_test.dart         - Links da aba Comunidade
│   ├── funcoes_hub_perfil_caderneta_test.dart - Avatar, cabeçalho, métricas e menu do Perfil
│   ├── funcoes_caderneta_test.dart            - Histórico de ascensões e exclusão
│   ├── funcoes_configuracoes_test.dart        - Preferências e conexão com Editor Desktop
│   ├── sobre_time_functions_test.dart         - Cartões dos integrantes
│   ├── markdown_offline_test.dart             - Imagens locais e tag <small> em Markdown
│   ├── sintaxe_tag_small_test.dart            - Parser da tag <small>
│   ├── construtor_elemento_small_test.dart    - Renderização da tag <small>
│   ├── fuzzy_search_test.dart                 - Busca aproximada sem diferenciação de acentos
│   └── mapa/
│       ├── mapa_global_functions_test.dart    - Marcadores, faixas de zoom e bottom sheet
│       └── mapa_marker_test.dart              - Geração de bitmaps de marcadores via Canvas
└── view_models/                               - Testes unitários dos ViewModels
    ├── login_view_model_test.dart             - Fluxo sem senha (OTP, Google, Apple) e limites de envio
    ├── hub_perfil_caderneta_view_model_test.dart - Perfil, foto, métricas, saída e exclusão de conta
    ├── edicao_perfil_view_model_test.dart     - Edição de nome e foto
    ├── perfil_view_model_test.dart            - Estatísticas, histórico e alertas na Caderneta
    ├── via_view_model_test.dart               - Modalidades, votação de grau, alertas com desfazer e Pix
    ├── formulario_alerta_via_view_model_test.dart - Seleção de categoria e formatação de alertas
    ├── alertas_mapa_interativo_view_model_test.dart - Projeção e confirmação de alertas no croqui
    ├── secao_caderneta_via_view_model_test.dart - Resumo pessoal de ascensões na ViaPage
    ├── registro_cadena_view_model_test.dart   - Registro/edição de cadena e contribuição pública
    ├── home_view_model_test.dart              - Catálogo e carrossel da Home
    ├── explorar_view_model_test.dart          - Ordenação, busca e downloads do Explorar
    ├── meus_croquis_view_model_test.dart      - Filtros e remoção de croquis salvos
    ├── pico_view_model_test.dart              - Estado online/offline e subpáginas do Pico
    ├── mapa_global_view_model_test.dart       - Pontos e marcadores do Mapa Global
    ├── mapa_pico_view_model_test.dart         - Coordenadas de picos para o Google Maps
    ├── card_croqui_view_model_test.dart       - Metadados de cartões de croqui
    ├── pico_proximo_view_model_test.dart      - Cálculo de distância GPS
    ├── comunidade_view_model_test.dart        - Links comunitários
    └── configuracoes_view_model_test.dart     - Preferências e modo de desenvolvedor
```

---

## Execução

```bash
flutter test test/view/
flutter test test/view/function_library/
flutter test test/view/view_models/
```

---

## Convenções de Teste

- **Isolamento**: Testes em `view_models/` validam a lógica de apresentação e estado sem acoplamento a Scaffolds, enquanto `function_library/` combina testes de unidade e testes com `testWidgets`.
- **Nomenclatura Descritiva**: Todos os nomes de suítes (`group`) e casos de teste (`test` / `testWidgets`) são redigidos em português brasileiro claro, expressando o comportamento esperado.
- **Resiliência a Mudanças**: Testes de View Models validam o desacoplamento de entidades Protobuf e garantem que cálculos como distâncias e estatísticas tratem valores nulos ou vazios de forma segura.
