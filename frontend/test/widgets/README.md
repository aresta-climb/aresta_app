# Testes de Widgets (`test/widgets/`)

Este diretório contém os testes de widget que espelham `lib/widgets/`.

## Principais Suítes

| Arquivo | Componente testado |
|---|---|
| `navegacao/botao_voltar_com_retorno_inicio_test.dart` | `BotaoVoltarComRetornoInicio` (toque rápido, segurar até retornar ao início, cancelamento no meio da animação, semântica e integração com `AppNav`) |
| `autenticacao/componentes_login_test.dart` | `BarraTopoLogin`, `CabecalhoTelaLogin`, `BotaoProvedorOAuthLogin`, `BannerAvisoLogin`, `CartaoCodigoEmailLogin` e `BotaoAbrirConfiguracoesLogin` |
| `perfil/dialogos_hub_perfil_test.dart` | `DialogoEditarPerfil`, `ModalDadosPrivacidade`, `DialogoConfirmarSaida` e `DialogoConfirmarExclusaoConta` |
| `caderneta/*_test.dart` | `ModalRegistroCadena`, `SecaoContribuicaoPublicaAscensao`, `ControlesFormularioCadena`, `SecaoMeusAlertasCaderneta`, `GraficoPiramideGraus` e `CardEstatistica` |
| `via/*_test.dart` | `BolhasFlutuantesAlertaVia`, `CamadaBolhasAlertaMapa`, `AnelConsensoGrauVia`, `SeletorPilulasVotoGrauVia`, `CabecalhoIdentidadeVia`, `AreaHeroiTopoGrauVia`, `BarraInferiorAcoesVia`, `DespachanteSnackBarSeguro` e seções técnicas da `ViaPage` |
| `provedor_imagem_aresta_test.dart` e `imagem_arquivo_aresta_test.dart` | Resolução de imagens em disco/cache/CDN e invalidação por SHA-256 |
| `busca_global_test.dart` | Pesquisa global sobre `catalogo.db`, trava de concorrência e estado offline |
| `card_pico_test.dart`, `carrossel_picos_proximos_test.dart`, `mapa_thumbnail_test.dart` | Cartões de picos, carrossel de próximos e miniaturas de mapas |
| `painel_filtros_indice_test.dart`, `card_indice_escalada_test.dart`, `badges_modalidades_test.dart` | Filtros, cartões de vias/boulders e badges de modalidades |
| `banner_modo_experimental_test.dart`, `banner_modo_online_test.dart`, `modal_confirmacao_saida_test.dart` | Banners de modo operacional e confirmação ao sair |
| `feedback/construtor_feedback_usuario_test.dart` | Formulário `CustomStringFeedback` com e sem croqui ativo |
| `app_bar_home_aresta_test.dart` e `verificador_versao_app_test.dart` | Barra superior da Home e verificação de versão mínima |

## Execução

```bash
flutter test test/widgets/
flutter test test/widgets/navegacao/botao_voltar_com_retorno_inicio_test.dart
```

## Notas

- `TestWidgetsFlutterBinding` bloqueia tráfego HTTP externo retornando status `400`; componentes que buscam dados externos recebem clientes/repositórios Fake injetados ou imagens em memória/disco temporário.
