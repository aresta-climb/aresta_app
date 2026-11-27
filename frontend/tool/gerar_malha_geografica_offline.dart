// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';

/// Resultado da execução de uma rotina de geração com rotação de cópia de segurança.
class ResultadoGeracaoComSeguranca {
  /// Indica se foi necessário recorrer à cópia de segurança devido à falha da fonte externa.
  final bool usouCopiaSeguranca;

  /// Mensagem descritiva do desfecho da operação para auditoria em terminal/CI.
  final String mensagem;

  const ResultadoGeracaoComSeguranca({
    required this.usouCopiaSeguranca,
    required this.mensagem,
  });
}

/// Gerador e rotacionador das malhas geográficas reais (IBGE API v3 + Natural Earth),
/// textura esférica NASA Blue Marble e altimetria/grade DEM real (NASA SRTM / Copernicus DEM).
///
/// Mantém exatamente uma cópia de segurança validada (`*.seguranca.*`) para cada artefato,
/// promovendo o arquivo atual anterior para cópia de segurança e descartando versões mais
/// antigas sempre que dados novos íntegros são coletados.
abstract final class GeradorMalhaGeograficaOffline {
  /// Limite máximo permitido para o arquivo vetorial de malha geográfica (400 KB).
  static const int limiteMaximoBytesMalha = 400 * 1024;

  /// Dimensão lateral (`N x N`) da grade DEM real amostrada ao redor de cada pico.
  static const int dimensaoGradeDem = 13;

  /// Raio angular (em graus de lat/lon, `~2.7 km`) coberto pela grade DEM local de cada pico.
  static const double raioGradeDemGraus = 0.024;

  static const Map<String, String> _codigoIbgeParaUf = <String, String>{
    '11': 'RO',
    '12': 'AC',
    '13': 'AM',
    '14': 'RR',
    '15': 'PA',
    '16': 'AP',
    '17': 'TO',
    '21': 'MA',
    '22': 'PI',
    '23': 'CE',
    '24': 'RN',
    '25': 'PB',
    '26': 'PE',
    '27': 'AL',
    '28': 'SE',
    '29': 'BA',
    '31': 'MG',
    '32': 'ES',
    '33': 'RJ',
    '35': 'SP',
    '41': 'PR',
    '42': 'SC',
    '43': 'RS',
    '50': 'MS',
    '51': 'MT',
    '52': 'GO',
    '53': 'DF',
  };

  /// Executa a geração e rotação atômica da malha geográfica (`atual` + `seguranca`).
  static Future<ResultadoGeracaoComSeguranca> executarGeracaoMalha({
    required String caminhoSaida,
    required String caminhoSeguranca,
    required Future<Map<String, dynamic>> Function() provedorMalhaExterna,
  }) {
    return _rotacionarJsonComCopiaSeguranca(
      caminhoSaida: caminhoSaida,
      caminhoSeguranca: caminhoSeguranca,
      buscarDados: provedorMalhaExterna,
      validarDados: validarEstruturaMalha,
      nomeRecurso: 'malha geográfica IBGE/Natural Earth',
    );
  }

  /// Executa a geração e rotação atômica do arquivo inicial de altimetria (`atual` + `seguranca`).
  static Future<ResultadoGeracaoComSeguranca> executarGeracaoAltimetria({
    required String caminhoSaida,
    required String caminhoSeguranca,
    required Future<Map<String, dynamic>> Function() provedorAltimetriaExterna,
  }) {
    return _rotacionarJsonComCopiaSeguranca(
      caminhoSaida: caminhoSaida,
      caminhoSeguranca: caminhoSeguranca,
      buscarDados: provedorAltimetriaExterna,
      validarDados: validarEstruturaAltimetria,
      nomeRecurso: 'altimetria real SRTM/Copernicus DEM',
    );
  }

  /// Executa a rotação atômica de um artefato binário (ex.: textura NASA Blue Marble) com 1 cópia de segurança.
  static Future<ResultadoGeracaoComSeguranca> executarGeracaoBinaria({
    required String caminhoSaida,
    required String caminhoSeguranca,
    required Future<List<int>> Function() provedorBytesExternos,
    int tamanhoMinimoBytes = 10240,
    String nomeRecurso = 'textura esférica NASA Blue Marble',
  }) async {
    final arquivoAtual = File(caminhoSaida);
    final arquivoSeguranca = File(caminhoSeguranca);
    arquivoAtual.parent.createSync(recursive: true);
    arquivoSeguranca.parent.createSync(recursive: true);

    bool validarBytes(File f) =>
        f.existsSync() && f.lengthSync() >= tamanhoMinimoBytes;

    try {
      final bytes = await provedorBytesExternos();
      if (bytes.length < tamanhoMinimoBytes) {
        throw FormatException(
          'Payload binário menor que $tamanhoMinimoBytes bytes para $nomeRecurso.',
        );
      }

      final arquivoTmp = File('$caminhoSaida.tmp');
      arquivoTmp.writeAsBytesSync(bytes, flush: true);

      if (validarBytes(arquivoAtual)) {
        arquivoAtual.copySync(caminhoSeguranca);
      } else {
        arquivoTmp.copySync(caminhoSeguranca);
      }

      if (arquivoAtual.existsSync()) {
        arquivoAtual.deleteSync();
      }
      arquivoTmp.renameSync(caminhoSaida);

      return ResultadoGeracaoComSeguranca(
        usouCopiaSeguranca: false,
        mensagem:
            'Atualizado $nomeRecurso (${bytes.length} bytes) e rotacionada cópia única de segurança.',
      );
    } catch (erro) {
      final arquivoTmp = File('$caminhoSaida.tmp');
      if (arquivoTmp.existsSync()) {
        arquivoTmp.deleteSync();
      }
      if (validarBytes(arquivoAtual)) {
        if (!validarBytes(arquivoSeguranca)) {
          arquivoAtual.copySync(caminhoSeguranca);
        }
        return ResultadoGeracaoComSeguranca(
          usouCopiaSeguranca: true,
          mensagem:
              'Falha ao baixar $nomeRecurso ($erro). Mantida versão local íntegra.',
        );
      }
      if (validarBytes(arquivoSeguranca)) {
        arquivoSeguranca.copySync(caminhoSaida);
        return ResultadoGeracaoComSeguranca(
          usouCopiaSeguranca: true,
          mensagem:
              'Falha ao baixar $nomeRecurso ($erro). Restaurado da cópia de segurança.',
        );
      }
      throw StateError(
        'Não foi possível obter $nomeRecurso ($erro) e não há cópia de segurança íntegra.',
      );
    }
  }

