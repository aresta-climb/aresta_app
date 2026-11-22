// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../data/modelos/interacao_via.dart';
import '../../services/compartilhamento/servico_compartilhamento.dart';
import '../../services/comunidade/repositorio_interacoes_via.dart';
import '../../services/controlador_interacoes_usuario.dart';
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

  /// Controlador de visibilidade dos recursos de perfil/comunidade.
  final ControladorInteracoesUsuario controladorInteracoes;

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
    ControladorInteracoesUsuario? controladorInteracoes,
    ServicoCompartilhamento? servicoCompartilhamento,
    TelemetryService? telemetria,
    Future<void> Function(String texto)? copiadorAreaTransferencia,
    Future<bool> Function(Uri uri)? lancadorUrlExterna,
    this.duracaoJanelaDesfazer = const Duration(seconds: 4),
  }) : repositorioInteracoes =
           repositorioInteracoes ?? RepositorioInteracoesViaMemoria.instancia,
       controladorInteracoes =
           controladorInteracoes ?? ControladorInteracoesUsuario.instancia,
       _servicoCompartilhamento = servicoCompartilhamento,
       _telemetria = telemetria,
       _copiadorAreaTransferencia =
           copiadorAreaTransferencia ??
           ((texto) => Clipboard.setData(ClipboardData(text: texto))),
       _lancadorUrlExterna =
           lancadorUrlExterna ??
           ((uri) => launchUrl(uri, mode: LaunchMode.externalApplication)) {
    this.repositorioInteracoes.alteracoesListenable.addListener(_notificar);
    this.controladorInteracoes.interacoesAtivasNotifier.addListener(
      _aoMudarVisibilidadeInteracoes,
    );
    _sincronizarInteracoesSeAtivo();
  }

  void _aoMudarVisibilidadeInteracoes() {
    _sincronizarInteracoesSeAtivo();
    _notificar();
  }

  void _sincronizarInteracoesSeAtivo() {
    if (!exibirRecursosComunidade || !possuiUid) return;
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
    repositorioInteracoes.alteracoesListenable.removeListener(_notificar);
    controladorInteracoes.interacoesAtivasNotifier.removeListener(
      _aoMudarVisibilidadeInteracoes,
    );
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

  /// Indica se os recursos interativos (alertas Waze, consenso, caderneta e betas) estão ativos.
  bool get exibirRecursosComunidade =>
      controladorInteracoes.exibirElementosInterativos;

  /// Indica se o botão de reportar alerta deve aparecer na barra superior da página.
  bool get podeReportarAlerta => exibirRecursosComunidade && possuiUid;

  /// Modalidade formatada em português (`'Esportiva'`, `'Móvel'`, `'Mista'`, `'Boulder'`, `'Multienfiada'`, `'Highline'`).
  String get modalidade => ExtratorDetalhesTecnicosVia.extrairModalidade(escalada);

  /// Indica se a linha é marcada como clássica/destaque do setor.
  bool get ehDestaque => ExtratorDetalhesTecnicosVia.extrairDestaque(escalada);

  /// Rótulo do bloco de grau oficial do conquistador.
  String get rotuloGrauOficial =>
      escalada.whichTipo() == Escalada_Tipo.viaMultiplasEnfiadas
      ? 'GRAU MÁXIMO'
      : 'GRAU OFICIAL';

  /// Grau oficial formatado (ou `'Projeto'`), retornando `null` quando indefinido ou em highline.
  String? get grauOficialExibicao =>
      ExtratorDetalhesTecnicosVia.extrairGrauOficialExibicao(escalada);

  /// Linha complementar abaixo do grau oficial (grau médio em multienfiadas e artificial).
  String get complementoGrauOficial =>
      ExtratorDetalhesTecnicosVia.extrairComplementoGrauOficial(escalada);

  /// Indica se o cartão comparativo de grau deve ser exibido na tela.
  bool get exibirCartaoGrau =>
      !ehHighline &&
      (grauOficialExibicao != null || (exibirRecursosComunidade && possuiUid));

  /// Consenso democrático de grau da comunidade (exposto apenas quando [exibirRecursosComunidade] está ativo).
  ConsensoGrauVia? get consensoGrau {
    if (!exibirRecursosComunidade || ehHighline || !possuiUid) {
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
    if (!exibirRecursosComunidade || !possuiUid) {
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
    if (!exibirRecursosComunidade || !possuiUid) {
      return const [];
    }
    return repositorioInteracoes.obterDadosEscalada(escalada.uid).comentarios;
  }

  /// Betas públicos pré-formatados com autor, data e estilo prontos para a Dumb UI.
  List<NotaComunidadeApresentacao> get notasComunidadeApresentacao =>
      ExtratorDetalhesTecnicosVia.formatarNotasComunidade(comentariosComunidade);

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

  /// Compartilha o link profundo da escalada delegando ao [ServicoCompartilhamento].
  Future<void> compartilharEscalada({
    required String cragId,
    String? nomePico,
    String? nomeSetor,
    String? nomeGrupo,
  }) {
    final servico = _servicoCompartilhamento ?? ServicoCompartilhamento.instancia;
    return servico.compartilharEscalada(
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
