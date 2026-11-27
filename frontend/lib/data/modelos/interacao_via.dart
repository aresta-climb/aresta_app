// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import '../../idioma/tradutor_app.dart';
import '../../utils/gerador_uid.dart';
import 'perfil_escalador.dart';
import 'tipo_ascensao.dart';

/// Categorias canônicas de alerta de segurança estilo Waze nas vias e setores.
///
/// Espelha exatamente os valores permitidos pela restrição `chk_fila_categoria_alerta`
/// na tabela `public.fila_interacoes` do Supabase, associando a cada categoria o emoji
/// renderizado na bolha vermelha flutuante da `ViaPage`.
enum CategoriaAlertaSeguranca {
  /// Presença de abelhas, marimbondos, cobras, aves em ninho ou outros animais na via.
  fauna(codigoBanco: 'FAUNA', emoji: '🐝'),

  /// Bloco solto, laca oca ou agarra quebrando na linha de escalada.
  rochaAgarraInstavel(codigoBanco: 'ROCHA_AGARRA_INSTAVEL', emoji: '🪨'),

  /// Chapeleta girando, grampo oxidado, porca frouxa ou parada comprometida.
  protecaoPrecaria(codigoBanco: 'PROTECAO_PRECARIA', emoji: '🔩'),

  /// Lance exposto severo (E4+), risco de queda no chão ou proteção distante.
  exposicaoE4Mais(codigoBanco: 'EXPOSICAO_E4_MAIS', emoji: '⚠️');

  /// Identificador textual persistido em `public.fila_interacoes.categoria_alerta`.
  final String codigoBanco;

  /// Emoji exibido dentro da bolha vermelha de alerta na tela da via.
  final String emoji;

  const CategoriaAlertaSeguranca({
    required this.codigoBanco,
    required this.emoji,
  });

  /// Título legível localizado exibido nos modais de confirmação e relato.
  String get rotulo => switch (this) {
    CategoriaAlertaSeguranca.fauna => tr(ChaveTexto.alertaFaunaTitulo),
    CategoriaAlertaSeguranca.rochaAgarraInstavel => tr(
      ChaveTexto.alertaRochaInstavelTitulo,
    ),
    CategoriaAlertaSeguranca.protecaoPrecaria => tr(
      ChaveTexto.alertaProtecaoPrecariaTitulo,
    ),
    CategoriaAlertaSeguranca.exposicaoE4Mais => tr(
      ChaveTexto.alertaExposicaoTitulo,
    ),
  };

  /// Explicação concisa localizada auxiliando o escalador na escolha rápida na base da falésia.
  String get descricaoCurta => switch (this) {
    CategoriaAlertaSeguranca.fauna => tr(ChaveTexto.alertaFaunaDesc),
    CategoriaAlertaSeguranca.rochaAgarraInstavel => tr(
      ChaveTexto.alertaRochaInstavelDesc,
    ),
    CategoriaAlertaSeguranca.protecaoPrecaria => tr(
      ChaveTexto.alertaProtecaoPrecariaDesc,
    ),
    CategoriaAlertaSeguranca.exposicaoE4Mais => tr(
      ChaveTexto.alertaExposicaoDesc,
    ),
  };

  /// Converte o [codigo] proveniente do banco ou YAML na [CategoriaAlertaSeguranca] correspondente.
  static CategoriaAlertaSeguranca deCodigoBanco(String codigo) {
    for (final item in CategoriaAlertaSeguranca.values) {
      if (item.codigoBanco == codigo) {
        return item;
      }
    }
    throw ArgumentError.value(
      codigo,
      'codigo',
      'Categoria de alerta de segurança desconhecida.',
    );
  }
}

/// Papel da contribuição do escalador autenticado sobre um alerta exibido na sua Caderneta.
enum PapelContribuicaoAlerta {
  /// Alerta aberto originalmente pelo próprio escalador.
  criadoPorMim,

  /// Alerta aberto por outro escalador e confirmado (`+1`) pelo usuário atual.
  confirmadoPorMim;

  /// Rótulo localizado em caixa alta exibido no selo visual da `CadernetaPage`.
  String get rotuloSelo => switch (this) {
    PapelContribuicaoAlerta.criadoPorMim => tr(ChaveTexto.alertaCriadoPorVoce),
    PapelContribuicaoAlerta.confirmadoPorMim => tr(
      ChaveTexto.alertaConfirmadoMaisUm,
    ),
  };
}

/// Estado de permissão e deduplicação do usuário atual diante do modal *"Ainda está lá?"*.
enum EstadoInteracaoAlertaUsuario {
  /// Usuário autenticado que ainda não criou nem confirmou este alerta (`+1` liberado).
  podeConfirmar,

