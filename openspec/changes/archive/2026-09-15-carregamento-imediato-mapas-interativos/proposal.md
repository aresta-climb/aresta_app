# Proposta: Carregamento Imediato e Não-Bloqueante de Mapas Interativos

## Why

Atualmente, ao abrir um croqui em modo online, a interface do setor e do mapa interativo apresenta alta latência percebida:
1. No setor, o componente `MapaThumbnail` bloqueia totalmente a exibição da área do mapa com um `CircularProgressIndicator` até que o download e decodificação da imagem sejam concluídos. O botão "Abrir Mapa Interativo" não existe durante esse período, deixando o usuário na incerteza sobre a disponibilidade da funcionalidade.
2. Na tela cheia do mapa (`MapaInterativoPage`), a árvore de widgets inteira é substituída por um spinner sobre tela preta, ocultando a barra superior (AppBar), o título do setor e a estrutura de navegação.

Como os metadados vetoriais e as dimensões do mapa (`larguraMapa` e `alturaMapa`) já estão disponíveis na memória (RAM) assim que o croqui é aberto, a interface pode ser renderizada instantaneamente a 0ms, eliminando a sensação de lentidão e melhorando drasticamente a experiência do usuário.

## What Changes

- **Renderização Imediata do Botão em `MapaThumbnail`**:
  * O container do mapa no setor passa a ser exibido no primeiro frame com seu `AspectRatio` exato (`larguraMapa / alturaMapa`), cantos arredondados e fundo escuro sóbrio.
  * O botão translúcido central ("Abrir Mapa Interativo") é renderizado imediatamente e aceita toques no frame 0.
  * O download da miniatura do mapa ocorre em background; ao finalizar, a imagem é exibida com uma transição suave de fade-in por trás do botão.
  * Se o usuário tocar no botão antes do término do download da miniatura, a navegação para `AppNav.toMapas` ocorre instantaneamente sem reter o usuário.

- **Montagem Estrutural Imediata em `MapaInterativoPage`**:
  * O `Scaffold`, a `AppBar` (com botão de voltar, título do setor/pico e seletor de mapas do carrossel) e a área do `InteractiveViewer` são montados instantaneamente com fundo escuro.
  * Enquanto a imagem em alta resolução estiver sendo baixada/resolvida, o canvas exibe um indicador sutil e elegante de carregamento centralizado.
  * A imagem da rocha, os marcadores (POIs) e os traçados vetoriais são revelados em conjunto com um fade-in suave assim que a imagem estiver pronta, evitando o estranhamento visual de marcadores soltos flutuando no vazio preto.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capacidade raiz necessária. -->

### Modified Capabilities
- `interactive-map`: Adiciona requisitos para exibição imediata não-bloqueante do botão no card do setor (`MapaThumbnail`) e montagem estrutural imediata da tela cheia do mapa interativo com revelação atômica de imagem e marcadores.

## Impact

- **Código Afetado**:
  * `frontend/lib/widgets/mapa_thumbnail.dart`
  * `frontend/lib/pages/mapa_interativo.dart`
  * Testes de widget correspondentes (`test/widgets/mapa_thumbnail_test.dart`, `test/pages/mapa_interativo_test.dart`, `test/pages/mapas_carrossel_test.dart`).
- **APIs & Dependências**: Nenhuma dependência externa adicionada ou alterada.
