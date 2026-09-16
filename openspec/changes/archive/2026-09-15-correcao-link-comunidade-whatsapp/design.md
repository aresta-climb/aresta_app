## Context

Atualmente o aplicativo `aresta_app` armazena a URL do grupo do WhatsApp estaticamente como uma constante no widget `comunidade.dart`, apontando para um link defasado (`Ip28rjQj4YbHgPgtN5Arcv`). O projeto já dispõe do serviço `RemoteConfigService` (`frontend/lib/services/firebase/remote_config_service.dart`), que orquestra defaults locais imediatos, busca assíncrona em segundo plano e notificação reativa.

No site `arestaclimb.com`, a página inicial já referencia o novo link oficial (`https://chat.whatsapp.com/JmxWeLSmGTT66AREtrKyjA`), mas a página de contato (`public/docs/contato.md`) ainda contém o link antigo, e não existe uma rota encurtada/memorável como `/comunidade`.

Para mais detalhes da motivação, veja `proposal.md`.

## Goals / Non-Goals

**Goals:**
- Corrigir a URL da comunidade do WhatsApp em todos os pontos do ecossistema para `https://chat.whatsapp.com/JmxWeLSmGTT66AREtrKyjA`.
- Desacoplar o aplicativo de links estáticos no código através do `RemoteConfigService`, permitindo atualizações remotas de emergência via painel do Firebase sem necessidade de nova versão nas lojas.
- Assegurar abertura nativa direta do aplicativo do WhatsApp sem intermediários visuais nos dispositivos móveis ao tocar no botão dentro do app.
- Prover um link curto sob domínio próprio (`arestaclimb.com/comunidade`) com redirecionamento temporário HTTP 302, ideal para marketing, cartazes físicos e redes sociais.
- Preservar 100% de cobertura de testes unitários e de widget no app e no site.

**Non-Goals:**
- Implementar esquema de URL customizado não-oficial (`whatsapp://chat?code=...`) devido a inconsistências de compatibilidade e exigências de whitelist restritivas no iOS.
- Forçar os usuários do aplicativo móvel a passarem pelo navegador web para ingressar na comunidade.

## Decisions

### 1. Estratégia Híbrida: Remote Config no App vs Link do Site no App
- **Decisão**: O aplicativo Flutter continuará disparando a URL direta do WhatsApp (`chat.whatsapp.com/...`) resolvida via `RemoteConfigService`, enquanto o site oficial fornecerá o redirecionador `/comunidade`.
- **Racional**:
  - Tanto o iOS (Safari) quanto o Android (Chrome) restringem a ativação de *Universal Links* e *App Links* a partir de redirecionamentos automáticos HTTP (301/302). Se o app abrisse `arestaclimb.com/comunidade`, o sistema operacional abriria o navegador, carregaria a página intermediária web do WhatsApp e exigiria que o usuário clicasse manualmente em "Entrar na conversa".
  - Abrindo o link direto do WhatsApp com `LaunchMode.externalApplication`, o SO reconhece imediatamente o app do WhatsApp instalado e exibe a tela de confirmação de entrada nativa instantaneamente (0 etapas intermediárias).
  - O `RemoteConfigService` garante a flexibilidade operacional: qualquer alteração de link é aplicada remotamente via Firebase Console.
- **Alternativas consideradas**:
  - *Fazer o app abrir `arestaclimb.com/comunidade`:* Rejeitado devido à fricção visual e toque extra exigido na tela do navegador móvel.
  - *Manter link estático no código:* Rejeitado pela impossibilidade de correção rápida em caso de revogação do grupo do WhatsApp.

### 2. Uso de Redirecionamento HTTP 302 (Temporário) em `_redirects`
- **Decisão**: Configurar `/comunidade https://chat.whatsapp.com/JmxWeLSmGTT66AREtrKyjA 302` no `public/_redirects` do site Cloudflare Pages.
- **Racional**: Um redirecionamento 301 (Permanente) é armazenado em cache de forma agressiva e por tempo indeterminado pelos navegadores dos usuários e nós intermediários de CDN. Se o link do WhatsApp precisar ser alterado, usuários com cache 301 seriam direcionados para um link quebrado. O status 302 garante que novas requisições sempre consultem a rota atualizada.
- **Alternativas consideradas**:
  - *Status 301:* Rejeitado pelo risco de cache local persistente no cliente.

### 3. Fallback Local Imediato no `RemoteConfigService`
- **Decisão**: Registrar a chave `"whatsapp_community_url": "https://chat.whatsapp.com/JmxWeLSmGTT66AREtrKyjA"` no método `setDefaults` do `RemoteConfigService`.
- **Racional**: Garante o princípio de *Offline-First* do Aresta Climb: mesmo na primeira inicialização sem internet ou em picos de escalada sem sinal de celular, o aplicativo sempre terá uma URL válida e funcional.

## Risks / Trade-offs

- **[Risco] Dispositivo sem WhatsApp instalado**:
  - *Mitigação*: Ao disparar `chat.whatsapp.com` com `LaunchMode.externalApplication`, caso o app nativo do WhatsApp não esteja instalado, o sistema operacional abre automaticamente o navegador na página web oficial com opções para baixar o aplicativo ou entrar via WhatsApp Web.
- **[Risco] Testes que interceptavam URL hardcoded quebrarem**:
  - *Mitigação*: Atualizar as asserções em `comunidade_test.dart` e adicionar casos de teste específicos no `remote_config_service_test.dart`.

## Migration Plan

1. Implementar a chave no `RemoteConfigService` do app com testes.
2. Atualizar o widget `comunidade.dart` para consumir o serviço e ajustar seus testes de widget.
3. Configurar a regra no `public/_redirects` e criar `comunidade.html` no repositório `arestaclimb.com`.
4. Atualizar `public/docs/contato.md` no site.
5. Rodar as suítes de teste de ambos os projetos garantindo 100% de aprovação e cobertura.
