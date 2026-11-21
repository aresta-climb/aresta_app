// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../tool/release_tools/auditar_binario_loja.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('auditar_binario_aresta_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  File criarZip(String nome, Map<String, List<int>> arquivos) {
    final archive = Archive();
    arquivos.forEach((caminho, bytes) {
      archive.addFile(ArchiveFile(caminho, bytes.length, bytes));
    });
    final zipBytes = ZipEncoder().encode(archive);
    final file = File('${tempDir.path}/$nome');
    file.writeAsBytesSync(zipBytes);
    return file;
  }

  group('AuditorBinarioLoja', () {
    test('aprova AAB limpo contendo classes.dex, libapp.so e libflutter.so', () {
      final aab = criarZip('limpo.aab', <String, List<int>>{
        'base/dex/classes.dex': utf8.encode('bytecode_producao_limpo'),
        'base/lib/arm64-v8a/libapp.so': utf8.encode('elf_arm64_aresta'),
        'base/lib/arm64-v8a/libflutter.so': utf8.encode('elf_flutter'),
      });

      final res = AuditorBinarioLoja.auditarAab(aab);
      expect(res.aprovado, isTrue, reason: res.erros.join('\n'));
      expect(res.erros, isEmpty);
    });

    test('reprova AAB inexistente, incompleto ou contaminado com marcador de smoke', () {
      final ausente = AuditorBinarioLoja.auditarAab(
        File('${tempDir.path}/nao_existe.aab'),
      );
      expect(ausente.aprovado, isFalse);

      final contaminado = criarZip('contaminado.aab', <String, List<int>>{
        'base/dex/classes.dex':
            utf8.encode('prefixo app.escalada.croquis/smoke_ci sufixo'),
        'base/lib/arm64-v8a/libapp.so': utf8.encode('ok'),
      });
      final res = AuditorBinarioLoja.auditarAab(contaminado);
      expect(res.aprovado, isFalse);
      expect(res.erros.join('\n'), contains('VIOLAÇÃO DE PUREZA'));
      expect(res.erros.join('\n'), contains('libflutter.so'));
    });

    test('aprova IPA limpo com Runner, App.framework, Flutter.framework e ITSAppUsesNonExemptEncryption', () {
      final ipa = criarZip('limpo.ipa', <String, List<int>>{
        'Payload/Runner.app/Runner': utf8.encode('macho_runner_limpo'),
        'Payload/Runner.app/Frameworks/App.framework/App':
            utf8.encode('macho_dart_aot_limpo'),
        'Payload/Runner.app/Frameworks/Flutter.framework/Flutter':
            utf8.encode('macho_flutter'),
        'Payload/Runner.app/Info.plist':
            utf8.encode('<plist><key>ITSAppUsesNonExemptEncryption</key><false/></plist>'),
      });

      final res = AuditorBinarioLoja.auditarIpa(ipa);
      expect(res.aprovado, isTrue, reason: res.erros.join('\n'));
    });

    test('reprova IPA inexistente, sem ITSAppUsesNonExemptEncryption ou contaminado com /__smoke__/', () {
      final ausente = AuditorBinarioLoja.auditarIpa(
        File('${tempDir.path}/inexistente.ipa'),
      );
      expect(ausente.aprovado, isFalse);

      final contaminado = criarZip('contaminado.ipa', <String, List<int>>{
        'Payload/Runner.app/Runner': utf8.encode('macho /__smoke__/oidc-token'),
        'Payload/Runner.app/Frameworks/App.framework/App': utf8.encode('ok'),
        'Payload/Runner.app/Info.plist': utf8.encode('<plist></plist>'),
      });
      final res = AuditorBinarioLoja.auditarIpa(contaminado);
      expect(res.aprovado, isFalse);
      expect(res.erros.join('\n'), contains('ITSAppUsesNonExemptEncryption'));
      expect(res.erros.join('\n'), contains('VIOLAÇÃO DE PUREZA'));
    });

    test('CLI retorna código 0 para pacotes limpos e diferente de zero para inválidos', () {
      final aab = criarZip('cli_ok.aab', <String, List<int>>{
        'base/dex/classes.dex': utf8.encode('limpo'),
        'base/lib/arm64-v8a/libapp.so': utf8.encode('limpo'),
        'base/lib/arm64-v8a/libflutter.so': utf8.encode('limpo'),
      });
      expect(executarCliAuditoria(<String>['--aab', aab.path]), 0);
      expect(
        executarCliAuditoria(<String>['--ipa', '${tempDir.path}/ausente.ipa']),
        1,
      );
      expect(executarCliAuditoria(const <String>[]), 2);
    });
  });
}
