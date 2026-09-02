# Testes de Widgets

Esta pasta contém testes de widget da interface do usuário. Os testes aqui verificam a renderização correta de componentes visuais e a lógica de interação do usuário.

## Arquivos

| Arquivo | Widget testado | Descrição |
|---|---|---|
| `widget_test.dart` | `HomePage` | Teste básico de carregamento da página principal da aplicação |
| `app_version_checker_test.dart` | `AppVersionChecker` | Testa verificação de obsolescência de versão e bloqueio rígido com UI |
| `banner_modo_online_test.dart` | `BannerModoOnline` | Testa a exibição e ações do banner de aviso de navegação online |
| `crag_list_item_test.dart` | `CragCard` | Testa o card de pico na grade de exploração com status e progresso de download |
| `global_search_test.dart` | `GlobalSearchModal` | Testa o modal de busca global com pesquisa aproximada (Fuzzy) |
| `mapa_thumbnail_test.dart` | `MapaThumbnail` | Testa preview interativo de mapa e transições |
| `modal_confirmacao_saida_test.dart` | `ModalConfirmacaoSaida` | Testa o guardião de saída em modo online (com feedback e salvamento) |
| `nearby_crags_carousel_test.dart` | `NearbyCragsCarousel` | Testa carrossel horizontal de picos próximos e destaques |
| `provedor_imagem_aresta_test.dart` | `ProvedorImagemAresta` | Testa resolução de imagens em camadas (local, cache temporário e CDN) |
| `feedback/custom_feedback_builder_test.dart` | `CustomStringFeedback` | Testa o layout e comportamento visual (Light/Dark mode) do formulário de In-App Feedback |

## Como executar

```bash
# Todos os testes desta pasta
flutter test test/widgets/

# Um arquivo específico
flutter test test/widgets/mapa_interativo_test.dart
```

## Notas

- Testes de widget requerem o `TestWidgetsFlutterBinding`, que inicializa o binding do Flutter.
- Requisições HTTP feitas durante testes de widget retornam **status 400** automaticamente (comportamento padrão do `TestWidgetsFlutterBinding`). Código que depende de rede real deve mockar o cliente HTTP.
- O `widget_test.dart` pode falhar em ambientes sem a estrutura de binding corretamente inicializada — isso é esperado e não indica problema na lógica de negócio.
