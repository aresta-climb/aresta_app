# Tasks: Restaurar Marcadores no Mapa Global e Desduplicação de Feedback

## 1. Resolução de Picos e Fallback no ViewModel (TDD)

- [x] 1.1 Escrever testes unitários em `frontend/test/view/view_models/mapa_global_view_model_test.dart` cobrindo a resolução de `picosNoMapa` a partir de instâncias de `CardCroquiViewModel`, identificadores em texto (`String`) e o fallback automático para o catálogo completo quando a lista inicial não contiver coordenadas (Red).
- [x] 1.2 Implementar a resolução de `CardCroquiViewModel` e IDs no `MapaGlobalViewModel.picosNoMapa` em `frontend/lib/view/view_models/mapa_global_view_model.dart`, consultando o catálogo ativo no repositório e aplicando fallback automático para `dataset.metadadosDisponiveis` caso nenhum marcador válido seja obtido (Green).

## 2. Normalização de Identificadores na Navegação (TDD)

- [x] 2.1 Adicionar testes de navegação em `frontend/test/navigation/arvore_navegacao_test.dart` e `frontend/test/navigation/construtor_view_arvore_test.dart` validando que `MapaGlobalNode` aceita `picoIds` ou coleções heterogêneas e constrói o `MapaGlobalViewModel` adequadamente (Red).
- [x] 2.2 Atualizar `MapaGlobalNode` em `frontend/lib/navigation/arvore/nos_globais.dart`, `AppNav.toMapaGlobal` em `frontend/lib/navigation/funcoes_navegacao.dart` e `frontend/lib/navigation/construtor_view_arvore.dart` para suportar `picoIds` e normalizar a passagem de identificadores de forma desacoplada (Green).

## 3. Desduplicação de Feedback e Testes de Widget no Mapa (TDD)

- [x] 3.1 Criar testes de widget em `frontend/test/pages/mapa_global_test.dart` validando que a tela `MapaGlobalPage` renderiza marcadores com sucesso ao receber `CardCroquiViewModel` e que a `AppBar` contém exatamente um botão de envio de feedback (Red).
- [x] 3.2 Remover o parâmetro redundante `actions: [buildFeedbackButton(context)]` em `frontend/lib/pages/mapa_global.dart`, permitindo que `buildCommonAppBar` faça o gerenciamento único do botão de feedback (Green).

## 4. Validação Geral e Documentação

- [x] 4.1 Executar os testes de widget, unitários e de navegação pertinentes (`flutter test test/pages/mapa_global_test.dart test/view/view_models/mapa_global_view_model_test.dart test/navigation/arvore_navegacao_test.dart test/navigation/construtor_view_arvore_test.dart`) garantindo 100% de sucesso.
- [x] 4.2 Atualizar a documentação pertinente em `frontend/lib/view/README.md` e `frontend/lib/navigation/README.md` refletindo o suporte a `CardCroquiViewModel` e identificadores de pico no Mapa Global.
