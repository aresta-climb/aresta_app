// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../idioma/tradutor_app.dart';
import '../../services/compartilhamento/servico_compartilhamento.dart';
import '../../services/repositorio_dataset.dart';
import '../../utils/extrator_detalhes_tecnicos_via.dart';
import '../../utils/formatador_escalada.dart';
import '../../view/function_library/via_functions.dart';

/// Tipos de entidades suportadas pelo fluxo unificado de compartilhamento.
enum TipoEntidadeCompartilhavel {
  pico('pico'),
  grupo('grupo'),
  setor('setor'),
  via('via');

  /// Código canônico enviado na telemetria e na geração de nomes de arquivo.
  final String codigoTelemetria;

  const TipoEntidadeCompartilhavel(this.codigoTelemetria);
}

/// Selo esportivo pessoal opcional exibido no cartão de uma escalada compartilhada.
///
/// Por design, não armazena notas privadas da caderneta para impedir qualquer
/// exposição acidental de anotações pessoais nos Stories.
@immutable
class SeloPessoalCompartilhamento {
  /// Indica se a melhor ascensão registrada é uma cadena completa (`true`) ou tentativa (`false`).
  final bool ehCadena;

  /// Texto resumido pré-formatado (ex.: `'Encadenada em 14/09 (Flash)'`).
  final String textoResumo;

  /// Cria uma instância imutável de [SeloPessoalCompartilhamento].
  const SeloPessoalCompartilhamento({
    required this.ehCadena,
    required this.textoResumo,
  });
}

/// Modelo de apresentação imutável e unificado que alimenta o cartão visual editorial
/// e o compartilhamento de link rápido para Pico, Grupo, Setor ou Escalada.
@immutable
class DadosCartaoCompartilhamento {
  /// Tipo semântico da entidade compartilhada.
  final TipoEntidadeCompartilhavel tipoEntidade;

  /// Identificador do croqui (`id_slug`).
  final String idCroqui;

  /// Identificador universal (NanoID 14c) usado na URL curta `aresta.cc/s/<uid>`.
  final String uid;

  /// Título principal exibido no cartão.
  final String titulo;

  /// Subtítulo contextual de localização (ex.: `'Pedra Grande • Setor Principal'`).
  final String subtituloLocalizacao;

  /// Etiqueta de categoria em caixa alta exibida no topo do cartão.
  final String etiquetaCategoria;

  /// Graduação em destaque à direita do título (apenas para escaladas com grau definido).
  final String? grauDestaque;

  /// Indica se a via compartilhada é clássica/destaque do setor.
  final bool ehClassica;

  /// Lista compacta de chips de resumo técnico ou estatístico.
  final List<String> chipsResumo;

  /// Selo pessoal de cadena ou tentativa, quando aplicável.
  final SeloPessoalCompartilhamento? seloPessoal;

  /// Caminho relativo ou URL da imagem heroica resolvida em cascata.
  final String? caminhoImagemHeroi;

  /// Rótulo identificador da linha no croqui (ex.: `'4'`), quando disponível.
  final String? rotuloLinhaNoMapa;

  /// Nome legível do pico associado, usado na formatação da mensagem de link.
  final String nomePico;

  /// Nome do grupo associado, quando aplicável.
  final String? nomeGrupo;

  /// Nome do setor associado, quando aplicável.
  final String? nomeSetor;

  /// Localização textual do pico (ex.: `'Igarapé - MG'`), quando aplicável.
  final String? localizacaoPico;

  /// Cria uma instância imutável de [DadosCartaoCompartilhamento].
  const DadosCartaoCompartilhamento({
    required this.tipoEntidade,
    required this.idCroqui,
    required this.uid,
    required this.titulo,
    required this.subtituloLocalizacao,
    required this.etiquetaCategoria,
    required this.nomePico,
    this.grauDestaque,
    this.ehClassica = false,
    this.chipsResumo = const [],
    this.seloPessoal,
    this.caminhoImagemHeroi,
    this.rotuloLinhaNoMapa,
    this.nomeGrupo,
    this.nomeSetor,
    this.localizacaoPico,
  });

