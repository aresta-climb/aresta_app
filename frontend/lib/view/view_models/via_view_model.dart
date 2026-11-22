// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../aresta_api/proto/generated/beta.pb.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../data/modelos/interacao_via.dart';
import '../../services/comunidade/repositorio_interacoes_via.dart';
import '../../services/controlador_interacoes_usuario.dart';
import '../../services/firebase/app_logger.dart';
import '../../utils/formatador_escalada.dart';
import '../../utils/extrator_detalhes_tecnicos_via.dart';

export '../../utils/extrator_detalhes_tecnicos_via.dart';

/// ViewModel (MVVM) responsável pelo estado reativo, comandos de negócio (compartilhamento,
/// Pix, links externos, telemetria de croqui e alertas estilo Waze) e modelos de apresentação
/// imutáveis consumidos pela Dumb UI da `ViaPage`.
class ViaViewModel extends ChangeNotifier {
  /// Escalada Protobuf exibida na página.
  final Escalada escalada;

  /// Repositório reativo de interações comunitárias e alertas de segurança.
  final RepositorioInteracoesVia repositorioInteracoes;

  /// Controlador de visibilidade dos recursos de perfil/comunidade.
  final ControladorInteracoesUsuario controladorInteracoes;

  final Future<void> Function(String texto) _copiadorAreaTransferencia;
  final Future<bool> Function(Uri uri) _lancadorUrlExterna;
  bool _descartado = false;

  /// Cria uma instância de [ViaViewModel].
  ViaViewModel({
    required this.escalada,
    RepositorioInteracoesVia? repositorioInteracoes,
    ControladorInteracoesUsuario? controladorInteracoes,
    Future<void> Function(String texto)? copiadorAreaTransferencia,
    Future<bool> Function(Uri uri)? lancadorUrlExterna,
  }) : repositorioInteracoes =
           repositorioInteracoes ?? RepositorioInteracoesViaMemoria.instancia,
       controladorInteracoes =
           controladorInteracoes ?? ControladorInteracoesUsuario.instancia,
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

  /// Indica se os recursos interativos (alertas Waze, consenso, caderneta e notas) estão ativos.
  bool get exibirRecursosComunidade =>
      controladorInteracoes.exibirElementosInterativos;

  /// Indica se o botão de reportar alerta deve aparecer na barra superior da página.
  bool get podeReportarAlerta => exibirRecursosComunidade && possuiUid;

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

  String? _extrairNomeEnumGrauPrincipal(Escalada alvo) {
    return switch (alvo.whichTipo()) {
      Escalada_Tipo.viaEsportiva => alvo.viaEsportiva.dificuldade.name,
      Escalada_Tipo.viaMovel => alvo.viaMovel.dificuldade.name,
      Escalada_Tipo.boulder => alvo.boulder.dificuldade.name,
      Escalada_Tipo.viaMultiplasEnfiadas =>
        alvo.viaMultiplasEnfiadas.dificuldadeMaxima.name,
      _ => null,
    };
  }

  String? _extrairArtificialFormatado() {
    final nome = switch (escalada.whichTipo()) {
      Escalada_Tipo.viaEsportiva =>
        escalada.viaEsportiva.dificuldadeArtificial.name,
      Escalada_Tipo.viaMovel => escalada.viaMovel.dificuldadeArtificial.name,
      Escalada_Tipo.viaMultiplasEnfiadas =>
        escalada.viaMultiplasEnfiadas.dificuldadeArtificial.name,
      _ => '',
    };
    if (nome.isEmpty || nome.contains('INDEFINIDO')) return null;
    return nome.replaceAll('_MAIS', '+');
  }

  String? _extrairArtificialEmLivreFormatado() {
    final nome = switch (escalada.whichTipo()) {
      Escalada_Tipo.viaMovel =>
        escalada.viaMovel.dificuldadeArtificialEmLivre.name,
      Escalada_Tipo.viaMultiplasEnfiadas =>
        escalada.viaMultiplasEnfiadas.dificuldadeArtificialEmLivre.name,
      _ => '',
    };
    final formatado = formatarTextoGrau(nome);
    return formatado.isNotEmpty ? formatado : null;
  }

