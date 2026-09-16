## 1. Testes de Widget em Primeiro Lugar (TDD)

- [ ] 1.1 Adicionar testes em `frontend/test/pages/mapas_carrossel_test.dart` verificando que, ao carregar a `MapasCarrosselPage` com múltiplos mapas, o download de todas as páginas para o cache em disco é disparado em segundo plano
- [ ] 1.2 Adicionar testes em `frontend/test/pages/mapas_carrossel_test.dart` verificando a reutilização de `ImageProvider`s resolvidos via `imageProviderOverride` nas páginas seguintes
- [ ] 1.3 Adicionar testes de resiliência cobrindo descarte do widget (`dispose`) e falhas de rede sem interromper a visualização do mapa ativo

## 2. Implementação do Pré-download em `MapasCarrosselPage`

- [ ] 2.1 Implementar rotina `_preCarregarImagensNoDisco` em `frontend/lib/pages/mapas_carrossel.dart` utilizando `WidgetsBinding.instance.addPostFrameCallback` e `ProvedorImagemAresta.resolver` para todas as páginas da lista
- [ ] 2.2 Adicionar mapa `_provedoresResolvidos` para armazenar provedores resolvidos e repassá-los para `MapaInterativoPage` através de `imageProviderOverride`
- [ ] 2.3 Tratar graciosamente exceções e assegurar verificação de `mounted`

## 3. Validação e Cobertura

- [ ] 3.1 Executar a suíte de testes de `frontend/test/pages/mapas_carrossel_test.dart` garantindo 100% de aprovação e cobertura
- [ ] 3.2 Executar a suíte geral do Flutter (`flutter test`) confirmando ausência de regressões

