## 0. TDD e Preparação de Testes (Unitários e de Widget)

- [x] 0.1 Escrever testes de widget para `MapaInterativoPage` assegurando que, quando `hideAppBar` for `true`, a página não contenha um `AppBar` renderizado (cobertura total do estado da tela).
- [x] 0.2 Escrever testes de widget para `MapaInterativoPage` assegurando que, quando `hideAppBar` for `false` (padrão), o `AppBar` tradicional ("<- Croqui Interativo") esteja presente.
- [x] 0.3 Escrever testes de widget para `MapasCarrosselPage` verificando que a nova `AppBar` existe e contém o botão de voltar e os controles numéricos (ex: "01 de 02").
- [x] 0.4 Escrever testes garantindo que o widget flutuante superior (`Positioned`) não seja mais injetado na árvore do `MapasCarrosselPage`.

## 1. Modificar MapaInterativoPage (Com Documentação)

- [x] 1.1 Adicionar parâmetro booleano `hideAppBar` ao construtor de `MapaInterativoPage` com valor default `false`. Incluir uma docstring detalhada explicando a motivação e comportamento dessa propriedade.
- [x] 1.2 Atualizar o método `build` de `MapaInterativoPage` para retornar a `AppBar` apenas quando `hideAppBar` for `false`. Se `true`, retornar apenas a estrutura do mapa (garantindo que os limites de SafeArea sejam respeitados e documentando isso no código).
- [x] 1.3 Avaliar os botões absolutos do mapa (como `Mapa Geral` e `Auto Zoom`) e, caso a `AppBar` não esteja presente, confirmar a margem com um padding/SafeArea. Adicionar docstrings às lógicas de layout afetadas.

## 2. Refatorar MapasCarrosselPage (Com Documentação)

- [x] 2.1 Adicionar o `Scaffold` envolvente em `MapasCarrosselPage` e documentar a hierarquia visual alterada na docstring da classe.
- [x] 2.2 Adicionar a `AppBar` no topo do `MapasCarrosselPage` e extrair as ações comuns do mapa (ex: botão de feedback). Documentar os componentes da `AppBar`.
- [x] 2.3 Substituir o título padrão da `AppBar` pela paginação (`< 01 de 02 >`) e documentar o estado do carrossel associado a esse título.
- [x] 2.4 Remover o widget `Positioned` ("UI Flutuante Superior") e garantir que toda a lógica de paginação funcione nativamente através da `AppBar`.

## 3. Teste, Validação e Cobertura (100%)

- [x] 3.1 Executar a suíte de testes de TDD para assegurar 100% de cobertura de código no comportamento de `hideAppBar` e da nova estrutura de layout do carrossel.
- [x] 3.2 Validar manualmente (se necessário/aplicável) a abertura unitária do mapa e ausência de regressões (AppBar presente).
- [x] 3.3 Validar a fluidez do *swipe* no carrossel assegurando que a `AppBar` fique fixa enquanto a imagem desliza, fechando os critérios de aceitação.