  /// Constrói os dados de compartilhamento para um **Pico/Croqui**.
  factory DadosCartaoCompartilhamento.dePico({
    required String idCroqui,
    required Croqui croqui,
    required Pico pico,
  }) {
    final nomePico = ServicoCompartilhamento.resolverNomeCroqui(
      idCroqui,
      nomePreferencial: pico.nome,
    );
    var totalSetores = 0;
    final todasEscaladas = <Escalada>[];
    for (final sg in pico.setoresOuGrupos) {
      if (sg.whichTipo() == SetorOuGrupo_Tipo.setor &&
          sg.setor.hasConteudo()) {
        totalSetores++;
        todasEscaladas.addAll(sg.setor.conteudo.escaladas);
      } else if (sg.whichTipo() == SetorOuGrupo_Tipo.grupo &&
          sg.grupo.hasConteudo()) {
        for (final sec in sg.grupo.conteudo.setores) {
          if (sec.hasConteudo()) {
            totalSetores++;
            todasEscaladas.addAll(sec.conteudo.escaladas);
          }
        }
      }
    }

    final chips = <String>[
      if (totalSetores > 0) _formatarContagemSetores(totalSetores),
      if (todasEscaladas.isNotEmpty)
        _formatarContagemEscaladas(todasEscaladas.length),
      ..._resumirModalidades(todasEscaladas),
    ];

    final thumbCroqui = croqui.caminhoThumbnail.trim();
    final imagemMapaGeral = pico.hasMapasGerais() &&
            pico.mapasGerais.hasConteudo()
        ? _primeiroCaminhoMapaValido(pico.mapasGerais.conteudo.mapas)
        : null;

    return DadosCartaoCompartilhamento(
      tipoEntidade: TipoEntidadeCompartilhavel.pico,
      idCroqui: idCroqui,
      uid: croqui.uid,
      titulo: nomePico,
      subtituloLocalizacao: pico.estado.trim(),
      etiquetaCategoria: tr(ChaveTexto.shareCardTipoPico),
      nomePico: nomePico,
      localizacaoPico: pico.estado.trim().isNotEmpty ? pico.estado.trim() : null,
      chipsResumo: List.unmodifiable(chips.take(4)),
      caminhoImagemHeroi: thumbCroqui.isNotEmpty ? thumbCroqui : imagemMapaGeral,
    );
  }

  /// Constrói os dados de compartilhamento para um **Grupo** de setores.
  factory DadosCartaoCompartilhamento.deGrupo({
    required String idCroqui,
    required Grupo grupo,
    Croqui? croqui,
    String? nomePicoPreferencial,
  }) {
    final nomePico = ServicoCompartilhamento.resolverNomeCroqui(
      idCroqui,
      nomePreferencial: nomePicoPreferencial ??
          (croqui != null && croqui.picos.isNotEmpty
              ? croqui.picos.first.nome
              : null),
    );
    final setores = grupo.setores
        .where((s) => s.hasConteudo())
        .map((s) => s.conteudo)
        .toList(growable: false);
    final todasEscaladas = setores
        .expand((s) => s.escaladas)
        .toList(growable: false);

    final chips = <String>[
      if (setores.isNotEmpty) _formatarContagemSetores(setores.length),
      if (todasEscaladas.isNotEmpty)
        _formatarContagemEscaladas(todasEscaladas.length),
      ..._resumirModalidades(todasEscaladas),
    ];

    final imagemGrupo = _resolverImagemGrupo(grupo) ??
        _resolverImagemSetores(setores) ??
        _resolverThumbnailCroqui(idCroqui, croqui: croqui);

    return DadosCartaoCompartilhamento(
      tipoEntidade: TipoEntidadeCompartilhavel.grupo,
      idCroqui: idCroqui,
      uid: grupo.uid,
      titulo: grupo.nome.trim(),
      subtituloLocalizacao: nomePico,
      etiquetaCategoria: tr(ChaveTexto.shareCardTipoGrupo),
      nomePico: nomePico,
      nomeGrupo: grupo.nome.trim(),
      chipsResumo: List.unmodifiable(chips.take(4)),
      caminhoImagemHeroi: imagemGrupo,
    );
  }

