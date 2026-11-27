// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../aresta_api/proto/generated/beta.pb.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../data/modelos/interacao_via.dart';
import '../idioma/tradutor_app.dart';
import 'consulta_dataset.dart';
import 'formatador_escalada.dart';
import 'modelos_apresentacao_via.dart';

export 'modelos_apresentacao_via.dart';

/// Extrator puro e sem estado responsável por mapear mensagens Protobuf [Escalada] e agregados
/// comunitários em modelos imutáveis prontos para consumo pelo `ViaViewModel` e Dumb UI.
abstract final class ExtratorDetalhesTecnicosVia {
  /// Extrai a chave canônica interna da modalidade da [escalada] para indexação e filtros.
  static String extrairChaveModalidade(Escalada escalada) {
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

  /// Traduz uma chave canônica de modalidade (`'Esportiva'`, `'Boulder'`, etc.) para o idioma ativo.
  static String traduzirRotuloModalidade(
    String chaveModalidade, {
    bool plural = false,
  }) {
    switch (chaveModalidade) {
      case 'Esportiva':
        return tr(plural ? ChaveTexto.modEsportivas : ChaveTexto.modEsportiva);
      case 'Móvel':
        return tr(plural ? ChaveTexto.modMoveis : ChaveTexto.modMovel);
      case 'Mista':
        return tr(ChaveTexto.modMista);
      case 'Boulder':
        return tr(plural ? ChaveTexto.modBoulders : ChaveTexto.modBoulder);
      case 'Multienfiada':
        return tr(
          plural ? ChaveTexto.modMultienfiadas : ChaveTexto.modMultienfiada,
        );
      case 'Highline':
        return tr(plural ? ChaveTexto.modHighlines : ChaveTexto.modHighline);
      case 'Outras':
        return tr(ChaveTexto.modOutras);
      default:
        return chaveModalidade;
    }
  }

  /// Extrai o rótulo localizado da modalidade da [escalada] no idioma ativo.
  static String extrairModalidade(Escalada escalada) =>
      traduzirRotuloModalidade(extrairChaveModalidade(escalada));

  /// Indica se a [escalada] é marcada como clássica/destaque do setor.
  static bool extrairDestaque(Escalada escalada) {
    return switch (escalada.whichTipo()) {
      Escalada_Tipo.viaEsportiva => escalada.viaEsportiva.destaque,
      Escalada_Tipo.viaMovel => escalada.viaMovel.destaque,
      Escalada_Tipo.boulder => escalada.boulder.destaque,
      Escalada_Tipo.viaMultiplasEnfiadas =>
        escalada.viaMultiplasEnfiadas.destaque,
      Escalada_Tipo.highline => escalada.highline.destaque,
      Escalada_Tipo.notSet => false,
    };
  }

  /// Extrai o grau oficial formatado (ou `'Projeto'`), retornando `null` quando indefinido.
  static String? extrairGrauOficialExibicao(Escalada escalada) {
    final bruto = switch (escalada.whichTipo()) {
      Escalada_Tipo.viaEsportiva => escalada.viaEsportiva.dificuldade.name,
      Escalada_Tipo.viaMovel => escalada.viaMovel.dificuldade.name,
      Escalada_Tipo.boulder => escalada.boulder.dificuldade.name,
      Escalada_Tipo.viaMultiplasEnfiadas =>
        escalada.viaMultiplasEnfiadas.dificuldadeMaxima.name,
      _ => null,
    };
    if (bruto == null || bruto.isEmpty || bruto.contains('INDEFINIDO')) {
      return null;
    }
    if (bruto == 'PROJETO') return tr(ChaveTexto.viaProjeto);
    final formatado = formatarTextoGrau(bruto);
    return formatado.isNotEmpty ? formatado : null;
  }

  /// Extrai o subtítulo complementar abaixo do grau oficial (média em multienfiadas e artificial).
  static String extrairComplementoGrauOficial(Escalada escalada) {
    final partes = <String>[];
    if (escalada.whichTipo() == Escalada_Tipo.viaMultiplasEnfiadas) {
      final media = formatarTextoGrau(
        escalada.viaMultiplasEnfiadas.dificuldadeMedia.name,
      );
      if (media.isNotEmpty && media != 'projeto') {
        partes.add(tr(ChaveTexto.viaMediaPrefixo, {'media': media}));
      }
    }
    final artificial = _extrairArtificialFormatado(escalada);
    if (artificial != null) {
      final livre = _extrairArtificialEmLivreFormatado(escalada);
      partes.add(
        livre != null
            ? tr(ChaveTexto.viaArtificialLivre, {
                'art': artificial,
                'livre': livre,
              })
            : tr(ChaveTexto.viaArtificialPuro, {'art': artificial}),
      );
    }
    return partes.isEmpty
        ? tr(ChaveTexto.viaGuiaOficialConquistador)
        : partes.join(' • ');
  }

  /// Extrai a descrição do tipo de parada/ancoragem quando preenchida.
  static String? extrairTipoAncoragem(Escalada escalada) {
    final texto = switch (escalada.whichTipo()) {
      Escalada_Tipo.viaEsportiva => escalada.viaEsportiva.tipoAncoragem.trim(),
      Escalada_Tipo.viaMovel => escalada.viaMovel.tipoAncoragem.trim(),
      _ => '',
    };
    return texto.isNotEmpty ? texto : null;
  }

  /// Extrai os atributos técnicos aplicáveis à modalidade da [escalada].
  static List<AtributoTecnicoVia> extrairAtributosTecnicos(Escalada escalada) {
    final itens = <AtributoTecnicoVia>[];
    switch (escalada.whichTipo()) {
      case Escalada_Tipo.viaEsportiva:
        final v = escalada.viaEsportiva;
        _adicionarMetros(itens, TipoIconeAtributoVia.extensao, tr(ChaveTexto.viaSpecExtensao), v.extensao);
        _adicionarProtecoes(itens, v.quantidadeProtecoesIntermediarias, v.quantidadeProtecoesParada);
        _adicionarSePreenchido(itens, TipoIconeAtributoVia.parede, tr(ChaveTexto.viaSpecParede), _formatarEnumSimples(v.tipoParede.name));
        _adicionarSePreenchido(itens, TipoIconeAtributoVia.exposicao, tr(ChaveTexto.viaSpecExposicao), _formatarEnumCodigo(v.exposicao.name));
      case Escalada_Tipo.viaMovel:
        final v = escalada.viaMovel;
        _adicionarMetros(itens, TipoIconeAtributoVia.extensao, tr(ChaveTexto.viaSpecExtensao), v.extensao);
        _adicionarProtecoes(itens, v.quantidadeProtecoesIntermediarias, v.quantidadeProtecoesParada);
        _adicionarSePreenchido(itens, TipoIconeAtributoVia.parede, tr(ChaveTexto.viaSpecParede), _formatarEnumSimples(v.tipoParede.name));
        _adicionarSePreenchido(itens, TipoIconeAtributoVia.exposicao, tr(ChaveTexto.viaSpecExposicao), _formatarEnumCodigo(v.exposicao.name));
      case Escalada_Tipo.boulder:
        _adicionarSePreenchido(itens, TipoIconeAtributoVia.parede, tr(ChaveTexto.viaSpecParede), _formatarEnumSimples(escalada.boulder.tipoParede.name));
      case Escalada_Tipo.viaMultiplasEnfiadas:
        final v = escalada.viaMultiplasEnfiadas;
        if (v.numeroEnfiadas > 0) {
          itens.add(AtributoTecnicoVia(icone: TipoIconeAtributoVia.enfiadas, rotulo: tr(ChaveTexto.viaSpecEnfiadas), valor: '${v.numeroEnfiadas}'));
        }
        _adicionarMetros(itens, TipoIconeAtributoVia.extensao, tr(ChaveTexto.viaSpecComprimento), v.comprimentoTotal);
        _adicionarMetros(itens, TipoIconeAtributoVia.distancia, tr(ChaveTexto.viaSpecMaiorEnfiada), v.comprimentoMaiorEnfiada);
        _adicionarProtecoes(itens, v.quantidadeCosturasIntermediarias, v.quantidadeEquipamentosParada);
        _adicionarSePreenchido(itens, TipoIconeAtributoVia.duracao, tr(ChaveTexto.viaSpecDuracao), _formatarEnumCodigo(v.duracao.name));
        _adicionarSePreenchido(itens, TipoIconeAtributoVia.exposicao, tr(ChaveTexto.viaSpecExposicao), _formatarEnumCodigo(v.exposicao.name));
        _adicionarSePreenchido(itens, TipoIconeAtributoVia.modalidade, tr(ChaveTexto.viaSpecTipo), _formatarEnumSimples(v.tipoViaMultiplasEnfiadas.name));
      case Escalada_Tipo.highline:
        final v = escalada.highline;
        _adicionarMetros(itens, TipoIconeAtributoVia.distancia, tr(ChaveTexto.viaSpecDistancia), v.distancia);
        _adicionarMetros(itens, TipoIconeAtributoVia.extensao, tr(ChaveTexto.viaSpecAltura), v.altura);
        if (v.exposicao > 0) {
          itens.add(AtributoTecnicoVia(icone: TipoIconeAtributoVia.exposicao, rotulo: tr(ChaveTexto.viaSpecExposicao), valor: '${v.exposicao}'));
        }
      case Escalada_Tipo.notSet:
        break;
    }
    return List.unmodifiable(itens);
  }

  /// Extrai as seções textuais e recomendações de equipamento da [escalada].
  static List<SecaoTextoVia> extrairSecoesTexto(Escalada escalada) {
    final secoes = <SecaoTextoVia>[];
    final descTitulo = tr(ChaveTexto.viaSecaoDescricao);
    switch (escalada.whichTipo()) {
      case Escalada_Tipo.viaEsportiva:
        _adicionarTexto(secoes, descTitulo, escalada.viaEsportiva.descricao, true);
      case Escalada_Tipo.viaMovel:
        _adicionarTexto(secoes, descTitulo, escalada.viaMovel.descricao, true);
        _adicionarTexto(secoes, tr(ChaveTexto.viaSecaoPecasMoveis), escalada.viaMovel.protecoesMoveis, false);
      case Escalada_Tipo.boulder:
        _adicionarTexto(secoes, descTitulo, escalada.boulder.descricao, true);
      case Escalada_Tipo.viaMultiplasEnfiadas:
        _adicionarTexto(secoes, descTitulo, escalada.viaMultiplasEnfiadas.descricao, true);
        _adicionarTexto(secoes, tr(ChaveTexto.viaSecaoRackEquipamento), escalada.viaMultiplasEnfiadas.equipamentoRecomendado, false);
      case Escalada_Tipo.highline:
        _adicionarTexto(secoes, tr(ChaveTexto.viaSecaoDescricaoAcesso), escalada.highline.descricaoAcesso, true);
        _adicionarTexto(secoes, tr(ChaveTexto.viaSecaoDescricaoAncoragem), escalada.highline.descricaoAncoragem, true);
        _adicionarTexto(secoes, descTitulo, escalada.highline.descricao, true);
      case Escalada_Tipo.notSet:
        break;
    }
    return List.unmodifiable(secoes);
  }

  /// Extrai a lista estruturada de enfiadas em vias de múltiplas enfiadas.
  static List<ResumoEnfiadaVia> extrairEnfiadas(Escalada escalada) {
    if (escalada.whichTipo() != Escalada_Tipo.viaMultiplasEnfiadas) {
      return const [];
    }
    final brutas = escalada.viaMultiplasEnfiadas.enfiadas;
    final resultado = <ResumoEnfiadaVia>[];
    for (var i = 0; i < brutas.length; i++) {
      final enf = brutas[i];
      final numero = i + 1;
      final nome = obterNomeEscalada(enf, padrao: '').trim();
      final prefixoEnf = tr(ChaveTexto.viaEnfiadaNumero, {'n': '$numero'});
      final titulo = nome.isNotEmpty ? '$prefixoEnf • $nome' : prefixoEnf;
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

  /// Extrai vídeos e postagens curadas de beta sem duplicação de URL.
  static List<ItemMidiaBetaVia> extrairMidiasBeta(Escalada escalada) {
    final itens = <ItemMidiaBetaVia>[];
    final urlsVistas = <String>{};

    for (final beta in escalada.betas) {
      final url = beta.url.trim();
      if (url.isEmpty || !urlsVistas.add(url)) continue;
      final origem = _rotuloFonteMidia(beta.fonte);
      final tituloLimpo = beta.titulo.trim();
      itens.add(
        ItemMidiaBetaVia(
          titulo: tituloLimpo.isNotEmpty
              ? tituloLimpo
              : tr(ChaveTexto.viaBetaEmOrigem, {'origem': origem}),
          url: url,
          origemRotulo: origem,
        ),
      );
    }

    final urlDireta = _extrairUrlVideoBeta(escalada);
    if (urlDireta != null && urlsVistas.add(urlDireta)) {
      itens.add(
        ItemMidiaBetaVia(
          titulo: tr(ChaveTexto.viaAssistirVideoBeta),
          url: urlDireta,
          origemRotulo: 'Vídeo',
        ),
      );
    }
    return List.unmodifiable(itens);
  }

  /// Extrai os nomes dos conquistadores unidos por vírgula, ou `null` quando ausentes.
  static String? extrairConquistadores(Escalada escalada) {
    final lista = switch (escalada.whichTipo()) {
      Escalada_Tipo.viaEsportiva => escalada.viaEsportiva.conquistadores,
      Escalada_Tipo.viaMovel => escalada.viaMovel.conquistadores,
      Escalada_Tipo.boulder => escalada.boulder.conquistadores,
      Escalada_Tipo.viaMultiplasEnfiadas =>
        escalada.viaMultiplasEnfiadas.conquistadores,
      Escalada_Tipo.highline => escalada.highline.conquistadores,
      Escalada_Tipo.notSet => const <String>[],
    };
    final limpos = lista.map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
    return limpos.isEmpty ? null : limpos.join(', ');
  }

  /// Extrai a data de conquista/abertura quando preenchida.
  static String? extrairDataAbertura(Escalada escalada) {
    final texto = switch (escalada.whichTipo()) {
      Escalada_Tipo.viaEsportiva => escalada.viaEsportiva.dataAbertura.trim(),
      Escalada_Tipo.viaMovel => escalada.viaMovel.dataAbertura.trim(),
      Escalada_Tipo.boulder => escalada.boulder.dataAbertura.trim(),
      Escalada_Tipo.viaMultiplasEnfiadas =>
        escalada.viaMultiplasEnfiadas.dataAbertura.trim(),
      Escalada_Tipo.highline => escalada.highline.dataAbertura.trim(),
      Escalada_Tipo.notSet => '',
    };
    return texto.isNotEmpty ? texto : null;
  }

  /// Extrai a data da última manutenção quando preenchida.
  static String? extrairDataManutencao(Escalada escalada) {
    final texto = switch (escalada.whichTipo()) {
      Escalada_Tipo.viaEsportiva => escalada.viaEsportiva.dataManutencao.trim(),
      Escalada_Tipo.viaMovel => escalada.viaMovel.dataManutencao.trim(),
      Escalada_Tipo.viaMultiplasEnfiadas =>
        escalada.viaMultiplasEnfiadas.dataManutencao.trim(),
      Escalada_Tipo.highline => escalada.highline.dataManutencao.trim(),
      _ => '',
    };
    return texto.isNotEmpty ? texto : null;
  }

  /// Extrai a chave Pix de manutenção quando cadastrada.
  static String? extrairChavePix(Escalada escalada) {
    final chave = switch (escalada.whichTipo()) {
      Escalada_Tipo.viaEsportiva =>
        escalada.viaEsportiva.chavePixManutencao.trim(),
      Escalada_Tipo.viaMovel => escalada.viaMovel.chavePixManutencao.trim(),
      Escalada_Tipo.boulder => escalada.boulder.chavePixManutencao.trim(),
      Escalada_Tipo.viaMultiplasEnfiadas =>
        escalada.viaMultiplasEnfiadas.chavePixManutencao.trim(),
      Escalada_Tipo.highline => escalada.highline.chavePixManutencao.trim(),
      Escalada_Tipo.notSet => '',
    };
    return chave.isNotEmpty ? chave : null;
  }

  /// Constrói o modelo visual completo [ApresentacaoConsensoGrauVia] para os gráficos da `ViaPage`.
  static ApresentacaoConsensoGrauVia construirApresentacaoConsenso(
    ConsensoGrauVia consenso, {
    required int? codigoGrauOficial,
    required bool ehBoulder,
    int? deltaVotoUsuario,
  }) => ApresentacaoConsensoGrauVia.deConsenso(
    consenso,
    codigoGrauOficial: codigoGrauOficial,
    ehBoulder: ehBoulder,
    deltaVotoUsuario: deltaVotoUsuario,
  );

  /// Formata comentários públicos em [NotaComunidadeApresentacao] para Dumb UI.
  static List<NotaComunidadeApresentacao> formatarNotasComunidade(
    List<ComentarioComunidadeVia> comentarios,
  ) {
    return comentarios
        .map((c) {
          final dia = c.criadoEm.day.toString().padLeft(2, '0');
          final mes = c.criadoEm.month.toString().padLeft(2, '0');
          return NotaComunidadeApresentacao(
            cabecalhoAutorData: '${c.autorNomePublico} • $dia/$mes/${c.criadoEm.year}',
            rotuloEstilo: c.rotuloEstilo,
            texto: c.texto,
          );
        })
        .toList(growable: false);
  }

  /// Resolve a miniatura ou itens de carrossel de croqui para a [escalada] sem lógica na UI.
  static EstadoCroquiVia resolverEstadoCroqui({
    required Escalada escalada,
    Pico? pico,
    Setor? setor,
    Grupo? grupo,
    DatasetResolver? resolvedorExterno,
  }) => EstadoCroquiVia.resolver(
    escalada: escalada,
    pico: pico,
    setor: setor,
    grupo: grupo,
    resolvedorExterno: resolvedorExterno,
  );

  static String? _extrairArtificialFormatado(Escalada escalada) {
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

  static String? _extrairArtificialEmLivreFormatado(Escalada escalada) {
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

  static String? _extrairUrlVideoBeta(Escalada escalada) {
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
        SecaoTextoVia(titulo: titulo, conteudo: limpo, ehMarkdown: ehMarkdown),
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
