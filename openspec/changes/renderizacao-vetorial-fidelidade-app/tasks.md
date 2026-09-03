## 1. Testes de Widget em Primeiro Lugar: Exibição Incondicional de Linhas e Interatividade (Princípios V e IV)

- [ ] 1.1 [VERMELHO] Escrever teste de widget em `test/pages/mapa_interativo_test.dart` com croqui contendo traçado de linha vetorial sem referência vinculada em `mapa.referencias`, comprovando que a linha não é descartada com `SizedBox.shrink()` e é renderizada na árvore de widgets
- [ ] 1.2 [VERMELHO] Escrever teste de widget validando que o toque do usuário sobre uma linha sem referência realiza a seleção visual (`isSelected == true`) e dispara o auto-zoom pela Bounding Box da linha sem propagar exceções
- [ ] 1.3 [VERDE] Implementar a permissão incondicional de desenho para pontos do tipo `linha` em `_buildMarkers` e o tratamento de foco/zoom em `_onMarkerTap` em `lib/pages/mapa_interativo.dart`
- [ ] 1.4 [REFATORAR] Validar passagem de todos os testes de widget de mapa interativo garantindo código limpo e sem redundâncias

## 2. Testes de Widget e Pintura: Fidelidade Cromática e Dimensional dos Marcadores (Princípios V e IV)

- [ ] 2.1 [VERMELHO] Escrever testes de pintura para `MarkerPainter._paintMarcadores` validando a fidelidade 1:1 com o editor: fundo na cor da via (`corLinha`), texto do rótulo em branco em negrito centralizado, borda interna branca e casing externo escuro de alto contraste
- [ ] 2.2 [VERMELHO] Escrever testes validando que o raio do círculo identificador e a tipografia adaptam-se proporcionalmente à escala da imagem no viewport com limites seguros (clamp entre 11.0 e 15.0dp de raio)
- [ ] 2.3 [VERDE] Implementar as camadas de pintura fiel de `_paintMarcadores` no arquivo `lib/pages/mapa_interativo.dart`
- [ ] 2.4 [REFATORAR] Assegurar renderização nítida dos marcadores sem alocações desnecessárias por quadro

## 3. Testes de Widget e Pintura: Espessura Proporcional e Halos Moderados (Princípios V e IV)

- [ ] 3.1 [VERMELHO] Escrever testes em `test/pages/mapa_interativo_test.dart` verificando que a espessura da linha desenhada é calculada proporcionalmente à largura da imagem na tela (clamp entre 2.0 e 4.0dp)
- [ ] 3.2 [VERMELHO] Escrever testes validando que o halo de seleção e o casing preto adotam larguras moderadas proporcionais (`espessuraVisual + 6.0` e `espessuraVisual + 1.5`)
- [ ] 3.3 [VERDE] Atualizar a fórmula de `espessuraVisual`, `haloPaint` e `casingPaint` em `MarkerPainter._paintLinha` em `lib/pages/mapa_interativo.dart`
- [ ] 3.4 [REFATORAR] Garantir contraste adequado do traço contra qualquer rocha sem poluição visual

## 4. Módulo Utilitário: Tracejado Dinâmico no Espaço do Viewport (Princípios IV e II)

- [ ] 4.1 [VERMELHO] Escrever testes unitários em `test/utils/construtor_caminho_trajeto_test.dart` para o método `aplicarEstiloNoViewport`, validando a aplicação de intervalos nítidos e visíveis de traço e espaço em dp (8.0dp traço / 4.0dp vão para `TRACEJADO`, 3.0dp traço / 4.0dp vão para `PONTILHADO`)
- [ ] 4.2 [VERDE] Implementar `aplicarEstiloNoViewport` em `lib/utils/construtor_caminho_trajeto.dart` preservando o encapsulamento e a barreira arquitetural de `path_drawing`
- [ ] 4.3 [VERDE] Conectar `aplicarEstiloNoViewport` no `MarkerPainter._paintLinha` utilizando o caminho já transformado para coordenadas de tela
- [ ] 4.4 [REFATORAR] Implementar cache em memória para caminhos estilizados no viewport evitando recalcular o tracejado a cada quadro de animação

## 5. 100% de Cobertura, Documentação Abrangente e Validação Visual (Princípios III, VII e I)

- [ ] 5.1 Adicionar docstrings detalhadas com comentários `///` em português em todas as classes, métodos e parâmetros modificados, explicando o racional e a intenção técnica (Princípios I e VII)
- [ ] 5.2 Atualizar o arquivo `lib/utils/README.md` documentando a arquitetura de fidelidade visual 1:1, a decomposição em viewport e as diretrizes de escalonamento
- [ ] 5.3 Executar bateria completa de testes com `flutter test --coverage` e validar rigorosamente a exigência inegociável de 100% de cobertura nos arquivos alterados (Princípio III)
