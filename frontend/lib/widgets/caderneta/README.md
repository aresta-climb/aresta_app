# Widgets da Caderneta (`lib/widgets/caderneta/`)

Este diretório contém os widgets usados no registro de ascensões e na página `CadernetaPage`. Nenhum arquivo deste diretório importa `lib/services/`.

---

## 1. Componentes

### `ModalRegistroCadena` (`modal_registro_cadena.dart`)
Bottom sheet controlado por `RegistroCadenaViewModel` para criar ou editar uma `Cadena`:
- Seleção de estilo (`À Vista`, `Flash`, `Trabalhado`, `Tentativa`), contador de tentativas ($\ge 1$), data da ascensão e `notasPrivadas` (até 200 caracteres).
- Integra `SecaoContribuicaoPublicaAscensao` (`secao_contribuicao_publica_cadena.dart`) para envio opcional de voto de grau (`-2` a `+2`) e comentário público.

### `ControlesFormularioCadena` (`controles_formulario_cadena.dart`)
Controles individuais do formulário: `SeletorEstiloAscensao`, `ContadorTentativasAscensao`, `SeletorDataAscensao` e `CampoNotasPrivadasAscensao`.

### `SecaoMeusAlertasCaderneta` (`secao_meus_alertas_caderneta.dart`)
Seção exibida na `CadernetaPage` com os alertas criados (`CRIADO POR VOCÊ`) e confirmados (`CONFIRMADO (+1)`) pelo usuário, permitindo abrir a via correspondente ou marcar o alerta como resolvido.

### `GraficoPiramideGraus` (`grafico_piramide_graus.dart`)
Exibe a distribuição de ascensões e tentativas por grau (do maior no topo ao menor na base) para vias e boulders, além do estado vazio quando não há registros.

### `CardEstatistica` e `PainelResumoEstatisticasCaderneta` (`card_estatistica.dart`)
Cartões numéricos organizados em grade 2×2 para resumo das métricas da caderneta.

---

## 2. Testes

Espelhados 1:1 em `test/widgets/caderneta/`:
- `modal_registro_cadena_test.dart`
- `secao_contribuicao_publica_cadena_test.dart`
- `controles_formulario_cadena_test.dart`
- `secao_meus_alertas_caderneta_test.dart`
- `grafico_piramide_graus_test.dart`
- `card_estatistica_test.dart`
