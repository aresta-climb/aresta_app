// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../data/modelos/dados_cartao_compartilhamento.dart';
import '../../data/modelos/interacao_via.dart';
import '../../idioma/tradutor_app.dart';
import '../../services/compartilhamento/servico_compartilhamento.dart';
import '../../services/comunidade/repositorio_interacoes_via.dart';
import '../../services/firebase/app_logger.dart';
import '../../services/firebase/telemetria.dart';
import '../../utils/consulta_dataset.dart';
import '../../utils/extrator_detalhes_tecnicos_via.dart';
import '../../utils/formatador_escalada.dart';

export '../../utils/extrator_detalhes_tecnicos_via.dart';

/// Resultado semântico de uma tentativa de votação direta nas pílulas de grau comunitário.
enum ResultadoVotoGrauVia {
  /// Voto computado localmente e enfileirado com sucesso.
  registrado,

  /// O escalador precisa entrar em sua conta antes de publicar votos comunitários.
  requerAutenticacao,

  /// Falha inesperada ao persistir o voto.
  falha,
}

/// ViewModel (MVVM) responsável pelo estado reativo, comandos de negócio (compartilhamento,
/// Pix, voto direto de grau, janela de desfazer em alertas e telemetria de croqui) e modelos
/// de apresentação imutáveis consumidos pela Dumb UI da `ViaPage`.
class ViaViewModel extends ChangeNotifier {
  /// Escalada Protobuf exibida na página.
  final Escalada escalada;

  /// Repositório reativo de interações comunitárias e alertas de segurança.
  final RepositorioInteracoesVia repositorioInteracoes;

  /// Duração da janela de desfazer antes de efetivar a resolução de um alerta de segurança.
  final Duration duracaoJanelaDesfazer;

  final ServicoCompartilhamento? _servicoCompartilhamento;
  final TelemetryService? _telemetria;
  final Future<void> Function(String texto) _copiadorAreaTransferencia;
  final Future<bool> Function(Uri uri) _lancadorUrlExterna;
  final Map<String, Timer> _timersResolucaoPendente = {};
  bool _descartado = false;

  /// Cria uma instância de [ViaViewModel].
  ViaViewModel({
    required this.escalada,
    RepositorioInteracoesVia? repositorioInteracoes,
    ServicoCompartilhamento? servicoCompartilhamento,
    TelemetryService? telemetria,
    Future<void> Function(String texto)? copiadorAreaTransferencia,
    Future<bool> Function(Uri uri)? lancadorUrlExterna,
    this.duracaoJanelaDesfazer = const Duration(seconds: 4),
  }) : repositorioInteracoes =
           repositorioInteracoes ?? RepositorioInteracoesViaMemoria.instancia,
       _servicoCompartilhamento = servicoCompartilhamento,
       _telemetria = telemetria,
       _copiadorAreaTransferencia =
           copiadorAreaTransferencia ??
           ((texto) => Clipboard.setData(ClipboardData(text: texto))),
       _lancadorUrlExterna =
           lancadorUrlExterna ??
           ((uri) => launchUrl(uri, mode: LaunchMode.externalApplication)) {
    this.repositorioInteracoes.alteracoesListenable.addListener(_notificar);
    ControladorIdiomaApp.instancia.notificadorIdioma.addListener(_notificar);
    _sincronizarInteracoesSeAtivo();
  }

  void _sincronizarInteracoesSeAtivo() {
    if (!possuiUid) return;
    unawaited(
      repositorioInteracoes
          .sincronizarEscalada(
            escalada.uid,
            codigoGrauOficial: codigoGrauOficial,
            ehBoulder: ehBoulder,
          )
          .catchError((Object e) {
            AppLogger.instance.logAviso(
              'Sincronização comunitária adiada para ${escalada.uid}: $e',
            );
          }),
    );
  }

