# Tasks: controles-e-mapa-responsivo

## 1. Limite de Altura no Mapa (`MapaThumbnail`)

- [x] 1.1 Criar testes de widget em `test/widgets/mapa_thumbnail_test.dart` garantindo que o container de miniatura tenha altura máxima limitada a 260px em mapas com proporção retrato/quadrada e preserve a proporção natural em mapas panorâmicos.
- [x] 1.2 Implementar contenção de altura máxima com `BoxConstraints(maxHeight: 260)`, `BoxFit.cover` e `Alignment.center` em `frontend/lib/widgets/mapa_thumbnail.dart` e verificar aprovação dos testes.

## 2. Rastreabilidade de Navegação (`ControlesNode`)

- [x] 2.1 Criar testes unitários em `test/navigation/arvore_navegacao_test.dart` para validar o comportamento, caminho curto (`Pico -> Setores -> Controles`) e mesclagem de ancestrais de `ControlesNode`.
- [x] 2.2 Implementar a classe `ControlesNode` em `frontend/lib/navigation/arvore/nos_modais.dart` e exportá-la em `frontend/lib/navigation/arvore_navegacao.dart`.

## 3. Modal Bottom Sheet de Controles e Barra de Chips Horizontais

- [x] 3.1 Escrever testes de widget em `test/widgets/painel_filtros_indice_test.dart` cobrindo a barra de Controles externa com scroll horizontal em linha única, chip de ordenação dinâmico com botão de reset rápido (`✕`), acionamento do Bottom Sheet reativo, botão "Limpar" unificado e botão de feedback na extrema direita do cabeçalho.
- [x] 3.2 Refatorar `frontend/lib/widgets/painel_filtros_indice.dart` para acionar o Modal Bottom Sheet reativo com seções separadas de "Ordenação" e "Filtros", empurrando `ControlesNode` para o `TreeNavigationController`, e renderizar a barra de chips horizontal compacta na página.

## 4. Integração nas Páginas de Exploração e Verificação

- [x] 4.1 Atualizar testes em `test/pages/pico_subpages/setores_page_test.dart` e `test/pages/grupo_test.dart` validando a interface unificada de exploração sem a presença da barra de ordenação solta.
- [x] 4.2 Atualizar `frontend/lib/pages/pico_subpages/setores_page.dart` e `frontend/lib/pages/grupo.dart` integrando a ordenação exclusivamente ao componente de Controles.
- [x] 4.3 Executar a suíte completa de testes (`flutter test`) e a análise estática (`flutter analyze`), garantindo 100% de testes passando e zero lints.
