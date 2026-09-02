## Why

O fluxo atual de sincronização e modo experimental foi concebido com foco primário em downloads sob demanda para produção, o que gera atrito na experiência de desenvolvimento (Live Preview):
1. **Fricção pós-conexão**: Ao conectar ao editor desktop (via QR Code ou código), o usuário permanece na tela de configurações e precisa navegar manualmente até o catálogo para baixar o croqui.
2. **Poluição visual e bloqueio no Hot Reload**: A cada atualização no modo experimental ou em segundo plano, surgem SnackBars informando sobre a atualização, interrompendo a visualização contínua.
3. **Falta de saída rápida do modo experimental**: Para retornar à biblioteca oficial de produção, o usuário precisa navegar profundamente até a tela de configurações.

Esta mudança moderniza a experiência tornando o Hot Reload instantâneo, silencioso e fluido, com auto-download imediato pós-conexão, navegação direta para o croqui e botão de desconexão rápida no banner global, seguindo rigorosamente os princípios de desenvolvimento do repositório (PRINCIPIOS.md): desenvolvimento orientado a testes (TDD), prioridade para testes de widget, componentes modulares e independentes, nomenclatura e documentação integralmente em português brasileiro e 100% de cobertura de testes.

## What Changes

- **Auto-Download & Navegação Imediata pós-pareamento**:
  - Ao conectar ao editor no modo experimental, o aplicativo baixa imediatamente o índice e o pacote binário do croqui em background.
  - Se o índice contiver 1 único croqui (caso padrão), o app navega e abre diretamente a tela do Pico (PicoNode), já renderizada com os dados atualizados.
  - Se contiver múltiplos croquis, navega para a aba de navegação/exploração (BrowseNode).
- **Hot Reload Reativo e Não-Intrusivo**:
  - No **Modo Experimental**: Elimina SnackBars/diálogos textuais a cada recarga. O aplicativo aplica a atualização silenciosamente em tela, preservando a posição de rolagem (scroll), e dispara uma animação de pulso/flash luminoso sutil no banner superior para confirmar o recebimento do frame.
  - Na **Produção**: O app aplica a atualização em memória/tela imediatamente e exibe uma notificação toast discreta informando que o croqui foi atualizado para a versão mais recente.
- **Componente Modular de Banner com Desconexão Rápida**:
  - Extrai o banner global em um widget independente e testável (BannerModoExperimental) com botão de ação rápida [ Sair ✕ ], permitindo limpar os dados temporários e voltar à biblioteca oficial com 1 toque a partir de qualquer tela.

## Capabilities

### New Capabilities
- hot-reload-experiencia-usuario: Especifica o comportamento de auto-download pós-conexão, reatividade visual sem interrupção (pulso luminoso no banner em modo experimental vs toast discreto em produção), componente modular de banner e controle de saída rápida no banner global.

### Modified Capabilities
- data-sync-feedback: Ajusta os requisitos de feedback de sincronização para diferenciar modo experimental (silencioso com flash no banner) de produção (hot-reload transparente com toast discreto).

## Impact

- **Código Afetado**:
  - rontend/lib/widgets/banner_modo_experimental.dart (Novo componente independente e modular).
  - rontend/lib/main.dart (Integração do banner global e feedback contextual de sync).
  - rontend/lib/services/editor_croqui.dart (Eventos de live reload e notificador reativo de pulso).
  - rontend/lib/view_functions/settings_functions.dart (Fluxo pós-conexão com auto-download e navegação inteligente).
  - rontend/lib/services/http/sync_service.dart (Callbacks e status de sincronização silenciosa).
- **APIs & Dependências**: Nenhuma nova dependência externa necessária.
- **Quebras**: Nenhuma quebra de API pública ou formato de dados (totalmente retrocompatível).
