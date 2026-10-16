# Tasks

## 1. Atualização do Submódulo aresta_api e Remoção de Campo Deprecado

- [x] 1.1 Atualizar o submódulo `frontend/lib/aresta_api` para o commit `16ebee3` (ou branch `origin/main`) e verificar que os novos bindings em `croqui.pb.dart` contêm `alvoUid`, `pontosUids`, `uid` e `rotulo`
- [x] 1.2 Remover as referências a `ref.hasIndiceMapaAlvo()` e `ref.indiceMapaAlvo` em `frontend/lib/pages/mapa_interativo.dart`, abrindo o carrossel no índice inicial zero e verificando a compilação do projeto

## 2. Normalizador In-Place de Croquis Legados (TDD)

- [x] 2.1 [RED] Escrever testes unitários em `frontend/test/services/dataset/normalizador_croqui_test.dart` cobrindo a conversão in-place de croquis legados: geração de UIDs sintéticos para `Grupo`, `Setor` e `Escalada`, cópia de `label` para `rotulo`, cópia de `ids` para `pontosUids` e síntese de `alvoUid` em referências, assegurando que botões legados não recebam UIDs sintéticos
- [x] 2.2 [GREEN] Implementar `NormalizadorCroqui` em `frontend/lib/services/dataset/normalizador_croqui.dart` realizando a mutação in-place segura das mensagens Protobuf
- [x] 2.3 [GREEN] Integrar a chamada a `NormalizadorCroqui` nos pontos de entrada de dados (`GerenciadorArquivosLocais`, `ServicoCroquiOnline`, `RepositorioDataset`)
- [x] 2.4 [REFACTOR] Adicionar docstrings detalhadas em `normalizador_croqui.dart` e garantir 100% de cobertura de código no módulo

## 3. Teste Arquitetural de Governança

- [x] 3.1 [RED/GREEN] Criar o teste arquitetural em `frontend/test/architecture/uso_campos_legados_croqui_test.dart` verificando estaticamente que arquivos em `frontend/lib/` (exceto `normalizador_croqui.dart` e `aresta_api/`) não contêm referências a `.label`, `.indiceMapaAlvo`, `.hasIndiceMapaAlvo`, `ref.escalada`, `ref.setor`, `ref.grupo` e `ref.ids`

## 4. Catálogo O(1) no DatasetResolver Operando 100% por UID (TDD)

- [x] 4.1 [RED] Escrever testes unitários em `frontend/test/utils/consulta_dataset_test.dart` cobrindo a resolução de `Botao`, `Grupo`, `Setor` e `Escalada` exclusivamente através de seus `uid`s em O(1), a validação do `tipo` (`TipoEntidadeResolved`) e o mapeamento automático de `referencias`
- [x] 4.2 [GREEN] Refatorar `DatasetResolver` em `frontend/lib/utils/consulta_dataset.dart` para indexar em O(1) apenas por `uid`, associando os pares `ReferenciaNoMapa` e removendo os loops de busca textual legados
- [x] 4.3 [REFACTOR] Documentar `DatasetResolver` e `ResolvedDataset` com docstrings abrangentes

## 5. Resolução no Escopo Local do Mapa e Interatividade (TDD)

- [x] 5.1 [RED] Escrever testes unitários em `frontend/test/utils/resolvedor_rotulos_referencia_test.dart` cobrindo a extração de rótulos consumindo exclusivamente `ref.pontosUids` e `ponto.rotulo`
- [x] 5.2 [GREEN] Atualizar `extrairRotuloReferencia` em `frontend/lib/utils/resolvedor_rotulos_referencia.dart` para operar unicamente com `ponto.rotulo` e `ref.pontosUids` no escopo de `mapa.pontosDeInteresse`
- [x] 5.3 [RED] Escrever testes de widget em `frontend/test/pages/mapa_interativo_test.dart` validando foco via `ponto.uid`, traçados com `pontos_uids` e cartões com `alvo_uid`
- [x] 5.4 [GREEN] Atualizar `_buildReferenceMaps`, `_getPontosForRef`, `_onMarkerTap`, `_selectedId` e `chaveCanonica` em `frontend/lib/pages/mapa_interativo.dart` para utilizar exclusivamente `uid`, `rotulo`, `alvoUid` e `pontosUids`

## 6. Aposentadoria do CroquiMapIndex e Integração em Setor e Via (TDD)

- [x] 6.1 [RED] Escrever testes unitários em `frontend/test/view/function_library/setor_functions_test.dart` e `frontend/test/view/function_library/via_functions_test.dart` validando o cruzamento de vias e mapas utilizando as referências associadas no `ResolvedDataset`
- [x] 6.2 [GREEN] Migrar `_buscarReferenciaNoMapa` e `resolveRouteLabels` em `frontend/lib/view/function_library/setor_functions.dart` para comparar `ref.alvoUid == escalada.uid`
- [x] 6.3 [GREEN] Migrar `buildBannersMapas` em `frontend/lib/view/function_library/via_functions.dart` para obter as referências diretamente de `resolved.referencias`, removendo a dependência de `CroquiMapIndex`
- [x] 6.4 [GREEN] Deletar a classe `CroquiMapIndex` e `ReferenceKey` em `frontend/lib/utils/indice_mapas_croqui.dart` e atualizar os testes correspondentes em `frontend/test/utils/indice_mapas_croqui_test.dart`

## 7. Verificação de Cobertura, Documentação e Integridade

- [x] 7.1 Executar o teste arquitetural e a suíte completa de testes do frontend com medição de cobertura (`flutter test --coverage`), garantindo 100% de aprovação e zero regressões
- [x] 7.2 Atualizar a documentação técnica relevante refletindo o pipeline com `NormalizadorCroqui`, catálogo de UIDs e remoção definitiva de `indice_mapa_alvo`
