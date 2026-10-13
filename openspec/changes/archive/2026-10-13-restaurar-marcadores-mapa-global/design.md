# Design: Resolução de Marcadores e Desduplicação de Ações no Mapa Global

## Context

A navegação a partir da aba de exploração (`BrowsePage`) aciona o botão "VER NO MAPA", invocando `AppNav.toMapaGlobal(context, crags: availableCrags)`. Na recente refatoração para Dumb UI, `availableCrags` passou a ser uma lista de `CardCroquiViewModel`, uma representação leve destinada estritamente a cartões de catálogo, desprovida de latitude e longitude.

O `MapaGlobalViewModel.picosNoMapa` recebia essa lista como `picosIniciais`, porém apenas aceitava instâncias de `MapaPicoViewModel`, `Map` ou `ResumoCroqui`. Com a incompatibilidade de tipo, todos os itens eram avaliados como `null`, resultando em uma lista vazia de marcadores. Como `picosIniciais` não era nulo, o fallback de metadados gerais do catálogo era ignorado, deixando o Google Maps totalmente sem pinos.

Além disso, a tela `mapa_global.dart` passava explicitamente `actions: [buildFeedbackButton(context)]` para `buildCommonAppBar`, que já anexa automaticamente um botão de feedback, gerando dois botões idênticos na barra de navegação.

## Goals / Non-Goals

**Goals:**
- Garantir que o `MapaGlobalViewModel` resolva coordenadas geográficas válidas mesmo quando alimentado com `CardCroquiViewModel`, IDs em texto ou objetos legados, consultando o repositório de dados ativo (`datasetRepo.activeDataset`).
- Implementar um mecanismo de fallback resiliente no `MapaGlobalViewModel`: caso `picosIniciais` não gere nenhum marcador com coordenadas válidas, o mapa deve carregar todos os picos disponíveis no catálogo ativo.
- Adequar `AppNav.toMapaGlobal` e `MapaGlobalNode` para suportar e preferir identificadores em texto (`picoIds`), respeitando a arquitetura declarada em `NavNode`.
- Remover a duplicação do botão de feedback na AppBar do Mapa Global.

**Non-Goals:**
- Não alterar as regras de agrupamento visual ou dimensões de marcadores (Macro, Regional, Local) já especificadas em `estabilidade-mapa-marcadores`.
- Não sobrecarregar `CardCroquiViewModel` com atributos geográficos de GPS que não pertencem ao contexto de exibição de cartões.

## Decisions

### 1. Resolução Reativa de Metadados por Identificador no ViewModel
No getter `picosNoMapa` do `MapaGlobalViewModel`, estender o tratamento de `picosIniciais`:
- Se o item for `CardCroquiViewModel`, extrair seu `id`.
- Se o item for `String`, usar diretamente como `id`.
- Se for obtido um `id`, buscar o `ResumoCroqui` correspondente em `dataset.metadadosDisponiveis`.
- Instanciar `MapaPicoViewModel.deMetadados(metadados: resumo, estaBaixado: estaBaixado(id), baseUrl: baseUrl)`.

*Alternativas consideradas*:
- Adicionar `double? latitude, longitude` a `CardCroquiViewModel`: Rejeitado por misturar responsabilidades de apresentação de cartões com cartografia.
- Converter diretamente no widget `BrowsePage`: Rejeitado por violar o princípio de UI burra (Dumb UI).

### 2. Fallback Transparente para Catálogo Completo
Se `picosIniciais != null`, mas a lista filtrada de picos com coordenadas válidas resultar vazia (`picosValidos.isEmpty`), o ViewModel automaticamente recorrerá à lista completa de `dataset.metadadosDisponiveis`.
Isso garante que falhas transitórias de sincronização ou filtros vazios nunca deixem o usuário com um mapa em branco.

### 3. Normalização no `MapaGlobalNode`
Alinhar `MapaGlobalNode` para aceitar `picoIds: List<String>` opcionalmente ou extrair IDs a partir de `crags`, mantendo retrocompatibilidade total com testes existentes e cumprindo o preceito de que nós da árvore mantêm apenas identificadores em texto.

### 4. Remoção do Botão Duplicado na AppBar
Em `frontend/lib/pages/mapa_global.dart`, remover o argumento `actions: [buildFeedbackButton(context)]` da chamada a `buildCommonAppBar`. O próprio `buildCommonAppBar` é responsável por incluir o botão de feedback com as cores do tema.

## Risks / Trade-offs

- **[Risco]** Busca de metadados no dataset para cada item de `picosIniciais` pode ter custo computacional se o catálogo crescer muito.
  → **Mitigação**: O catálogo de escaladas possui centenas de picos, uma busca linear ou via mapa por ID leva frações de milissegundo. O resultado é construído de forma reativa sob demanda.
