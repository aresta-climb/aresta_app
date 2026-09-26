# Proposta: Mapas Individuais de Escalada

## Why

Atualmente, o sistema de croquis e mapas interativos do Aresta é centrado exclusivamente nos níveis de Pico, Grupo e Setor. Isso limita severamente a clareza e segurança em dois cenários críticos na rocha:
1. **Boulders**: Agarras de partida (*sit-start*), trajetos de saída (*top-out* cego) e linhas de descida do bloco (*downclimb*) demandam fotos dedicadas de ângulos específicos que ficam ilegíveis ou invisíveis na foto frontal do setor.
2. **Vias de Múltiplas Enfiadas e Vias Técnicas**: Paredes de 300m a 800m possuem detalhes cruciais de paradas intermediárias, bivaques, crux e rotas de rapel que se tornam impraticáveis de visualizar em uma única foto geral de falésia.

Esta mudança introduz suporte nativo a mapas individuais a nível de escalada, com um modelo de orçamento de dados rigoroso (1.0 MP @ WebP Q85, economia de ~70% em pixels e memória) e uma experiência unificada de carrossel no aplicativo móvel.

## What Changes

- **Schema Protobuf (`aresta_api`)**:
  - Adição de `repeated Mapa mapas = 7;` diretamente na mensagem raiz `Escalada`.
  - Remoção completa do campo protótipo `repeated Mapa mapas = 21;` de `ViaMultiplasEnfiadas` (marcando o campo 21 como reservado).
- **Banco de Dados e Editor (`aresta_db`)**:
  - Suporte a `mapas:` no bloco de cada item em `escaladas:` no frontmatter YAML dos setores.
  - Perfil de compressão dedicado para escaladas: teto de 1.0 MP (~1150x870 px) e WebP Qualidade 85, limitando o peso por imagem a ~120 KB com alta fidelidade de agarras e texturas de rocha.
  - Sub-seleção/recorte (*rubber-band crop*) opcional no `DialogoAdicionarMapa` para permitir selecionar uma região de detalhe em fotos originais de alta resolução antes da conversão.
  - Banner instrutivo no `DialogoAdicionarMapa` orientando o autor a selecionar a área de interesse para preservar a máxima qualidade nas agarras.
  - Exibição de mapas de escaladas na árvore de navegação e lista de seleção do `WidgetEditorMapas`.
  - Validação e pré-compilação vetorial Catmull-Rom para GPU de traçados contidos em mapas de escaladas no `preparar_submissao_lib.py`.
- **Aplicativo Móvel (`aresta_app`)**:
  - Extensão do `CroquiMapIndex` para catalogar em $O(1)$ mapas próprios de escaladas.
  - Na `ViaPage`: substituição do botão estático por um card visual `MapaThumbnail` quando a via tiver mapas próprios.
  - Carrossel unificado na `ViaPage`: exibe primeiro os mapas locais detalhados da escalada e, em seguida, os mapas de setor/grupo onde ela é referenciada (com o traçado pré-focado).
  - No `mapa_interativo.dart`: habilitação da ação secundária "Ver mapas" no rodapé ao clicar em uma rota do setor que possui mapas próprios.

## Capabilities

### New Capabilities
- `mapas-escalada`: Apresentação e navegação de mapas individuais de escalada na `ViaPage` e no `mapa_interativo`, incluindo `MapaThumbnail` dedicado, carrossel unificado (fotos locais seguidas por mapas de contexto) e ação "Ver mapas" em seleções de rota.

### Modified Capabilities
- `croqui-map-indexing`: Indexação $O(1)$ de mapas pertencentes diretamente a instâncias de `Escalada` no índice global do pico.
- `view-on-map`: Resolução de mapas para uma escalada priorizando seus mapas próprios e mantendo navegação encadeada para mapas do setor/grupo.

## Impact

- **Modelos Protobuf**: Atualização dos stubs gerados para Python (`aresta_db`) e Dart (`aresta_app`).
- **Navegação & UI**: `ViaPage`, `mapa_interativo.dart`, `MapaThumbnail`, `CroquiMapIndex` e `MapasCarrosselPage`.
- **Armazenamento e Offline**: Aumento mínimo no tamanho de download offline devido ao perfil de 1.0 MP / WebP Q75.
- **Editor Desktop**: `DialogoAdicionarMapa`, `WidgetEditorMapas`, `nomes_arquivos.py` e validador de submissão.
