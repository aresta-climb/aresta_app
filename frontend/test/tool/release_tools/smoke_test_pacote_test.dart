// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../tool/release_tools/smoke_test_pacote.dart';

void main() {
  HttpOverrides.global = null;
  late Directory tempDir;

  setUp(() {
    HttpOverrides.global = null;
    tempDir = Directory.systemTemp.createTempSync('orquestrador_smoke_aresta_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  File criarZip(String nome, Map<String, List<int>> entradas) {
    final archive = Archive();
    entradas.forEach((k, v) => archive.addFile(ArchiveFile(k, v.length, v)));
    final f = File('${tempDir.path}/$nome');
    f.writeAsBytesSync(ZipEncoder().encode(archive));
    return f;
  }

  group('OrquestradorSmokePacote', () {
    test('executarAndroid valida AAB, Cold Start do universal.apk e jornada ponta a ponta', () async {
      final aab = criarZip('app-release.aab', <String, List<int>>{
        'base/dex/classes.dex': utf8.encode('dex_limpo'),
        'base/lib/arm64-v8a/libapp.so': utf8.encode('so_app'),
        'base/lib/arm64-v8a/libflutter.so': utf8.encode('so_flutter'),
      });
      final apkSmoke = File('${tempDir.path}/smoke.apk')..writeAsStringSync('apk');
      final bundletool = File('${tempDir.path}/bundletool.jar')..writeAsStringSync('jar');
      final evidencia = File('${tempDir.path}/evidencia-android.json');

      final comandos = <String>[];
      final orq = OrquestradorSmokePacote(
        tempoEsperaColdStart: const Duration(milliseconds: 10),
        executorProcesso: (exec, args, {ambiente}) async {
          comandos.add('$exec ${args.join(' ')}');
          if (exec == 'java' && args.contains('build-apks')) {
            final outArg = args.firstWhere((a) => a.startsWith('--output='));
            final outPath = outArg.substring('--output='.length);
            final apksArchive = Archive()
              ..addFile(ArchiveFile('universal.apk', 3, utf8.encode('apk')));
            File(outPath).writeAsBytesSync(ZipEncoder().encode(apksArchive));
            return const ResultadoProcessoCli(0, 'ok', '');
          }
          if (exec == 'adb' && args.length >= 2 && args[1] == 'pidof') {
            return const ResultadoProcessoCli(0, '4242\n', '');
          }
          if (exec == 'adb' && args.contains('--es')) {
            final idxSrv = args.indexOf('smoke_server');
            final idxTok = args.indexOf('smoke_token');
            final urlEmulador = args[idxSrv + 1];
            final token = args[idxTok + 1];
            final urlLocal = urlEmulador.replaceFirst('10.0.2.2', '127.0.0.1');

            final client = HttpClient();
            final req = await client.postUrl(Uri.parse('$urlLocal/__smoke__/relatorio'));
            req.headers.contentType = ContentType.json;
            req.write(jsonEncode(<String, dynamic>{
              'token': token,
              'sucesso': true,
              'etapas': <String>['login_oidc', 'croqui_aberto', 'cadena_salva'],
            }));
            final resp = await req.close();
            await resp.drain<void>();
            client.close(force: true);
            return const ResultadoProcessoCli(0, 'Starting', '');
          }
          return const ResultadoProcessoCli(0, '', '');
        },
      );

      await orq.executarAndroid(
        arquivoAab: aab,
        arquivoApkSmoke: apkSmoke,
        bundletoolJar: bundletool,
        pacote: 'app.escalada.croquis',
        arquivoSaidaEvidencia: evidencia,
      );

      expect(evidencia.existsSync(), isTrue);
      final jsonEvidencia = jsonDecode(evidencia.readAsStringSync()) as Map<String, dynamic>;
      expect(jsonEvidencia['auditoriaAabAprovada'], isTrue);
      expect(jsonEvidencia['coldStartLojaAprovado'], isTrue);
      expect(comandos.any((c) => c.contains('pidof app.escalada.croquis')), isTrue);
    });

    test('executarIos valida IPA, codesign/otool e jornada Simulator', () async {
      final ipa = criarZip('Runner.ipa', <String, List<int>>{
        'Payload/Runner.app/Runner': utf8.encode('macho'),
        'Payload/Runner.app/Frameworks/App.framework/App': utf8.encode('app'),
        'Payload/Runner.app/Frameworks/Flutter.framework/Flutter': utf8.encode('fl'),
        'Payload/Runner.app/Info.plist':
            utf8.encode('<key>ITSAppUsesNonExemptEncryption</key><false/>'),
      });
      final simApp = Directory('${tempDir.path}/Runner.app')..createSync();
      final evidencia = File('${tempDir.path}/evidencia-ios.json');

      final orq = OrquestradorSmokePacote(
        executorProcesso: (exec, args, {ambiente}) async {
          if (exec == 'xcrun' && args.contains('launch')) {
            final srv = ambiente!['SIMCTL_CHILD_ARESTA_SMOKE_SERVER']!;
            final tok = ambiente['SIMCTL_CHILD_ARESTA_SMOKE_TOKEN']!;
            final client = HttpClient();
            final req = await client.postUrl(Uri.parse('$srv/__smoke__/relatorio'));
            req.headers.contentType = ContentType.json;
            req.write(jsonEncode(<String, dynamic>{
              'token': tok,
              'sucesso': true,
              'etapas': <String>['login_oidc_ios', 'croqui_aberto', 'cadena_salva'],
            }));
            final resp = await req.close();
            await resp.drain<void>();
            client.close(force: true);
          }
          return const ResultadoProcessoCli(0, 'ok', '');
        },
      );

      await orq.executarIos(
        arquivoIpa: ipa,
        diretorioAppSimulador: simApp,
        pacote: 'app.escalada.croquis',
        arquivoSaidaEvidencia: evidencia,
      );

      expect(evidencia.existsSync(), isTrue);
      final jsonEvidencia = jsonDecode(evidencia.readAsStringSync()) as Map<String, dynamic>;
      expect(jsonEvidencia['auditoriaIpaAprovada'], isTrue);
    });
  });
}
