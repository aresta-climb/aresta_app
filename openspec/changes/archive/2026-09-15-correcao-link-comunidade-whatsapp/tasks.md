## 1. Firebase Remote Config no Aplicativo (`aresta_app`)

- [x] 1.1 Escrever testes unitários em `frontend/test/services/firebase/remote_config_service_test.dart` cobrindo o valor padrão da chave `whatsapp_community_url` e o getter tipado `whatsappCommunityUrl`
- [x] 1.2 Implementar a chave `whatsapp_community_url` com o valor padrão `https://chat.whatsapp.com/JmxWeLSmGTT66AREtrKyjA` e o getter `whatsappCommunityUrl` em `frontend/lib/services/firebase/remote_config_service.dart`, verificando a passagem dos testes

## 2. Consumo Dinâmico na Tela de Comunidade (`aresta_app`)

- [x] 2.1 Atualizar os testes de widget em `frontend/test/pages/comunidade_test.dart` para validar o lançamento da URL do WhatsApp obtida do `RemoteConfigService`
- [x] 2.2 Refatorar o widget em `frontend/lib/pages/comunidade.dart` para consumir `RemoteConfigService.instance.whatsappCommunityUrl` e manter o modo `LaunchMode.externalApplication`, verificando aprovação dos testes de widget com 100% de cobertura

## 3. Redirecionador Web e Correção no Site (`arestaclimb.com`)

- [x] 3.1 Adicionar a regra de redirecionamento HTTP 302 temporário de `/comunidade` para `https://chat.whatsapp.com/JmxWeLSmGTT66AREtrKyjA` no arquivo `public/_redirects` de `arestaclimb.com`
- [x] 3.2 Criar página de fallback e desenvolvimento `comunidade.html` e registrar a rota no `vite.config.js` de `arestaclimb.com`
- [x] 3.3 Atualizar o link de convite do WhatsApp para o endereço oficial em `public/docs/contato.md` de `arestaclimb.com` (e espelhar no repositório de documentos legais do app `frontend/legal/repo/public/docs/contato.md`)
- [x] 3.4 Escrever e atualizar testes no repositório `arestaclimb.com` (em `src/domStructure.test.js`) validando a rota `/comunidade` e o link correto em `contato.md`, garantindo passagem com `npm test`

## 4. Validação Integrada e Cobertura

- [x] 4.1 Executar a suíte de testes do Flutter (`flutter test`) em `aresta_app/frontend` assegurando 100% de aprovação e integridade de cobertura
- [x] 4.2 Executar a suíte de testes do site (`npm test`) em `arestaclimb.com` assegurando 100% de aprovação e cobertura completa
