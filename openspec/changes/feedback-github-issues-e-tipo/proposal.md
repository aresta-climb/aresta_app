# Proposta: Categorização de Feedback In-App, Novo Ícone e Despacho via GitHub Issues

## Why

Atualmente, o sistema de envio de feedback e relato de problemas do Aresta App utiliza o ícone de "inseto" (`Icons.bug_report`), que passa uma impressão estrita de falha de software em vez de convidar sugestões de escalada e correções de croquis. Além disso, o formulário de feedback não diferencia se o relato diz respeito a uma via/croqui específico ou a uma falha do aplicativo, dificultando a triagem. Por fim, o envio era concentrado em um webhook do Discord, centralizando os relatos em conversas efêmeras; migrar para GitHub Issues públicas no repositório comunitário `aresta_db` permite que conquistadores e mantenedores locais acompanhem, discutam e resolvam melhorias de forma transparente, enquanto dados sensíveis de diagnóstico permanecem sob controle de acesso restrito no Supabase.

## What Changes

- **Novo Ícone na Barra de Navegação**: Substituição do ícone `Icons.bug_report` por `Icons.warning_amber_rounded` (moldura triangular com cantos suaves e ponto de exclamação) em todas as ocorrências do `buildFeedbackButton`.
- **Categorização Contextual no Formulário de Feedback**:
  - Título do formulário atualizado para `"Sobre o que é a sugestão?"`.
  - Quando acionado dentro do contexto de um croqui/setor/via: exibição de um `SegmentedButton` com as opções `"Sobre o Croqui"` e `"Sobre o App"`, sem pré-seleção forçada, exigindo a seleção explícita mais o preenchimento da mensagem para habilitar o envio.
  - Quando acionado em uma tela neutra (Home, Configurações, etc.): o seletor é completamente omitido da interface, adotando automaticamente a categoria `"app"` por baixo dos panos.
- **Aviso de Transparência e Privacidade**: Inclusão de mensagem amigável no rodapé do formulário explicando que a sugestão e a captura de tela serão registradas publicamente no GitHub comunitário sem expor dados pessoais ou do aparelho.
- **Migração do Discord para GitHub Issues no Repositório `aresta_db`**:
  - A Edge Function `app-feedback` do Supabase deixa de despachar payloads para o webhook do Discord e passa a criar Issues públicas na API do GitHub no repositório `aresta_db`.
  - Aplicação automática de labels: tipo (`feedback:croqui` ou `feedback:app`), sistema operacional (`so:android` ou `so:ios`) e contexto geográfico (`pico:<cragId>`).
- **Segregação Estrita de Dados Sensíveis e Painel Supabase**:
  - Dados públicos (descrição, captura de tela, versão semver do app, SO resumido, arquivos de auditoria e status de hash do croqui) são inseridos no corpo público da issue.
  - Dados sensíveis e de diagnóstico técnico (`app_instance_id`, `device_model`, resolução de tela, `os_version` detalhada, conectividade, IP de origem) são gravados em tabela restrita no Postgres do Supabase com RLS ativo.
  - A issue pública inclui um link restrito para o Supabase Dashboard (`/editor/feedback_diagnosticos?id=UUID`), acessível apenas pela equipe oficial do Aresta mediante autenticação.

## Capabilities

### New Capabilities
- `in-app-feedback-categorizacao`: Interface de feedback in-app com seletor de categoria (`SegmentedButton`), inteligência contextual de omissão em telas neutras, aviso de transparência pública e ícone `Icons.warning_amber_rounded`.

### Modified Capabilities
- `discord-feedback-security`: Redefinição do transporte e destino de feedbacks da Edge Function do Supabase, substituindo o webhook do Discord pela criação de issues públicas no GitHub (`aresta_db`) com etiquetagem automática, mantendo a atestação via Firebase App Check e isolando dados sensíveis de diagnóstico no Supabase Postgres com link restrito.

## Impact

- **Frontend Flutter**:
  - `lib/view/function_library/common_functions.dart`: troca do ícone para `Icons.warning_amber_rounded`.
  - `lib/widgets/feedback/custom_feedback_builder.dart`: refatoração para incluir `SegmentedButton`, inteligência de contexto, validação de preenchimento e aviso de privacidade.
  - `lib/application_managers/feedback/submit_feedback_usecase.dart` e `lib/data/models/feedback_metadata.dart`: suporte ao campo de categoria `tipoFeedback`.
  - Suíte de testes automatizados (`test/`): atualização dos testes que verificavam `Icons.bug_report` e adição de testes cobrindo a seleção e despacho de categorias.
- **Backend Supabase (Edge Functions)**:
  - `supabase/functions/app-feedback/handler.ts`: remoção da integração com Discord; integração com GitHub API (criação de issues com labels) e persistência de diagnósticos privados com RLS.
- **Infraestrutura / Secrets**:
  - Configuração do token de acesso do GitHub (`GITHUB_FEEDBACK_TOKEN` ou GitHub App) nos secrets do Supabase.
