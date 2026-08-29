## 1. Fase 1: Zoom Monotônico para Pontos Únicos (TDD)

- [x] 1.1 [TDD - Red] Escrever testes de widget em `mapa_interativo_test.dart` verificando que a escala 4.5x não é reduzida ao tocar em ponto único e que escala 1.0x é ampliada para 2.5x
- [x] 1.2 [TDD - Green] Implementar obtenção de `escalaAtual` e regra monotônica `escalaAlvo = math.max(escalaAtual, escalaAlvoPadrao)` em `_zoomToPoints` no arquivo `mapa_interativo.dart`
- [x] 1.3 [TDD - Green] Validar que a lógica de enquadramento (caixa delimitadora) para rotas com múltiplos pontos (`pontos.length > 1`) permanece intacta e passando nos testes existentes
- [x] 1.4 [Documentação] Adicionar docstrings explicativas em português brasileiro (`///`) documentando a regra de zoom monotônico em `mapa_interativo.dart`

## 2. Fase 2: Zoom Dinâmico e Limite de Escala Expandido (TDD)

- [x] 2.1 [TDD - Red] Escrever testes de widget para ampliação com `maxScale` de 10.0x e para o cálculo de zoom dinâmico proporcional à dimensão do elemento (~44dp)
- [x] 2.2 [TDD - Green] Atualizar `maxScale: 10.0` no `InteractiveViewer` em `mapa_interativo.dart`
- [x] 2.3 [TDD - Green] Implementar função de cálculo de zoom dinâmico confortável (~44dp) respeitando estritamente a regra monotônica de nunca reduzir a escala atual
- [x] 2.4 [Documentação] Documentar detalhadamente o cálculo de escala dinâmica e dimensões lógicas com comentários `///` em português

## 3. Fase 2: Gestos e Preservação de Intenção do Usuário (TDD)

- [x] 3.1 [TDD - Red] Escrever testes de widget para detecção de zoom manual do usuário ("Memória de Zoom") e para o gesto de duplo toque
- [x] 3.2 [TDD - Green] Implementar rastreamento de interação manual de pinça para manter a escala escolhida pelo usuário em toques subsequentes
- [x] 3.3 [TDD - Green] Implementar manipulador de gesto de duplo toque para alternar entre visão geral e zoom ótimo centrado no ponto tocado
- [x] 3.4 [Documentação] Documentar o comportamento dos gestos e da memória de zoom com docstrings em português

## 4. Validação Geral e Cobertura 100%

- [x] 4.1 Executar a suíte completa de testes de `mapa_interativo_test.dart` e garantir 100% de sucesso
- [x] 4.2 Verificar que a navegação e transições visuais entre `MapasCarrosselPage`, `ViaPage` e `MapaInterativoPage` operam sem nenhuma regressão