  /// Constrói os dados de compartilhamento para um **Setor**.
  factory DadosCartaoCompartilhamento.deSetor({
    required String idCroqui,
    required Setor setor,
    Grupo? grupoContext,
    Croqui? croqui,
    String? nomePicoPreferencial,
  }) {
    final nomePico = ServicoCompartilhamento.resolverNomeCroqui(
      idCroqui,
      nomePreferencial: nomePicoPreferencial,
    );
    final nomeGrupoLimpo = grupoContext?.nome.trim() ?? '';
    final subtitulo = nomeGrupoLimpo.isNotEmpty
        ? '$nomePico • $nomeGrupoLimpo'
        : nomePico;

    final faixaGraus = _calcularFaixaGraus(setor.escaladas);
    final chips = <String>[
      if (setor.escaladas.isNotEmpty)
        _formatarContagemEscaladas(setor.escaladas.length),
      if (faixaGraus != null)
        tr(ChaveTexto.shareCardFaixaGraus, {'faixa': faixaGraus}),
      ..._resumirModalidades(setor.escaladas),
    ];

    final imagemSetor = _resolverImagemSetor(setor) ??
        (grupoContext != null ? _resolverImagemGrupo(grupoContext) : null) ??
        _resolverThumbnailCroqui(idCroqui, croqui: croqui);

    return DadosCartaoCompartilhamento(
      tipoEntidade: TipoEntidadeCompartilhavel.setor,
      idCroqui: idCroqui,
      uid: setor.uid,
      titulo: setor.nome.trim(),
      subtituloLocalizacao: subtitulo,
      etiquetaCategoria: tr(ChaveTexto.shareCardTipoSetor),
      nomePico: nomePico,
      nomeGrupo: nomeGrupoLimpo.isNotEmpty ? nomeGrupoLimpo : null,
      nomeSetor: setor.nome.trim(),
      chipsResumo: List.unmodifiable(chips.take(4)),
      caminhoImagemHeroi: imagemSetor,
    );
  }

  /// Constrói os dados de compartilhamento para uma **Escalada** (Via, Boulder ou Highline).
  factory DadosCartaoCompartilhamento.deEscalada({
    required String idCroqui,
    required Escalada escalada,
    Pico? pico,
    Setor? setor,
    Grupo? grupo,
    Croqui? croqui,
    EstadoCroquiVia? estadoCroqui,
    SeloPessoalCompartilhamento? seloPessoal,
  }) {
    final nomePico = ServicoCompartilhamento.resolverNomeCroqui(
      idCroqui,
      nomePreferencial: pico?.nome,
    );
    final nomeSetorBruto = (setor?.nome ?? grupo?.nome ?? 'Geral').trim();
    final temSetorEspecifico =
        nomeSetorBruto.isNotEmpty && nomeSetorBruto.toLowerCase() != 'geral';
    final subtitulo = temSetorEspecifico
        ? '$nomePico • $nomeSetorBruto'
        : nomePico;

    final modalidade = ExtratorDetalhesTecnicosVia.extrairModalidade(escalada);
    final categoria = modalidade.isNotEmpty
        ? modalidade.toUpperCase()
        : tr(ChaveTexto.navExplorar).toUpperCase();

    final chips = <String>[];
    for (final atributo in ExtratorDetalhesTecnicosVia.extrairAtributosTecnicos(escalada)) {
      if (chips.length >= 3) break;
      chips.add(atributo.valor);
    }
    final ancoragem = ExtratorDetalhesTecnicosVia.extrairTipoAncoragem(escalada);
    if (ancoragem != null && chips.length < 4) {
      chips.add(ancoragem);
    }

    final caminhoMapaHeroi = estadoCroqui != null
        ? _primeiroCaminhoMapaValido(estadoCroqui.mapasMiniatura)
        : _primeiroCaminhoMapaValido(escalada.mapas);

    final caminhoImagem = caminhoMapaHeroi ??
        (setor != null ? _resolverImagemSetor(setor) : null) ??
        (grupo != null ? _resolverImagemGrupo(grupo) : null) ??
        _resolverThumbnailCroqui(idCroqui, croqui: croqui);

    return DadosCartaoCompartilhamento(
      tipoEntidade: TipoEntidadeCompartilhavel.via,
      idCroqui: idCroqui,
      uid: escalada.uid,
      titulo: obterNomeEscalada(escalada),
      subtituloLocalizacao: subtitulo,
      etiquetaCategoria: categoria,
      grauDestaque:
          ExtratorDetalhesTecnicosVia.extrairGrauOficialExibicao(escalada),
      ehClassica: ExtratorDetalhesTecnicosVia.extrairDestaque(escalada),
      chipsResumo: List.unmodifiable(chips),
      seloPessoal: seloPessoal,
      caminhoImagemHeroi: caminhoImagem,
      rotuloLinhaNoMapa: estadoCroqui?.rotuloLinhaNoMapa,
      nomePico: nomePico,
      nomeGrupo: grupo?.nome,
      nomeSetor: nomeSetorBruto.isNotEmpty ? nomeSetorBruto : 'Geral',
    );
  }

