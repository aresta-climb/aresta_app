## 1. Atualizações de Banco de Dados e Linter

- [x] 1.1 Adicionar `int32 indice_mapa_padrao` nas definições de `Setor`, `Grupo`, `ViaEsportiva`, `ViaMovel`, `Boulder`, `ViaMultiplasEnfiadas` e `Highline` em `aresta_db/aresta_api/proto/croqui.proto`.
- [x] 1.2 Regerar os bindings em Dart (`protoc` script no repositório do backend/API).
- [x] 1.3 Adicionar TODO em `aresta_db/TODO.md` para o linter: (a) emitir warnings para usos inválidos de `indice_mapa_padrao` e (b) emitir warnings durante a compilação do croqui caso existam POIs no mapa sem nenhuma referência apontando para eles.

## 2. Utilitário de Resolução de Dataset

- [x] 2.1 Criar a classe `DatasetResolver` com um método estático `resolve(...)` que receba o Pico atual, mais o contexto alvo (Grupo, Setor, Escalada).
- [x] 2.2 Adicionar testes unitários (TDD) para o `DatasetResolver` e todo o código recém-criado visando garantir 100% de code coverage para a nova lógica. Cobrir cenários de falta de setor e referências quebradas.
- [x] 2.3 Refatorar o `PageListenableBuilder` para usar internamente o `DatasetResolver` no lugar de sua lógica inline.

## 3. Estado e Indexação do Mapa Interativo

- [x] 3.1 Adicionar a tipagem auxiliar `ResolvedReference` ou `MapTarget` com as propriedades resultantes de uma resolução (referência da entidade).
- [x] 3.2 No `initState` ou hook de atualização de dataset do `InteractiveMap`, invocar o `DatasetResolver` iterando por `widget.mapa.referencias`.
- [x] 3.3 Construir e salvar no estado os mapeamentos otimizados: `Map<String, List<Referencia>>` (ID -> Refs) e `Map<Referencia, ResolvedReference>` (Ref -> Objects).

## 4. UI Dinâmica do Mapa (Cards)

- [x] 4.1 Criar componente `MapBottomCard` (ou similar) que receba o `ResolvedReference` selecionado.
- [x] 4.2 Implementar variação do Card para Escalada (Nome, Grau, Botão "Mais Informações" que navega para `AppNav.toVia`).
- [x] 4.3 Implementar variação do Card para Setor (Nome, Info Básica, Botões "Ir para Setor" e "Ver Mapa do Setor" respeitando `indice_mapa_alvo`).
- [x] 4.4 Implementar variação do Card para Grupo.
- [x] 4.5 Modificar a renderização de POIs do SVG: POIs no mapa que não têm referências atreladas a eles simplesmente não serão desenhados. Ao tocar num POI ativo, exibe a seleção e sobe o card adequado.

## 5. Integração com a Árvore de Navegação (TargetContext)

- [x] 5.1 Atualizar `MapaInterativoNode` e `AppNav.toMapaInterativo` para aceitar um novo modelo `TargetContext` (grupo, setor, escalada opcional) em substituição ao `initialSelectedId` do tipo String.
- [x] 5.2 Ao carregar o mapa interativo, caso exista um `TargetContext`, buscar na indexação pré-computada qual POI (ID) reflete aquele contexto, aplicando os `AjustesDeCamera` definidos pela referência.

## 6. Ação "Ver no Mapa" nas Páginas de Escalada

- [x] 6.3 Implementar o fallback no roteamento: caso o índice for inválido ou ausente, procurar o primeiro mapa do contexto que possua uma referência resolvida válida para a entidade em questão.
