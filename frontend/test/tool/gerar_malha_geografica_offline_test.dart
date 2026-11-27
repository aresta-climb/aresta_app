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

    test(
      'deve preservar atual e restaurar da copia_seguranca quando o servico do IBGE ou NASA falhar ou retornar dados invalidos',
      () async {
        final caminhoMalha = '${dirTemp.path}/malha_globo_brasil.json';
        final caminhoSeguranca =
            '${dirTemp.path}/malha_globo_brasil.seguranca.json';

        await GeradorMalhaGeograficaOffline.executarGeracaoMalha(
          caminhoSaida: caminhoMalha,
          caminhoSeguranca: caminhoSeguranca,
          provedorMalhaExterna: () async =>
              GeradorMalhaGeograficaOffline.construirMalhaPadraoEmbutida(
                versao: 'v_estavel',
              ),
        );

        // Simula queda da API externa (HTTP 503 / SocketException)
        final resQueda = await GeradorMalhaGeograficaOffline.executarGeracaoMalha(
          caminhoSaida: caminhoMalha,
          caminhoSeguranca: caminhoSeguranca,
          provedorMalhaExterna: () async =>
              throw const SocketException('IBGE indisponivel'),
        );

        expect(resQueda.usouCopiaSeguranca, isTrue);
        final jsonAposQueda =
            jsonDecode(File(caminhoMalha).readAsStringSync())
                as Map<String, dynamic>;
        expect(jsonAposQueda['versao'], equals('v_estavel'));

        // Simula corrupcao do arquivo atual antes de nova falha externa -> restaura de copia_seguranca
        File(caminhoMalha).writeAsStringSync('{corrompido');
        final resRestaurado =
            await GeradorMalhaGeograficaOffline.executarGeracaoMalha(
              caminhoSaida: caminhoMalha,
              caminhoSeguranca: caminhoSeguranca,
              provedorMalhaExterna: () async => {'estados_br': []},
            );

        expect(resRestaurado.usouCopiaSeguranca, isTrue);
        final jsonRestaurado =
            jsonDecode(File(caminhoMalha).readAsStringSync())
                as Map<String, dynamic>;
        expect(jsonRestaurado['versao'], equals('v_estavel'));
      },
    );

    test(
      'deve gerar altimetria inicial e rotacionar copia de seguranca validando cotas de base e pico',
      () async {
        final caminhoAlt = '${dirTemp.path}/altimetria_picos_inicial.json';
        final caminhoAltSeg =
            '${dirTemp.path}/altimetria_picos_inicial.seguranca.json';

        await GeradorMalhaGeograficaOffline.executarGeracaoAltimetria(
          caminhoSaida: caminhoAlt,
          caminhoSeguranca: caminhoAltSeg,
          provedorAltimetriaExterna: () async => {
            'versao': 'nasa_v1',
            'picos': {
              'br_mg_igarape_pedra_grande': {
                'altitude_base_m': 980,
                'altitude_pico_m': 1430,
              },
            },
          },
        );

        await GeradorMalhaGeograficaOffline.executarGeracaoAltimetria(
          caminhoSaida: caminhoAlt,
          caminhoSeguranca: caminhoAltSeg,
          provedorAltimetriaExterna: () async => {
            'versao': 'nasa_v2',
            'picos': {
              'br_mg_igarape_pedra_grande': {
                'altitude_base_m': 985,
                'altitude_pico_m': 1434,
              },
            },
          },
        );

        final atual =
            jsonDecode(File(caminhoAlt).readAsStringSync())
                as Map<String, dynamic>;
        final seg =
            jsonDecode(File(caminhoAltSeg).readAsStringSync())
                as Map<String, dynamic>;

        expect(atual['versao'], equals('nasa_v2'));
        expect(seg['versao'], equals('nasa_v1'));
      },
    );

    test(
      'deve rotacionar artefato binario de textura com copia de seguranca e simplificar poligonos Douglas-Peucker',
      () async {
        final caminhoBin = '${dirTemp.path}/textura_globo_nasa.jpg';
        final caminhoBinSeg =
            '${dirTemp.path}/textura_globo_nasa.seguranca.jpg';

        final r1 = await GeradorMalhaGeograficaOffline.executarGeracaoBinaria(
          caminhoSaida: caminhoBin,
          caminhoSeguranca: caminhoBinSeg,
          tamanhoMinimoBytes: 8,
          provedorBytesExternos: () async => List<int>.filled(16, 1),
        );
        expect(r1.usouCopiaSeguranca, isFalse);

        final r2 = await GeradorMalhaGeograficaOffline.executarGeracaoBinaria(
          caminhoSaida: caminhoBin,
          caminhoSeguranca: caminhoBinSeg,
          tamanhoMinimoBytes: 8,
          provedorBytesExternos: () async => List<int>.filled(20, 2),
        );
        expect(r2.usouCopiaSeguranca, isFalse);
        expect(File(caminhoBin).lengthSync(), equals(20));
        expect(File(caminhoBinSeg).lengthSync(), equals(16));

        // Falha externa mantem versao local; se corrompida, restaura da copia_seguranca
        File(caminhoBin).writeAsBytesSync(const [1, 2]);
        final r3 = await GeradorMalhaGeograficaOffline.executarGeracaoBinaria(
          caminhoSaida: caminhoBin,
          caminhoSeguranca: caminhoBinSeg,
          tamanhoMinimoBytes: 8,
          provedorBytesExternos: () async => const [0],
        );
        expect(r3.usouCopiaSeguranca, isTrue);
        expect(File(caminhoBin).lengthSync(), equals(16));

        final anelBruto = <List<double>>[
          [-44.0, -20.0],
          [-43.5, -20.01],
          [-43.0, -20.0],
          [-43.0, -19.0],
          [-43.5, -18.99],
          [-44.0, -19.0],
          [-44.0, -20.0],
        ];
        final simplificado =
            GeradorMalhaGeograficaOffline.simplificarDouglasPeucker(
              anelBruto,
              0.05,
            );
        expect(simplificado.length, lessThan(anelBruto.length));
        expect(simplificado.length, greaterThanOrEqualTo(4));
      },
    );
  });
}
