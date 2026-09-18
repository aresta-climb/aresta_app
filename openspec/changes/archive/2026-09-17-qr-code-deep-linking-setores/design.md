## Context

O aplicativo Aresta Climb utiliza uma arquitetura de navegação declarativa baseada em nós (`TreeNavigationController` e `NavNode`), onde cada tela é um nó que conhece seu nó pai. Atualmente, o aplicativo possui configurações iniciais no `AndroidManifest.xml` e `Runner.entitlements` apenas para `previa.arestaclimb.com` (modo editor), mas não possui um serviço centralizado de escuta de App Links / Universal Links nem lógica de roteamento profundo para os croquis de produção.

O site oficial está hospedado no domínio `arestaclimb.com`, gerenciado com Vite, já contendo bibliotecas de suporte a QR Code (`qrcode`, `jsqr`).

## Goals / Non-Goals

**Goals:**
- Interceptar URLs sob `app.arestaclimb.com` via Android App Links e iOS Universal Links.
- Decompor e mapear rotas de até 4 níveis: `/:pico`, `/:pico/:setor_ou_grupo`, `/:pico/:setor_ou_grupo/:sub_elemento` e `/:pico/:grupo/:setor/:via`.
- Reconstruir a árvore de ancestrais na navegação (`HomeNode -> PicoNode -> [GrupoNode] -> SetorNode -> [ViaNode]`) para preservar o botão voltar e o histórico.
- Prover carregamento sob demanda para croquis não baixados via `ServicoCroquiOnline` quando houver conexão, e feedback gracioso quando offline.
- Adicionar atalho de escaneamento de QR Code na UI de busca/exploração.
- Hospedar `.well-known/assetlinks.json` e `.well-known/apple-app-site-association` no subdomínio `app.arestaclimb.com`, com fallback amigável para download nas lojas.

**Non-Goals:**
- Deferred deep linking via SDKs proprietários (Branch, AppsFlyer): se o usuário não tiver o app instalado, a web exibe links diretos para as lojas, e na primeira abertura o app abre na Home normal.
- Suporte a esquemas personalizados complexos legados (o foco é 100% em URLs web HTTPS padronizadas).

## Decisions

### 1. Pacote `app_links` para Escuta de Deep Links
- **Decisão**: Utilizar o pacote `app_links` no Flutter em vez do legado `uni_links`.
- **Justificativa**: `app_links` é a solução moderna e ativamente mantida para Flutter 3+, tratando streams unificados de Cold Start e Warm Start no Android 12+ e iOS 14+.
- **Alternativas consideradas**: `uni_links` (descontinuado); `Navigator 2.0 RouterDelegate` puro (mais verboso e difícil de integrar cirurgicamente com o `TreeNavigationController` existente).

### 2. Subdomínio Dedicado `app.arestaclimb.com`
- **Decisão**: Isolar o deep linking no subdomínio `app.arestaclimb.com`.
- **Justificativa**: Garante que os arquivos `.well-known` sejam validados sem colidir com regras de roteamento ou páginas institucionais de `arestaclimb.com`.
- **Alternativas consideradas**: `arestaclimb.com/s/...` (mais propenso a conflitos de rota com o site Vite existente).

### 3. Normalização de Slugs Determinística
- **Decisão**: Criar a função utilitária `slugify(String texto)` para transformar nomes do Protobuf (ex: *"Grupo Estacionamento"*, *"Pé de Cabra"*) em strings comparáveis (`grupo_estacionamento`, `pe_de_cabra`).
- **Justificativa**: Remove diacríticos, pontuações e converte espaços em underlines, permitindo correspondência exata sem ambiguidades.
- **Alternativas consideradas**: Regex com fuzzy match (imprevisível e propenso a falsos positivos).

### 4. Construção de Pilha Ascendente Sintética
- **Decisão**: Ao navegar para um nó folha vindo de link externo, instanciar a cadeia de nós pais:
  `HomeNode -> PicoNode(cragId) -> GrupoNode? -> SetorNode -> ViaNode?`.
- **Justificativa**: O `TreeNavigationController` utiliza nós imutáveis encadeados por `parent`. Isso garante que o botão Voltar (`goBack()`) funcione perfeitamente sem modificações estruturais no motor de navegação.

### 5. Resolução Híbrida de Dados (Cache Local com Fallback Online)
- **Decisão**: Consultar primeiro `datasetRepo.activeDataset.value.downloadedPicos`. Se ausente, invocar `datasetRepo.servicoCroquiOnline.abrirCroquiOnline(cragId)` mantendo o usuário informado via overlay de carregamento. Se offline, disparar SnackBar informativo.
- **Justificativa**: Mantém o compromisso offline-first do Aresta Climb enquanto aproveita a infraestrutura de streaming online já implementada no app.

## Risks / Trade-offs

- **[Cache de AASA pela Apple]** → A Apple faz cache do arquivo de associação em sua CDN por várias horas.  
  *Mitigação*: Validar o endpoint `.well-known/apple-app-site-association` antes de gerar a build de release e testar no TestFlight.
- **[Acesso Offline a Picos Não Baixados]** → O usuário escaneia uma placa na rocha sem ter sinal de internet e sem ter baixado o pico previamente.  
  *Mitigação*: Tratar a ausência de dados graciosamente com aviso explícito de que o pico precisa de download com internet, sem travar nem fechar o app.
- **[Colisão de Nomes entre Grupos e Setores]** → Um grupo e um setor com nomes idênticos no mesmo pico.  
  *Mitigação*: O algoritmo inspeciona primeiro o nível de Grupos; se houver sub-rotas, desce para os setores internos.

## Migration Plan

1. Configurar o apontamento DNS de `app.arestaclimb.com` no Cloudflare.
2. Publicar os arquivos estáticos de validação (`assetlinks.json` e `apple-app-site-association`) e a página de fallback no repositório `arestaclimb.com`.
3. Implementar o serviço de deep linking e o roteador no `aresta_app/frontend` com testes automatizados.
4. Atualizar os manifestos nativos (`AndroidManifest.xml` e `Runner.entitlements`).