  String? _extrairUrlVideoBeta() {
    final url = switch (escalada.whichTipo()) {
      Escalada_Tipo.viaEsportiva => escalada.viaEsportiva.urlVideoBeta.trim(),
      Escalada_Tipo.viaMovel => escalada.viaMovel.urlVideoBeta.trim(),
      Escalada_Tipo.boulder => escalada.boulder.urlVideoBeta.trim(),
      Escalada_Tipo.viaMultiplasEnfiadas =>
        escalada.viaMultiplasEnfiadas.urlVideoBeta.trim(),
      Escalada_Tipo.highline => escalada.highline.urlVideoBeta.trim(),
      Escalada_Tipo.notSet => '',
    };
    return url.isNotEmpty ? url : null;
  }

  static void _adicionarMetros(
    List<AtributoTecnicoVia> itens,
    TipoIconeAtributoVia icone,
    String rotulo,
    int metros,
  ) {
    if (metros > 0) {
      itens.add(
        AtributoTecnicoVia(icone: icone, rotulo: rotulo, valor: '${metros}m'),
      );
    }
  }

  static void _adicionarProtecoes(
    List<AtributoTecnicoVia> itens,
    int intermediarias,
    int parada,
  ) {
    if (intermediarias > 0 || parada > 0) {
      itens.add(
        AtributoTecnicoVia(
          icone: TipoIconeAtributoVia.protecoes,
          rotulo: 'PROTEÇÕES',
          valor: '$intermediarias+$parada',
        ),
      );
    }
  }

  static void _adicionarSePreenchido(
    List<AtributoTecnicoVia> itens,
    TipoIconeAtributoVia icone,
    String rotulo,
    String valor,
  ) {
    if (valor.isNotEmpty) {
      itens.add(AtributoTecnicoVia(icone: icone, rotulo: rotulo, valor: valor));
    }
  }

  static void _adicionarTexto(
    List<SecaoTextoVia> secoes,
    String titulo,
    String conteudo,
    bool ehMarkdown,
  ) {
    final limpo = conteudo.trim();
    if (limpo.isNotEmpty) {
      secoes.add(
        SecaoTextoVia(
          titulo: titulo,
          conteudo: limpo,
          ehMarkdown: ehMarkdown,
        ),
      );
    }
  }

  static String _formatarEnumSimples(String nome) {
    if (nome.isEmpty || nome.contains('INDEFINIDO')) return '';
    final minusculo = nome.replaceAll('_', ' ').toLowerCase();
    return minusculo[0].toUpperCase() + minusculo.substring(1);
  }

  static String _formatarEnumCodigo(String nome) {
    if (nome.isEmpty || nome.contains('INDEFINIDO')) return '';
    return nome;
  }

  static String? _extrairExtensaoEnfiada(Escalada enf) {
    final metros = switch (enf.whichTipo()) {
      Escalada_Tipo.viaEsportiva => enf.viaEsportiva.extensao,
      Escalada_Tipo.viaMovel => enf.viaMovel.extensao,
      _ => 0,
    };
    return metros > 0 ? '${metros}m' : null;
  }

  static String? _extrairProtecoesEnfiada(Escalada enf) {
    final (inter, par) = switch (enf.whichTipo()) {
      Escalada_Tipo.viaEsportiva => (
        enf.viaEsportiva.quantidadeProtecoesIntermediarias,
        enf.viaEsportiva.quantidadeProtecoesParada,
      ),
      Escalada_Tipo.viaMovel => (
        enf.viaMovel.quantidadeProtecoesIntermediarias,
        enf.viaMovel.quantidadeProtecoesParada,
      ),
      _ => (0, 0),
    };
    return (inter > 0 || par > 0) ? '$inter+$par' : null;
  }

  static String? _extrairDescricaoSimples(Escalada enf) {
    final texto = switch (enf.whichTipo()) {
      Escalada_Tipo.viaEsportiva => enf.viaEsportiva.descricao.trim(),
      Escalada_Tipo.viaMovel => enf.viaMovel.descricao.trim(),
      _ => '',
    };
    return texto.isNotEmpty ? texto : null;
  }

  static String _rotuloFonteMidia(FonteMidia_Enum fonte) {
    return switch (fonte) {
      FonteMidia_Enum.YOUTUBE => 'YouTube',
      FonteMidia_Enum.INSTAGRAM => 'Instagram',
      FonteMidia_Enum.BLOG => 'Blog',
      FonteMidia_Enum.TIKTOK => 'TikTok',
      _ => 'Beta',
    };
  }
}
