## 1. Testes de Unidade e Widget (TDD - Fase Vermelha)

- [x] 1.1 Atualizar testes de widget existentes de renderização de linhas e marcadores em `test/pages/mapa_interativo_test.dart` para esperar espessura e raio estritamente proporcionais 1:1 (`espessura * escalaX` e `raio * escalaX`), verificando que os testes falham inicialmente.
- [x] 1.2 Adicionar testes de widget e de unidade para a hitbox adaptativa em `test/pages/mapa_interativo_test.dart`, verificando área mínima ergonômica no zoom 1.0x e colapso da tolerância extra para zero no zoom ampliado.

## 2. Implementação de Renderização Proporcional 1:1

- [x] 2.1 Refatorar `_paintLinha` em `lib/pages/mapa_interativo.dart` para calcular a espessura visual como `espessuraNominal * escalaX` e casing proporcional sem o multiplicador `2.2` e sem `clamp(2.0, 4.0)`.
- [x] 2.2 Refatorar `_paintMarcadores` em `lib/pages/mapa_interativo.dart` para calcular raio e tamanho de fonte estritamente como `raioNominal * escalaX` e `tamanhoFonteNominal * escalaX` sem `clamp(11.0, 15.0)`.

## 3. Implementação da Hitbox Adaptativa ao Tamanho em Tela

- [x] 3.1 Propagar a escala de zoom atual (`zoomAtual`) da matriz de transformação para o `MarkerPainter` no método `_buildMarkers`.
- [x] 3.2 Implementar a fórmula de tolerância ergonômica adaptativa em `MarkerPainter.hitTest`, garantindo área mínima de toque em tela (22.0 dp para nós e 16.0 dp para linhas) com colapso progressivo para zero conforme o zoom aumenta.

## 4. Documentação, Cobertura e Validação Integrada

- [x] 4.1 Documentar toda a implementação e fórmulas com docstrings abrangentes (`///`) em português explicando a intenção e o porquê dos cálculos, conforme o Princípio VII do `AGENTS.md`.
- [x] 4.2 Executar a suíte de testes com cobertura (`flutter test --coverage test/pages/mapa_interativo_test.dart`) e validar 100% de test coverage nas linhas modificadas/adicionadas, conforme o Princípio III do `AGENTS.md`.
- [x] 4.3 Executar a análise estática (`flutter analyze`) e garantir zero erros, warnings ou lints pendentes.
