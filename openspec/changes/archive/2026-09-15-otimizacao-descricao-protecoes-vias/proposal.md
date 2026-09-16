## Why

Escaladores na base da rocha dependem de informações rápidas e críticas de segurança (como movimentações perigosas, lances delicados e material necessário). Atualmente, na página de detalhes da via, a descrição textual rica fica enterrada no final da página (abaixo de informações de conquista de décadas atrás), enquanto as proteções são divididas em dois cartões confusos ("Proteções" e "Paradas", onde "Paradas: 2" confunde o usuário sugerindo duas paradas/enfiadas). Além disso, o card flutuante do mapa interativo não exibe nenhuma prévia da descrição nem a quantidade de proteções, e vias com proteção mista (grampos fixos + proteções móveis) são rotuladas rigidamente como "Esportiva" ou "Móvel".

## What Changes

- **Página de Detalhes da Via**:
  - **Reordenação de Seções**: A seção de **Descrição** agora é exibida no topo do conteúdo, imediatamente após os *Stat Cards* métricos e antes das seções técnicas ("Informações", "Peças Móveis") e "Histórico & Conquista".
  - **Unificação do Card de Proteções (Notação `X+Y`)**: Remoção do cartão individual "Paradas" e unificação em um único cartão "Proteções" exibindo `<intermediárias>+<parada>` (ex: `3+2`, `9+0`, `12+2`).
  - **Posicionamento de Ações Secundárias**: Botões secundários ("Assistir Vídeo Beta" e "Apoie a Manutenção") são mantidos ao final da página, após a seção de Histórico.
- **Card Flutuante do Mapa Interativo**:
  - **Prévia da Descrição**: Exibição de um resumo textual higienizado (sem marcações Markdown) limitado a 2 linhas com reticências (`maxLines: 2, overflow: TextOverflow.ellipsis`), preservando o espaço útil do croqui.
  - **Proteções no Subtítulo**: Inclusão da contagem de proteções no subtítulo do card na notação `X+Y` (`Modalidade | Grau | Intermediárias+Parada`).
- **Detecção Dinâmica de Modalidade Mista**:
  - Em vias do tipo `ViaMovel`, se houver proteções fixas intermediárias (`quantidadeProtecoesIntermediarias > 0`), o aplicativo passa a identificar e exibir a via como **"Mista"** (em vez de "Móvel"), tanto no card do mapa quanto na listagem do setor e busca.
  - Em vias do tipo `ViaMultiplasEnfiadas` com `tipoViaMultiplasEnfiadas == MISTA`, o rótulo é exibido como **"Mista"**.

## Capabilities

### New Capabilities
- `detalhes-via`: Apresentação estruturada e ergonômica dos detalhes da via de escalada, incluindo ordenação prioritária de betas de segurança (Descrição), cartão unificado de proteções na notação convencional `X+Y`, e suporte à modalidade Mista.

### Modified Capabilities
- `interactive-map`: Exibição de resumo textual compacto da descrição da via e inclusão da contagem de proteções e modalidade dinâmica no subtítulo do cartão flutuante de seleção.

## Impact

- **Código Afetado**:
  - `frontend/lib/view_functions/via_functions.dart` (reordenação de seções em `_buildViaEsportiva`, `_buildViaMovel`, `_buildBoulder`, `_buildMultipitch` e `_buildHighline`; unificação de cartões de proteção para `X+Y`).
  - `frontend/lib/view_functions/common_functions.dart` (`buildOutlineStatCard` permitindo quebra de texto elegante para títulos de 2 linhas).
  - `frontend/lib/pages/mapa_interativo.dart` (`_buildBaseCard` e `_buildEscaladaCard` com prévia de descrição higienizada e subtítulo enriquecido com proteções).
  - `frontend/lib/view_functions/setor_functions.dart` e `frontend/lib/widgets/global_search.dart` (reconhecimento de vias mistas).
- **Testes**:
  - Atualização e adição de testes unitários e de widget em `frontend/test/view_functions/via_functions_widget_test.dart`, `frontend/test/view_functions/via_functions_test.dart`, `frontend/test/pages/via_test.dart` e `frontend/test/pages/mapa_interativo_test.dart`.
