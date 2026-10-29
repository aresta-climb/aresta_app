// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/classificador_dispositivo.dart';

void main() {
  late Directory dirTemp;

  setUp(() async {
    dirTemp = await Directory.systemTemp.createTemp(
      'classificador_dispositivo_test_',
    );
    ClassificadorDispositivo.resetarParaTestes(
      caminhoMeminfoPadrao: '${dirTemp.path}/meminfo_inexistente',
    );
  });

  tearDown(() async {
    ClassificadorDispositivo.resetarParaTestes();
    if (dirTemp.existsSync()) {
      dirTemp.deleteSync(recursive: true);
    }
  });

  group('ClassificadorDispositivo - Classificação por RAM (MB)', () {
    test(
      'deve classificar dispositivo com <= 3 GB de RAM (ex: 3072 MB) como tier baixo e limite de 50 MB',
      () {
        final perfil = ClassificadorDispositivo.instancia.classificar(
          ramTotalMb: 3072,
        );

        expect(perfil.tierDispositivo, equals('baixo'));
        expect(perfil.ramGb, equals('3'));
        expect(perfil.limiteCacheImagensBytes, equals(50 * 1024 * 1024));
        expect(
          ClassificadorDispositivo.instancia.tierDispositivo,
          equals('baixo'),
        );
        expect(ClassificadorDispositivo.instancia.ramGb, equals('3'));
        expect(
          ClassificadorDispositivo.instancia.limiteCacheImagensBytes,
          equals(50 * 1024 * 1024),
        );
      },
    );

    test(
      'deve classificar dispositivo entre 4 GB e 6 GB de RAM (ex: 4096 MB e 6144 MB) como tier medio e limite de 100 MB',
      () {
        final perfil4Gb = ClassificadorDispositivo.instancia.classificar(
          ramTotalMb: 4096,
        );
        expect(perfil4Gb.tierDispositivo, equals('medio'));
        expect(perfil4Gb.ramGb, equals('4'));
        expect(perfil4Gb.limiteCacheImagensBytes, equals(100 * 1024 * 1024));

        final perfil6Gb = ClassificadorDispositivo.instancia.classificar(
          ramTotalMb: 6144,
        );
        expect(perfil6Gb.tierDispositivo, equals('medio'));
        expect(perfil6Gb.ramGb, equals('6'));
        expect(perfil6Gb.limiteCacheImagensBytes, equals(100 * 1024 * 1024));
      },
    );

    test(
      'deve classificar dispositivo com >= 8 GB de RAM (ex: 12288 MB) como tier alto e limite de 150 MB',
      () {
        final perfil = ClassificadorDispositivo.instancia.classificar(
          ramTotalMb: 12288,
        );

        expect(perfil.tierDispositivo, equals('alto'));
        expect(perfil.ramGb, equals('12'));
        expect(perfil.limiteCacheImagensBytes, equals(150 * 1024 * 1024));
      },
    );

    test(
      'deve usar fallback seguro desconhecido e limite de 100 MB quando RAM não está disponível',
      () {
        final perfil = ClassificadorDispositivo.instancia.classificar();

        expect(perfil.tierDispositivo, equals('desconhecido'));
        expect(perfil.ramGb, equals('0'));
        expect(perfil.limiteCacheImagensBytes, equals(100 * 1024 * 1024));
      },
    );
  });

  group('ClassificadorDispositivo - Leitura de /proc/meminfo', () {
    test(
      'deve extrair MemTotal em kB de arquivo meminfo real e classificar dispositivo corretamente',
      () {
        final arquivoMeminfo = File('${dirTemp.path}/meminfo_baixo');
        // 3.145.728 kB = 3072 MB = 3 GB
        arquivoMeminfo.writeAsStringSync(
          'MemTotal:        3145728 kB\nMemFree:          512000 kB\n',
        );

        final perfil = ClassificadorDispositivo.instancia.classificar(
          caminhoMeminfo: arquivoMeminfo.path,
        );

        expect(perfil.tierDispositivo, equals('baixo'));
        expect(perfil.ramGb, equals('3'));
        expect(perfil.limiteCacheImagensBytes, equals(50 * 1024 * 1024));
      },
    );

    test(
      'deve retornar fallback desconhecido quando arquivo meminfo não contém linha MemTotal válida',
      () {
        final arquivoInvalido = File('${dirTemp.path}/meminfo_invalido');
        arquivoInvalido.writeAsStringSync('MemFree: 12345 kB\n');

        final perfil = ClassificadorDispositivo.instancia.classificar(
          caminhoMeminfo: arquivoInvalido.path,
        );

        expect(perfil.tierDispositivo, equals('desconhecido'));
        expect(perfil.ramGb, equals('0'));
        expect(perfil.limiteCacheImagensBytes, equals(100 * 1024 * 1024));
      },
    );
  });
}
