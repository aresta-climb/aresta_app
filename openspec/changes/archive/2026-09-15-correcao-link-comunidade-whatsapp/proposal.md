## Why

O link de convite para o grupo oficial da comunidade do WhatsApp atualmente configurado na tela de Comunidade do aplicativo (`frontend/lib/pages/comunidade.dart`) e na página de contato do site (`arestaclimb.com/public/docs/contato.md`) está desatualizado (`Ip28rjQj4YbHgPgtN5Arcv`). O link correto e oficial é `https://chat.whatsapp.com/JmxWeLSmGTT66AREtrKyjA`.

Além da correção pontual do link, manter o endereço do WhatsApp estático no código do aplicativo cria fragilidade operacional: se o link do grupo for revogado no futuro (por controle de spam ou alteração de comunidade), os usuários ficam impossibilitados de ingressar sem que um novo deploy do app seja publicado na Apple App Store e no Google Play. Ao mesmo tempo, para divulgação externa (redes sociais, stickers e cartazes nos picos), é fundamental contar com um atalho limpo e memorável sob o domínio próprio (`arestaclimb.com/comunidade`).

## What Changes

- **Aplicativo (`aresta_app`)**:
  - Integração do link da comunidade ao `RemoteConfigService` (`whatsapp_community_url`), garantindo fallback local imediato offline para `https://chat.whatsapp.com/JmxWeLSmGTT66AREtrKyjA`.
  - Atualização do card "GRUPO DO WHATSAPP" em `frontend/lib/pages/comunidade.dart` para consumir a URL provida pelo `RemoteConfigService`.
  - Disparo nativo via `LaunchMode.externalApplication`, preservando a abertura direta do app do WhatsApp sem fricção de navegador intermediário.
  - Atualização e expansão da suíte de testes unitários e de widget com 100% de cobertura.

- **Site Oficial (`arestaclimb.com`)**:
  - Criação da regra de redirecionamento HTTP 302 temporário para `/comunidade` em `public/_redirects` apontando para `https://chat.whatsapp.com/JmxWeLSmGTT66AREtrKyjA`.
  - Adição de página de contingência `comunidade.html` para ambiente de desenvolvimento local e fallbacks web.
  - Correção do link na documentação pública em `public/docs/contato.md`.
  - Atualização da suíte de testes do site (`vitest`).

## Capabilities

### New Capabilities
- `comunidade-links-externos`: Gerenciamento dinâmico de links de comunidade (WhatsApp) e canais externos via Firebase Remote Config com resiliência offline e redirecionamento web oficial.

### Modified Capabilities

## Impact

- **Código Afetado no App**: `frontend/lib/services/firebase/remote_config_service.dart`, `frontend/lib/pages/comunidade.dart` e seus respectivos testes em `frontend/test/`.
- **Código Afetado no Site**: `public/_redirects`, `comunidade.html`, `public/docs/contato.md`, `vite.config.js` e testes em `src/`.
- **Dependências / APIs**: Utiliza a infraestrutura já existente de `FirebaseRemoteConfig` no Flutter e regras nativas do Cloudflare Pages / Vite no site.
- **Ruptura**: Nenhuma alteração com quebra de compatibilidade (Non-breaking).
