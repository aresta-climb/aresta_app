## Context

Com a migração para a v3, a infraestrutura Protobuf agora expõe `mapasGerais` nativamente em `Pico`. O aplicativo possui o widget de miniatura de mapa `MapaThumbnail` e uma tela rica e interativa para mapas de setores/grupos chamada `MapaInterativoPage`. Atualmente, há uma lacuna em que os mapas de acesso gerais (pico) ainda dependem do código legado `mapa_geral_pico.dart` que faz a leitura via botões de markdown desatualizados e estáticos, sem o suporte rico que os demais mapas usufruem.

## Goals / Non-Goals

**Goals:**
- Exibir as miniaturas dos Mapas Gerais (`MapaThumbnail`) na tela `PicoDetailsPage`, situados logo acima da listagem de setores, garantindo consistência visual.
- Ligar os cliques nessas miniaturas à `MapaInterativoPage`, tirando proveito automático do pan, zoom e tratamento de marcadores de polígonos.
- Aproveitar o método de resolução de referência existente (`DatasetResolver.resolveReferencia`) para abrir as informações dos POIs.
- Eliminar o código de mapas estáticos legados em `mapa_geral_pico.dart`.
- Ajustar os roteamentos do botão 'Ir para Grupo' no mapa, utilizando o `AppNav.toGrupo` que já se encontra implementado.

**Non-Goals:**
- Modificar os tipos ou a infraestrutura do editor/backend; a intenção é estritamente atualizar as ligações na UI do frontend consumindo o v3.

## Decisions

- **Posicionamento de UI na Página do Pico**: Decidiu-se renderizar as miniaturas de Mapas Gerais sob um título explícito de "Mapas Gerais" antes da listagem de setores. Motivo: Mantém consistência visual com outras áreas da página e expõe o mapa de acesso logo no topo de navegação.
- **Uso do Widget de Mapa Interativo sem Contexto**: O `MapaInterativoPage` e `DatasetResolver` serão instanciados sem `setorContext` e sem `grupoContext`. O `DatasetResolver` já inclui lógica robusta (`resolveReferencia`) para fazer busca global no `Pico` e descobrir o Setor ou Grupo através de um `Mapa_Referencia`, permitindo que POIs sejam clicados no mapa geral livremente.
- **Reutilização da UX Legada de Scroll**: O atributo local `_mapaKey`, anteriormente atrelado ao conteúdo do botão markdown, agora atrelará ao widget das miniaturas de Mapas Gerais, preservando o suporte a rolagem caso outra parte do app evoque essa flag.

## Risks / Trade-offs

- *Risco*: Referências e IDs inválidos podem falhar ao tentar resolver Setor/Grupo a partir do Mapa Geral.
  - *Mitigação*: A implementação existente do `DatasetResolver.resolveReferencia` já trata as exceções (falha silenciosa para fallback e log de `AppLogger` ou não renderiza `POIs`), resultando na ocultação do POI defeituoso de forma resiliente, como já ocorre no mapa de setores.
