# Design Técnico: Carregamento Imediato e Não-Bloqueante de Mapas Interativos

## Context

Conforme estabelecido em `proposal.md`, a abertura de croquis em modo online sofre com alta latência percebida porque:
1. `MapaThumbnail` aguarda a resolução do `_imageProviderFuture` antes de renderizar qualquer elemento visual, substituindo o card do setor por um `CircularProgressIndicator` até o download terminar.
2. `MapaInterativoPage` aguarda o download em alta resolução antes de exibir o `Scaffold`, a `AppBar` e os controles.

Os metadados geométricos (`larguraMapa`, `alturaMapa`), o identificador das mídias e a lista de referências vetoriais já estão decodificados na memória (RAM) no `Croqui`, permitindo renderizar a estrutura completa sem depender do I/O de rede da imagem.

## Goals / Non-Goals

**Goals:**
- Renderizar o card de miniatura e o botão interativo em `MapaThumbnail` instantaneamente (0ms), aceitando toque e navegando sem esperar o download da miniatura.
- Desacoplar a camada de imagem da camada de interface em `MapaThumbnail` e `MapaInterativoPage`.
- Montar imediatamente a casca visual da tela cheia (`Scaffold`, `AppBar`, botões de fechar/voltar, seletor de mapas) em `MapaInterativoPage`.
- Revelar imagem e marcadores/traçados vetoriais de forma atômica e coordenada, evitando marcadores soltos flutuando em fundo preto.

**Non-Goals:**
- Modificar o pipeline de compressão ou formato de imagem no servidor CDN.
- Alterar o protocolo protobuf de croquis ou a estrutura de dados de mapas.
- Adiar deliberadamente o download de mapas no setor (o usuário solicitou que a experiência online completa permaneça ativa em segundo plano).

## Decisions

### 1. Desacoplamento da Camada Visual em `MapaThumbnail`
- **Decisão**: A estrutura base de `MapaThumbnail` passa a ser renderizada independentemente do estado do `FutureBuilder`. O `Stack` principal conterá:
  * Camada 0 (Fundo): Container escuro estilizado (`carbonFiber` / `abyssalRock`) com cantos arredondados (`BorderRadius.circular(10)`).
  * Camada 1 (Imagem): `FutureBuilder<ImageProvider?>` gerenciando apenas a imagem com `AnimatedOpacity` (ou `FadeInImage` / `Image(image: ...)`).
  * Camada 2 (Overlay Escuro): Mantido para legibilidade visual do botão.
  * Camada 3 (Botão Interativo): Centralizado e envolvido pelo `GestureDetector` com navegação ativa para `AppNav.toMapas`.
- **Alternativa Considerada**: Manter o `FutureBuilder` global e exibir um botão "estático" enquanto carrega. *Rejeitado porque gerava reconstrução brusca e duplicidade de estados.*

### 2. Montagem Estrutural Imediata em `MapaInterativoPage`
- **Decisão**: Mover o `FutureBuilder` para dentro do canvas de visualização (substituindo apenas a área do mapa e seus marcadores). O `Scaffold` com sua `AppBar` (quando `hideAppBar == false`) e os botões de controle permanecem visíveis desde o primeiro frame.
- **Alternativa Considerada**: Mostrar marcadores vetoriais e pins antes da imagem carregar. *Rejeitado após alinhamento: marcadores flutuando em fundo preto oferecem uma experiência visual precária e confusa.*

### 3. Revelação Coordenada (Atômica) de Imagem e Marcadores
- **Decisão**: Enquanto `_imageProviderFuture` não resolver, o centro do canvas do mapa exibe um indicador sutil de progresso (`CircularProgressIndicator` com cor do tema). Assim que o provedor de imagem estiver pronto, o `InteractiveViewer` renderiza o conteúdo (imagem + SVG de traçados + marcadores POI) de forma unificada.
- **Alternativa Considerada**: Renderizar a imagem primeiro e depois disparar o cálculo dos marcadores. *Rejeitado porque os marcadores já estão pré-calculados em memória, permitindo exibição simultânea imediata.*

## Risks / Trade-offs

- **[Risco] Toque rápido no botão antes da miniatura baixar**: O usuário toca no botão de abrir mapa e navega para `MapaInterativoPage` enquanto a imagem ainda não está em cache local.
  * *Mitigação*: `MapaInterativoPage` gerencia graciosamente o carregamento assíncrono com o indicador no canvas; o `ProvedorImagemAresta` reutiliza a mesma chamada de download/cache sem duplicar requisições.
- **[Risco] Erro de rede ou imagem indisponível**: Falha na conexão ou imagem corrompida.
  * *Mitigação*: Se a imagem falhar ao carregar, o botão no setor permanece visível e a tela do mapa exibe mensagem amigável de erro com opção de retentativa, em vez de colapsar para `SizedBox.shrink()`.
