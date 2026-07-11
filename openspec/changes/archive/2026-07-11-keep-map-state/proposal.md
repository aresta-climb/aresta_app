## Why

Quando um usuário alterna entre múltiplos mapas interativos na página `MapasCarrosselPage`, o `PageView` destrói o estado dos mapas que foram visualizados anteriormente. Como resultado, ao retornar para um mapa, a animação de zoom inicial é acionada novamente e o estado de movimentação/zoom (pan/zoom) do usuário é perdido. Esta mudança visa preservar o estado dos mapas para melhorar a experiência do usuário e fazer com que pareça o retorno a uma aba já aberta.

Além disso, esta mudança deve ser implementada seguindo estritamente os princípios de Desenvolvimento Orientado a Testes (TDD), garantindo 100% de cobertura de testes unitários para o novo comportamento. Docstrings detalhadas também serão adicionadas para melhorar a manutenibilidade do código.

## What Changes

- **TDD Primeiro:** Escrever testes de widget que verifiquem a preservação do estado do mapa no `PageView` antes de modificar o widget.
- **Implementação:** Adicionar `AutomaticKeepAliveClientMixin` ao `_MapaInterativoPageState`, definir `wantKeepAlive => true` e chamar `super.build(context)`.
- **Documentação:** Adicionar docstrings abrangentes ao `MapaInterativoPage` e sua classe de estado para explicar o comportamento de preservação de estado (keep-alive).

## Capabilities

### New Capabilities
None.

### Modified Capabilities
None.

## Impact

- `frontend/lib/pages/mapa_interativo.dart`
- `frontend/test/pages/mapa_interativo_test.dart` (ou arquivo similar de teste de widget)
- Ligeiro aumento no uso de memória ao visualizar vários mapas em um carrossel, já que os widgets de mapa serão mantidos vivos. No entanto, como o número típico de mapas por pico é pequeno (<= 5), isso está perfeitamente dentro dos limites aceitáveis.