  void _notificar() {
    if (!_descartado) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _descartado = true;
    final pendentes = _timersResolucaoPendente.keys.toList(growable: false);
    for (final alertaUid in pendentes) {
      _timersResolucaoPendente.remove(alertaUid)?.cancel();
      unawaited(confirmarAlerta(alertaUid, aindaEstaLa: false));
    }
    ControladorIdiomaApp.instancia.notificadorIdioma.removeListener(_notificar);
    repositorioInteracoes.alteracoesListenable.removeListener(_notificar);
    super.dispose();
  }

  /// Nome legível da escalada.
  String get nomeEscalada => obterNomeEscalada(escalada);

  /// Indica se a escalada possui um `uid` NanoID válido para compartilhamento e interações.
  bool get possuiUid => escalada.hasUid() && escalada.uid.trim().isNotEmpty;

  /// Indica se a modalidade é um Highline (sem grau esportivo de escalada).
  bool get ehHighline => escalada.whichTipo() == Escalada_Tipo.highline;

  /// Indica se a escalada pertence à modalidade Boulder (escala V).
  bool get ehBoulder => escalada.whichTipo() == Escalada_Tipo.boulder;

  /// Código numérico Protobuf do grau oficial da escalada, quando definido.
  int? get codigoGrauOficial => obterCodigoGrauOficial(escalada);

  /// Indica se o botão de reportar alerta deve aparecer na barra superior da página.
  bool get podeReportarAlerta => possuiUid;

  /// Indica se o escalador atual possui sessão autenticada para criar ou confirmar alertas.
  bool get usuarioEstaAutenticado => repositorioInteracoes.usuarioEstaAutenticado;

  /// Determina o estado de permissão e deduplicação do usuário atual sobre [alerta].
  EstadoInteracaoAlertaUsuario estadoInteracaoDoAlerta(
    AlertaSegurancaVia alerta,
  ) => alerta.resolverEstadoParaUsuario(
    estaAutenticado: repositorioInteracoes.usuarioEstaAutenticado,
    autorIdPublicoUsuario: repositorioInteracoes.autorIdPublicoAtual,
  );

  /// Modalidade formatada em português (`'Esportiva'`, `'Móvel'`, `'Mista'`, `'Boulder'`, `'Multienfiada'`, `'Highline'`).
  String get modalidade => ExtratorDetalhesTecnicosVia.extrairModalidade(escalada);

  /// Indica se a linha é marcada como clássica/destaque do setor.
  bool get ehDestaque => ExtratorDetalhesTecnicosVia.extrairDestaque(escalada);

  /// Rótulo do bloco de grau oficial do conquistador.
  String get rotuloGrauOficial =>
      escalada.whichTipo() == Escalada_Tipo.viaMultiplasEnfiadas
      ? tr(ChaveTexto.viaGrauMaximo)
      : tr(ChaveTexto.viaGrauOficial);

  /// Grau oficial formatado (ou `'Projeto'`), retornando `null` quando indefinido ou em highline.
  String? get grauOficialExibicao =>
      ExtratorDetalhesTecnicosVia.extrairGrauOficialExibicao(escalada);

  /// Linha complementar abaixo do grau oficial (grau médio em multienfiadas e artificial).
  String get complementoGrauOficial =>
      ExtratorDetalhesTecnicosVia.extrairComplementoGrauOficial(escalada);

  /// Indica se o cartão comparativo de grau deve ser exibido na tela.
  bool get exibirCartaoGrau =>
      !ehHighline && (grauOficialExibicao != null || possuiUid);

  /// Consenso democrático de grau da comunidade.
  ConsensoGrauVia? get consensoGrau {
    if (ehHighline || !possuiUid) {
      return null;
    }
    return repositorioInteracoes.obterDadosEscalada(escalada.uid).consensoGrau;
  }

