# Proposta: Fidelidade 1:1 de Escala de Traçados e Hitbox Dinâmica

## Why

Atualmente, o aplicativo móvel aplica multiplicadores arbitrários (`* 2.2`) e limites mínimos forçados (`clamp(11.0, 15.0)` e `clamp(2.0, 4.0)`) ao renderizar linhas de trajeto e marcadores de croqui no mapa interativo. Isso faz com que desenhos que no editor desktop parecem finos, elegantes e bem proporcionados apareçam gigantescos no celular, cobrindo a rocha e encavalando múltiplos círculos na base das vias. 

Além disso, a área de toque (hitbox) atual possui tolerância estática em coordenadas locais, o que impede precisão cirúrgica ao aproximar o zoom e não se adapta adequadamente a fotos com diferentes resoluções.

## What Changes

- **Eliminação de distorções visuais**: Remoção do multiplicador `* 2.2` e dos `clamps` visuais em `MarkerPainter._paintLinha` e `_paintMarcadores`, garantindo que o raio do círculo, a espessura da linha e o tamanho de fonte sejam calculados estritamente em pixels nominais da imagem multiplicados pela escala de projeção da tela (`escalaX`).
- **Paridade 1:1 com o Editor**: O que o autor vê no editor desktop é exatamente a proporção que aparecerá sobre a rocha no aplicativo móvel.
- **Hitbox adaptativa com área mínima ergonômica na tela**: Desacoplamento da área de toque da geometria visual. A tolerância de toque no `hitTest` garante um raio físico mínimo confortável para o dedo humano na tela (ex: 22 dp para círculos e 16 dp para linhas). Conforme o usuário dá zoom e o desenho visual atinge ou supera esse tamanho mínimo em dp, a tolerância extra colapsa para zero, garantindo precisão milimétrica em vias e nós muito próximos.

## Capabilities

### New Capabilities
<!-- Nenhuma nova capability necessária -->

### Modified Capabilities
- `tracados-vetoriais-app`: Atualização dos requisitos de renderização visual da espessura de traço e raio dos marcadores para respeitar estritamente a proporção matemática 1:1 da imagem em pixels sem limites artificiais de clamp visual, além da introdução da hitbox ergonômica adaptativa em dp de tela.

## Impact

- **Código afetado**: `frontend/lib/pages/mapa_interativo.dart` e utilitários associados.
- **Testes**: Atualização dos testes unitários e de widget em `frontend/test/pages/mapa_interativo_test.dart` para refletir as novas asserções proporcionais de espessura e raio, mantendo 100% de cobertura.
- **Compatibilidade**: Nenhuma quebra de API no backend ou no protocolo protobuf; os dados persistidos continuam idênticos e o editor desktop permanece como a fonte canônica da verdade.
