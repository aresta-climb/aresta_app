## 1. Testes de Integração e Fronteira de UI em Primeiro Lugar (Princípio V)

- [ ] 1.1 Escrever teste de integração de ponta a ponta em `test/integration/cache_imagens_online_test.dart` cobrindo o fluxo do usuário em `ExplorarLocalPage`: abertura de croqui online, espera do carregamento da capa, navegação de retorno (pop) e reabertura, esperando falha inicial (Red) por disparar requisições HTTP redundantes

## 2. Motor de Cache Volátil e Integridade no ProvedorImagemAresta (TDD - Princípios I, II, IV e VI)

- [ ] 2.1 Escrever testes unitários em `test/widgets/provedor_imagem_aresta_test.dart` para validação de hash obrigatório (erro de telemetria e fallback direto para `NetworkImage` sem gravação em cache quando hash for ausente ou nulo) (Red)
- [ ] 2.2 Escrever testes unitários em `test/widgets/provedor_imagem_aresta_test.dart` para download e persistência atômica no formato `<caminho>.<hash>` em `temp_cache`, garantindo resolução instantânea sem requisição de rede em chamadas subsequentes (Red)
- [ ] 2.3 Escrever testes unitários em `test/widgets/provedor_imagem_aresta_test.dart` para expurgo automático de versões anteriores com hashes divergentes no mesmo diretório após conclusão de download (Red)
- [ ] 2.4 Escrever testes unitários em `test/widgets/provedor_imagem_aresta_test.dart` para deduplicação de downloads concorrentes (múltiplos widgets solicitando a mesma mídia em paralelo compartilham a mesma Future e disparam apenas 1 requisição HTTP) (Red)
- [ ] 2.5 Escrever testes unitários em `test/widgets/provedor_imagem_aresta_test.dart` para resolução e cache de miniaturas globais sob `temp_cache/thumbnails/<picoId>.webp.<hash>` e consulta prioritária a `$docsDir/thumbnails/<picoId>.webp` (Red)
- [ ] 2.6 Implementar no `ProvedorImagemAresta` (`lib/widgets/provedor_imagem_aresta.dart`) a lógica de download atômico, persistência em `temp_cache` com padrão `<caminho>.<hash>`, exigência estrita de hash, limpeza de versões antigas, deduplicação de downloads concorrentes e suporte a miniaturas, com docstrings `///` em português brasileiro explicando a intenção (Green)

## 3. Refinamento de Ciclo de Vida no OfflineMarkdown (TDD - Princípios IV e V)

- [ ] 3.1 Escrever teste de widget em `test/view_functions/offline_markdown_test.dart` garantindo que reconstruções de tela com conteúdo idêntico não expurgam o cache de memória do Flutter (Red)
- [ ] 3.2 Refatorar `_OfflineMarkdownState.didUpdateWidget` em `lib/view_functions/offline_markdown.dart` para condicionar qualquer evicção à alteração real de `widget.data` ou `widget.cragId`, mantendo docstrings completas (Green)

## 4. Unificação de Miniaturas Globais na Interface (Feature-First & Espelhamento - Princípios II, IV e V)

- [ ] 4.1 Criar arquivo de teste de widget em `test/view_functions/meus_croquis_functions_test.dart` cobrindo a renderização de miniatura via `ProvedorImagemAresta` com downsampling (Red)
- [ ] 4.2 Atualizar testes de widget em `test/view_functions/browse_functions_test.dart` e `test/pages/browse_test.dart` para validar miniaturas via `ProvedorImagemAresta` (Red)
- [ ] 4.3 Refatorar `_CragBackgroundWidget` em `lib/view_functions/browse_functions.dart` e o componente correspondente em `lib/view_functions/meus_croquis_functions.dart` para consumir `ProvedorImagemAresta.resolver` com `larguraAlvo: 300` e docstrings `///` em português (Green)

## 5. Aproveitamento do Cache Volátil no Download Offline (SyncService - Princípio II, IV e VI)

- [ ] 5.1 Escrever testes unitários em `test/services/http/sync_isolate_test.dart` validando que mídias com hash idêntico presentes no `temp_cache` são copiadas diretamente para `.tmp` sem acionar requisições HTTP (Red)
- [ ] 5.2 Implementar na rotina `downloadAtomic` de `lib/services/http/sync_isolate.dart` a verificação prévia no `temp_cache` e cópia direta, com docstrings `///` em português (Green)

## 6. Validação de 100% de Cobertura, Anti-Regressão e Documentação Contínua (Princípios I, III e VII)

- [ ] 6.1 Executar e validar o teste de integração ponta a ponta `test/integration/cache_imagens_online_test.dart` passando em Green (exatamente 1 requisição HTTP total de rede)
- [ ] 6.2 Executar a suíte de testes completa com verificação de 100% de cobertura nos arquivos modificados e criados (`flutter test --coverage`)
- [ ] 6.3 Atualizar a documentação técnica nos arquivos `README.md` pertinentes (`frontend/lib/services/README.md` e `frontend/lib/widgets/README.md`) refletindo a arquitetura de cache em disco e o padrão `<caminho>.<hash>`
