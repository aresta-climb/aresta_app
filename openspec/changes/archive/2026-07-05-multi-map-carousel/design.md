## Context

Atualmente a `MapaInterativoPage` é projetada para renderizar e controlar exatamente um `Mapa`. 
Iteramos sobre a lista `foundMaps` e geramos botões individuais para cada mapa na tela de vias, o que prejudica a experiência visual. Além disso, a mudança exige qualidade de software rigorosa usando o paradigma Test-Driven Development (TDD).

## Goals / Non-Goals

**Goals:**
- Prover um container (`MapasCarrosselPage`) capaz de injetar mapas sequenciais.
- Evitar conflitos de gestos do `PageView` com a capacidade de pan do `InteractiveViewer`.
- Manter o foco automático (`initialSelectedId` + `autoZoomEnabled`) quando o mapa for alterado no carrossel.
- Seguir estritamente TDD, alcançando 100% de cobertura de testes unitários e de widget nas lógicas novas inseridas.

**Non-Goals:**
- Refatorar o funcionamento interno do `InteractiveViewer` atual, apenas orquestrá-lo.
- Não focaremos em testes end-to-end (E2E) nesta mudança, apenas unitários e de widget isolados para garantir os 100%.

## Decisions

1. **Test-Driven Development (TDD)**
   - O desenvolvimento será feito no ciclo Red-Green-Refactor.
   - Serão criados mocks para o sistema de navegação da aplicação para validar isoladamente se `MapasCarrosselNode` está sendo chamado pela interface.
   - `MapasCarrosselPage` terá sua UI validada com `WidgetTester` para garantir o ciclo de atualização de índice e renderização das setas.
2. **Uso de PageView com NeverScrollableScrollPhysics**
   - Evita o conflito de scroll táctil com o mapa.
3. **Passagem Contextual Dinâmica**
   - Na troca do carrossel, a `MapaInterativoPage` recebe `initialSelectedId: mapas[currentIndex].referencedId`, o que invoca nativamente seu autozoom no `initState` para destacar a rota.

## Risks / Trade-offs

- **[Risco] Reconstrução pesada no PageView:** Trocas podem destruir a página anterior e forçar recarga.
  - **Mitigação:** TDD focará em garantir que, caso isso aconteça, a transição retenha a referência correta.
- **[Risco] Falso Positivo em Cobertura:** 100% de cobertura pode omitir cenários complexos reais.
  - **Mitigação:** Os cenários no Spec definirão a matriz exata de casos que cada teste unitário precisará replicar (cenário base, transição, cliques em botões extras).