  static String _formatarContagemSetores(int n) => n == 1
      ? tr(ChaveTexto.shareCardContagemUmSetor)
      : tr(ChaveTexto.shareCardContagemSetores, {'n': '$n'});

  static String _formatarContagemEscaladas(int n) => n == 1
      ? tr(ChaveTexto.shareCardContagemUmaEscalada)
      : tr(ChaveTexto.shareCardContagemEscaladas, {'n': '$n'});

  static List<String> _resumirModalidades(Iterable<Escalada> escaladas) {
    final chaves = <String>{};
    for (final escalada in escaladas) {
      final chave = ExtratorDetalhesTecnicosVia.extrairChaveModalidade(
        escalada,
      );
      if (chave.isNotEmpty) {
        chaves.add(chave);
      }
    }
    return chaves
        .take(2)
        .map(ExtratorDetalhesTecnicosVia.traduzirRotuloModalidade)
        .toList(growable: false);
  }

  static String? _calcularFaixaGraus(Iterable<Escalada> escaladas) {
    final candidatos = <({int peso, String texto})>[];
    for (final escalada in escaladas) {
      final texto = obterTextoGrauEscalada(escalada).trim();
      if (texto.isEmpty || texto.toLowerCase() == 'projeto') continue;
      final peso = getGrauValue(escalada);
      if (peso >= 9998) continue;
      candidatos.add((peso: peso, texto: texto));
    }
    if (candidatos.isEmpty) return null;
    candidatos.sort((a, b) => a.peso.compareTo(b.peso));
    final minimo = candidatos.first.texto;
    final maximo = candidatos.last.texto;
    return minimo == maximo ? minimo : '$minimo – $maximo';
  }

  static String? _primeiroCaminhoMapaValido(Iterable<Mapa> mapas) {
    for (final mapa in mapas) {
      final caminho = mapa.caminhoImagemMapa.trim();
      if (caminho.isNotEmpty && mapa.larguraMapa > 0 && mapa.alturaMapa > 0) {
        return caminho;
      }
    }
    return null;
  }

  static String? _resolverImagemSetor(Setor setor) {
    if (setor.caminhoImagemCapa.trim().isNotEmpty) {
      return setor.caminhoImagemCapa.trim();
    }
    return _primeiroCaminhoMapaValido(setor.mapas);
  }

  static String? _resolverImagemGrupo(Grupo grupo) {
    if (grupo.caminhoImagemCapa.trim().isNotEmpty) {
      return grupo.caminhoImagemCapa.trim();
    }
    return _primeiroCaminhoMapaValido(grupo.mapas);
  }

  static String? _resolverImagemSetores(Iterable<Setor> setores) {
    for (final setor in setores) {
      final imagem = _resolverImagemSetor(setor);
      if (imagem != null) return imagem;
    }
    return null;
  }

  static String? _resolverThumbnailCroqui(
    String idCroqui, {
    Croqui? croqui,
  }) {
    final thumbDireta = croqui?.caminhoThumbnail.trim() ?? '';
    if (thumbDireta.isNotEmpty) return thumbDireta;

    final repo = DatasetRepository.instance;
    if (repo == null) return null;

    final dataset = repo.activeDataset.value;
    if (dataset != null) {
      for (final c in dataset.croquisBaixados) {
        if (c.id == idCroqui && c.caminhoThumbnail.trim().isNotEmpty) {
          return c.caminhoThumbnail.trim();
        }
      }
    }
    final croquiOnline = repo.gerenciadorSessaoOnline.obterCroquiOnline(
      idCroqui,
    );
    if (croquiOnline != null &&
        croquiOnline.caminhoThumbnail.trim().isNotEmpty) {
      return croquiOnline.caminhoThumbnail.trim();
    }
    return null;
  }
}
