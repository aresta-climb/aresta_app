# Testes de `function_library` (`test/view/function_library/`)

Este diretório contém os testes unitários e de widget dos construtores visuais e funções auxiliares de `lib/view/function_library/`.

## Arquivos

| Arquivo | Escopo |
|---|---|
| `biblioteca_funcoes_comuns_test.dart` | `safeString`, `isBoulderArea`, `normalizeSearchString`, `buildCommonAppBar` (incluindo `BotaoVoltarComRetornoInicio` e feedback) e `handleManualSync` |
| `funcoes_hub_perfil_caderneta_test.dart` | `construirProvedorAvatarPerfil` (base64 e URL), `buildCabecalhoHubPerfil`, `buildBarraMetricasHub` e `buildMenuOpcoesHub` |
| `funcoes_caderneta_test.dart` | `SecaoHistoricoCadenas`, `EstadoVazioHistoricoCaderneta`, `ItemHistoricoCadena` e `DialogoConfirmarExclusaoCadena` |
| `via_functions_test.dart` e `via_functions_widget_test.dart` | `getGrauString`, `getGrauValue`, formatação de proteções e renderização de `CorpoDetalhesVia` |
| `funcoes_home_test.dart` e `funcoes_explorar_test.dart` | Listas da Home e do Explorar, progresso de download e tratamento de falhas offline/integridade em `handlePicoSelection` |
| `pico_functions_test.dart`, `pico_functions_widget_test.dart`, `pico_search_online_test.dart` | Seções do Pico, formatação de data de atualização e busca em `PicoSearchDelegate` |
| `setor_functions_test.dart` e `grupo_functions_test.dart` | `resolveRouteLabels` (`RotulosVia`), cores FEMEMG e listagens de setores e grupos |
| `meus_croquis_functions_test.dart` | Remoção e listagem de croquis salvos |
| `comunidade_functions_test.dart` e `sobre_time_functions_test.dart` | Links comunitários e cartões de `MembroTime` |
| `funcoes_configuracoes_test.dart` | Tema, QR Code e conexão com Editor Desktop |
| `markdown_offline_test.dart`, `sintaxe_tag_small_test.dart`, `construtor_elemento_small_test.dart` | Leitura local de imagens em Markdown e tag `<small>` |
| `fuzzy_search_test.dart` | Busca aproximada com remoção de diacríticos e pesos por campo |
| `mapa/mapa_global_functions_test.dart` e `mapa/mapa_marker_test.dart` | Faixas de zoom do Mapa Global e geração de bitmaps de marcadores via `Canvas` |

## Execução

```bash
flutter test test/view/function_library/
```
