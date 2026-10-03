# Tarefas de Implementação: Categorização de Feedback In-App e GitHub Issues

## 1. Atualização Visual do Ícone de Feedback (TDD)

- [ ] 1.1 Atualizar os testes de widget existentes (`common_functions_test.dart`, `mapa_interativo_test.dart`, `terms_of_use_test.dart`, `offline_markdown_test.dart`, `modal_confirmacao_saida_test.dart`) para esperar `Icons.warning_amber_rounded` e verificar que falham inicialmente (Red).
- [ ] 1.2 Substituir `Icons.bug_report` por `Icons.warning_amber_rounded` em `buildFeedbackButton` (`frontend/lib/view/function_library/common_functions.dart`) e verificar aprovação de todos os testes visuais (Green).

## 2. Modelo de Dados e Enfileiramento de Feedback (TDD)

- [ ] 2.1 Criar enum/modelo fortemente tipado para a categoria de feedback e escrever testes unitários para serialização/desserialização de `tipoFeedback` em `test/data/models/feedback_metadata_test.dart`.
- [ ] 2.2 Implementar suporte ao campo `tipoFeedback` em `FeedbackMetadata` (`frontend/lib/data/models/feedback_metadata.dart`) e na persistência em disco do `FeedbackQueueService` (`frontend/lib/services/feedback/feedback_queue_service.dart`).
- [ ] 2.3 Atualizar `SubmitFeedbackUseCase` (`frontend/lib/application_managers/feedback/submit_feedback_usecase.dart`) para extrair a categoria dos extras de `UserFeedback` e repassá-la ao `FeedbackMetadata`, verificando aprovação dos testes em `test/application_managers/feedback/submit_feedback_usecase_test.dart`.

## 3. Interface do Formulário com SegmentedButton e Consentimento (Widget TDD)

- [ ] 3.1 Escrever testes de widget em `test/widgets/feedback/custom_feedback_builder_test.dart` cobrindo:
  - Exibição do título "Sobre o que é a sugestão?".
  - Exibição do `SegmentedButton` com as opções "Sobre o Croqui" e "Sobre o App" sem seleção prévia quando há croqui ativo.
  - Bloqueio do botão de envio até que uma categoria seja selecionada e a descrição seja preenchida.
  - Ocultação do `SegmentedButton` em telas neutras (sem croqui ativo) com envio direto baseado no texto.
  - Renderização do aviso amigável de publicação comunitária no GitHub sem dados sensíveis.
- [ ] 3.2 Implementar a nova interface no widget `CustomStringFeedback` (`frontend/lib/widgets/feedback/custom_feedback_builder.dart`) com `SegmentedButton`, detecção contextual do croqui, aviso amigável e despacho com `extras`, verificando aprovação total dos testes (Green).

## 4. Backend Supabase: Tabela Restrita e GitHub Issues (TDD)

- [ ] 4.1 Criar script de migração SQL para a tabela `feedback_diagnosticos` no Supabase com Row Level Security (RLS) habilitado para leitura exclusiva de membros autorizados.
- [ ] 4.2 Escrever testes unitários em Deno/TypeScript para a Edge Function `app-feedback` em `aresta_backend/supabase/functions/app-feedback/handler_test.ts` cobrindo o envio para o GitHub no repositório `aresta-climb/aresta_db`, aplicação de labels (`feedback:croqui/app`, `so:android/ios`, `pico:<id>`) e persistência segura no Supabase.
- [ ] 4.3 Refatorar a Edge Function `app-feedback` (`aresta_backend/supabase/functions/app-feedback/handler.ts`) substituindo o despacho ao Discord pela criação da issue pública no GitHub e persistência restrita no Supabase Postgres com link para o Supabase Dashboard.

## 5. Validação Integrada e Documentação

- [ ] 5.1 Executar a suíte completa de testes no frontend (`flutter test`) garantindo 100% de cobertura nos componentes alterados e ausência de regressões.
- [ ] 5.2 Atualizar as especificações centrais e o `README.md` do módulo de feedback detalhando o fluxo de transparência comunitária via GitHub Issues e a proteção de dados sensíveis no Supabase.
