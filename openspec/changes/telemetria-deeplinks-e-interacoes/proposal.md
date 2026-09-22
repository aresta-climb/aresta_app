# Proposta: Telemetria para Deep Links, QR Codes e Interações de Interface

## Why

Atualmente, quando um escalador acessa o Aresta Climb escaneando um QR Code físico em uma montanha ou tocando em um In-App Link (Android App Links / iOS Universal Links), o sistema operacional intercepta a requisição e abre o aplicativo diretamente. Como a requisição web é ignorada pelo sistema operacional, nenhum dado trafega pelo servidor web nem pelo analytics do site (Cloudflare, Umami). Simultaneamente, o aplicativo móvel descarta os parâmetros de campanha (UTM) e não registra nenhum evento de telemetria, tornando o uso de QR Codes em rochas e guias físicos completamente invisível para os gestores e autores de croquis.

Além disso, diversas interações chave do usuário na interface — como abertura do modal de Beta Aberto, clique para cópia de chave PIX de manutenção do pico, ações do guardião de saída ("Salvar Offline" vs "Sair sem Salvar"), botões de redes sociais e filtros de ordenação — não possuem registro analítico, impedindo a compreensão precisa do engajamento e das funcionalidades mais valorizadas pela comunidade.

Implementar essa cobertura analítica agora é essencial para medir a adesão real de placas físicas nos picos e mapear o comportamento do usuário durante a fase de Beta Aberto.

## What Changes

- **Captura e Preservação de Metadados de Deep Links**: O analisador de rotas (`DeepLinkRouteParser`) passa a extrair e reter parâmetros de consulta (`queryParameters`), incluindo `utm_source`, `utm_medium`, `utm_campaign` e `origem`.
- **Rastreamento de Inicialização e Navegação via Deep Link / QR Code**: O serviço de navegação profunda (`DeepLinkNavigatorService`) passa a despachar evento estruturado no `TelemetryService` (`deep_link_aberto` ou `acao_deep_link`), registrando se a abertura foi em inicialização a frio (*Cold Start*) ou retorno de segundo plano (*Warm Start*), o destino alcançado (`pico`, `grupo`, `setor`, `via`) e se o carregamento foi bem-sucedido ou falhou (ex: sem conexão à internet).
- **Telemetria do Modal de Beta Aberto e Canais Oficiais**: Disparo de eventos ao abrir o modal de Beta Aberto (ao clicar no logotipo ou badge `BETA` da Home) e ao clicar nos botões de Instagram Oficial, Comunidade WhatsApp e Enviar Sugestão dentro do modal.
- **Telemetria de Apoio ao Pico e PIX**: Disparo de evento ao tocar para copiar a chave PIX de manutenção das proteções ou acessar produtos e informações do pico.
- **Telemetria do Guardião de Saída e Modo Online**: Registro de eventos ao exibir o modal de confirmação de saída (`ModalConfirmacaoSaida`), na escolha de salvar offline ou sair sem salvar, e ao acionar o botão "Salvar Offline" no banner de modo online.
- **Telemetria de Ações Comunitárias e Redes**: Registro de cliques nos links externos da tela de Comunidade e da tela "Sobre o Time" (WhatsApp, Instagram, LinkedIn, Discord, GitHub e membros do time).
- **Telemetria de Hub de Páginas e Ordenação**: Rastreamento de navegação nos cards centrais do pico (Setores, Explorar Local, Regras, Comunidade, Créditos) e da alteração de filtros/ordenação de setores e vias.

## Capabilities

### New Capabilities
- `telemetria-interacoes-usuario`: Rastreamento estruturado no `TelemetryService` para interações de interface de alto valor que atualmente não possuem métricas, cobrindo o modal de Beta Aberto, botões de apoio PIX, guardião de saída, banners offline, links comunitários externos e ordenação de listas.

### Modified Capabilities
- `qr-deep-linking`: Adiciona o requisito de extração de parâmetros UTM e despacho de telemetria ao interceptar, resolver e navegar para destinos via App Links / Universal Links e QR Codes físicos.

## Impact

- **Código Afetado**:
  - `lib/navigation/deep_link_route_parser.dart`
  - `lib/navigation/deep_link_navigator_service.dart`
  - `lib/services/firebase/telemetry_service.dart`
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
  - Testes de widgets correspondentes às telas com novas chamadas de telemetria (garantindo 100% de cobertura).
- **Dependências Externas**: Nenhuma dependência externa nova é necessária; utiliza o Firebase Analytics já configurado via `TelemetryService`.
