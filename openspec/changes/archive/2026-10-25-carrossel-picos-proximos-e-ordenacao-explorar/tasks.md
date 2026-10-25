# Tasks

## 1. Unificação do Cálculo Geodésico e Formatação de Distância

- [x] 1.1 Escrever testes unitários em `frontend/test/view/function_library/funcoes_home_test.dart` e `frontend/test/view/view_models/home_view_model_test.dart` validando `calcularPicosMaisProximos` sem limite (`limite: null`), formatação unificada de distância (`formatarDistanciaKm`) e a flag `temMaisPicosParaExplorar` no `HomeViewModel`, verificando que os novos casos falham inicialmente (Red)
- [x] 1.2 Atualizar `calcularPicosMaisProximos` em `frontend/lib/view/function_library/funcoes_home.dart`, extrair a formatação compartilhada de distância e adicionar `temMaisPicosParaExplorar` e callback de sincronização de localização em `frontend/lib/view/view_models/home_view_model.dart`, verificando que `flutter test test/view/function_library/funcoes_home_test.dart test/view/view_models/home_view_model_test.dart` passa com 100% de cobertura (Green/Refactor)

## 2. Ordenação por Proximidade, Badges de Distância e Foco no 7º Pico no BrowseViewModel

- [x] 2.1 Escrever testes unitários orientados a comportamento em `frontend/test/view/view_models/explorar_view_model_test.dart` cobrindo ordenação padrão por distância ("Mais próximos") idêntica à Home, fallback alfabético sem GPS, presença de `textoDistancia` nos `picosCards` em todas as ordenações (`Mais próximos`, `Alfabético`, `Mais escaladas`) e acionamento de `focarSetimoPicoProximo()`, verificando a falha inicial (Red)
- [x] 2.2 Implementar no `BrowseViewModel` (`frontend/lib/view/view_models/explorar_view_model.dart`) o recebimento das coordenadas do usuário, o uso de `calcularPicosMaisProximos` para ordenação por distância e cálculo das *badges*, e o notificador `solicitacaoScrollSetimoPico` via `focarSetimoPicoProximo()`, verificando que `flutter test test/view/view_models/explorar_view_model_test.dart` passa com 100% de cobertura (Green/Refactor)

## 3. Carrossel Finito de Top 6 e Card "VER MAIS ->" na Página Inicial

- [x] 3.1 Atualizar e adicionar testes de widget em `frontend/test/widgets/carrossel_picos_proximos_test.dart` e `frontend/test/pages/home_test.dart` verificando a remoção do loop circular repetitivo, a exibição dos top 6 picos seguidos pelo card `"VER MAIS ->"` (quando houver mais de 6 picos) e o acionamento da navegação ao tocar no card, confirmando a falha inicial (Red)
- [x] 3.2 Refatorar `NearbyCragsCarousel` (`frontend/lib/widgets/carrossel_picos_proximos.dart`), `funcoes_home.dart` e `HomePage` (`frontend/lib/pages/home.dart`) para remover a rolagem circular infinita, renderizar o card minimalista `"VER MAIS ->"` (`340x200`, `borderRadius: 24`) após o 6º pico e propagar o callback `onVerMais`, verificando que `flutter test test/widgets/carrossel_picos_proximos_test.dart test/pages/home_test.dart` passa com 100% de cobertura (Green/Refactor)

## 4. Aba Explorar (UI, Modal de Ordenação e Auto-Scroll para o 7º Pico) e Integração de Navegação

- [x] 4.1 Escrever testes de widget em `frontend/test/pages/explorar_test.dart`, `frontend/test/view/function_library/funcoes_explorar_test.dart` e `frontend/test/navigation/wrapper_navegacao_arvore_test.dart` validando as opções do modal (`Mais próximos`, `Alfabético (A-Z)`, `Mais escaladas`), a renderização da *badge* de distância nos cards, a sincronia de localização entre Home e Explorar e o auto-scroll automático até o 7º pico ao clicar em `"VER MAIS ->"`, verificando a falha inicial (Red)
- [x] 4.2 Atualizar `BrowsePage` (`frontend/lib/pages/explorar.dart`), `funcoes_explorar.dart` (`frontend/lib/view/function_library/funcoes_explorar.dart`) e `TreeNavigationWrapper` (`frontend/lib/navigation/wrapper_navegacao_arvore.dart`) para exibir as novas opções de ordenação, realizar o auto-scroll até o 7º pico e conectar o card `"VER MAIS ->"` da Home com a aba Explorar, atualizando docstrings e `README.md` pertinentes e verificando que toda a suíte de testes passa sem avisos de análise estática
