# Widgets da Caderneta e Perfil do Escalador

Este diretório contém os componentes modulares e independentes de interface (*Widget Components*) dedicados ao registro esportivo e visualização de desempenho do escalador no Aresta Climb.

---

## 1. Componentes

### `ModalRegistroCadena`
Bottom sheet modal para registro e edição de cadenas, seguindo o padrão de **Dumb UI / Humble View** alimentado pelo `RegistroCadenaViewModel`:
- **Chips de Estilo Esportivo**: Permite a seleção entre *À Vista*, *Flash*, *Trabalhado* e *Tentativa*.
- **Contador de Tentativas**: Campo numérico com validação para garantir que tentativas sejam sempre maiores ou iguais a 1.
- **Seletor de Data**: `DatePicker` integrado permitindo registrar ascensões passadas com data retroativa.
- **Notas Privadas**: Campo de texto limitado a 200 caracteres com contador visual em tempo real para anotações íntimas de beta, sensação de esforço ou condições climáticas.

### `GraficoPiramideGraus`
Gráfico visual em pirâmide de graduação de escalada:
- Apresenta as faixas de graduação organizadas verticalmente (do maior grau no topo ao menor na base).
- Barras horizontais dimensionadas proporcionalmente ao volume de ascensões.
- Distinção cromática sutil entre ascensões completas (cadenas) e tentativas totais.
- Estado vazio com mensagem amigável e incentivo esportivo caso o atleta ainda não tenha registros na modalidade selecionada.

### `CardEstatistica`
Card modular de resumo métrico:
- Renderiza ícone temático, valor numérico em destaque e rótulo explicativo.
- Desenvolvido para exibição em grade fluida na tela de perfil do escalador.

---

## 2. Testes de Widget

Seguindo o princípio **V. Testes de Widget em Primeiro Lugar** do `AGENTS.md`, cada componente possui uma suíte dedicada em `test/widgets/caderneta/`:
- `modal_registro_cadena_test.dart`
- `grafico_piramide_graus_test.dart`
- `card_estatistica_test.dart`
