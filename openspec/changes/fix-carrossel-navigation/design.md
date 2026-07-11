## Context

A navegação para visualizar mapas foi expandida recentemente com o recurso de "Múltiplos Mapas" via Carrossel (`MapasCarrosselPage`). Esse carrossel exibe instâncias de `MapaInterativoPage`. No entanto, quando um ponto de interesse (como uma via) é aberto através de um `initialSelectedId`, a lógica atual de `MapaInterativoPage` assume que a página anterior na pilha de navegação foi a de `Detalhes da Via`. Com isso, ao clicar em "Mais Info", a página faz um `pop` na pilha, assumindo retornar ao detalhe. Quando aberta pelo carrossel a partir de outro mapa, esse `pop` fecha o carrossel, deixando o usuário na tela do mapa original com o cartão flutuante aberto. 

## Goals / Non-Goals

**Goals:**
- Corrigir a navegação de "Mais Info" do cartão flutuante de vias/setores quando o mapa é exibido dentro do carrossel.
- Garantir que o comportamento padrão de "voltar para Detalhes da Via se o mapa foi aberto pela Via" seja mantido por padrão.
- **Implementar as alterações utilizando TDD (Test-Driven Development) rigoroso.**
- **Atingir 100% de test coverage para as lógicas de navegação e instanciamento alteradas.**
- **Incluir docstrings detalhadas para documentar as premissas de navegação de UI, evitando confusões futuras.**

**Non-Goals:**
- Refatorar a classe `AppNav` profundamente.
- Modificar o fluxo de seleção ou a animação de zoom da `MapaInterativoPage`.

## Decisions

**Decisão 1:** Adicionar um parâmetro explícito `popOnActionIfOriginal` à classe `MapaInterativoPage`.
- **Rationale:** A responsabilidade de definir o que a página anterior é pertence a quem chama o mapa, e não ao mapa deduzir isso de forma implícita. O carrossel passará `popOnActionIfOriginal: false` ao instanciar seus mapas internos.

**Decisão 2:** TDD e Documentação (Docstrings)
- **Rationale:** Como o bug atual foi fruto de uma premissa subentendida (a de que a página anterior era sempre uma ViaPage), documentar e testar de forma extensiva o porquê do parâmetro `popOnActionIfOriginal` é mandatório.

## Risks / Trade-offs

- **[Risco de Regressão na Navegação]** → Modificações no `MapaInterativoPage` podem acidentalmente quebrar o fluxo onde ele é aberto da própria `ViaPage`. **Mitigação**: Seguir fluxo TDD, escrevendo testes que garantem o comportamento de `pop` antes de alterar o código, e mantendo o valor padrão `popOnActionIfOriginal = true`.
