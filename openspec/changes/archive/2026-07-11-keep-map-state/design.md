## Context

A `MapasCarrosselPage` permite que os usuários deslizem entre múltiplos mapas (ex: setores ou diferentes níveis de zoom de um pico). Atualmente, por usar um `PageView.builder` padrão, os mapas que saem da visualização são destruídos para economizar memória. Quando o usuário volta para eles, os mapas são reconstruídos do zero, fazendo com que a animação inicial de zoom seja reproduzida novamente e o estado anterior de zoom e movimentação (pan) seja perdido.

## Goals / Non-Goals

**Goals:**
- Preservar o estado visual (pan, zoom e status da animação) dos mapas interativos ao deslizar pelo carrossel de mapas.
- Garantir que a experiência do usuário pareça contínua e responsiva.
- Manter 100% de cobertura de testes unitários para as mudanças introduzidas, seguindo o Desenvolvimento Orientado a Testes (TDD).
- Melhorar a manutenibilidade do código através de docstrings abrangentes.

**Non-Goals:**
- Não implementar gerenciamento de memória customizado ou uma variante customizada de `IndexedStack`. Vamos contar com a preservação de estado padrão do Flutter.

## Decisions

1. **Usar `AutomaticKeepAliveClientMixin`**:
   Adicionaremos o `AutomaticKeepAliveClientMixin` ao `_MapaInterativoPageState`.
   *Justificativa*: Esta é a abordagem idiomática do Flutter para manter o estado vivo em listas sob demanda (lazy) como `PageView` ou `ListView`. É simples, embutida no framework e evita a necessidade de extrair o estado complexo (movendo o `TransformationController` para fora do widget de mapa).

2. **Desenvolvimento Orientado a Testes (TDD)**:
   Escreveremos testes de widget que instanciam um `PageView` contendo múltiplas instâncias de `MapaInterativoPage`. O teste irá deslizar para frente e para trás e verificará se o estado do primeiro mapa não é descartado (disposed).
   *Justificativa*: Garante que o bug seja reproduzível em testes e que nossa correção evite corretamente a destruição do estado.

3. **Considerações de Memória**:
   Embora o `AutomaticKeepAliveClientMixin` mantenha widgets na memória, o caso de uso típico envolve carrosséis com um número pequeno de mapas (<= 5). Isso está perfeitamente dentro dos limites de memória dos dispositivos modernos, mesmo com imagens grandes de mapas.

## Risks / Trade-offs

- **[Risco] Alto uso de memória em dispositivos com muitos mapas** → *Mitigação*: O número de mapas por pico é tipicamente baixo. Se encontrarmos problemas de memória no futuro, podemos explorar um cache LRU (Least Recently Used) ou a elevação explícita (state hoisting) das propriedades do `InteractiveViewer` em vez de manter o widget inteiro vivo.
