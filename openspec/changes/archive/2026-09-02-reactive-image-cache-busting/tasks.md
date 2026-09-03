## 1. Testes de Widget em Primeiro Lugar (TDD - Fase Red)

- [x] 1.1 Criar teste de widget em `frontend/test/widgets/imagem_arquivo_aresta_test.dart` validando que a imagem atualiza na tela quando o `checksumSha256` muda e é retida quando o hash é idêntico
- [x] 1.2 Criar testes de widget em `frontend/test/pages/setor_test.dart` e `frontend/test/pages/grupo_test.dart` validando a atualização da imagem de capa durante Hot Reload
- [x] 1.3 Criar testes de widget em `frontend/test/pages/mapa_interativo_test.dart` e `frontend/test/widgets/mapa_thumbnail_test.dart` validando a atualização da imagem de mapa durante Hot Reload sem depender de alteração nos campos do Protobuf Mapa

## 2. Implementação do Provedor de Imagem com Cache-Busting (Fase Green)

- [x] 2.1 Criar testes unitários para `ImagemArquivoAresta` e `ChaveImagemArquivoAresta` cobrindo `operator ==`, `hashCode` e chave de cache
- [x] 2.2 Implementar `ImagemArquivoAresta` em `frontend/lib/widgets/imagem_arquivo_aresta.dart` com docstrings explicativas detalhadas em português brasileiro

## 3. Pré-indexação de Hashes no DatasetRepository (TDD)

- [x] 3.1 Criar testes em `frontend/test/services/dataset_repository_test.dart` para o método `obterSha256DaMidia` cobrindo mídias de croqui e miniaturas de pico
- [x] 3.2 Implementar a tabela de dispersão $O(1)$ e o método `obterSha256DaMidia(picoId, caminho)` no `DatasetRepository`

## 4. Integração do ProvedorImagemAresta e Cache-Busting Remoto (TDD)

- [x] 4.1 Criar testes em `frontend/test/widgets/provedor_imagem_aresta_test.dart` validando a resolução com `ImagemArquivoAresta` (local) e `NetworkImage` com `?v=hash` (remoto)
- [x] 4.2 Atualizar `ProvedorImagemAresta.resolver` para consultar o `DatasetRepository` e aplicar o hash automaticamente para arquivos locais e remotos

## 5. Alinhamento de Ciclo de Vida dos Widgets de Tela (Fase Green)

- [x] 5.1 Atualizar `SetorPage` e `GrupoPage` re-resolvendo o futuro da imagem de capa em `didUpdateWidget` com `setState()`
- [x] 5.2 Atualizar `MapaInterativoPage` e `MapaThumbnail` re-resolvendo o futuro do mapa em `didUpdateWidget` com `setState()`, eliminando a checagem falha de Protobuf e o `provider?.evict()` legado

## 6. Documentação Abrangente e Validação de Cobertura 100%

- [x] 6.1 Atualizar `frontend/HOT_RELOAD.md`, `frontend/lib/README.md` e `frontend/lib/services/README.md` documentando a arquitetura de cache-busting reativo e garantindo docstrings `///` em todo o código novo
- [x] 6.2 Executar a suíte de testes e validar 100% de cobertura nos arquivos criados e modificados sem nenhuma quebra de regressão


