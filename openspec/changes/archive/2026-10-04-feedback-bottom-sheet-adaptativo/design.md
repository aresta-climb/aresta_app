# Design: Bottom Sheet de Feedback Adaptativo e Política de Privacidade

## Context

O pacote `better_feedback` gerencia a interface de captura e anotação visual de feedback do Aresta. Atualmente, o `FeedbackThemeData` no `main.dart` não definia `feedbackSheetHeight`, recaindo sobre o padrão estático de 25% da altura da tela. Em aparelhos modernos e compactos, 25% da tela não comporta a totalidade do formulário de categorização, campo descritivo, aviso de transparência e botão de envio, forçando rolagem vertical interna e ocultando o botão primário.

Adicionalmente, com a evolução da infraestrutura de feedback (migração de canal privado do Discord para issues públicas no GitHub com telemetria restrita em banco Supabase), a Política de Privacidade (`politica-de-privacidade.md`) precisa refletir com exatidão a natureza pública das anotações e a custódia segura dos dados de diagnóstico técnico.

## Goals / Non-Goals

**Goals:**
- Prover altura adaptativa (`feedbackSheetHeight`) proporcional à altura da tela de forma a alocar ~210–220 dp de altura fixa (com `clamp` entre 0.22 e 0.45).
- Eliminar completamente a necessidade de rolagem interna vertical em qualquer dispositivo móvel em modo retrato (desde 320x640 dp até resoluções ultra-altas).
- Maximizar o espaço desobstruído da tela (~75% de área útil livre) para que o usuário possa desenhar e destacar elementos na captura de tela.
- Compactar a interface gráfica:
  - `SegmentedButton` com `VisualDensity.compact` e ícones reduzidos a 16 px (~34 dp de altura total).
  - Campo de texto otimizado para compacidade (1 a 2 linhas com preenchimento interno reduzido).
  - Botão de envio com altura ajustada de 48 dp para 42 dp.
  - Aviso de consentimento em linha única, sem jargões e com redimensionamento proporcional: `"Feedback público. Nenhum dado pessoal é exposto."` via `FittedBox`.
- Atualizar a Política de Privacidade do aplicativo móvel, documentando o fluxo de publicação no GitHub e coleta diagnóstica no Supabase, regenerando o hash em `legal_version.g.dart`.
- Garantir 100% de cobertura de testes automatizados unitários e de widget, seguindo rigorosamente o TDD.

**Non-Goals:**
- Modificar o contrato da API de feedback no backend (já implementado e coberto por testes no Deno).
- Permitir arrasto manual livre da folha (`sheetIsDraggable` permanece `false`), pois o gesto de arrastar entraria em conflito direto com as ferramentas de desenho e anotação do *screenshot*.
- Reestruturar outros fluxos da Política de Privacidade não relacionados a feedback e serviços de telemetria.

## Decisions

### 1. Cálculo Dinâmico de `feedbackSheetHeight` no `main.dart`
- **Abordagem**: Obter a altura física/lógica da tela através do `PlatformDispatcher` ou `MediaQuery` na montagem do `ArestaApp` e parametrizar `feedbackSheetHeight`:
  ```dart
  final double alturaTela = PlatformDispatcher.instance.views.first.physicalSize.height /
      PlatformDispatcher.instance.views.first.devicePixelRatio;
  final double fracaoFolha = (220.0 / (alturaTela > 0 ? alturaTela : 800.0)).clamp(0.22, 0.45);
  ```
- **Racional**: Dispositivos com alturas maiores (ex.: Galaxy S24 Ultra com ~892 dp) recebem uma fração menor (~0.25), deixando ~75% de espaço livre para desenho. Dispositivos compactos (ex.: altura de ~640 dp) recebem uma fração proporcionalmente maior (~0.34), assegurando que os mesmos 220 dp de conteúdo não sofram truncamento ou rolagem.
- **Alternativas Consideradas**:
  - *Fração fixa maior (ex.: 0.35 ou 0.40)*: Desperdiçaria espaço em telas grandes, reduzindo desnecessariamente a área de desenho do usuário.
  - *DraggableScrollableSheet*: Incompatível com o motor de canvas do `better_feedback` que intercepta gestos de toque para pincéis e marcações.

### 2. Compactação dos Elementos no `construtor_feedback_usuario.dart`
- **Abordagem**:
  - `SegmentedButton`: Adição de `style: ButtonStyle(visualDensity: VisualDensity.compact)` e ícones de 16 px.
  - Espaçamentos verticais: `SizedBox(height: 6)` entre blocos funcionais.
  - Campo de texto: `contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)`, `minLines: 1`, `maxLines: isKeyboardVisible ? 1 : 2`.
  - Aviso de Privacidade: Substituição do `Container` decorado por um `FittedBox` direto com `Text('Feedback público. Nenhum dado pessoal é exposto.', maxLines: 1)`.
- **Racional**: Reduz a altura acumulada do formulário de ~345 dp para ~210 dp (quando o seletor está visível) e ~170 dp (em telas neutras sem seletor), eliminando completamente o acionamento da barra de rolagem.

### 3. Atualização Jurídica e Rastreabilidade LGPD
- **Abordagem**:
  - Inserir seção `## Envio de Feedbacks e Sugestões` em `frontend/legal/repo/public/docs/politica-de-privacidade.md`, informando a publicação de relatos comunitários no GitHub e o armazenamento de metadados técnicos no Supabase.
  - Incluir GitHub e Supabase na lista de serviços de terceiros.
  - Executar `dart run tool/legal_updater/bin/update_legal_version.dart` para recalcular o hash de integridade em `legal_version.g.dart`.
- **Racional**: Cumprimento estrito da LGPD (Art. 6º, VI - transparência ativa) e garantia de que o aplicativo sincronize seu estado de aceite dos termos com integridade criptográfica.

## Risks / Trade-offs

- **[Risco: Dispositivos extremamente reduzidos em altura (< 500 dp) ou com fontes gigantes de acessibilidade]** → *Mitigação*: A estrutura mantém o `SingleChildScrollView` como proteção (*fallback*) de layout para evitar *RenderFlex overflow*, garantindo acessibilidade e robustez caso o usuário utilize escala de fonte ampliada pelo sistema.
- **[Risco: Quebra de testes de widget legados por mudança de texto de aviso]** → *Mitigação*: Atualização prévia dos testes de widget em `test/widgets/feedback/construtor_feedback_usuario_test.dart` no ciclo TDD (Red-Green-Refactor) buscando os novos textos e propriedades visuais.
- **[Risco: Falha de compilação ou validação caso o script de hash legal não seja executado]** → *Mitigação*: Execução automatizada e verificação via `flutter test test/core/legal/` após a alteração do Markdown.
