## 1. Configurações de Plataforma e Dependências

- [x] 1.1 Adicionar a dependência `app_links` ao `pubspec.yaml` do frontend e verificar resolução limpa via `flutter pub get`.
- [x] 1.2 Configurar o `AndroidManifest.xml` com o `intent-filter` de `autoVerify="true"` para o host `app.arestaclimb.com` e verificar a sintaxe do manifesto.
- [x] 1.3 Configurar o `Runner.entitlements` do iOS com a entrada `applinks:app.arestaclimb.com` e verificar a integridade do plist.

## 2. Roteador e Parser de Slugs (TDD)

- [x] 2.1 Criar testes unitários para a função utilitária de geração e comparação de slugs (`slugify`) em `test/utils/slug_utils_test.dart` e verificar a falha inicial (RED).
- [x] 2.2 Implementar a função `slugify` em `lib/utils/slug_utils.dart` com remoção de diacríticos e caracteres especiais, verificando aprovação total dos testes (GREEN).
- [x] 2.3 Criar testes unitários para o analisador de URLs (`DeepLinkRouteParser`) cobrindo rotas de 1 a 4 níveis (`/:pico`, `/:pico/:setor`, `/:pico/:grupo/:setor`, `/:pico/:setor/:via`, `/:pico/:grupo/:setor/:via`) e verificar falha inicial (RED).
- [x] 2.4 Implementar o `DeepLinkRouteParser` em `lib/navigation/deep_link_route_parser.dart`, verificando aprovação total dos testes unitários (GREEN).

## 3. Resolução de Dados e Árvore de Navegação (TDD)

- [x] 3.1 Criar testes unitários para o despachante de navegação profunda (`DeepLinkNavigatorService`) validando a montagem da árvore de linhagem (`HomeNode -> PicoNode -> [GrupoNode] -> SetorNode -> [ViaNode]`) e verificar falha inicial (RED).
- [x] 3.2 Implementar a resolução e reconstrução de linhagem no `DeepLinkNavigatorService` em `lib/navigation/deep_link_navigator_service.dart`, verificando aprovação dos testes com preservação do botão voltar (GREEN).
- [x] 3.3 Criar testes unitários cobrindo cenários de dados (pico baixado em cache local, pico não baixado com streaming online via `ServicoCroquiOnline`, e falha com aviso amigável quando offline) e verificar falha inicial (RED).
- [x] 3.4 Implementar o suporte a carregamento online sob demanda e tratamento gracioso de offline no `DeepLinkNavigatorService`, verificando aprovação total dos testes (GREEN).

## 4. Integração no Ciclo de Vida e Leitor QR In-App

- [x] 4.1 Criar testes de widget simulando recebimento de links externos em Cold Start e Warm Start via stream mockado de `app_links` e verificar falha inicial (RED).
- [x] 4.2 Integrar a escuta de deep links no `MyApp` / `TreeNavigationWrapper` em `lib/main.dart`, tratando eventos recebidos com o despachante e verificando aprovação dos testes de widget (GREEN).
- [x] 4.3 Adicionar atalho de escaneamento de QR Code na barra de busca de `lib/pages/browse.dart` conectando a leitura de câmera ao `DeepLinkNavigatorService`, verificando comportamento via teste de widget.

## 5. Infraestrutura Web e Gerador de QR Codes (`arestaclimb.com`)

- [x] 5.1 Criar os arquivos de verificação de associação `.well-known/assetlinks.json` e `.well-known/apple-app-site-association` no repositório `arestaclimb.com` e verificar integridade dos formatos JSON.
- [x] 5.2 Implementar página de fallback web em `arestaclimb.com` para o subdomínio `app.arestaclimb.com`, apresentando cartão informativo do setor e links para App Store e Google Play, verificando via testes em `vitest`.
- [x] 5.3 Criar script de automação para geração de QR Codes vetoriais (SVG) e em alta resolução (PNG) para placas físicas de setores e vias a partir dos croquis compilados, verificando execução e geração de arquivo de teste.
