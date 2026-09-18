# Proposta: QR Code e Deep Linking para Setores, Vias e Picos

## Why

Escaladores no campo de escalada (rocha) frequentemente encontram placas físicas ou recebem links de setores específicos compartilhados pela comunidade. Atualmente, o aplicativo não possui suporte a Universal Links e App Links que permitam abrir diretamente a página de um setor, grupo ou via a partir de um QR Code ou URL no formato `app.arestaclimb.com/{pico}/{setor}`, exigindo busca manual na lista de croquis.

## What Changes

- **Suporte a Deep Links Nativos (App Links & Universal Links)**: O aplicativo passa a registrar e tratar links do domínio `app.arestaclimb.com` tanto em inicialização a frio (*Cold Start*) quanto com app em segundo plano (*Warm Start*).
- **Roteador Hierárquico de Slugs**: Implementação de um resolvedor que analisa URLs de até 4 níveis de profundidade:
  - `/:pico`
  - `/:pico/:setor_ou_grupo`
  - `/:pico/:grupo/:setor` ou `/:pico/:setor/:via`
  - `/:pico/:grupo/:setor/:via`
- **Reconstrução Declarativa da Pilha de Navegação**: Ao abrir um setor ou via diretamente via deep link, a árvore de navegação (`TreeNavigationController`) constrói a linhagem ascendente completa (`HomeNode -> PicoNode -> [GrupoNode] -> SetorNode -> [ViaNode]`), garantindo que o botão "Voltar" funcione naturalmente.
- **Resolução Automática Online/Offline**: Se o pico já estiver baixado no dispositivo, o setor é aberto instantaneamente offline. Se não estiver baixado mas houver conectividade, o croqui é carregado sob demanda via sessão online existente.
- **Leitor de QR Code In-App Integrado**: Adição de atalho para leitura de QR Code diretamente na interface de exploração do app (reutilizando a infraestrutura do `mobile_scanner`), permitindo apontar a câmera para plaquinhas sem sair do aplicativo.
- **Infraestrutura Web de Validação e Fallback (`app.arestaclimb.com`)**:
  - Arquivos de associação `.well-known/assetlinks.json` e `.well-known/apple-app-site-association`.
  - Página de fallback para usuários que abrirem o link sem o aplicativo instalado, exibindo o contexto do setor e botões para baixar na App Store e Google Play.

## Capabilities

### New Capabilities
- `qr-deep-linking`: Captura de App Links / Universal Links em `app.arestaclimb.com`, parsing hierárquico de slugs (pico, grupo, setor, via), resolução de dados com suporte a cache/sessão online e leitor QR in-app.

### Modified Capabilities
- `navigation`: Reconstrução de linhagem de nós na árvore de rotas (`TreeNavigationController`) a partir de alvos profundos injetados externamente por deep links.

## Impact

- **Código Flutter**: `frontend/lib/navigation/`, `frontend/lib/services/`, novo serviço gerenciador de deep links e integração no `main.dart`.
- **Configurações Nativas**: `AndroidManifest.xml` (intent-filter autoVerify para `app.arestaclimb.com`) e `Runner.entitlements` (`applinks:app.arestaclimb.com`).
- **Dependências Flutter**: Inclusão de pacote padronizado para captura de links (`app_links`).
- **Repositório Web (`arestaclimb.com`)**: Configuração dos endpoints `.well-known` e rota de fallback para o subdomínio `app.arestaclimb.com`.
