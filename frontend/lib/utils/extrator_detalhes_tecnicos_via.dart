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
  }
}
