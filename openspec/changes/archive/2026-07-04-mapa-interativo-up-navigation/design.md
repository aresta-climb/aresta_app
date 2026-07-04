## Context
Atualmente, a `MapaInterativoPage` possui um botão estático "Mapa Geral" que chama `AppNav.toPico` para abrir a `PicoPage`. Os usuários relataram que isso quebra a imersão de exploração, pois esperam que um botão de navegação de mapa os leve para outro mapa, não para uma página de texto com uma visão geral. Toda a nova funcionalidade deve ser desenvolvida sob a disciplina de TDD (Test-Driven Development) garantindo 100% de cobertura.

## Goals / Non-Goals

**Goals:**
- Prover uma navegação hierárquica fluida (Mapa do Setor -> Mapa do Grupo -> Mapa Geral).
- Manter o usuário dentro do ambiente da `MapaInterativoPage` para navegação entre mapas.
- Garantir que o botão não obstrua a visualização do mapa usando um design compacto e truncando textos longos.
- **TDD & Qualidade**: Atingir 100% de cobertura de testes unitários para o código que decide se o botão é exibido, seu texto e o destino da navegação.

**Non-Goals:**
- Alterar as estruturas de dados (Protobuf) dos mapas (`Pico`, `SetorOuGrupo`, `Mapa`).
- Remover a seção de mapas gerais da `PicoPage` (que continua existindo para usuários navegando a partir da página do pico).

## Decisions

- **Texto Dinâmico do Botão**: O texto do botão indicará o destino (ex: `^ Grupo Oculto` ou `^ Mapa Geral`) para dar contexto imediato. Usaremos um widget compacto como `ActionChip` ou um botão pequeno customizado ao invés do grande `FloatingActionButton.extended`.
- **Truncamento de Texto**: Um `ConstrainedBox` com uma `maxWidth` razoável (aprox. 150-200px ou 40% da largura da tela) será usado em conjunto com `TextOverflow.ellipsis` para garantir que o mapa não seja obscurecido por nomes longos.
- **Lógica de Fallback Hierárquica (Testável via TDD)**:
  1. Verifica se `setorContext` pertence a um `grupoContext` que possui mapas. Se sim, o destino é o Mapa do Grupo.
  2. Senão, verifica se o `pico` tem `mapasGerais`. Se sim, o destino é o Mapa Geral.
  3. Senão, o botão não deve ser exibido.
- **Pilha de Navegação (Navigation Stack)**: Navegar "para cima" irá chamar `AppNav.toMapaInterativo(...)`, empurrando um novo `MapaInterativoNode` para a pilha de navegação. Isso permite que o usuário use intuitivamente o botão "Voltar" do sistema para descer a hierarquia.

## Risks / Trade-offs

- **Risco**: Empurrar instâncias novas de `MapaInterativoPage` na pilha ao invés de substituir (replace) pode consumir mais memória.
  - **Mitigação**: A hierarquia é estritamente rasa (Setor -> Grupo -> Pico), significando que a pilha terá no máximo 2-3 níveis de profundidade para mapas, o que o Flutter lida sem esforço.
- **Risco**: Descobrir se um `Setor` pertence a um `Grupo` pode exigir varrer `pico.setoresOuGrupos` se o `grupoContext` não for provido à página.
  - **Mitigação**: A página `MapaInterativoPage` já aceita `grupoContext`. Garantiremos, através de testes rigorosos, que ele seja provido corretamente e que a lógica de resolução lide adequadamente quando ausente.
