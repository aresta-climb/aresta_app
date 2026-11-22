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

  /// Modalidade formatada em português (`'Esportiva'`, `'Móvel'`, `'Mista'`, `'Boulder'`, `'Multienfiada'`, `'Highline'`).
  String get modalidade {
    switch (escalada.whichTipo()) {
      case Escalada_Tipo.viaEsportiva:
        return 'Esportiva';
      case Escalada_Tipo.viaMovel:
        return escalada.viaMovel.quantidadeProtecoesIntermediarias > 0
            ? 'Mista'
            : 'Móvel';
      case Escalada_Tipo.boulder:
        return 'Boulder';
      case Escalada_Tipo.viaMultiplasEnfiadas:
        return escalada.viaMultiplasEnfiadas.tipoViaMultiplasEnfiadas ==
                ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas.MISTA
            ? 'Mista'
            : 'Multienfiada';
      case Escalada_Tipo.highline:
        return 'Highline';
      case Escalada_Tipo.notSet:
        return '';
    }
  }

  /// Grau oficial formatado (ou `'Projeto'`), retornando `null` quando indefinido ou em highline.
  String? get grauOficialExibicao {
    final bruto = _extrairNomeEnumGrauPrincipal(escalada);
    if (bruto == null || bruto.isEmpty || bruto.contains('INDEFINIDO')) {
      return null;
    }
    if (bruto == 'PROJETO') {
      return 'Projeto';
    }
    final formatado = formatarTextoGrau(bruto);
    return formatado.isNotEmpty ? formatado : null;
  }

  /// Linha complementar abaixo do grau oficial (grau médio em multienfiadas e artificial).
  String get complementoGrauOficial {
    final partes = <String>[];
    if (escalada.whichTipo() == Escalada_Tipo.viaMultiplasEnfiadas) {
      final media = formatarTextoGrau(
        escalada.viaMultiplasEnfiadas.dificuldadeMedia.name,
      );
      if (media.isNotEmpty && media != 'projeto') {
        partes.add('Média $media');
      }
    }
    final artificial = _extrairArtificialFormatado();
    if (artificial != null) {
      final livre = _extrairArtificialEmLivreFormatado();
      partes.add(
        livre != null
            ? 'Artificial $artificial ($livre em livre)'
            : 'Artificial $artificial',
      );
    }
    return partes.isEmpty ? 'Guia Oficial / Conquistador' : partes.join(' • ');
  }

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

  /// Lista de alertas de segurança estilo Waze ativos para renderização das bolhas vermelhas flutuantes.
  List<AlertaSegurancaVia> get alertasAtivos {
    if (!exibirRecursosComunidade || !possuiUid) {
      return const [];
    }
    return repositorioInteracoes.obterDadosEscalada(escalada.uid).alertasAtivos;
  }

  /// Lista de comentários e notas de beta públicas da comunidade.
  List<ComentarioComunidadeVia> get comentariosComunidade {
    if (!exibirRecursosComunidade || !possuiUid) {
      return const [];
    }
    return repositorioInteracoes.obterDadosEscalada(escalada.uid).comentarios;
  }

  /// Tipo de ancoragem/parada da via, quando informado.
  String? get tipoAncoragem {
    final texto = switch (escalada.whichTipo()) {
      Escalada_Tipo.viaEsportiva => escalada.viaEsportiva.tipoAncoragem.trim(),
      Escalada_Tipo.viaMovel => escalada.viaMovel.tipoAncoragem.trim(),
      _ => '',
    };
    return texto.isNotEmpty ? texto : null;
  }

  /// Lista enxuta e sem duplicações dos atributos técnicos específicos da modalidade.
  List<AtributoTecnicoVia> get atributosTecnicos {
    final itens = <AtributoTecnicoVia>[];
    switch (escalada.whichTipo()) {
      case Escalada_Tipo.viaEsportiva:
        final v = escalada.viaEsportiva;
        _adicionarMetros(itens, TipoIconeAtributoVia.extensao, 'EXTENSÃO', v.extensao);
        _adicionarProtecoes(
          itens,
          v.quantidadeProtecoesIntermediarias,
          v.quantidadeProtecoesParada,
        );
        _adicionarSePreenchido(
          itens,
          TipoIconeAtributoVia.parede,
          'PAREDE',
          _formatarEnumSimples(v.tipoParede.name),
        );
        _adicionarSePreenchido(
          itens,
          TipoIconeAtributoVia.exposicao,
          'EXPOSIÇÃO',
          _formatarEnumCodigo(v.exposicao.name),
        );
      case Escalada_Tipo.viaMovel:
        final v = escalada.viaMovel;
        _adicionarMetros(itens, TipoIconeAtributoVia.extensao, 'EXTENSÃO', v.extensao);
        _adicionarProtecoes(
          itens,
          v.quantidadeProtecoesIntermediarias,
          v.quantidadeProtecoesParada,
        );
        _adicionarSePreenchido(
          itens,
          TipoIconeAtributoVia.parede,
          'PAREDE',
          _formatarEnumSimples(v.tipoParede.name),
        );
        _adicionarSePreenchido(
          itens,
          TipoIconeAtributoVia.exposicao,
          'EXPOSIÇÃO',
          _formatarEnumCodigo(v.exposicao.name),
        );
      case Escalada_Tipo.boulder:
        _adicionarSePreenchido(
          itens,
          TipoIconeAtributoVia.parede,
          'PAREDE',
          _formatarEnumSimples(escalada.boulder.tipoParede.name),
        );
      case Escalada_Tipo.viaMultiplasEnfiadas:
        final v = escalada.viaMultiplasEnfiadas;
        if (v.numeroEnfiadas > 0) {
          itens.add(
            AtributoTecnicoVia(
              icone: TipoIconeAtributoVia.enfiadas,
              rotulo: 'ENFIADAS',
              valor: '${v.numeroEnfiadas}',
            ),
          );
        }
        _adicionarMetros(
          itens,
          TipoIconeAtributoVia.extensao,
          'COMPRIMENTO',
          v.comprimentoTotal,
        );
        _adicionarMetros(
          itens,
          TipoIconeAtributoVia.distancia,
          'MAIOR ENFIADA',
          v.comprimentoMaiorEnfiada,
        );
        _adicionarProtecoes(
          itens,
          v.quantidadeCosturasIntermediarias,
          v.quantidadeEquipamentosParada,
        );
        _adicionarSePreenchido(
          itens,
          TipoIconeAtributoVia.duracao,
          'DURAÇÃO',
          _formatarEnumCodigo(v.duracao.name),
        );
        _adicionarSePreenchido(
          itens,
          TipoIconeAtributoVia.exposicao,
          'EXPOSIÇÃO',
          _formatarEnumCodigo(v.exposicao.name),
        );
        _adicionarSePreenchido(
          itens,
          TipoIconeAtributoVia.modalidade,
          'TIPO',
          _formatarEnumSimples(v.tipoViaMultiplasEnfiadas.name),
        );
      case Escalada_Tipo.highline:
        final v = escalada.highline;
        _adicionarMetros(itens, TipoIconeAtributoVia.distancia, 'DISTÂNCIA', v.distancia);
        _adicionarMetros(itens, TipoIconeAtributoVia.extensao, 'ALTURA', v.altura);
        if (v.exposicao > 0) {
          itens.add(
            AtributoTecnicoVia(
              icone: TipoIconeAtributoVia.exposicao,
              rotulo: 'EXPOSIÇÃO',
              valor: '${v.exposicao}',
            ),
          );
        }
      case Escalada_Tipo.notSet:
        break;
    }
    return List.unmodifiable(itens);
  }

  /// Seções textuais e de equipamento recomendadas para a escalada.
  List<SecaoTextoVia> get secoesTexto {
    final secoes = <SecaoTextoVia>[];
    switch (escalada.whichTipo()) {
      case Escalada_Tipo.viaEsportiva:
        _adicionarTexto(secoes, 'Descrição', escalada.viaEsportiva.descricao, true);
      case Escalada_Tipo.viaMovel:
        _adicionarTexto(secoes, 'Descrição', escalada.viaMovel.descricao, true);
        _adicionarTexto(
          secoes,
          'Peças Móveis',
          escalada.viaMovel.protecoesMoveis,
          false,
        );
      case Escalada_Tipo.boulder:
        _adicionarTexto(secoes, 'Descrição', escalada.boulder.descricao, true);
      case Escalada_Tipo.viaMultiplasEnfiadas:
        _adicionarTexto(
          secoes,
          'Descrição',
          escalada.viaMultiplasEnfiadas.descricao,
          true,
        );
        _adicionarTexto(
          secoes,
          'Rack & Equipamento',
          escalada.viaMultiplasEnfiadas.equipamentoRecomendado,
          false,
        );
      case Escalada_Tipo.highline:
        _adicionarTexto(
          secoes,
          'Descrição do Acesso',
          escalada.highline.descricaoAcesso,
          true,
        );
        _adicionarTexto(
          secoes,
          'Descrição da Ancoragem',
          escalada.highline.descricaoAncoragem,
          true,
        );
        _adicionarTexto(secoes, 'Descrição', escalada.highline.descricao, true);
      case Escalada_Tipo.notSet:
        break;
    }
    return List.unmodifiable(secoes);
  }

  /// Lista estruturada das enfiadas em vias de múltiplas enfiadas.
  List<ResumoEnfiadaVia> get enfiadas {
    if (escalada.whichTipo() != Escalada_Tipo.viaMultiplasEnfiadas) {
      return const [];
    }
    final brutas = escalada.viaMultiplasEnfiadas.enfiadas;
    final resultado = <ResumoEnfiadaVia>[];
    for (var i = 0; i < brutas.length; i++) {
      final enf = brutas[i];
      final numero = i + 1;
      final nome = obterNomeEscalada(enf, padrao: '').trim();
      final titulo = nome.isNotEmpty ? 'Enfiada $numero • $nome' : 'Enfiada $numero';
      final grau = obterTextoGrauEscalada(enf);
      resultado.add(
        ResumoEnfiadaVia(
          numero: numero,
          titulo: titulo,
          grau: grau.isNotEmpty ? grau : null,
          extensao: _extrairExtensaoEnfiada(enf),
          protecoes: _extrairProtecoesEnfiada(enf),
          equipamentoMovel: enf.whichTipo() == Escalada_Tipo.viaMovel &&
                  enf.viaMovel.protecoesMoveis.trim().isNotEmpty
              ? enf.viaMovel.protecoesMoveis.trim()
              : null,
          descricao: _extrairDescricaoSimples(enf),
        ),
      );
    }
    return List.unmodifiable(resultado);
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
