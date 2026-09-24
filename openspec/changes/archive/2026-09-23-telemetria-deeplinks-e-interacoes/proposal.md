# Proposta: Telemetria para Deep Links, QR Codes, Índice de Escaladas e Interações de Interface

## Why

Atualmente, quando um escalador acessa o Aresta Climb escaneando um QR Code físico em uma montanha ou tocando em um In-App Link (Android App Links / iOS Universal Links), o sistema operacional intercepta a requisição e abre o aplicativo diretamente. Como a requisição web é ignorada pelo sistema operacional, nenhum dado trafega pelo servidor web nem pelo analytics do site (Cloudflare, Umami). Simultaneamente, o aplicativo móvel descarta os parâmetros de campanha (UTM) e não registra nenhum evento de telemetria, tornando o uso de QR Codes em rochas e guias físicos completamente invisível para os gestores e autores de croquis.

Além disso, a nova tela de Índice de Escaladas (`IndiceEscaladasPage`), seus filtros contextuais (`PainelFiltrosIndice`) e diversas interações chave do usuário na interface — como abertura do modal de Beta Aberto, clique para cópia de chave PIX de manutenção do pico, ações do guardião de saída ("Salvar Offline" vs "Sair sem Salvar"), botões de redes sociais e filtros de ordenação — não possuem registro analítico, impedindo a compreensão precisa do engajamento e das funcionalidades mais valorizadas pela comunidade.

Implementar essa cobertura analítica agora é essencial para medir a adesão real de placas físicas nos picos e mapear o comportamento do usuário durante a fase de Beta Aberto, aproveitando ao máximo as dimensões analíticas já existentes no GA4 e adicionando apenas uma dimensão genérica (`detalhe`).

## What Changes

- **Captura e Preservação de Metadados de Deep Links**: O analisador de rotas (`DeepLinkRouteParser`) passa a extrair e reter parâmetros de consulta (`queryParameters`), incluindo `utm_source`, `utm_medium`, `utm_campaign` e `origem`.
- **Rastreamento de Inicialização e Navegação via Deep Link / QR Code**: O serviço de navegação profunda (`DeepLinkNavigatorService`) passa a despachar evento estruturado no `TelemetryService` (`deep_link_aberto` ou `acao_deep_link`), registrando se a abertura foi em inicialização a frio (*Cold Start*) ou retorno de segundo plano (*Warm Start*), o destino alcançado (`pico`, `grupo`, `setor`, `via`) e se o carregamento foi bem-sucedido ou falhou (ex: sem conexão à internet).
- **Telemetria do Índice de Escaladas e Filtros Contextuais**:
  - Ponto de entrada no pico: rastreamento ao tocar no card "ÍNDICE DE ESCALADAS" (`acao: 'abrir_indice_escaladas'`).
  - Alternância de abas de modalidade: registro de troca de aba (`acao: 'trocar_aba'`, `detalhe: modalidade`).
  - Painel de filtros com ações padronizadas: `filtrar_grau`, `filtrar_setor`, `filtrar_conquistador`, `filtrar_classicas`, `limpar_filtros`, `expandir_filtros`, `colapsar_filtros`.
  - Atribuição de modalidade na dimensão existente `origem` (ex: `indice_esportiva`, `indice_boulder`, `indice_movel`, etc.) e o valor do filtro na dimensão genérica `detalhe` (ex: `'5º a 8ºb'`, `'André Braga'`).
  - Toque no card de escalada: registro de `abrir_detalhes` com `origem: 'indice_<modalidade>'`.
- **Telemetria do Modal de Beta Aberto e Canais Oficiais**: Disparo de eventos ao abrir o modal de Beta Aberto (ao clicar no logotipo ou badge `BETA` da Home) e ao clicar nos botões de Instagram Oficial, Comunidade WhatsApp e Enviar Sugestão dentro do modal.
- **Telemetria de Apoio ao Pico e PIX**: Disparo de evento ao tocar para copiar a chave PIX de manutenção das proteções ou acessar produtos e informações do pico.
- **Telemetria do Guardião de Saída e Modo Online**: Registro de eventos ao exibir o modal de confirmação de saída (`ModalConfirmacaoSaida`), na escolha de salvar offline ou sair sem salvar, e ao acionar o botão "Salvar Offline" no banner de modo online.
- **Telemetria de Ações Comunitárias e Redes**: Registro de cliques nos links externos da tela de Comunidade e da tela "Sobre o Time" (WhatsApp, Instagram, LinkedIn, Discord, GitHub e membros do time).
- **Telemetria de Hub de Páginas e Ordenação**: Rastreamento de navegação nos cards centrais do pico (Setores, Explorar Local, Regras, Comunidade, Créditos) e da alteração de filtros/ordenação de setores e vias.

## Capabilities

### New Capabilities
- `telemetria-interacoes-usuario`: Rastreamento estruturado no `TelemetryService` para interações de interface de alto valor que atualmente não possuem métricas, cobrindo o Índice de Escaladas e seus filtros contextuais, modal de Beta Aberto, botões de apoio PIX, guardião de saída, banners offline, links comunitários externos e ordenação de listas.

### Modified Capabilities
- `qr-deep-linking`: Adiciona o requisito de extração de parâmetros UTM e despacho de telemetria ao interceptar, resolver e navegar para destinos via App Links / Universal Links e QR Codes físicos.

## Impact

- **Código Afetado**:
  - `lib/navigation/deep_link_route_parser.dart`
  - `lib/navigation/deep_link_navigator_service.dart`
  - `lib/services/firebase/telemetry_service.dart`
  - `lib/pages/indice_escaladas_page.dart`
  - `lib/widgets/painel_filtros_indice.dart`
  - `lib/widgets/card_indice_escalada.dart`
  - `lib/view_functions/home_functions.dart`
  - `lib/widgets/modal_beta_aberto.dart`
  - `lib/widgets/modal_confirmacao_saida.dart`
  - `lib/widgets/banner_modo_online.dart`
  - `lib/pages/pico.dart` e `lib/pages/pico_subpages/` (`apoie_pico_page.dart`, `comunidade_pico_page.dart`, `explorar_local_page.dart`, `setores_page.dart`)
  - `lib/pages/comunidade.dart` e `lib/pages/sobre_time.dart`
  - `lib/pages/browse.dart`
- **Testes Afetados**:
  - `test/navigation/deep_link_route_parser_test.dart`
  - `test/navigation/deep_link_navigator_service_test.dart`
  - `test/services/firebase/telemetry_service_test.dart`
  - `test/pages/indice_escaladas_page_test.dart`
  - `test/widgets/painel_filtros_indice_test.dart`
  - `test/widgets/card_indice_escalada_test.dart`
  - Testes de widgets correspondentes às telas com novas chamadas de telemetria (garantindo 100% de cobertura).
- **Dependências Externas**: Nenhuma dependência de pacote nova no `pubspec.yaml`; utiliza o Firebase Analytics já configurado com a adição de 1 dimensão genérica (`detalhe`) no Firebase Console.
