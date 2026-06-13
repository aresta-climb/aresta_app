# Camada de Tema (`lib/theme/`)

Este diretório contém a lógica de estilização, cores e o gerenciamento do tema do aplicativo Aresta Climb.

A arquitetura de tema do aplicativo é construída utilizando o sistema nativo do Flutter (`ThemeData`, `ThemeMode` e `ThemeExtension`), o que garante alta performance, suporte a temas claros e escuros de forma fluida, e *type-safety* (segurança de tipos) durante o desenvolvimento.

## Componentes

### `app_colors.dart`
Define a paleta de cores unificada do aplicativo usando `ThemeExtension`.
Em vez de depender de instâncias hardcoded de `Color` que não podem mudar com base no contexto, as cores são acessadas de forma reativa através do `BuildContext`.

- **`AppColors`**: Uma extensão do `ThemeData` que armazena todas as cores semânticas (ex: `nobleBlack`, `beastHide`, `fishBone`).
- Duas instâncias estáticas são fornecidas: `AppColors.light` e `AppColors.dark`.
- **Acesso fácil**: Uma extensão no `BuildContext` (`AppColorsExtension`) permite acessar as cores em qualquer widget com a sintaxe enxuta: `context.colors.nomeDaCor`.
- **Cor da Logomarca**: Além das cores reativas aos modos de tela, a extensão abriga a `AppColors.brandColor`, que centraliza a cor oficial e vibrante do aplicativo usada em marcadores de mapas e ícones de identidade visual.

### `theme_controller.dart`
Controlador Singleton que gerencia o estado global do tema selecionado pelo usuário.
- Armazena a preferência de tema (Sistema, Claro, ou Escuro) utilizando o `SharedPreferences` para persistir a escolha entre as sessões do aplicativo.
- Expõe um `ValueNotifier<ThemeMode>` que o `main.dart` escuta via `ValueListenableBuilder` para reconstruir toda a árvore de widgets quando o tema é alterado, sem a necessidade de pacotes externos de gerenciamento de estado.