  /// Modelo visual imutável do consenso comunitário pronto para renderização na Dumb UI.
  ApresentacaoConsensoGrauVia? get apresentacaoConsenso {
    final consenso = consensoGrau;
    if (consenso == null) return null;
    return ExtratorDetalhesTecnicosVia.construirApresentacaoConsenso(
      consenso,
      codigoGrauOficial: codigoGrauOficial,
      ehBoulder: ehBoulder,
      deltaVotoUsuario: repositorioInteracoes.obterDeltaVotoUsuario(escalada.uid),
    );
  }

  /// Lista de alertas de segurança ativos (filtrando alertas em janela temporária de desfazer).
  List<AlertaSegurancaVia> get alertasAtivos {
    if (!possuiUid) {
      return const [];
    }
    final todos = repositorioInteracoes
        .obterDadosEscalada(escalada.uid)
        .alertasAtivos;
    if (_timersResolucaoPendente.isEmpty) return todos;
    return todos
        .where((a) => !_timersResolucaoPendente.containsKey(a.uid))
        .toList(growable: false);
  }

  /// Lista de comentários e betas públicos da comunidade.
  List<ComentarioComunidadeVia> get comentariosComunidade {
    if (!possuiUid) {
      return const [];
    }
    return repositorioInteracoes.obterDadosEscalada(escalada.uid).comentarios;
  }

  /// Betas públicos pré-formatados com autor, data e estilo prontos para a Dumb UI.
  List<NotaComunidadeApresentacao> get notasComunidadeApresentacao =>
      ExtratorDetalhesTecnicosVia.formatarNotasComunidade(
        comentariosComunidade,
        autorIdUsuarioAutenticado: usuarioEstaAutenticado
            ? repositorioInteracoes.autorIdPublicoAtual
            : null,
      );

  /// Tipo de ancoragem/parada da via, quando informado.
  String? get tipoAncoragem =>
      ExtratorDetalhesTecnicosVia.extrairTipoAncoragem(escalada);

  /// Lista enxuta e sem duplicações dos atributos técnicos específicos da modalidade.
  List<AtributoTecnicoVia> get atributosTecnicos =>
      ExtratorDetalhesTecnicosVia.extrairAtributosTecnicos(escalada);

  /// Seções textuais e de equipamento recomendadas para a escalada.
  List<SecaoTextoVia> get secoesTexto =>
      ExtratorDetalhesTecnicosVia.extrairSecoesTexto(escalada);

  /// Lista estruturada das enfiadas em vias de múltiplas enfiadas.
  List<ResumoEnfiadaVia> get enfiadas =>
      ExtratorDetalhesTecnicosVia.extrairEnfiadas(escalada);

  /// Vídeos e postagens curadas de beta (`escalada.betas` + `urlVideoBeta`).
  List<ItemMidiaBetaVia> get midiasBeta =>
      ExtratorDetalhesTecnicosVia.extrairMidiasBeta(escalada);

  /// Nomes dos conquistadores unidos por vírgula, ou `null` quando ausentes.
  String? get conquistadoresTexto =>
      ExtratorDetalhesTecnicosVia.extrairConquistadores(escalada);

  /// Data de conquista/abertura, quando preenchida.
  String? get dataAbertura =>
      ExtratorDetalhesTecnicosVia.extrairDataAbertura(escalada);

  /// Data da última manutenção registrada, quando preenchida.
  String? get dataManutencao =>
      ExtratorDetalhesTecnicosVia.extrairDataManutencao(escalada);

  /// Indica se há informações de conquista ou manutenção a exibir.
  bool get possuiHistorico =>
      conquistadoresTexto != null ||
      dataAbertura != null ||
      dataManutencao != null;

  /// Chave Pix para apoio à manutenção da via, quando cadastrada.
  String? get chavePixManutencao =>
      ExtratorDetalhesTecnicosVia.extrairChavePix(escalada);

  /// Resolve os mapas, rótulo de linha e itens de carrossel do croqui para a Dumb UI.
  EstadoCroquiVia resolverEstadoCroqui({
    Pico? pico,
    Setor? setor,
    Grupo? grupo,
    DatasetResolver? resolvedorExterno,
  }) {
    return ExtratorDetalhesTecnicosVia.resolverEstadoCroqui(
      escalada: escalada,
      pico: pico,
      setor: setor,
      grupo: grupo,
      resolvedorExterno: resolvedorExterno,
    );
  }

