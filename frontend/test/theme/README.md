# Testes de Tema (`test/theme/`)

Este diretório contém os testes unitários dos módulos em `lib/theme/`.

## Escopo

- **`GerenciadorTema`**: Persistência e leitura do `ThemeMode` (`system`, `light`, `dark`) em `SharedPreferences`.
- **`AppColors` (`ThemeExtension`)**: Interpolação (`lerp`), cópia (`copyWith`) e acesso às paletas `AppColors.light` e `AppColors.dark`.
- **Construtores de Tema**: Validação de `construirTemaClaro()` e `construirTemaEscuro()`.

## Execução

```bash
flutter test test/theme/
```