  /// Usuário autenticado que criou originalmente este alerta (`+1` bloqueado, resolução liberada).
  criadoPorMim,

  /// Usuário autenticado que já confirmou (`+1`) este alerta (`+1` bloqueado, resolução liberada).
  jaConfirmadoPorMim,

  /// Usuário sem conta autenticada (visualização liberada, ações exigem login no Perfil).
  requerAutenticacao,
}

/// Representa um alerta ativo de segurança estilo Waze vinculado a uma escalada.
///
/// Projetado para ser exibido como uma bolha vermelha compacta no canto superior
/// direito do croqui/cartão de grau e confirmado rapidamente via *"Ainda está lá?"*.
@immutable
class AlertaSegurancaVia {
  /// Limite máximo de caracteres para detalhes opcionais do alerta (`chk_fila_interacoes_payload_por_tipo`).
  static const int limiteCaracteresDetalhe = 100;

  /// Identificador único NanoID 14c do alerta.
  final String uid;

  /// Identificador único NanoID 14c da escalada associada.
  final String escaladaUid;

  /// Categoria semântica do risco reportado.
  final CategoriaAlertaSeguranca categoria;

  /// Observação complementar opcional (máximo de 100 caracteres).
  final String? detalhe;

  /// Identificador público NanoID 14c do perfil que abriu o alerta, quando conhecido.
  final String? autorIdPublico;

  /// Apelido público do escalador que reportou o alerta.
  final String autorNomePublico;

  /// Instante em que o alerta foi registrado.
  final DateTime criadoEm;

  /// Total acumulado de confirmações *"Ainda está lá?"* positivas (1 por perfil).
  final int confirmacoesAtivas;

  /// Conjunto imutável de `autorIdPublico` que já contabilizam confirmação ativa neste alerta.
  final Set<String> confirmadoresUids;

  /// Cria uma instância imutável de [AlertaSegurancaVia].
  const AlertaSegurancaVia({
    required this.uid,
    required this.escaladaUid,
    required this.categoria,
    this.detalhe,
    this.autorIdPublico,
    required this.autorNomePublico,
    required this.criadoEm,
    this.confirmacoesAtivas = 1,
    this.confirmadoresUids = const {},
  });

  /// Fábrica validada que gera um NanoID 14c e normaliza os campos textuais sob filosofia Fail-Fast.
  factory AlertaSegurancaVia.criar({
    String? uid,
    required String escaladaUid,
    required CategoriaAlertaSeguranca categoria,
    String? detalhe,
    String? autorIdPublico,
    String? autorNomePublico,
    DateTime? criadoEm,
    int confirmacoesAtivas = 1,
    Set<String>? confirmadoresUids,
  }) {
    final detalheLimpo = detalhe?.trim();
    if (detalheLimpo != null && detalheLimpo.length > limiteCaracteresDetalhe) {
      throw ArgumentError.value(
        detalheLimpo.length,
        'detalhe',
        'O detalhe do alerta deve ter no máximo $limiteCaracteresDetalhe caracteres.',
      );
    }
    final nomeLimpo = autorNomePublico?.trim();
    final idLimpo = autorIdPublico?.trim();
    final autorIdEfetivo = (idLimpo != null && idLimpo.isNotEmpty)
        ? idLimpo
        : null;
    final conjuntoConfirmadores = <String>{
      if (confirmadoresUids != null)
        ...confirmadoresUids.map((u) => u.trim()).where((u) => u.isNotEmpty),
      ?autorIdEfetivo,
    };

    return AlertaSegurancaVia(
      uid: uid ?? gerarUid(),
      escaladaUid: escaladaUid,
      categoria: categoria,
      detalhe: (detalheLimpo != null && detalheLimpo.isNotEmpty)
          ? detalheLimpo
          : null,
      autorIdPublico: autorIdEfetivo,
      autorNomePublico: (nomeLimpo != null && nomeLimpo.isNotEmpty)
          ? nomeLimpo
          : PerfilEscalador.apelidoPadrao,
      criadoEm: criadoEm ?? DateTime.now(),
      confirmacoesAtivas: confirmacoesAtivas,
      confirmadoresUids: Set.unmodifiable(conjuntoConfirmadores),
    );
  }

  /// Indica se este alerta foi aberto originalmente por [autorId].
  bool foiCriadoPor(String? autorId) {
    final limpo = autorId?.trim();
    return limpo != null && limpo.isNotEmpty && autorIdPublico == limpo;
  }

