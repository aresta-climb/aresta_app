# Módulo de Feedback Visual — Aresta Climb

Este diretório contém os componentes de interface dedicados à captura e formulação de sugestões e relatos de problemas pelos usuários no aplicativo Aresta.

---

## Componentes

### `CustomStringFeedback` (`construtor_feedback_usuario.dart`)
Widget de formulário exibido na folha inferior durante o fluxo de anotação e envio de feedback com o pacote `better_feedback`.

#### Funcionalidades Principais:
1. **Identificação e Abertura**:
   - Acionado universalmente via `buildFeedbackButton`, exibindo o ícone Material `Icons.warning_amber_rounded` (alerta com cantos arredondados).
2. **Categorização Contextual com `SegmentedButton`**:
   - Quando o usuário está visualizando um croqui (`cragId != null`), o seletor `SegmentedButton<TipoFeedback>` é renderizado com as opções:
     - **"Sobre o Croqui"** (`TipoFeedback.croqui`)
     - **"Sobre o App"** (`TipoFeedback.aplicativo`)
   - O seletor inicia sem pré-seleção obrigando a escolha deliberada.
   - O botão de envio permanece desabilitado até que uma categoria seja selecionada e uma descrição textual não vazia seja digitada.
3. **Otimização para Telas Neutras**:
   - Em telas sem croqui ativo (Home, Configurações, Termos de Uso, Comunidade), o `SegmentedButton` é omitido para economia de espaço vertical, assumindo automaticamente a categoria `app`.
4. **Transparência e Consentimento Comunitário**:
   - Exibe rodapé informativo comunicando que o relato e o screenshot serão registrados publicamente no repositório GitHub `aresta-climb/aresta_db`, assegurando que nenhum dado pessoal ou de dispositivo é exposto publicamente.
5. **Integração com Backend e Diagnóstico Seguro**:
   - Os dados técnicos sensíveis (modelo de aparelho, identificador de instalação, etc.) são enviados via formulário multipart com `X-Firebase-AppCheck` para a Edge Function `app-feedback` no Supabase, que cria a issue pública no GitHub e preserva os diagnósticos confidenciais na tabela restrita `feedback_diagnosticos` (RLS) com link de auditoria para o Supabase Dashboard.
