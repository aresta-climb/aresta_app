# Design Técnico: Renderização, Interatividade e Destaque de Traçados Vetoriais SVG no App

## Context

O Aresta DB introduziu o suporte à criação de linhas vetoriais de vias de escalada através da mudança `tracados-vetoriais-vias-mapas`. Nesse novo formato, as rotas desenhadas sobre fotos em alta definição são pré-compiladas pela biblioteca matemática do backend em strings de caminho SVG contendo curvas cúbicas de Bézier (`caminho_svg`), uma caixa delimitadora calculada (`caixa_delimitadora`), lista de marcadores semânticos com rotação angular (`marcadores`), estilos de traço (tracejado, sólido) e cores personalizadas (`cor`).

No aplicativo móvel (`aresta_app`), o componente `MapaInterativoPage` e seu auxiliar `MarkerPainter` foram projetados originalmente para áreas fechadas delimitadas (`circulo`, `quadrado`, `retangulo`, `poligono`), onde o hit-test utiliza `path.contains(touchPoint)` e o zoom de pontos individuais assume um elemento pontual de ~20dp.

Este documento detalha as decisões arquiteturais e técnicas para suportar a visualização e interação com traçados vetoriais, estruturado rigorosamente sob as diretrizes de `PRINCIPIOS.md`.

## Alinhamento com os Princípios de Engenharia (`PRINCIPIOS.md`)

1. **Princípio I (Tudo em Português):**
   - Todos os novos arquivos, classes, métodos, testes, docstrings e variáveis adotam estritamente o português brasileiro como idioma.
   - O utilitário central é denominado `ConstrutorCaminhoTrajeto` (em `lib/utils/construtor_caminho_trajeto.dart`), com métodos como `obterCaminho()`, `aplicarTracejado()` e `limparCache()`.
   - O teste de integridade arquitetural é nomeado `path_drawing_isolation_test.dart` no diretório `test/architecture/`, seguindo o padrão de nomenclatura pré-existente `firebase_isolation_test.dart`.

2. **Princípio II (Componentes Independentes / Feature-First):**
   - O módulo `ConstrutorCaminhoTrajeto` é autossuficiente e desacoplado de widgets ou estados de tela, podendo ser testado e reutilizado de maneira isolada.
   - Regras de geometria e cálculo de distância de toque ficam concentradas em funções puras, sem contaminar o fluxo de ciclo de vida da página `MapaInterativoPage`.

3. **Princípio III (100% de Test Coverage):**
   - Exigência inegociável de 100% de cobertura de código para o novo arquivo `lib/utils/construtor_caminho_trajeto.dart` e para todas as ramificações adicionadas ou modificadas em `lib/pages/mapa_interativo.dart` (`AreaHelper`, `MarkerPainter`, `_zoomToPoints`).

4. **Princípio IV (Imperativo do Teste em Primeiro Lugar / TDD):**
   - Todo arquivo `.dart` de código de produção possui seu arquivo `_test.dart` correspondente espelhando o caminho na pasta `test/`.
   - O ciclo Red-Green-Refactor é aplicado estritamente: os testes de unidade, de widget e de arquitetura são escritos e executados em falha antes da implementação do código de produção correspondente.

5. **Princípio V (Testes de Widget em Primeiro Lugar):**
   - A validação da experiência do usuário é priorizada através de testes de widget em `test/pages/mapa_interativo_test.dart`, simulando toques em curvas abertas, toques fora para ativação do pulso de highlight e verificação do enquadramento de câmera com animação.

6. **Princípio VI (Simplicidade e Anti-Abstração):**
   - Sem hierarquias abstratas desnecessárias de pintores ou classes genéricas de desenho. O código utiliza de forma direta as primitivas do Flutter (`Path`, `Paint`, `Canvas`, `MaskFilter`), preferindo clareza e simplicidade declarativa a generalizações prematuras.