  /// Indica se [autorId] já contribuiu para este alerta (como criador ou confirmador `+1`).
  bool jaConfirmadoPor(String? autorId) {
    final limpo = autorId?.trim();
    if (limpo == null || limpo.isEmpty) return false;
    return autorIdPublico == limpo || confirmadoresUids.contains(limpo);
  }

  /// Determina o [EstadoInteracaoAlertaUsuario] aplicável ao escalador atual.
  EstadoInteracaoAlertaUsuario resolverEstadoParaUsuario({
    required bool estaAutenticado,
    required String? autorIdPublicoUsuario,
  }) {
    if (!estaAutenticado) {
      return EstadoInteracaoAlertaUsuario.requerAutenticacao;
    }
    if (foiCriadoPor(autorIdPublicoUsuario)) {
      return EstadoInteracaoAlertaUsuario.criadoPorMim;
    }
    if (jaConfirmadoPor(autorIdPublicoUsuario)) {
      return EstadoInteracaoAlertaUsuario.jaConfirmadoPorMim;
    }
    return EstadoInteracaoAlertaUsuario.podeConfirmar;
  }

  /// Retorna uma nova cópia com os campos informados atualizados e validados sob Fail-Fast.
  AlertaSegurancaVia copyWith({
    CategoriaAlertaSeguranca? categoria,
    String? detalhe,
    bool limparDetalhe = false,
    int? confirmacoesAtivas,
    Set<String>? confirmadoresUids,
  }) {
    String? novoDetalhe;
    if (limparDetalhe) {
      novoDetalhe = null;
    } else if (detalhe != null) {
      final limpo = detalhe.trim();
      if (limpo.length > limiteCaracteresDetalhe) {
        throw ArgumentError.value(
          limpo.length,
          'detalhe',
          'O detalhe do alerta deve ter no máximo $limiteCaracteresDetalhe caracteres.',
        );
      }
      novoDetalhe = limpo.isNotEmpty ? limpo : null;
    } else {
      novoDetalhe = this.detalhe;
    }

    return AlertaSegurancaVia(
      uid: uid,
      escaladaUid: escaladaUid,
      categoria: categoria ?? this.categoria,
      detalhe: novoDetalhe,
      autorIdPublico: autorIdPublico,
      autorNomePublico: autorNomePublico,
      criadoEm: criadoEm,
      confirmacoesAtivas: confirmacoesAtivas ?? this.confirmacoesAtivas,
      confirmadoresUids: confirmadoresUids != null
          ? Set.unmodifiable(confirmadoresUids)
          : this.confirmadoresUids,
    );
  }
}

/// Registro consolidado de um alerta criado ou confirmado pelo usuário para acesso rápido na Caderneta.
@immutable
class AlertaContribuidoCaderneta {
  /// Dados do alerta de segurança associado.
  final AlertaSegurancaVia alerta;

  /// Distingue se o alerta foi criado pelo próprio usuário ou confirmado (`+1`) por ele.
  final PapelContribuicaoAlerta papel;

  /// Indica se o alerta segue ativo na rocha (`true`) ou já foi marcado como resolvido (`false`).
  final bool ativo;

  /// Instante da última interação relevante do usuário ou da comunidade sobre este alerta.
  final DateTime ultimaInteracaoEm;

  /// Cria uma instância imutável de [AlertaContribuidoCaderneta].
  const AlertaContribuidoCaderneta({
    required this.alerta,
    required this.papel,
    required this.ativo,
    required this.ultimaInteracaoEm,
  });
}

/// Consolida a percepção democrática da comunidade sobre o grau técnico de uma escalada,
/// coexistindo lado a lado com o grau oficial atribuído pelo conquistador.
@immutable
class ConsensoGrauVia {
  /// Grau sugerido pela mediana/moda dos votos comunitários (ex.: `'7b'`, `'v5'`).
  final String? grauSugerido;

  /// Quantidade total de votos computados para a escalada.
  final int totalVotos;

  /// Contagem de votos por delta relativo ao grau oficial (`-2` a `+2`).
  final Map<int, int> distribuicaoDeltas;

  /// Cria uma instância imutável de [ConsensoGrauVia].
  const ConsensoGrauVia({
    required this.grauSugerido,
    required this.totalVotos,
    this.distribuicaoDeltas = const {},
  });

  /// Representa o estado inicial de uma escalada ainda sem avaliações de grau.
  const ConsensoGrauVia.vazio()
    : grauSugerido = null,
      totalVotos = 0,
      distribuicaoDeltas = const {};

  /// Indica se há ao menos um voto comunitário registrado para exibição estatística.
  bool get possuiVotos =>
      totalVotos > 0 && grauSugerido != null && grauSugerido!.isNotEmpty;

