# Proposta: Bottom Sheet de Feedback Adaptativo e Política de Privacidade

## Why

Atualmente, o formulário inferior (*bottom sheet*) de coleta de feedback in-app utiliza uma fração estática de altura (25% da tela no pacote `feedback`), o que corta o botão de envio e o aviso de transparência, forçando o usuário a realizar uma rolagem interna desconfortável. Em aparelhos menores, esse comportamento degrada severamente a usabilidade. Além disso, o aviso de consentimento anterior ocupava espaço excessivo com termos técnicos ("GitHub"), e a mudança do destino dos feedbacks (do Discord privado para issues públicas no GitHub com diagnósticos no Supabase) precisa estar plenamente refletida e transparente na Política de Privacidade do aplicativo móvel.

## What Changes

- **Dimensionamento Dinâmico do Bottom Sheet**: Cálculo adaptativo do parâmetro `feedbackSheetHeight` no `BetterFeedback` (`main.dart`), alocando uma fração calculada para ~210–220 dp de altura fixa (clamp entre 0.22 e 0.45). Isso garante que o formulário completo caiba perfeitamente sem nenhuma rolagem interna, maximizando o espaço em tela (~75% livre) para desenho e marcação na captura de tela (*screenshot*).
- **Layout Compacto do Formulário**:
  - Redução visual do `SegmentedButton` com `VisualDensity.compact` e ícones de 16 px.
  - Redução de espaçamentos verticais e preenchimentos internos (*padding*) do campo descritivo.
  - Botão de envio com altura reduzida para 42 dp.
  - Substituição da caixa de aviso por uma linha única e direta sem jargão: `"Feedback público. Nenhum dado pessoal é exposto."`, escalada via `FittedBox` para manter legibilidade sem quebra de linha mesmo em telas de 320–360 dp de largura.
- **Atualização da Política de Privacidade**:
  - Adição de seção explícita sobre o envio de feedbacks na `politica-de-privacidade.md`, esclarecendo a visibilidade pública dos relatos e marcações no GitHub e a guarda de logs diagnósticos técnicos no Supabase.
  - Atualização dos serviços de terceiros e recomputação do hash de termos legais em `legal_version.g.dart` via ferramenta oficial do projeto.

## Capabilities

### Modified Capabilities

- `in-app-feedback-categorizacao`: Atualiza a especificação de interface para exigir dimensionamento adaptativo sem rolagem, compactação de componentes visuais, novo texto simplificado de transparência em linha única e conformidade com a Política de Privacidade.

## Impact

- **Código Afetado**:
  - `lib/widgets/feedback/construtor_feedback_usuario.dart`: Adaptação do layout para máxima compacidade e novo aviso.
  - `lib/main.dart`: Cálculo dinâmico do `feedbackSheetHeight` no tema do `BetterFeedback`.
  - `frontend/legal/repo/public/docs/politica-de-privacidade.md`: Nova seção e inclusão de GitHub e Supabase.
  - `lib/core/legal/legal_version.g.dart`: Novo hash de versão jurídica gerado.
  - `test/widgets/feedback/construtor_feedback_usuario_test.dart`: Testes de widget atualizados para os novos tamanhos e strings.
  - Testes de integridade jurídica existentes.
