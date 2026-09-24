## 1. Extensão do TelemetryService

- [x] 1.1 Criar testes unitários para os novos métodos de telemetria no `test/services/firebase/telemetry_service_test.dart` (incluindo `logAcaoIndiceEscaladas`, `logDeepLinkAberto`, `logAcaoBetaAberto`, `logApoioPix`, etc.) e verificar que falham inicialmente (TDD).
- [x] 1.2 Implementar os novos métodos no `TelemetryService` suportando a dimensão `detalhe`, ações padronizadas (`filtrar_grau`, `filtrar_setor`, `filtrar_conquistador`, `filtrar_classicas`, `limpar_filtros`) e verificar aprovação dos testes unitários.

## 2. Captura de UTM e Telemetria de Deep Links / QR Codes

- [x] 2.1 Adicionar testes unitários em `test/navigation/deep_link_route_parser_test.dart` validando a extração de `queryParameters` (incluindo `utm_source`, `utm_medium`, `utm_campaign`) e verificar que falham inicialmente.
- [x] 2.2 Atualizar `RotaDeepLink` e `DeepLinkRouteParser` para reter e expor `parametros`, verificando aprovação dos testes do parser.
- [x] 2.3 Adicionar testes em `test/navigation/deep_link_navigator_service_test.dart` verificando que `logDeepLinkAberto` é chamado com metadados de sucesso, falha, tipo de start e parâmetros UTM, verificando que falham inicialmente.
- [x] 2.4 Integrar o disparo de `logDeepLinkAberto` no `DeepLinkNavigatorService.processarLink` e verificar aprovação de todos os testes de navegação de links profundos.

## 3. Telemetria do Índice de Escaladas e Filtros Contextuais

- [x] 3.1 Adicionar testes de widget em `test/pages/pico_test.dart` para validar que o toque no card "ÍNDICE DE ESCALADAS" dispara telemetria com `acao: 'abrir_indice_escaladas'` e `origem: 'pico_hub'`, verificando falha inicial.
- [x] 3.2 Instrumentar o card "ÍNDICE DE ESCALADAS" em `PicoDetailsPage` com `logNavegacaoPicoHub` ou `logAcaoCroqui` e verificar aprovação do teste.
- [x] 3.3 Adicionar testes de widget em `test/pages/indice_escaladas_page_test.dart` para verificar disparo ao alternar abas de modalidade (`acao: 'trocar_aba'`) e toque em cards de via (`acao: 'abrir_detalhes'`, `origem: 'indice_<modalidade>'`), verificando falha inicial.
- [x] 3.4 Instrumentar `IndiceEscaladasPage` com `logAcaoIndiceEscaladas` e `logAcaoEscalada` no clique do `CardIndiceEscalada`, verificando aprovação dos testes.
- [x] 3.5 Adicionar testes de widget em `test/widgets/painel_filtros_indice_test.dart` validando disparo das ações `filtrar_grau`, `filtrar_setor`, `filtrar_conquistador`, `filtrar_classicas`, `limpar_filtros`, `expandir_filtros` e `colapsar_filtros`, verificando falha inicial.
- [x] 3.6 Instrumentar `PainelFiltrosIndice` com `logAcaoIndiceEscaladas` enviando os valores dinâmicos no parâmetro `detalhe` e verificar aprovação dos testes.

## 4. Telemetria do Modal de Beta Aberto e Cabeçalho da Home

- [x] 4.1 Adicionar testes de widget em `test/widgets/modal_beta_aberto_test.dart` e `test/pages/home_test.dart` para validar que abrir o modal e clicar nos botões sociais/feedback dispara telemetria, verificando que falham inicialmente.
- [x] 4.2 Instrumentar `exibirModalBetaAberto` e os botões de Instagram, WhatsApp e Enviar Sugestão em `ModalBetaAberto` com chamadas ao `TelemetryService`, verificando aprovação dos testes de widget.

## 5. Telemetria do Pico, Subpáginas, Guardião de Saída e Banner Online

- [x] 5.1 Escrever testes de widget para cópia da chave PIX em `test/pages/pico_subpages/apoie_pico_page_test.dart`, navegação nos cards centrais em `test/pages/pico_test.dart`, e ações do Guardião de Saída e Banner Modo Online, verificando que falham inicialmente.
- [x] 5.2 Instrumentar `ApoiePicoPage` para disparar `logApoioPix` ao tocar na chave PIX e verificar aprovação do teste.
- [x] 5.3 Instrumentar os cards de hub do pico (`Setores`, `Explorar Local`, `Regras`, `Comunidade`, `Créditos`) em `PicoDetailsPage` com `logNavegacaoPicoHub` e verificar aprovação dos testes.
- [x] 5.4 Instrumentar `ModalConfirmacaoSaida` e `BannerModoOnline` com `logAcaoGuardiaoSaida` e `logSalvarOfflineBanner`, verificando aprovação dos testes.

## 6. Telemetria da Comunidade, Sobre o Time e Ordenação

- [x] 6.1 Escrever testes de widget para os links externos em `test/pages/comunidade_test.dart` e `test/pages/sobre_time_test.dart`, além das ordenações em `SetorPage` e `BrowsePage`, verificando que falham inicialmente.
- [x] 6.2 Instrumentar os cards de redes/links em `ComunidadePage` e membros/links em `SobreTimePage` com `logLinkExterno` enviando a URL no parâmetro `detalhe`, verificando aprovação dos testes.
- [x] 6.3 Instrumentar as opções de ordenação em `SetorPage`, `GrupoPage` e `BrowsePage` com `logAlterarOrdenacao` e verificar aprovação dos testes.

## 7. Verificação e Conformidade Geral

- [x] 7.1 Executar a suíte completa de testes (`flutter test`) garantindo que nenhum teste regrediu e que 100% de cobertura de código foi mantida.
- [x] 7.2 Executar o analisador estático (`flutter analyze`) para validar ausência de warnings, lints ou violações de regras do projeto.
