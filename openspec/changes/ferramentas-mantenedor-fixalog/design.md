## Context

O Aresta Climb possui configurações na página `SettingsPage` (`frontend/lib/pages/settings.dart`) construídas com funções auxiliares em `settings_functions.dart`. A persistência de preferências de usuário é realizada via `shared_preferences`, utilizando o padrão de controladores reativos baseados em `ValueNotifier` (como visto no `ThemeController`).

A exibição de detalhes de uma escalada ocorre na `ViaPage` (`frontend/lib/pages/via.dart` e `frontend/lib/view_functions/via_functions.dart`), onde informações de histórico (conquistadores, data de abertura e data de última manutenção) são agrupadas em um card específico.

O aplicativo já conta com o utilitário `slugify` em `frontend/lib/utils/slug_utils.dart` para normalização de nomes em rotas e deep links, além do pacote `url_launcher` para lançamento de links externos.

Para mais detalhes sobre motivação e escopo, veja `proposal.md` e `specs/ferramentas-mantenedor-fixalog/spec.md`.

## Goals / Non-Goals

**Goals:**
- Implementar `ConfiguracaoMantenedorController` como singleton leve com `ValueNotifier<bool>` e persistência via `shared_preferences` com chave `'ferramentas_mantenedor_ativa'`.
- Adicionar o card de configuração "FERRAMENTAS PARA MANTENEDORES" na tela de Configurações, respeitando o tema visual e a paleta de cores existente (`context.colors`).
- Criar a função utilitária `gerarLinkFixalog({required String cragId, Grupo? grupo, Setor? setor, required Escalada escalada})` para construir a URL no formato `https://fixalog.arestaclimb.com/<pico_id>/[<grupo_slug>/]<setor_slug>/<via_slug>`.
- Integrar a ação "MANUTENIR NO FIXALOG" à seção "Histórico & Conquista" da `ViaPage` para modalidades de escalada relevantes (vias esportivas, vias móveis, multienfiadas e highlines).
- Garantir que a ação seja exibida mesmo em vias sem histórico prévio cadastrado, caso o modo mantenedor esteja ativado.
- Registrar telemetria da ação via `TelemetryService.instance.logAcaoEscalada` e exibir `SnackBar` em caso de erro na abertura do link.
- Manter 100% de cobertura de testes unitários e de widget, com TDD estrito e código integralmente em português brasileiro (conforme `AGENTS.md`).

**Non-Goals:**
- Alterar o esquema Protobuf ou estruturas de dados de croqui (`croqui.proto`).
- Integrar diretamente com APIs privadas do Fixalog via chamadas HTTP/REST.
- Incorporar visualização web (WebView) do Fixalog dentro do aplicativo Aresta Climb.

## Decisions

### 1. Controlador Reativo Singleton com `ValueNotifier<bool>`
- **Decisão**: Criar `ConfiguracaoMantenedorController` em `frontend/lib/services/configuracao_mantenedor_controller.dart` seguindo a mesma estrutura do `ThemeController`.
- **Racional**: Simplicidade e desacoplamento (Princípio VI). Não introduz dependências complexas de injeção de dependência e permite reatividade instantânea na UI via `ValueListenableBuilder`.
- **Alternativas consideradas**:
  - `InheritedWidget` na raiz: Exigiria rebuild de árvores maiores e adicionaria boilerplate desnecessário.
  - Leitura assíncrona direta do `SharedPreferences` na tela: Causaria "flicker" e atraso visual ao navegar entre telas.

### 2. Deep Links no domínio `fixalog.arestaclimb.com` via `slug_utils`
- **Decisão**: Padronizar as URLs no subdomínio `fixalog.arestaclimb.com` utilizando a mesma regra de slugs já aplicada nos deep links do Aresta Climb (`https://fixalog.arestaclimb.com/<picoId>/<setorSlug>/<viaSlug>` ou com `<grupoSlug>`).
- **Racional**: Compatibilidade direta com Android App Links e iOS Universal Links. Se o aplicativo Fixalog estiver instalado com o intent associado, o SO o abre diretamente. Caso contrário, o navegador abre a URL web institucional sem erros silenciosos.
- **Alternativas consideradas**:
  - Custom URI Scheme (ex: `fixalog://route/...`): Falharia silenciosamente ou causaria exceções de "No Activity found" em dispositivos sem o app instalado.

### 3. Integração na Seção de Histórico e Conquista (Opção A)
- **Decisão**: Posicionar o botão "MANUTENIR NO FIXALOG" no bloco "Histórico & Conquista" de cada modalidade em `via_functions.dart`. Caso a via não possua dados históricos cadastrados, o container de histórico é renderizado exibindo o botão quando o modo mantenedor estiver ativo.
- **Racional**: Proximidade contextual direta com as informações de conquista e data da última manutenção já existentes na via.
- **Alternativas consideradas**:
  - Botão genérico no rodapé junto a Pix/Vídeo: Ficaria distante do contexto de manutenção de proteções.
  - Ícone na AppBar: Poluiria o cabeçalho já concorrido da página da via.

### 4. Abertura Externa com `LaunchMode.externalApplication`
- **Decisão**: Disparar a URL usando `launchUrl(uri, mode: LaunchMode.externalApplication)`.
- **Racional**: Garante que o sistema operacional delegue a abertura para o aplicativo do Fixalog (se instalado) ou para o navegador padrão, sem prender a navegação dentro da webview interna do Aresta.
- **Alternativas consideradas**:
  - `LaunchMode.inAppWebView`: Bloquearia o usuário dentro de uma visualização web empobrecida e impediria o app nativo do Fixalog de capturar o link.

## Risks / Trade-offs

- **[Risco: Aplicativo do Fixalog não instalado no aparelho]** → **Mitigação**: O uso de HTTPS padrão no domínio `fixalog.arestaclimb.com` direciona o usuário ao navegador, onde a página de destino pode apresentar instruções de download do Fixalog.
- **[Risco: Falha no `launchUrl` por restrições do sistema operacional]** → **Mitigação**: Tratamento em bloco `try/catch` com verificação de `context.mounted` e exibição de `SnackBar` amigável ao usuário.
- **[Risco: Caracteres especiais ou divergências de nomenclatura de setores e vias]** → **Mitigação**: Uso estrito da função `slugify` já testada e validada no módulo `slug_utils.dart`.