  /// Texto sintético destacando a tendência majoritária (ex.: `'75% sugerem +1'`).
  String? get resumoTendencia {
    if (!possuiVotos || distribuicaoDeltas.isEmpty) {
      return null;
    }
    var deltaDominante = 0;
    var maiorContagem = -1;
    for (final entrada in distribuicaoDeltas.entries) {
      if (entrada.value > maiorContagem) {
        maiorContagem = entrada.value;
        deltaDominante = entrada.key;
      }
    }
    final percentual = ((maiorContagem / totalVotos) * 100).round();
    if (deltaDominante == 0) {
      return tr(ChaveTexto.viaConfirmamGrauPct, {'pct': '$percentual'});
    }
    final sinal = deltaDominante > 0 ? '+$deltaDominante' : '$deltaDominante';
    return tr(ChaveTexto.viaSugeremGrauPct, {
      'pct': '$percentual',
      'sinal': sinal,
    });
  }
}

/// Comentário público de beta, leitura de movimentos ou equipamento deixado na via.
///
/// Desacoplado de dados pessoais privados (LGPD), expondo apenas o `autorIdPublico`
/// (NanoID 14c) e o apelido público do escalador.
@immutable
class ComentarioComunidadeVia {
  /// Limite máximo de caracteres permitido para comentários públicos (`VARCHAR(280)`).
  static const int limiteCaracteres = 280;

  /// Identificador único NanoID 14c do comentário.
  final String uid;

  /// Identificador público NanoID 14c do autor.
  final String autorIdPublico;

  /// Nome ou apelido esportivo exibido junto à nota.
  final String autorNomePublico;

  /// URL pública (`http`/`https`) ou Data URI opcional da foto de perfil do autor.
  final String? autorAvatarUrl;

  /// Data e hora de publicação do comentário.
  final DateTime criadoEm;

  /// Estilo esportivo da ascensão associada ao comentário, quando informado.
  final TipoAscensao? estiloAscensao;

  /// Conteúdo textual validado e sem espaços excedentes nas extremidades.
  final String texto;

  /// Cria uma instância validada de [ComentarioComunidadeVia].
  ComentarioComunidadeVia({
    required this.uid,
    required this.autorIdPublico,
    required this.autorNomePublico,
    String? autorAvatarUrl,
    required this.criadoEm,
    this.estiloAscensao,
    required String texto,
  }) : autorAvatarUrl = _normalizarAvatar(autorAvatarUrl),
       texto = _validarTexto(texto);

  static String? _normalizarAvatar(String? bruto) {
    final limpo = bruto?.trim();
    return (limpo != null && limpo.isNotEmpty) ? limpo : null;
  }

  static String _validarTexto(String bruto) {
    final limpo = bruto.trim();
    if (limpo.isEmpty || limpo.length > limiteCaracteres) {
      throw ArgumentError.value(
        bruto,
        'texto',
        'O comentário deve conter entre 1 e $limiteCaracteres caracteres.',
      );
    }
    return limpo;
  }

  /// Selo visual em caixa alta do estilo esportivo (destacando À Vista e Flash com `★`).
  String? get rotuloEstilo {
    final estilo = estiloAscensao;
    if (estilo == null) return null;
    final textoCaixaAlta = estilo.rotulo.toUpperCase();
    final mereceEstrela =
        estilo == TipoAscensao.aVista || estilo == TipoAscensao.flash;
    return mereceEstrela ? '$textoCaixaAlta ★' : textoCaixaAlta;
  }

  /// Indica se este comentário foi publicado originalmente por [autorId].
  bool foiCriadoPor(String? autorId) {
    final limpo = autorId?.trim();
    return limpo != null && limpo.isNotEmpty && autorIdPublico == limpo;
  }

  /// Retorna uma cópia imutável atualizando e validando [texto] (`1..280` caracteres).
  ComentarioComunidadeVia copyWith({String? texto}) {
    return ComentarioComunidadeVia(
      uid: uid,
      autorIdPublico: autorIdPublico,
      autorNomePublico: autorNomePublico,
      autorAvatarUrl: autorAvatarUrl,
      criadoEm: criadoEm,
      estiloAscensao: estiloAscensao,
      texto: texto ?? this.texto,
    );
  }
}

/// Agregado imutável com todos os dados comunitários e de segurança de uma escalada.
@immutable
class DadosComunidadeVia {
  /// Estatística consolidada de avaliação de grau da comunidade.
  final ConsensoGrauVia consensoGrau;