  /// Registra telemetria de navegação para o croqui interativo sem acoplar a UI ao serviço.
  void registrarVisualizacaoCroqui({
    required String cragId,
    String? nomeSetor,
  }) {
    (_telemetria ?? TelemetryService.instance).logAcaoEscalada(
      cragId,
      nomeSetor ?? '',
      nomeEscalada,
      'ver_no_mapa_destaque',
      'detalhes_via',
    );
  }

  /// Serviço de compartilhamento ativo (injetado em testes ou padrão global).
  ServicoCompartilhamento get servicoCompartilhamento =>
      _servicoCompartilhamento ?? ServicoCompartilhamento.instancia;

  /// Constrói o modelo unificado de compartilhamento para a [escalada] atual.
  DadosCartaoCompartilhamento construirDadosCompartilhamento({
    required String cragId,
    Pico? pico,
    Setor? setor,
    Grupo? grupo,
    Croqui? croqui,
    EstadoCroquiVia? estadoCroqui,
    DatasetResolver? resolvedorExterno,
    SeloPessoalCompartilhamento? seloPessoal,
  }) {
    final estado =
        estadoCroqui ??
        resolverEstadoCroqui(
          pico: pico,
          setor: setor,
          grupo: grupo,
          resolvedorExterno: resolvedorExterno,
        );
    return DadosCartaoCompartilhamento.deEscalada(
      idCroqui: cragId,
      escalada: escalada,
      pico: pico,
      setor: setor,
      grupo: grupo,
      croqui: croqui,
      estadoCroqui: estado,
      seloPessoal: seloPessoal,
    );
  }

  /// Compartilha o link profundo da escalada delegando ao [ServicoCompartilhamento].
  Future<void> compartilharEscalada({
    required String cragId,
    String? nomePico,
    String? nomeSetor,
    String? nomeGrupo,
  }) {
    return servicoCompartilhamento.compartilharEscalada(
      idCroqui: cragId,
      uid: escalada.uid,
      nomeEscalada: nomeEscalada,
      grau: obterTextoGrauEscalada(escalada),
      nomeSetor: nomeSetor ?? nomeGrupo ?? 'Geral',
      nomePico: nomePico ?? cragId,
    );
  }

