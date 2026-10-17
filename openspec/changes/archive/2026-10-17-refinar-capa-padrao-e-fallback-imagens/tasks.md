# Tasks

## 1. Cartões de Pico e Cabeçalho da Página de Pico (`CardPico` e `PicoPage`)

- [x] 1.1 Escrever testes de widget (Red) em `frontend/test/widgets/card_pico_test.dart` e `frontend/test/pages/pico_test.dart` validando que: (a) quando `capaPath` e `thumbnailUrl` são vazios, exibe `assets/logo_in_app.jpg` sem `Padding` dentro de um `Container` com `color: Colors.black`; (b) quando `capaPath` ou `thumbnailUrl` não são vazios mas `ProvedorImagemAresta.resolver` retorna `null` ou falha na decodificação (`errorBuilder`), exibe `Icons.broken_image` com `color: Colors.grey` e NÃO exibe `assets/logo_in_app.jpg`; (c) durante `ConnectionState.waiting`, exibe apenas o container neutro sem logo nem ícone de erro
- [x] 1.2 Implementar a separação entre `_construirCapaPadraoAresta` (`assets/logo_in_app.jpg` com fundo `Colors.black`) e `_construirImagemIndisponivel` (`Icons.broken_image` cinza) em `frontend/lib/widgets/card_pico.dart` com docstrings em português, verificando que os testes `card_pico_test.dart` e `pico_test.dart` passam com 100% de cobertura nas linhas alteradas

## 2. Cartões da Lista de Meus Croquis (`OfflineCragCard`)

- [x] 2.1 Escrever testes de widget (Red) em `frontend/test/view/function_library/meus_croquis_functions_test.dart` validando que: (a) quando `caminhoMiniatura` é vazio, exibe `assets/logo_in_app.jpg` sem `Padding` sobre fundo `Colors.black`; (b) quando `caminhoMiniatura` não é vazio mas `ProvedorImagemAresta.resolver` retorna `null` ou aciona `errorBuilder`, exibe `Icons.broken_image` com `color: Colors.grey` e NÃO exibe `assets/logo_in_app.jpg`; (c) durante `ConnectionState.waiting`, exibe o container escuro neutro sem logo nem ícone
- [x] 2.2 Implementar `_construirCapaPadraoAresta` e `_construirImagemIndisponivel` em `frontend/lib/view/function_library/meus_croquis_functions.dart` com docstrings em português, verificando que `meus_croquis_functions_test.dart` passa com 100% de cobertura nas linhas alteradas