  /// Lista de alertas de segurança estilo Waze atualmente ativos na via.
  final List<AlertaSegurancaVia> alertasAtivos;

  /// Lista cronológica reversa de notas e betas públicos da comunidade.
  final List<ComentarioComunidadeVia> comentarios;

  /// Cria uma instância imutável de [DadosComunidadeVia].
  const DadosComunidadeVia({
    this.consensoGrau = const ConsensoGrauVia.vazio(),
    this.alertasAtivos = const [],
    this.comentarios = const [],
  });

  /// Estado comunitário vazio padrão quando não há interações registradas.
  const DadosComunidadeVia.vazio()
    : consensoGrau = const ConsensoGrauVia.vazio(),
      alertasAtivos = const [],
      comentarios = const [];

  /// Retorna uma nova instância substituindo seletivamente os campos desejados.
  DadosComunidadeVia copyWith({
    ConsensoGrauVia? consensoGrau,
    List<AlertaSegurancaVia>? alertasAtivos,
    List<ComentarioComunidadeVia>? comentarios,
  }) {
    return DadosComunidadeVia(
      consensoGrau: consensoGrau ?? this.consensoGrau,
      alertasAtivos: alertasAtivos ?? this.alertasAtivos,
      comentarios: comentarios ?? this.comentarios,
    );
  }

  /// Edita o comentário [comentarioUid] exigindo autoria de [autorIdPublico] sob Fail-Fast.
  DadosComunidadeVia comComentarioEditado({
    required String comentarioUid,
    required String autorIdPublico,
    required String novoTexto,
  }) {
    final idx = comentarios.indexWhere((c) => c.uid == comentarioUid.trim());
    if (idx < 0) {
      throw StateError('Comentário $comentarioUid não encontrado nesta via.');
    }
    final alvo = comentarios[idx];
    if (!alvo.foiCriadoPor(autorIdPublico)) {
      throw StateError('Apenas o próprio autor pode editar este comentário.');
    }
    final lista = List<ComentarioComunidadeVia>.from(comentarios);
    lista[idx] = alvo.copyWith(texto: novoTexto);
    return copyWith(comentarios: List.unmodifiable(lista));
  }

  /// Remove o comentário [comentarioUid] exigindo autoria de [autorIdPublico] sob Fail-Fast.
  DadosComunidadeVia semComentarioDoAutor({
    required String comentarioUid,
    required String autorIdPublico,
  }) {
    final idx = comentarios.indexWhere((c) => c.uid == comentarioUid.trim());
    if (idx < 0) {
      throw StateError('Comentário $comentarioUid não encontrado nesta via.');
    }
    if (!comentarios[idx].foiCriadoPor(autorIdPublico)) {
      throw StateError('Apenas o próprio autor pode excluir este comentário.');
    }
    final lista = List<ComentarioComunidadeVia>.from(comentarios)..removeAt(idx);
    return copyWith(comentarios: List.unmodifiable(lista));
  }

  /// Edita a categoria e/ou detalhe de [alertaUid] exigindo autoria de [autorIdPublico].
  (DadosComunidadeVia, AlertaSegurancaVia) comAlertaEditado({
    required String alertaUid,
    required String autorIdPublico,
    required CategoriaAlertaSeguranca novaCategoria,
    String? detalhe,
  }) {
    final idx = alertasAtivos.indexWhere((a) => a.uid == alertaUid.trim());
    if (idx < 0) {
      throw StateError('Alerta $alertaUid não encontrado nesta via.');
    }
    final alvo = alertasAtivos[idx];
    if (!alvo.foiCriadoPor(autorIdPublico)) {
      throw StateError('Apenas o próprio autor pode editar este alerta.');
    }
    final conflitoCategoria = alertasAtivos.any(
      (a) => a.uid != alvo.uid && a.categoria == novaCategoria,
    );
    if (conflitoCategoria) {
      throw StateError(
        'Já existe um alerta ativo na categoria ${novaCategoria.rotulo} nesta via.',
      );
    }
    final detalheLimpo = detalhe?.trim();
    final atualizado = alvo.copyWith(
      categoria: novaCategoria,
      detalhe: detalheLimpo,
      limparDetalhe: detalheLimpo == null || detalheLimpo.isEmpty,
    );
    final lista = List<AlertaSegurancaVia>.from(alertasAtivos);
    lista[idx] = atualizado;
    return (copyWith(alertasAtivos: List.unmodifiable(lista)), atualizado);
  }

  /// Remove o alerta [alertaUid] exigindo autoria de [autorIdPublico] sob Fail-Fast.
  DadosComunidadeVia semAlertaDoAutor({
    required String alertaUid,
}
