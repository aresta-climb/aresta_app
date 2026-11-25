# Widgets (`lib/widgets/`)

Este diretório reúne os componentes visuais compartilhados entre as telas do aplicativo. Os subdiretórios `autenticacao/`, `caderneta/`, `navegacao/`, `perfil/` e `via/` não importam `lib/services/` (`isolamento_mvvm_modulos_test.dart`).

---

## 1. Resolução e Cache de Imagens

### `ProvedorImagemAresta` (`provedor_imagem_aresta.dart`)
Resolve imagens em três etapas:
1. **Downloads Locais (`$downloadsRoot/<picoId>/` ou `$downloadsRoot/thumbnails/`)**: Retorna `ImagemArquivoAresta` para arquivos salvos no aparelho.
2. **Cache Temporário (`/temp_cache/<picoId>/<caminho>.<hash>`)**: Retorna `ImagemArquivoAresta` se o arquivo correspondente ao SHA-256 já tiver sido baixado na sessão online.
3. **Rede (CDN)**: Baixa via `ClienteHttpAresta.instancia` (timeout de 20s), grava em `.tmp`, renomeia para `.<hash>`, apaga hashes anteriores do mesmo arquivo e compartilha a mesma `Future` entre chamadas simultâneas para o mesmo destino. Se o SHA-256 não constar nos metadados, usa `NetworkImage` sem gravar em disco e registra no `AppLogger`.
4. **Redimensionamento**: Quando `larguraAlvo` ou `alturaAlvo` são informados, aplica `ResizeImage.resizeIfNeeded` (padrão `larguraAlvo: 300` em cartões e carrosséis).

### `ImagemArquivoAresta` (`imagem_arquivo_aresta.dart`)
Subclasse de `FileImage` que inclui `checksumSha256` em `operator ==` e `hashCode` para invalidar a entrada no `ImageCache` do Flutter quando o conteúdo do arquivo muda.

---

## 2. Componentes por Domínio

| Componente | Arquivo | Responsabilidade |
|---|---|---|
| `BotaoVoltarComRetornoInicio` | `navegacao/botao_voltar_com_retorno_inicio.dart` | Botão de retorno usado nas páginas secundárias: toque rápido executa `aoVoltar` (`AppNav.back`); manter pressionado anima um arco de progresso, alterna o ícone para `Icons.home_rounded`, exibe a pílula `"Início"` via `OverlayPortal` e executa `aoIrParaInicio` (`AppNav.home`). |
| `BarraTopoLogin`, `CabecalhoTelaLogin`, `BotaoProvedorOAuthLogin`, `DivisorSecaoLogin`, `BannerAvisoLogin`, `CartaoCodigoEmailLogin`, `BotaoAbrirConfiguracoesLogin` | `autenticacao/componentes_login.dart` | Componentes da `LoginPage` para provedores OAuth, solicitação/confirmação de código OTP de 6 dígitos, avisos e atalho de configurações. |
| `DialogoEditarPerfil`, `ModalDadosPrivacidade`, `DialogoConfirmarSaida`, `DialogoConfirmarExclusaoConta` | `perfil/dialogos_hub_perfil.dart` | Diálogos do Hub de Perfil para edição de nome e foto, cópia do `autorIdPublico` (NanoID 14c), encerramento de sessão e exclusão de conta. |
| `ModalRegistroCadena`, `SecaoContribuicaoPublicaAscensao`, `SecaoMeusAlertasCaderneta` | `caderneta/` | Formulário de registro de ascensões com voto opcional de grau/beta e seção da `CadernetaPage` que lista alertas criados (`CRIADO POR VOCÊ`) ou confirmados (`CONFIRMADO (+1)`) com ação de resolução e desfazer. |
| `BolhasFlutuantesAlertaVia`, `BolhaEmojiAlertaVia`, `exibirModalConfirmacaoAlertaVia`, `exibirModalReportarAlertaVia`, `CamadaBolhasAlertaMapa` | `via/bolha_alerta_seguranca_via.dart`, `via/camada_bolhas_alerta_mapa.dart` | Balões de alerta com emojis (`🐝`, `🪨`, `🔩`, `⚠️`) exibidos na `ViaPage` e sobre os nós do `MapaInterativoPage`, além dos modais *"Ainda está lá?"* e de reporte. |
| `AnelConsensoGrauVia`, `BarrasDistribuicaoGrauVia`, `SeletorPilulasVotoGrauVia` | `via/grafico_consenso_grau_via.dart` | Gráficos de distribuição de votos e fileira de 5 pílulas (`-2` a `+2`) para votação de grau na `ViaPage`. |
| `CabecalhoIdentidadeVia`, `AreaHeroiTopoGrauVia`, `CartaoGrauVia`, `SecaoMapaCroquiVia`, `BarraInferiorAcoesVia`, `DespachanteSnackBarSeguro`, `GradeAtributosTecnicosVia`, `SecaoTextosETecnicasVia`, `SecaoEnfiadasVia`, `SecaoBetasMidiaVia`, `SecaoNotasComunidadeVia`, `SecaoHistoricoEPixVia` | `via/` | Seções da `ViaPage` (identidade, grau oficial/consenso, atributos técnicos, enfiadas, betas, notas, Pix, barra inferior e `SnackBar` posicionado acima dos controles do sistema). |
| `LinhaLocalizacaoSetor` | `linha_localizacao_setor.dart` | Exibe `Grupo > Setor` e o atalho `"Ver no croqui"`, navegando para o `SetorNode`. |
| `BannerModoExperimental`, `ModalSessaoExperimentalEncerrada` | `banner_modo_experimental.dart`, `modal_sessao_experimental_encerrada.dart` | Indicador de sessão experimental ativa com botão `[ SAIR ✕ ]` e diálogo de encerramento por expiração (`HTTP 404`). |
| `BannerModoOnline`, `ModalConfirmacaoSaida`, `ModalCroquiSemConexao` | `banner_modo_online.dart`, `modal_confirmacao_saida.dart`, `bottom_sheets/modal_croqui_sem_conexao.dart` | Aviso de leitura sem download local, confirmação de salvamento ao sair e modal exibido quando um croqui não baixado é aberto sem rede. |
| `BuscaGlobal` | `busca_global.dart` | Barra de busca textual sobre `catalogo.db` e dados em memória para picos, grupos, setores e vias, abrindo o destino via `LocalizadorDestinoUid`. |
| `ArestaHomeAppBar`, `CarrosselPicosProximos`, `CardPico`, `MapaThumbnail` | `widgets/` | Barra superior da Home, carrossel horizontal de picos próximos, cartão de pico e miniatura de mapa. |
| `BarraOrdenacaoExploracao`, `PainelFiltrosIndice`, `CardIndiceEscalada`, `BadgesModalidades` | `widgets/` | Ordenação `[ PADRÃO | GRAU | ALFABÉTICO ]`, painel de filtros sobre `EstadoFiltrosUnificado`, cartão de escalada e badges de contagem por modalidade. |
