# Testes de Tema (`test/theme/`)

Esta pasta contém os testes unitários focados na arquitetura de cores e tema do aplicativo Aresta Climb.

## Escopo dos Testes

- **`ThemeController`**: Verifica se o controlador gerencia e persiste adequadamente o `ThemeMode` (Claro, Escuro) selecionado pelo usuário via `SharedPreferences`.
- **`AppColors` (ThemeExtension)**: Assegura que o Flutter é capaz de ler e misturar (`lerp`) as cores definidas dinamicamente para os temas Claro e Escuro sem lançar exceções.
- **Integração de Cores em Helpers Globais**: Testa se helpers (como os de `common_functions.dart` ou getters dinâmicos) conseguem resolver a cor correta dependendo do `ThemeMode` ativo.

## Como Executar

Para executar apenas os testes deste módulo:

```bash
flutter test test/theme/
```