7. **Princípio VII (Documentação Contínua e Abrangente):**
   - Todas as novas classes, métodos e funções contêm docstrings em blocos `///` detalhando a motivação (*o porquê*) e não apenas o comportamento mecânico (*o quê*).
   - O arquivo `frontend/lib/README.md` é atualizado documentando o funcionamento do pipeline de renderização vetorial e a barreira de isolamento arquitetural.

## Goals / Non-Goals

**Goals:**
- Sincronizar as mensagens Protobuf (`croqui.pb.dart`) para suportar `LinhaTrajeto`, `DadosCompiladosLinha`, `MarcadorCompilado` e os campos `linha` e `cor`.
- Criar a classe utilitária `ConstrutorCaminhoTrajeto` (`lib/utils/construtor_caminho_trajeto.dart`) encapsulando o pacote `path_drawing` e provendo cache em memória.
- Implementar teste de barreira arquitetural (`test/architecture/path_drawing_isolation_test.dart`) garantindo que nenhum outro arquivo do projeto importe `path_drawing`.
- Expandir `AreaHelper.getAreaInfo` para suportar `Mapa_PontoDeInteresse_TipoArea.linha`, extraindo a caixa delimitadora da linha e seus pontos de controle.
- Implementar hit-testing ergonômico no `MarkerPainter.hitTest` por menor distância euclidiana a segmentos da curva (~16dp de tolerância).
- Implementar renderização em camadas no `MarkerPainter`: halo de destaque difuso com `MaskFilter.blur` ao redor da via selecionada, contorno de contraste (*casing*), traço principal com cor customizada (`ponto.cor`) e marcadores compilados.
- Renderizar pulso de advertência luminoso ao redor de linhas clicáveis quando o usuário toca em área livre (`highlightIntensity > 0`).
- Adaptar o cálculo de zoom em `_zoomToPoints` para enquadrar a extensão completa de vias com traçado vetorial (da base ao topo) por Bounding Box.
- Atingir 100% de cobertura de testes em todos os arquivos tocados.

**Non-Goals:**
- Não recalcular splines ou interpolações no aplicativo: o dispositivo móvel consome diretamente o `caminho_svg` pré-calculado pelo backend.
- Não alterar a interface dos cartões inferiores de vias, setores ou grupos.
- Não modificar o comportamento ou renderização de áreas fechadas legadas (`circulo`, `quadrado`, `retangulo`, `poligono`).

## Decisions

### Decisão 1: Encapsulamento Estrito em `ConstrutorCaminhoTrajeto` com Teste de Barreira
- **Escolha:** O acesso ao pacote `path_drawing` é confinado a `lib/utils/construtor_caminho_trajeto.dart`. Um teste automatizado (`test/architecture/path_drawing_isolation_test.dart`) varre recursivamente a pasta `lib/` e falha caso qualquer outro arquivo contenha a instrução `import 'package:path_drawing/`.
- **Justificativa:** Atende aos Princípios I, II e VI. Garante que se a dependência precisar ser substituída ou atualizada no futuro, a alteração se restrinja a um único arquivo de domínio com menos de 50 linhas, sem risco de vazamento para a UI.

### Decisão 2: Cache em Memória dos Caminhos (`ui.Path`) Processados
- **Escolha:** Os objetos `ui.Path` gerados a partir da string SVG e estilizados via tracejado são armazenados em um mapa de cache em memória dentro de `ConstrutorCaminhoTrajeto`, indexados por chave composta `"$pontoId-$estilo"`.
- **Justificativa:** O método `paint` do Flutter é executado a cada quadro (60–120 FPS) durante translações e pinças de zoom. Re-executar o parsing do SVG e o cálculo de intervalos de tracejado a cada quadro criaria milhares de objetos descartáveis, pressionando o coletor de lixo (*Garbage Collector*). O cache elimina essa sobrecarga.

