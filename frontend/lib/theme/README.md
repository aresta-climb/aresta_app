# Tema e Cores (`lib/theme/`)

Este diretório define as cores, a tipografia e o controle de tema (claro e escuro) do aplicativo usando `ThemeData`, `ThemeMode` e `ThemeExtension`.

## Arquivos

### `cores_app.dart`
Define a extensão `AppColors` sobre `ThemeData`:
- Contém as instâncias `AppColors.light` e `AppColors.dark` com tokens de cor nomeados (`deepBasalt`, `caveShadow`, `graniteEdge`, `chalkWhite`, `ashGrey`, `dryMoss`, `rustIron`, etc.).
- Expõe a extensão `context.colors` em `BuildContext` para leitura das cores do tema atual.
- Define `AppColors.brandColor` para marcadores de mapa e elementos de destaque da marca.

### `gerenciador_tema.dart`
Controlador que persiste o `ThemeMode` escolhido (`system`, `light` ou `dark`) em `SharedPreferences` e expõe um `ValueNotifier<ThemeMode>` observado em `main.dart`.

### `temas.dart`
Funções `construirTemaClaro()` e `construirTemaEscuro()` que montam o `ThemeData` com `ColorScheme`, fonte Montserrat e temas explícitos para `IconButton`, `MenuButton` e `PopupMenu`.
