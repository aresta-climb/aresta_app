## Context

O aplicativo utiliza um arquivo de imagem (mapa/croqui) e renderiza polígonos sobrepostos a essa imagem utilizando as coordenadas (bounding boxes) cadastradas no backend. Ao clicar no botão "Ver nos mapas" a partir da tela de uma Via (Escalada), o app inicia a tela `MapasCarrosselNode` (que empilha um `MapaInterativoPage` dentro de um `PageView`).
Para que o `MapaInterativoPage` saiba qual polígono deve focar (auto-zoom e highlight), ele precisa do ID do polígono (`ponto.id`) ou, no caso de transição entre mapas, as referências mapeadas na inicialização em `DatasetResolver.resolveReferencia`.
Atualmente, o método construtor da tela perde o contexto do "Grupo" (ex: o setor/grupo que engloba a via no backend), repassando `null` de forma hardcoded (`grupoContextNome: null`). A perda de contexto faz com que a busca da via no dataset do Pico não funcione, ignorando o ponto e inviabilizando o auto-zoom.

## Goals / Non-Goals

**Goals:**
- Garantir que o `grupoContextNome` seja corretamente passado para a tela do carrossel ao invés de usar `null` de forma hardcoded, permitindo que a hierarquia do dataset (Grupo -> Setor -> Via) seja corretamente resolvida na tela de destino.
- Garantir que o `escaladaContextNome` (via) atual seja propagado pela cadeia de navegação (`NavNode`) até a interface `CarrosselItemData` e eventualmente até o `MapaInterativoPage`.
- **Qualidade**: Aplicar **TDD (Test-Driven Development)**, criando e alterando os testes de unidade e de widget **antes** da implementação.
- **Cobertura**: Atingir **100% de cobertura de testes** (unit test coverage) sobre todas as áreas refatoradas ou criadas por esta proposta.
- **Documentação**: Todo o código modificado deve ser **bem comentado com docstrings**, explicando o papel de cada contexto na propagação da navegação.

**Non-Goals:**
- Não iremos alterar a lógica principal de zoom (`_zoomToPoints`), apenas o seu fornecimento de dados iniciais.
- Não faremos refatorações pesadas na estrutura do `DatasetResolver`, apenas a correção da montagem dos dados na tela de origem.

## Decisions

1. **Utilizar `fm.grupoContext?.nome` em `CarrosselItemData`**
   - Ao invés de hardcodar `null` em `mapa_interativo.dart` e `via_functions.dart`, aproveitaremos que `foundMaps` já é um array do tipo `IndexedMap`, o qual possui o campo `grupoContext`.
   - **TDD Approach**: Serão escritos testes para a formação do `CarrosselItemData` garantindo que se o `grupoContext` não for nulo, ele seja propagado.

2. **Adicionar `escaladaContextNome` no `CarrosselItemData` e em instâncias relacionadas**
   - Na estrutura do frontend (`navigation_tree.dart`), `NavNode` já tem um `escaladaContextNome`. Alteraremos `CarrosselItemData` para armazenar `escaladaContextNome` (via string).
   - Ao criar o objeto `CarrosselItemData`, pegaremos `getEscaladaNome(escalada)` onde aplicável e inseriremos nessa nova propriedade, alimentando adequadamente a inicialização do `MapaInterativoPage`.
   - As propriedades recém-criadas contarão com docstrings claras para facilitar a manutenção futura.

## Risks / Trade-offs

- **Maior tempo de desenvolvimento**: A exigência de TDD e 100% de cobertura em testes de widget já existentes pode implicar em reestruturar alguns mocks de testes, mas o ganho em estabilidade do auto-zoom compensa o esforço extra.