### Decisão 3: Hit-Testing por Amostragem de Segmentos e Distância Euclidiana
- **Escolha:** Em vez de depender de `path.contains()`, que não é aplicável a caminhos abertos, o método `MarkerPainter.hitTest(Offset position)` decompõe a curva em segmentos de reta locais utilizando amostragem regular via métricas do caminho (`Path.computeMetrics()`) a cada 15dp.
- **Tolerância Física:** Raio de 16dp ao redor do traçado.
- **Delegação ao Toque Fora:** Se a menor distância euclidiana da coordenada de toque a qualquer segmento for $\le 16\text{dp}$, o método retorna `true`. Se for maior, retorna `false`, permitindo que o `GestureDetector` pai descarte o toque no marcador e acione a desseleção ou o pulso de destaque no fundo da tela.

### Decisão 4: Pintura em Camadas (Layering) do Traçado
- **Escolha:** O `MarkerPainter` desenha o traçado vetorial na seguinte ordem de profundidade:
  1. *Halo de Seleção* (quando `isSelected == true`): traço largo (`espessura + 12`) com `MaskFilter.blur(BlurStyle.normal, 5.0)` e cor viva.
  2. *Halo de Pulso* (quando não selecionado e `highlightIntensity > 0`): traço largo (`espessura + 8 * highlightIntensity`) em branco com opacidade proporcional.
  3. *Contorno de Contraste (Casing)*: traço fino escuro/claro (`espessura + 2`) para separar a linha do fundo da rocha.
  4. *Traço Principal*: traçado estilizado (sólido, tracejado ou pontilhado) com a cor da via (`ponto.cor`).
  5. *Marcadores*: círculos numerados na base, cruxes e paradas desenhados sobre as posições compiladas.

### Decisão 5: Enquadramento de Câmera por Bounding Box Total da Linha
- **Escolha:** No método `_zoomToPoints`, qualquer seleção que inclua um ponto do tipo `linha` utiliza obrigatoriamente a lógica de enquadramento por caixa delimitadora (*Bounding Box*), calculando a escala alvo para que toda a via (da base ao topo) caiba confortavelmente na área útil do viewport (acima do card flutuante).
- **Justificativa:** Corrige a limitação do código legado que tratava qualquer via com um único ponto como pin pontual de 20dp.

## Risks / Trade-offs

- **[Risco: String SVG inválida ou vazia recebida do backend]** → *Mitigação:* `ConstrutorCaminhoTrajeto` utiliza bloco `try/catch` defensivo, registrando o erro no `AppLogger` e retornando um `Path()` vazio, impedindo que a aplicação trave na tela do usuário.
- **[Risco: Toques concorrentes em vias com traçados muito próximos]** → *Mitigação:* O `hitTest` calcula a distância euclidiana exata; em caso de sobreposição de tolerâncias, o sistema seleciona o traçado com menor distância absoluta até o ponto de toque.
- **[Risco: Regressão de comportamento em croquis legados]** → *Mitigação:* A suíte pré-existente de mais de 40 testes de mapa interativo continuará rodando integralmente no CI/CD, e os novos testes validarão que pontos do tipo círculo, retângulo, quadrado e polígono mantêm seu comportamento inalterado.

## Migration Plan

1. Atualização do `frontend/pubspec.yaml` com a adição de `path_drawing: ^1.0.1` e execução de `flutter pub get`.
2. Sincronização dos arquivos compilados Dart do Protobuf (`croqui.pb.dart`).
3. Criação do teste arquitetural `test/architecture/path_drawing_isolation_test.dart` e validação da sua falha/sucesso (TDD).
4. Implementação de `test/utils/construtor_caminho_trajeto_test.dart` e de `lib/utils/construtor_caminho_trajeto.dart`.
5. Escrita dos testes de widget e unidade para `AreaHelper`, `MarkerPainter` e `_zoomToPoints` em `test/pages/mapa_interativo_test.dart`.
6. Implementação das atualizações correspondentes em `lib/pages/mapa_interativo.dart`.
7. Execução completa da suíte de testes com `flutter test --coverage` para verificar aprovação unânime e 100% de cobertura.
8. Atualização de documentação em `frontend/lib/README.md`.
