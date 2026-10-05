# Design Técnico: Categorização de Feedback In-App e GitHub Issues

## Context

O sistema de feedback do Aresta App opera sob uma arquitetura de envio resiliente:
- Coleta local de contexto e integridade criptográfica ([`FeedbackMetadataCollector`](file:///c:/Renato/Devel/aresta-climb/aresta_app/frontend/lib/services/feedback/feedback_metadata_collector.dart)).
- Fila persistente em disco baseada em arquivos JSON + PNG ([`FeedbackQueueService`](file:///c:/Renato/Devel/aresta-climb/aresta_app/frontend/lib/services/feedback/feedback_queue_service.dart)).
- Despacho em segundo plano via Workmanager e cliente HTTP multipart ([`FeedbackNetworkService`](file:///c:/Renato/Devel/aresta-climb/aresta_app/frontend/lib/services/feedback/feedback_network_service.dart)).
- Validação no servidor via Firebase App Check e despacho para o Discord na Edge Function do Supabase (`aresta_backend/supabase/functions/app-feedback/handler.ts`).

Esta mudança reformula a ponta visual do usuário (ícone e categorização) e redireciona o destino do backend para GitHub Issues no repositório `aresta_db`, garantindo a segregação de dados confidenciais através do Supabase Postgres (RLS) e Supabase Dashboard.

## Goals / Non-Goals

**Goals:**
- Substituir o ícone `Icons.bug_report` por `Icons.warning_amber_rounded` de forma consistente em todo o app.
- Permitir ao usuário categorizar explicitamente a sugestão entre "Sobre o Croqui" e "Sobre o App" quando estiver visualizando um croqui.
- Omitir o seletor em telas neutras para economia de espaço vertical, assumindo "app" de forma transparente.
- Publicar os feedbacks como issues públicas no repositório GitHub `aresta-climb/aresta_db` com etiquetagem automática por labels.
- Proteger dados técnicos confidenciais (UUIDs, modelo de aparelho, telemetria) no banco Postgres do Supabase, fornecendo um link restrito na issue para inspeção pela equipe autorizada.
- Manter 100% de cobertura de testes unitários e de widget, seguindo TDD rigoroso em português.

**Non-Goals:**
- Criar um painel web customizado do zero: o Supabase Studio / Dashboard nativo já supre a necessidade de consulta autenticada para quem assinou NDA.
- Modificar o mecanismo de anotação de tela da biblioteca `better_feedback`.
- Permitir edição ou exclusão de feedbacks diretamente pelo app mobile.

## Decisions

### 1. Ícone: `Icons.warning_amber_rounded`
- **Decisão**: Utilizar `Icons.warning_amber_rounded` em `buildFeedbackButton`.
- **Justificativa**: Apresenta traço outline suave e cantos arredondados, alinhando-se à identidade visual do design system do Aresta sem o peso agressivo de um alerta sólido (`warning_rounded`).
- **Alternativas consideradas**:
  - `Icons.warning_rounded`: Descartado por ser preenchido, criando destaque excessivo e sensação de erro do sistema operacional.
  - `Icons.report_problem_outlined`: Similar, porém menos arredondado nos vértices.

### 2. Seletor de Categoria: `SegmentedButton<TipoFeedback>`
- **Decisão**: Utilizar o `SegmentedButton` do Material 3 com duas opções: `"Sobre o Croqui"` e `"Sobre o App"`.
- **Comportamento**:
  - Quando dentro de um croqui (`cragId != null`): exibição obrigatória sem pré-seleção (`selected: {}`). O botão "Enviar" só é liberado quando o usuário escolhe uma categoria e digita ao menos um caractere não-vazio.
  - Quando em tela neutra (`cragId == null`): o `SegmentedButton` não é renderizado. O formulário assume internamente `TipoFeedback.aplicativo`.
- **Justificativa**: Em smartphones, o espaço vertical é crítico ao abrir o teclado virtual; o `SegmentedButton` é horizontal, conciso e elegante. Ocultá-lo em telas neutras preserva a usabilidade.

### 3. Propagação de Dados via `extras` e `FeedbackMetadata`
- **Decisão**:
  - `CustomStringFeedback` invoca `widget.onSubmit(text, extras: {'tipo_feedback': selectedType.name})`.
  - `SubmitFeedbackUseCase` lê o mapa `feedback.extra` e alimenta o campo fortemente tipado `tipoFeedback` em `FeedbackMetadata`.
  - O JSON salvo na fila local passa a conter `'tipo_feedback': 'croqui' | 'app'`.

### 4. Criação de GitHub Issues no Repositório `aresta_db`
- **Decisão**: A Edge Function `app-feedback` utiliza um GitHub Personal Access Token (PAT fine-grained com permissão `Issues: Read & Write` no repositório `aresta-climb/aresta_db`) armazenado como secret no Supabase (`GITHUB_FEEDBACK_TOKEN`).
- **Formatação da Issue**:
  - **Título**: `[Croqui | <Nome/ID do Pico>] <Resumo do texto>` ou `[App] <Resumo do texto>`.
  - **Labels automáticas**:
    - `feedback:croqui` ou `feedback:app`
    - `so:android` ou `so:ios`
    - `pico:<cragId>` (quando aplicável)
  - **Corpo (Markdown)**:
    - Seção de descrição do usuário
    - Captura de tela com os desenhos anexada (via Supabase Storage público)
    - Versão do aplicativo e sistema operacional simplificado
    - Seção de integridade criptográfica dos arquivos locais
    - Links para download dos arquivos binários (`compilado.binarypb` e `indice.binarypb`)
    - 🔒 Seção de acesso restrito com link formatado para o Supabase Dashboard:
      `[Ver diagnóstico completo do dispositivo no Supabase](https://supabase.com/dashboard/project/{PROJECT_REF}/editor/{TABLE_ID}?filter=id%3Deq%3D{feedback_id})`

### 5. Segregação de Privacidade no Supabase Postgres
- **Decisão**: Criar a tabela `feedback_diagnosticos` no Supabase com Row Level Security (RLS) onde apenas membros autorizados possuem permissão de leitura.
- **Campos protegidos**: `feedback_id`, `app_instance_id`, `device_model`, `os_version`, `screen_size`, `connectivity`, `ip_address`, `submitted_at`, `payload_completo`.

## Risks / Trade-offs

- **[Risco] Rate limiting da API do GitHub (máximo de requisições por hora)**
  - *Mitigação*: A Edge Function já possui rate limit rigoroso por IP (5 req/min) validado pelo Firebase App Check. Além disso, tokens de GitHub para organização possuem teto de 5.000 requisições/hora, o que cobre com folga a volumetria de feedbacks do app. Em caso de 429 do GitHub, a Edge Function executa retentativa com backoff ou retorna 503 para a fila local reprocessar.
- **[Risco] Vazamento acidental de dados pessoais em screenshots públicas**
  - *Mitigação*: Exibição de aviso claro e visível no formulário antes do envio: *"Seu relato e a captura da tela serão registrados publicamente no nosso GitHub comunitário para que os mantenedores possam atuar. Nenhum dado pessoal ou de dispositivo é exposto."*
- **[Risco] Quebra de testes de widget existentes que procuram por `Icons.bug_report`**
  - *Mitigação*: Mapeamento prévio de todos os testes afetados (`common_functions_test.dart`, `mapa_interativo_test.dart`, `terms_of_use_test.dart`, `offline_markdown_test.dart`, etc.) para atualização atômica e manutenção de 100% de cobertura.

## Migration Plan

1. **Supabase**: Criar a tabela `feedback_diagnosticos` e configurar o secret `GITHUB_FEEDBACK_TOKEN` e `GITHUB_REPO` (`aresta-climb/aresta_db`).
2. **Edge Function**: Atualizar `handler.ts` com a nova lógica do GitHub e persistência restrita, deprecando o webhook do Discord.
3. **Frontend**: Implementar as mudanças no Aresta App com testes rigorosos (TDD) e efetuar o build de atualização.
