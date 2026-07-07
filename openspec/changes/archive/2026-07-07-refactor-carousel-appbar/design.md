## Context

O aplicativo possui a tela `MapaInterativoPage` para exibir croquis de escalada de forma interativa (zoom, pan, e marcadores). Quando há múltiplos mapas para uma mesma área (ex: várias faces de uma montanha), o app utiliza a página `MapasCarrosselPage`, que envelopa múltiplas instâncias de `MapaInterativoPage` dentro de um `PageView`.

O problema atual é que o `MapaInterativoPage` renderiza sua própria `AppBar` (incluindo o título e botão de voltar). O `MapasCarrosselPage` adiciona um widget de paginação (ex: `< 01 de 02 >`) usando uma posição absoluta sobre o topo. Isso causa *clipping* visual com o `AppBar` do mapa e outros botões do próprio mapa. Além disso, a animação de *swipe* entre páginas move não só a imagem do mapa, mas o `AppBar` inteiro, o que não parece nativo.

## Goals / Non-Goals

**Goals:**
- Centralizar o controle do `AppBar` no `MapasCarrosselPage` durante a visualização de múltiplos mapas.
- Garantir que a `AppBar` fique fixa (não deslize) durante o swipe entre mapas.
- Integrar os controles de paginação (anterior/próximo e texto) de forma limpa, substituindo o problema de *clipping*.
- Permitir que o `MapaInterativoPage` continue funcionando normalmente com o seu próprio `AppBar` quando for aberto sozinho (fora do carrossel).
- **Testabilidade**: Implementar a refatoração guiada por TDD (Test-Driven Development), focando em atingir 100% de cobertura nos métodos alterados ou adicionados.
- **Manutenibilidade**: Incluir *docstrings* claras (padrão Dart) descrevendo todas as lógicas complexas de paginação, modo headless da AppBar, e estados internos afetados.

**Non-Goals:**
- Não alterar a lógica de marcações (pins), navegação interna ou auto-zoom do mapa.
- Não mudar a estrutura fundamental do `InteractiveViewer`.

## Decisions

1. **Abordagem TDD para a UI**
   *Rationale:* Como essa é uma refatoração crucial da navegação e layout primário do app, as lógicas de visibilidade (`hideAppBar`) e paginação no `MapasCarrosselPage` devem ser antecedidas pela criação de testes de widget (*widget tests*) que verifiquem a presença correta de `AppBar`, `Scaffold`, e botões interativos nas árvores de teste, assegurando ausência de falhas visuais por conta do estado da flag.

2. **Adicionar Parâmetro `hideAppBar` no `MapaInterativoPage`**
   *Rationale:* Para reaproveitar o `MapaInterativoPage` em ambos os cenários (standalone e carrossel), ele deve aceitar uma flag `hideAppBar` (padrão `false`). Quando verdadeira, a tela retorna apenas o `body` (ou um Scaffold sem AppBar, permitindo que as áreas de Safe Area sejam delegadas ao parent). Este comportamento deverá ser minuciosamente coberto por testes.

3. **Migrar Scaffold principal para o `MapasCarrosselPage`**
   *Rationale:* O `MapasCarrosselPage` terá seu próprio `Scaffold` e `AppBar`. O `PageView` ocupará o `body`.
   *Trade-off:* O `MapasCarrosselPage` precisará replicar ou construir uma `AppBar` semelhante à do mapa (com botão de feedback e título apropriado). O botão de voltar funcionará fechando o carrossel. O título do `AppBar` no carrossel abrigará a paginação `< 01 de 02 >`.

4. **Documentação Explícita e Comentada**
   *Rationale:* O código da UI anterior já possuía alguma complexidade. A nova flag de estado do `hideAppBar` e a estrutura híbrida do Carrossel exigem *docstrings* que expliquem por que `AppBar` foi transferida. Todos os métodos de extração de layout e construtores deverão possuir comentários Dart (`///`).

## Risks / Trade-offs

- [Risk] O `MapaInterativoPage` usa o botão "Mapa Geral" no topo esquerdo do body. Sem a `AppBar` própria, ele pode subir demais e sobrepor o topo caso o `Safe Area` não seja devidamente respeitado.
  → **Mitigation:** A suíte de TDD deve simular o ambiente SafeArea no teste do widget, assegurando que o botão e o conteúdo não estourem o topo caso `hideAppBar` seja modificado. Adicionar docstrings que alertem futuros desenvolvedores sobre essa restrição estrutural.
