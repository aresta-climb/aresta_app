// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../aresta_api/proto/generated/beta.pb.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../data/modelos/interacao_via.dart';
import 'consulta_dataset.dart';
import 'formatador_escalada.dart';
import 'modelos_apresentacao_via.dart';

export 'modelos_apresentacao_via.dart';

/// Extrator puro e sem estado responsável por mapear mensagens Protobuf [Escalada] e agregados
/// comunitários em modelos imutáveis prontos para consumo pelo `ViaViewModel` e Dumb UI.
abstract final class ExtratorDetalhesTecnicosVia {
  /// Extrai o rótulo legível da modalidade da [escalada].
  static String extrairModalidade(Escalada escalada) {
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
    if (bruto == 'PROJETO') return 'Projeto';
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
        partes.add('Média $media');
      }
    }
    final artificial = _extrairArtificialFormatado(escalada);
    if (artificial != null) {
      final livre = _extrairArtificialEmLivreFormatado(escalada);
      partes.add(
        livre != null
            ? 'Artificial $artificial ($livre em livre)'
            : 'Artificial $artificial',
      );
    }
    return partes.isEmpty ? 'Guia Oficial / Conquistador' : partes.join(' • ');
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

  /// Extrai as seções textuais e recomendações de equipamento da [escalada].
  static List<SecaoTextoVia> extrairSecoesTexto(Escalada escalada) {
    final secoes = <SecaoTextoVia>[];
    switch (escalada.whichTipo()) {
      case Escalada_Tipo.viaEsportiva:
        _adicionarTexto(secoes, 'Descrição', escalada.viaEsportiva.descricao, true);
      case Escalada_Tipo.viaMovel:
        _adicionarTexto(secoes, 'Descrição', escalada.viaMovel.descricao, true);
        _adicionarTexto(secoes, 'Peças Móveis', escalada.viaMovel.protecoesMoveis, false);
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
        _adicionarTexto(secoes, 'Descrição do Acesso', escalada.highline.descricaoAcesso, true);
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
          titulo: tituloLimpo.isNotEmpty ? tituloLimpo : 'Beta em $origem',
          url: url,
          origemRotulo: origem,
        ),
      );
    }

    final urlDireta = _extrairUrlVideoBeta(escalada);
    if (urlDireta != null && urlsVistas.add(urlDireta)) {
      itens.add(
        ItemMidiaBetaVia(
          titulo: 'Assistir Vídeo Beta',
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
    }
  }
}
