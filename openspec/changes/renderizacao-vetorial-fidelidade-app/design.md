## Contexto (Context)

A implementação inicial dos traçados vetoriais estabeleceu o isolamento estrito de dependências externas (`path_drawing`) e o modelo de interatividade via caixas delimitadoras. Entretanto, ao comparar o resultado na tela do dispositivo com o editor desktop, foram observadas distorções estéticas e de usabilidade:
1. O tracejado do caminho funde-se em uma linha sólida quando escalado.
2. A espessura do traço e os halos usam valores fixos em dp (densidade de tela), gerando uma fita excessivamente grossa.
3. O círculo identificador ("1") apresenta fundo branco com texto preto, em desacordo com o padrão do editor (fundo ciano, texto branco, bordas duplas).
4. O raio de 18dp é fixo e ocupa espaço desproporcional quando a câmera está sem zoom.
5. Linhas não vinculadas em `mapa.referencias` são suprimidas na tela.

## Metas e Não-Metas (Goals / Non-Goals)

**Metas (Goals):**
- Fidelidade estética e funcional de 1:1 entre o aplicativo móvel e o editor de mapas desktop.
- Tracejado nítido e visível em qualquer tamanho de tela ou nível de zoom da rocha.
- Espessura proporcional da linha, do casing e do halo, evitando poluição visual sobre a rocha.
- Círculo identificador padronizado com o desenho do editor: fundo na cor da via (`corLinha`), texto branco em negrito e borda dupla de alto contraste.
- Exibição de linhas vetoriais no mapa interativo independentemente de possuírem referência vinculada.
- Conformidade estrita com todos os 7 princípios do repositório (`PRINCIPIOS.md`).

**Não-Metas (Non-Goals):**
- Alterar o contrato de dados no Protobuf ou modificar os croquis compilados.
- Quebrar o isolamento de `path_drawing` fora de `ConstrutorCaminhoTrajeto`.
- Introduzir classes intermediárias ou abstrações prematuras desnecessárias (Princípio VI: Simplicidade e Anti-Abstração).

## Decisões Arquiteturais (Decisions)

### Decisão 1: Aplicação do Tracejado no Espaço de Tela do Viewport
- **Problema:** O método atual aplica `dashPath` ao `basePath` em coordenadas da imagem original (ex: 2304x1300). Quando a matriz de escala da tela (`scaleX ≈ 0.17`) é aplicada, os traços de 12px viram ~2dp e os vãos de 6px viram ~1dp, fundindo-se em uma linha sólida.
- **Escolha:** O `ConstrutorCaminhoTrajeto` fornecerá a função `aplicarEstiloNoViewport(Path caminhoTransformado, LinhaTrajeto_EstiloTraco estilo)`, que decompõe o caminho já projetado no espaço de coordenadas locais de tela usando medidas fixas em dp (8.0dp traço / 4.0dp vão para `TRACEJADO`, 3.0dp traço / 4.0dp vão para `PONTILHADO`).
- **Alternativa Descartada:** Escalar inversamente o dash na imagem original. Descartada por violar o Princípio VI (Simplicidade), pois criaria complexidade matemática dependente de resoluções arbitrárias de imagem.

### Decisão 2: Escalonamento Proporcional da Espessura e Halos
- **Problema:** Usar `linha.espessura` diretamente como dp gera traços pesados de até 20dp (somando halos) em telas de celular.
- **Escolha:** Calcular a espessura visual de forma proporcional e com limites seguros:
  ```dart
  final double espessuraVisual = (espessuraNominal * scaleX * 2.2).clamp(2.0, 4.0);
  ```
  O halo de seleção recebe `espessuraVisual + 6.0` (em vez de `+12.0`) e o casing de contraste recebe `espessuraVisual + 1.5` (em vez de `+2.0`).
- **Rationale:** Preserva o contraste contra o fundo da rocha sem cobrir lances importantes da escalada.

### Decisão 3: Fidelidade Cromática e Borda Dupla do Círculo Identificador
- **Problema:** Fundo branco com texto preto parece um elemento flutuante desconectado da via.
- **Escolha:** Replicar com precisão o desenho de `AlcaNoTrajeto` do editor desktop:
  1. Casing externo escuro (`Colors.black54`, strokeWidth 3.0).
  2. Borda intermediária branca (`Colors.white`, strokeWidth 1.5).
  3. Fundo preenchido na cor da via (`corLinha`).
  4. Rótulo textual em branco em negrito centralizado.
  5. Raio proporcional calibrado via clamp: `(m.raio * scaleX * 2.0).clamp(11.0, 15.0)`.

### Decisão 4: Exibição Incondicional de Linhas no Mapa
- **Problema:** O filtro `if (!_poiToRefs.containsKey(ponto.id))` descarta linhas desenhadas sem referência, quebrando o Live Reload e ocultando caminhos de acesso.
- **Escolha:** Permitir que pontos do tipo linha sempre passem para renderização:
  ```dart
  final isLinha = ponto.whichTipoArea() == Mapa_PontoDeInteresse_TipoArea.linha;
  if (!isLinha && !_poiToRefs.containsKey(ponto.id)) {
    return const SizedBox.shrink();
  }
  ```
  Ao tocar em linha sem referência, o mapa seleciona visualmente o traço e aplica o auto-zoom na sua Bounding Box.

## Aderência a PRINCIPIOS.md

1. **Tudo em Português:** Métodos (`aplicarEstiloNoViewport`, `converterCorHex`), variáveis e comentários totalmente em português.
2. **Feature-First & Modularidade:** Regras encapsuladas em seus respectivos arquivos funcionais sem monólitos.
3. **100% de Test Coverage:** Exigência formal em `ConstrutorCaminhoTrajeto` e nas rotinas do `MarkerPainter`.
4. **TDD (Vermelho-Verde-Refatorar):** Todo teste falha antes de qualquer código de produção.
5. **Widget Tests First:** Testes de widget priorizados na interface antes de testes utilitários.
6. **Simplicidade e Anti-Abstração:** Fórmulas diretas e declarativas, sem camadas intermediárias inúteis.
7. **Documentação Contínua:** Blocos `///` com o *porquê* de cada ajuste e atualização de documentação técnica.
