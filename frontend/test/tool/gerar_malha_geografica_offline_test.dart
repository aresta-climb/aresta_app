// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/gerar_malha_geografica_offline.dart';

void main() {
  late Directory dirTemp;

  setUp(() async {
    dirTemp = await Directory.systemTemp.createTemp('gerador_malha_geo_test_');
  });

  tearDown(() async {
    if (dirTemp.existsSync()) {
      dirTemp.deleteSync(recursive: true);
    }
  });

  group('GeradorMalhaGeograficaOffline', () {
    test(
      'deve criar arquivo atual e copia_seguranca na primeira geracao valida contendo as 27 UFs e continentes abaixo de 400 KB',
      () async {
        final caminhoMalha = '${dirTemp.path}/malha_globo_brasil.json';
        final caminhoSeguranca =
            '${dirTemp.path}/malha_globo_brasil.seguranca.json';

        final resultado = await GeradorMalhaGeograficaOffline.executarGeracaoMalha(
          caminhoSaida: caminhoMalha,
          caminhoSeguranca: caminhoSeguranca,
          provedorMalhaExterna: () async =>
              GeradorMalhaGeograficaOffline.construirMalhaPadraoEmbutida(
                versao: 'v1',
              ),
        );

        expect(resultado.usouCopiaSeguranca, isFalse);
        expect(File(caminhoMalha).existsSync(), isTrue);
        expect(File(caminhoSeguranca).existsSync(), isTrue);
        expect(File(caminhoMalha).lengthSync(), lessThan(400 * 1024));

        final jsonAtual =
            jsonDecode(File(caminhoMalha).readAsStringSync())
                as Map<String, dynamic>;
        final estados = jsonAtual['estados_br'] as List<dynamic>;
        expect(estados.length, equals(27));
        expect(jsonAtual['versao'], equals('v1'));

        final jsonSeg =
            jsonDecode(File(caminhoSeguranca).readAsStringSync())
                as Map<String, dynamic>;
        expect(jsonSeg['versao'], equals('v1'));
      },
    );

    test(
      'deve rotacionar atual anterior para copia_seguranca e descartar versao mais velha a cada coleta nova valida',
      () async {
        final caminhoMalha = '${dirTemp.path}/malha_globo_brasil.json';
        final caminhoSeguranca =
            '${dirTemp.path}/malha_globo_brasil.seguranca.json';

        for (final versao in ['v1', 'v2', 'v3']) {
          await GeradorMalhaGeograficaOffline.executarGeracaoMalha(
            caminhoSaida: caminhoMalha,
            caminhoSeguranca: caminhoSeguranca,
            provedorMalhaExterna: () async =>
                GeradorMalhaGeograficaOffline.construirMalhaPadraoEmbutida(
                  versao: versao,
                ),
          );
        }

        final jsonAtual =
            jsonDecode(File(caminhoMalha).readAsStringSync())
                as Map<String, dynamic>;
        final jsonSeg =
            jsonDecode(File(caminhoSeguranca).readAsStringSync())
                as Map<String, dynamic>;

        // v1 foi descartada; copia_seguranca contem v2 e atual contem v3
        expect(jsonAtual['versao'], equals('v3'));
        expect(jsonSeg['versao'], equals('v2'));
        expect(
          dirTemp.listSync().whereType<File>().length,
          equals(2),
        );
      },
    );

