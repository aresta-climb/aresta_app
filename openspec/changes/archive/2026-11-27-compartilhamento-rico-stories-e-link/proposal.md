# Proposta: Compartilhamento Rico com Cartões Visuais para Stories e Link Rápido

## Why

Atualmente, o `ServicoCompartilhamento` envia apenas texto puro (`text/plain`) para o menu nativo do sistema operacional (`share_plus`), o que faz o Android e o iOS ocultarem o destino **Instagram Stories** (que exige mídia `image/*` ou `video/*`). Por outro lado, substituir todo compartilhamento por imagem impediria o WhatsApp e mensageiros diretos de renderizarem o card OpenGraph clicável (`aresta.cc/s/<uid>`), reduzindo a conversão direta para download do aplicativo. Precisamos preservar o fluxo clicável de link para mensageiros e oferecer um cartão editorial limpo em PNG para Stories com assinatura discreta de marca (`arestaclimb.com` / `@arestaclimb`), cópia automática do link curto e gatilhos rápidos pós-registro na caderneta.

## What Changes

- **Modelo unificado `DadosCartaoCompartilhamento` (`frontend/lib/data/modelos/dados_cartao_compartilhamento.dart`)**: Abstração imutável para representar Pico/Croqui, Grupo, Setor e Escalada (com resolução em cascata de imagem de capa/mapa, pílula `LINHA #N`, faixa de graus, contagens, modalidades e selo esportivo opcional sem expor `notasPrivadas`).
- **Cartão editorial para Stories (`frontend/lib/widgets/compartilhamento/cartao_compartilhamento_aresta.dart`)**: Widget declarativo em tema escuro basalto/pinheiro que destaca a rocha e os dados da entidade/conquista, omitindo integralmente notas privadas e exibindo no rodapé uma assinatura discreta (`Aresta Climb • arestaclimb.com • @arestaclimb`) sem QR Code.
- **Captura assíncrona em PNG (`frontend/lib/services/compartilhamento/capturador_imagem_cartao.dart`)**: Captura via `RepaintBoundary` em alta nitidez sem bloquear o orçamento de meio frame da UI.
- **BottomSheet unificado (`frontend/lib/widgets/compartilhamento/modal_compartilhamento_entidade.dart`)**: Pré-visualização ao vivo do cartão com duas ações explícitas: **Compartilhar Imagem (Stories)** (exporta `image/png` via `share_plus`, copia `https://aresta.cc/s/<uid>` automaticamente para a área de transferência e exibe toast orientativo) e **Compartilhar Link (WhatsApp)** (mantém `text/plain` preservando o card OpenGraph clicável).
- **Integração nas quatro páginas e na Caderneta**: Atualização dos botões de compartilhamento em `pico.dart`, `grupo.dart`, `setor.dart` e `via.dart`, além de atalho rápido no selo de ascensão no Passaporte da Via e ação `Compartilhar` no toast exibido ao salvar uma cadena ou tentativa.
- **Telemetria diferenciada por formato**: Inclusão do parâmetro `formato` (`'link'` ou `'imagem_stories'`) no evento `compartilhar_entidade` de `TelemetryService`.
- **Internacionalização e Fake determinístico**: Novas chaves tipadas em `ChaveTexto` nos 5 idiomas suportados (`pt`, `en`, `es`, `de`, `nl`) e criação de `ServicoCompartilhamentoFake` testado.

## Capabilities

### New Capabilities

_(Nenhuma nova capability isolada; os novos requisitos estendem diretamente a especificação `compartilhamento-entidades`.)_

### Modified Capabilities

- `compartilhamento-entidades`: Evolui o fluxo de compartilhamento de Pico/Croqui, Grupo, Setor e Escalada para abrir um BottomSheet com pré-visualização visual e escolha entre link clicável (`text/plain`) e cartão PNG para Stories (`image/png`), com cópia automática do link curto, omissão de notas privadas, gatilhos rápidos na caderneta e telemetria por formato.

## Impact

- **Código de Produção (`frontend/lib/`)**:
  - `idioma/modelo_idioma_app.dart` e `idioma/dicionario_{pt,en,es,de,nl}.dart`
  - `data/modelos/dados_cartao_compartilhamento.dart`
  - `services/firebase/telemetria.dart`
  - `services/compartilhamento/servico_compartilhamento.dart` e `capturador_imagem_cartao.dart`
  - `widgets/compartilhamento/cartao_compartilhamento_aresta.dart` e `modal_compartilhamento_entidade.dart`
  - `view/view_models/via_view_model.dart`, `view/function_library/via_functions.dart`, `pages/pico.dart`, `pages/grupo.dart`, `pages/setor.dart`, `pages/via.dart`
- **Testes e Governança (`frontend/test/` e `README.md`)**:
  - Espelhamento 1:1 com TDD para todos os novos arquivos, criação de `test/fakes/servico_compartilhamento_fake.dart` (+ `_test.dart`), atualização dos testes das páginas/ViewModels/telemetria e atualização do `frontend/README.md`.
- **Dependências**: Nenhuma dependência externa nova necessária (`share_plus`, `flutter/rendering` e `flutter/services` já atendem integralmente).