  /// Registra o voto direto do escalador em uma das 5 pílulas de percepção de grau (`-2` a `+2`).
  Future<ResultadoVotoGrauVia> votarGrauComunidade(int delta) async {
    if (!repositorioInteracoes.usuarioEstaAutenticado) {
      return ResultadoVotoGrauVia.requerAutenticacao;
    }
    try {
      await repositorioInteracoes.registrarAvaliacaoAscensao(
        escaladaUid: escalada.uid,
        deltaGrau: delta,
        codigoGrauOficial: codigoGrauOficial,
        ehBoulder: ehBoulder,
      );
      return ResultadoVotoGrauVia.registrado;
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Falha ao registrar voto direto de grau na via ${escalada.uid}',
        error: e,
        stackTrace: stackTrace,
      );
      return ResultadoVotoGrauVia.falha;
    }
  }

  /// Oculta imediatamente [alertaUid] na UI e agenda sua resolução definitiva após [duracaoJanelaDesfazer].
  void iniciarResolucaoAlertaComDesfazer(String alertaUid) {
    _timersResolucaoPendente.remove(alertaUid)?.cancel();
    _timersResolucaoPendente[alertaUid] = Timer(duracaoJanelaDesfazer, () {
      _timersResolucaoPendente.remove(alertaUid);
      unawaited(confirmarAlerta(alertaUid, aindaEstaLa: false));
    });
    _notificar();
  }

  /// Cancela a resolução pendente de [alertaUid], restaurando imediatamente a bolha na UI.
  void desfazerResolucaoAlerta(String alertaUid) {
    final timer = _timersResolucaoPendente.remove(alertaUid);
    if (timer != null) {
      timer.cancel();
      _notificar();
    }
  }

  /// Copia [chavePixManutencao] para a área de transferência do dispositivo.
  Future<bool> copiarChavePix() async {
    final chave = chavePixManutencao;
    if (chave == null) return false;
    await _copiadorAreaTransferencia(chave);
    return true;
  }

  /// Abre uma mídia externa de beta no aplicativo ou navegador correspondente.
  Future<bool> abrirMidiaBeta(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return false;
    }
    return _lancadorUrlExterna(uri);
  }

  /// Edita o texto de um comentário público criado pelo próprio escalador.
  Future<bool> editarComentario(String comentarioUid, String novoTexto) async {
    if (!possuiUid || !repositorioInteracoes.usuarioEstaAutenticado) {
      return false;
    }
    try {
      await repositorioInteracoes.editarComentario(
        escaladaUid: escalada.uid,
        comentarioUid: comentarioUid,
        novoTexto: novoTexto,
      );
      return true;
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Falha ao editar comentário $comentarioUid na via ${escalada.uid}',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Exclui permanentemente um comentário público criado pelo próprio escalador.
  Future<bool> excluirComentario(String comentarioUid) async {
    if (!possuiUid || !repositorioInteracoes.usuarioEstaAutenticado) {
      return false;
    }
    try {
      await repositorioInteracoes.excluirComentario(
        escaladaUid: escalada.uid,
        comentarioUid: comentarioUid,
      );
      return true;
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Falha ao excluir comentário $comentarioUid na via ${escalada.uid}',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Registra um novo alerta de segurança estilo Waze para a escalada atual.
  Future<bool> reportarAlerta(
    CategoriaAlertaSeguranca categoria, {
    String? detalhe,
  }) async {
    try {
      await repositorioInteracoes.reportarAlerta(
        escaladaUid: escalada.uid,
        categoria: categoria,
        detalhe: detalhe,
      );
      return true;
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Falha ao reportar alerta de segurança na via ${escalada.uid}',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Edita a categoria e/ou o detalhe de um alerta de segurança criado pelo próprio escalador.
  Future<bool> editarAlerta(
    String alertaUid,
    CategoriaAlertaSeguranca novaCategoria, {
    String? detalhe,
  }) async {
    if (!possuiUid || !repositorioInteracoes.usuarioEstaAutenticado) {
      return false;
    }
    try {
      await repositorioInteracoes.editarAlerta(
        escaladaUid: escalada.uid,
        alertaUid: alertaUid,
        novaCategoria: novaCategoria,
        detalhe: detalhe,
      );
      return true;
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Falha ao editar alerta $alertaUid na via ${escalada.uid}',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Exclui permanentemente um alerta de segurança criado pelo próprio escalador.
  Future<bool> excluirAlerta(String alertaUid) async {
    if (!possuiUid || !repositorioInteracoes.usuarioEstaAutenticado) {
      return false;
    }
    _timersResolucaoPendente.remove(alertaUid)?.cancel();
    try {
      await repositorioInteracoes.excluirAlerta(
        escaladaUid: escalada.uid,
        alertaUid: alertaUid,
      );
      return true;
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Falha ao excluir alerta $alertaUid na via ${escalada.uid}',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Confirma se um alerta ativo ainda está presente na via ou se já foi resolvido.
  Future<bool> confirmarAlerta(
    String alertaUid, {
    required bool aindaEstaLa,
  }) async {
    try {
      await repositorioInteracoes.confirmarAlerta(
        escaladaUid: escalada.uid,
        alertaUid: alertaUid,
        aindaEstaLa: aindaEstaLa,
      );
      return true;
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Falha ao confirmar alerta de segurança $alertaUid na via ${escalada.uid}',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
