# Tarefas de Implementação: Mapas Individuais de Escalada

## 1. Schema Protobuf e Stubs (`aresta_api`)

- [x] 1.1 Atualizar `proto/croqui.proto` adicionando `repeated Mapa mapas = 7;` em `Escalada`, removendo o campo 21 de `ViaMultiplasEnfiadas` e marcando `reserved 21;`. Verificar sintaxe com `protoc`.
- [x] 1.2 Executar `python build.py` no `aresta_api` para gerar stubs Python atualizados em `aresta_db` e stubs Dart atualizados em `aresta_app`. Verificar presença de `mapas` nas classes geradas em ambas as linguagens.
- [x] 1.3 Adicionar testes em `aresta_api/proto_validacao_test.py` validando que instâncias de `Escalada` (boulder, via esportiva, móvel e multipitch) aceitam e serializam `mapas`.

## 2. Processamento e Orçamento de Imagens (`aresta_db`)

- [x] 2.1 Criar testes unitários em `editor/core/processamento_imagem_campo_test.py` cobrindo o perfil de compressão para escaladas (`AREA_MAXIMA_ESCALADA = 1_000_000` e `QUALIDADE_WEBP_ESCALADA = 85`), garantindo que fotos acima de 1.0 MP sejam redimensionadas mantendo o aspect ratio.
- [x] 2.2 Implementar constantes e parâmetros de perfil em `editor/core/processamento_imagem_campo.py` e verificar aprovação de todos os testes unitários da biblioteca.
- [x] 2.3 Atualizar `editor/core/nomes_arquivos.py` para sugerir nomes padronizados `boulder_<nome>_p<idx>.webp` e `via_<nome>_p<idx>.webp` quando a entidade pai for uma escalada, verificando com testes em `nomes_arquivos_test.py`.

## 3. Diálogo de Adição de Mapas com Recorte e Dica (`aresta_db`)

- [x] 3.1 Criar testes em `editor/views/dialogos/dialogo_adicionar_mapa_test.py` para seleção de recorte (*rubber-band crop*), verificação do banner contextual de dica de qualidade e aplicação do perfil de escalada (1.0 MP @ Q85).
- [x] 3.2 Implementar o banner visual informativo `💡 Dica de Qualidade` em `DialogoAdicionarMapa` quando aberto no contexto de uma escalada.
- [x] 3.3 Integrar a ferramenta de recorte interativo (*rubber-band selection*) na área de pré-visualização do `DialogoAdicionarMapa`, conectando-a com `cortar_imagem_bytes` de `editor/core/transformacoes_imagem.py` e botão para reverter para imagem original. Verificar com testes automatizados do diálogo.

## 4. Editor de Mapas e Validador (`aresta_db`)

- [x] 4.1 Criar testes em `editor/views/widget_editor_mapas_test.py` validando que mapas de escaladas são listados na árvore lateral do editor visual e podem ser selecionados para edição e desenho de traçados.
- [x] 4.2 Atualizar `WidgetEditorMapas` para listar e permitir desenhar sobre mapas de escaladas, com suporte ao preenchimento de `LinhaTrajeto` e nós semânticos.
- [x] 4.3 Atualizar `preparar_submissao_lib.py` para incluir mapas de escaladas no manifesto de arquivos externos e na pré-compilação vetorial Catmull-Rom para GPU. Verificar executando a suíte de testes de submissão.

## 5. Indexação Global e Resolução de Mapas (`aresta_app`)

- [x] 5.1 Escrever testes unitários em `test/utils/croqui_map_index_test.dart` validando que `CroquiMapIndex` cataloga mapas locais de escaladas em $O(1)$ e os diferencia de referências em mapas de setores/grupos.
- [x] 5.2 Estender `CroquiMapIndex` em `lib/utils/croqui_map_index.dart` para registrar `escalada.mapas` associados ao `ReferenceKey` correspondente e implementar método auxiliar de resolução unificada de carrossel.
- [x] 5.3 Verificar cobertura de 100% nos testes de `croqui_map_index_test.dart` via `flutter test`.

## 6. Interface do Usuário e Carrossel Unificado (`aresta_app`)

- [x] 6.1 Escrever testes de widget em `test/view_functions/via_functions_test.dart` verificando que a `ViaPage` renderiza o componente `MapaThumbnail` quando a escalada possui mapas próprios, e o botão tradicional quando não possui.
- [x] 6.2 Implementar a renderização condicional do `MapaThumbnail` rico na `ViaPage` em `lib/view_functions/via_functions.dart` com abertura do carrossel sequenciando mapas locais seguidos por mapas de setor/grupo.
- [x] 6.3 Escrever testes de widget em `test/pages/mapa_interativo_test.dart` verificando a presença e o comportamento da ação secundária "Ver mapas" no rodapé ao selecionar uma rota com mapas próprios.
- [x] 6.4 Implementar a ação "Ver mapas" no bottom sheet de rota selecionada em `lib/pages/mapa_interativo.dart`, navegando diretamente para o carrossel da escalada.

## 7. Integração Ponta a Ponta e Validação Prática

- [x] 7.1 Cadastrar e validar um mapa de saída de boulder piloto no bloco da Pedra Grande (`database/br_mg_igarape_pedra_grande`), verificando compilação sem warnings via `preparar_submissao_lib.py`.
- [x] 7.2 Executar a suíte completa de testes (`pytest` no `aresta_db` e `flutter test --coverage` no `aresta_app`) assegurando 100% de aprovação e integridade arquitetural.
