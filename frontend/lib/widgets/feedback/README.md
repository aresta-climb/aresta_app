# Feedback de Usuário (`lib/widgets/feedback/`)

Este diretório contém o formulário exibido ao acionar o relato de problemas e sugestões no aplicativo (`better_feedback`).

---

## Componente

### `CustomStringFeedback` (`construtor_feedback_usuario.dart`)
Formulário aberto pelo botão `buildFeedbackButton` (`Icons.warning_amber_rounded`):

1. **Seleção de Categoria (`SegmentedButton<TipoFeedback>`)**:
   - Quando há um croqui ativo (`cragId != null`), exibe `"Sobre o Croqui"` (`TipoFeedback.croqui`) e `"Sobre o App"` (`TipoFeedback.aplicativo`) sem opção pré-marcada.
   - Em telas sem croqui ativo (Home, Configurações, Termos de Uso, Comunidade), omite o seletor e define a categoria como `aplicativo`.
   - O botão de envio só é habilitado quando há categoria definida e texto preenchido.
2. **Aviso de Publicação e Destino dos Dados**:
   - Informa no rodapé que o texto e a captura de tela geram uma issue pública em `aresta-climb/aresta_db`.
   - Os metadados do aparelho (`FeedbackMetadata`) seguem via requisição multipart com `X-Firebase-AppCheck` para a Edge Function `app-feedback` no Supabase, que separa os dados de diagnóstico na tabela restrita `feedback_diagnosticos` (RLS).
