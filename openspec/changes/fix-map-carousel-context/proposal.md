## Why

Quando um usuário clica no botão "Ver nos mapas" em uma via/boulder que aparece em múltiplos mapas, o aplicativo navega para o Carrossel de Mapas e deve aplicar um auto-zoom para focar na pedra selecionada. No entanto, o aplicativo falha e o zoom não ocorre (nenhuma seleção é feita). Isso acontece porque o contexto do Grupo (ex: "pedreira") não está sendo repassado para a tela do carrossel (está hardcoded como `null`), impedindo o aplicativo de encontrar a referência (SVG) correspondente à via. Além disso, o contexto da Escalada atual precisa ser repassado para garantir que a aba certa do carrossel seja selecionada quando múltiplas vias compartilham o mesmo desenho.

## What Changes

- O objeto `CarrosselItemData` será instanciado repassando o `grupoContextNome` (obtido do mapa indexado) ao invés de `null`.
- Adição da propriedade `escaladaContextNome` na classe `CarrosselItemData`.
- Atualização das chamadas em `via_functions.dart` e `mapa_interativo.dart` para repassar esses dois contextos.
- **TDD e Cobertura**: Todo o código modificado e novo será desenvolvido utilizando Test-Driven Development (TDD) para garantir 100% de cobertura nos testes unitários/widgets das áreas afetadas.
- **Documentação**: Adição de docstrings explicativas detalhando o porquê de cada contexto estar sendo repassado e como eles afetam a navegação e o auto-zoom.

## Capabilities

### New Capabilities

### Modified Capabilities

## Impact

- `frontend/lib/pages/mapa_interativo.dart` (lógica e testes)
- `frontend/lib/view_functions/via_functions.dart` (lógica e testes)
- `frontend/lib/navigation/navigation_tree.dart` (modelo, testes e docstrings)
