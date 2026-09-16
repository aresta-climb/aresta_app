## Context

Na visualização de croquis do Aresta App, a navegação entre setores e grupos ocorre primordialmente através da lista de setores (`SetoresPage`), da tela de grupo (`GrupoPage`) e do mapa interativo (`MapaInterativoPage`). 

Atualmente, `buildSectorTile` e `buildGrupoTile` em [`pico_functions.dart`](file:///c:/Renato/Devel/aresta-climb/aresta_app/frontend/lib/view_functions/pico_functions.dart) utilizam um `ListTile` básico sem subtítulo. No mapa interativo, os cartões flutuantes de setor e grupo em [`mapa_interativo.dart`](file:///c:/Renato/Devel/aresta-climb/aresta_app/frontend/lib/pages/mapa_interativo.dart) mostram apenas uma linha genérica de texto (ex: `14 vias`).

Todos os dados necessários já existem no modelo de dados em memória: `Setor.escaladas` (lista de `Escalada` onde cada item possui `whichTipo()`) e `Grupo.setores` contendo os setores filhos.

## Goals / Non-Goals

**Goals:**
- Criar um utilitário funcional puro para consolidar e formatar modalidades de escalada com regras gramaticais de concordância no singular e plural.
- Criar um componente de interface reutilizável `BadgesModalidades` autossuficiente e testável.
- Exibir badges nos cards de setor da `SetoresPage` e `GrupoPage`.
- Exibir estrutura em duas linhas para grupos (Linha 1: `X setores • Y escaladas`; Linha 2: badges consolidadas).
- Atualizar os cards flutuantes de setor e grupo no `MapaInterativoPage` para exibir a mesma estrutura visual.
- Garantir 100% de cobertura de testes unitários e de widget, seguindo TDD e diretrizes do `AGENTS.md`.

**Non-Goals:**
- Não alterar schemas Protobuf nem depender de re-geração de código de API.
- Não alterar os tiles de vias individuais dentro da página de detalhes do setor.
- Não implementar filtros interativos ao clicar nas badges (ex: filtrar lista ao tocar na badge de boulder) neste ciclo.

## Decisions

### Decisão 1: Cálculo dinâmico em memória vs. dependência exclusiva de precomputados
- **Escolha**: Inspecionar diretamente a lista de `escaladas` de cada setor em memória (e agregá-las para grupos). Se uma lista estiver vazia mas `precomputados` estiver preenchido, usar `precomputados` como fallback.
- **Justificativa**: Em tempo de execução, os croquis abertos possuem as árvores de escaladas completamente carregadas em memória. Uma iteração sobre dezenas de escaladas roda em frações de milissegundo. Além disso, em testes de widget e mocks, o campo `precomputados` muitas vezes não é sintetizado.
- **Alternativas consideradas**: Depender estritamente de `precomputados` (quebraria testes existentes de widget que injetam setores com vias mockadas).

### Decisão 2: Nomenclatura e concordância gramatical
- **Escolha**: Aplicar as regras gramaticais estritas:
  - Esportiva: `1 esportiva` / `X esportivas`
  - Móvel: `1 móvel` / `X móveis`
  - Boulder: `1 boulder` / `X boulders`
  - Multienfiada: `1 multienfiada` / `X multienfiadas` (escolha validada com o usuário)
  - Highline: `1 highline` / `X highlines`
- **Justificativa**: Evita termos em inglês desnecessários como *multipitch* e garante naturalidade no português brasileiro conforme o princípio I do `AGENTS.md`.

### Decisão 3: Estruturação visual modular do componente `BadgesModalidades`
- **Escolha**: Criar `BadgesModalidades` como um widget independente (`StatelessWidget`) que aceita uma lista de `Escalada` ou um mapeamento já consolidado. Internamente utiliza `Wrap(spacing: 6, runSpacing: 4)` com chips estilizados (`Container` com `BorderRadius.circular(8)` ou `12`, fundo translúcido sutil e tipografia legível).
- **Justificativa**: Garante o princípio II do `AGENTS.md` (componentes autossuficientes e testáveis de forma independente), além de permitir o reuso tanto nos tiles da listagem quanto nos cartões do mapa interativo.

### Decisão 4: Cartões flutuantes do Mapa Interativo
- **Escolha**: Atualizar `_buildBaseCard` em `mapa_interativo.dart` para aceitar um parâmetro opcional `Widget? badges` (ou corpo de conteúdo), permitindo que `_buildSetorCard` e `_buildGrupoCard` injetem o `BadgesModalidades` diretamente na hierarquia do card flutuante.
- **Justificativa**: Mantém o design unificado do app e reaproveita a infraestrutura existente de animação e toque do mapa.

## Risks / Trade-offs

- **[Risco] Crescimento da altura do card em telas pequenas com muitas modalidades**  
  *Mitigação*: O uso de `Wrap` com padding compacto (`horizontal: 8, vertical: 3`) e fontes discretas (`fontSize: 12`) garante que mesmo setores com 3 ou 4 modalidades quebrem linha suavemente sem estourar (`overflow`).
- **[Risco] Setor sem nenhuma escalada cadastrada**  
  *Mitigação*: Quando o total de escaladas for 0, o componente não renderiza nenhum badge (retorna `SizedBox.shrink()`), mantendo a UI limpa.
