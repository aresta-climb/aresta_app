# Testes de Widgets

Esta pasta contém testes de widget da interface do usuário. Os testes aqui verificam a renderização correta de componentes visuais e a lógica de interação do usuário.

## Arquivos

| Arquivo | Widget testado | Descrição |
|---|---|---|
| `widget_test.dart` | `HomePage` | Teste básico de carregamento da página principal da aplicação |
| `mapa_interativo_test.dart` | `MapaInterativoPage` | Testa a renderização de marcadores no mapa interativo (posição, labels, overlapping) |
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
