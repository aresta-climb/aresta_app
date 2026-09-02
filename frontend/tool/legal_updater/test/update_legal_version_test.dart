// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../bin/update_legal_version.dart';

void main() {
  late Directory tempDir;
  late Directory docsDir;
  late File dartFile;
  late File termos;
  late File politica;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('legal_test_');
    docsDir = Directory('${tempDir.path}/public/docs');
    await docsDir.create(recursive: true);

    dartFile = File('${tempDir.path}/legal_version.g.dart');

    termos = File('${docsDir.path}/termos-de-uso.md');
    politica = File('${docsDir.path}/politica-de-privacidade.md');

    await termos.writeAsString('Conteudo termos');
    await politica.writeAsString('Conteudo politica');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
      'Deve retornar false e nao alterar arquivo quando não há mudanças nos textos',
      () async {
    final termosHash =
        sha256.convert(utf8.encode('Conteudo termos')).toString();
    final politicaHash =
        sha256.convert(utf8.encode('Conteudo politica')).toString();

    final initialDart = '''
const int kLegalVersion = 1;
const String kLegalLastUpdatedDate = '2026-06-04';

const Map<String, String> kLegalHashes = {
  'termos-de-uso.md': '$termosHash',
  'politica-de-privacidade.md': '$politicaHash',
};
''';
    await dartFile.writeAsString(initialDart);

    final updater = LegalVersionUpdater(tempDir.path, dartFile.path);
    final wasUpdated = await updater.checkAndUpdate();

    expect(wasUpdated, isFalse);
  });

  test('Deve retornar true e alterar versão para 2 se um dos textos mudar',
      () async {
    final termosHash =
        sha256.convert(utf8.encode('Conteudo termos antigo')).toString();
    final politicaHash =
        sha256.convert(utf8.encode('Conteudo politica')).toString();

    final initialDart = '''
const int kLegalVersion = 1;
const String kLegalLastUpdatedDate = '2026-06-04';

const Map<String, String> kLegalHashes = {
  'termos-de-uso.md': '$termosHash',
  'politica-de-privacidade.md': '$politicaHash',
};
''';
    await dartFile.writeAsString(initialDart);

    final updater = LegalVersionUpdater(tempDir.path, dartFile.path);
    final wasUpdated = await updater.checkAndUpdate();

    expect(wasUpdated, isTrue);

    final currentDart = await dartFile.readAsString();

    expect(currentDart.contains('const int kLegalVersion = 2;'), isTrue);

    final newTermosHash =
        sha256.convert(utf8.encode('Conteudo termos')).toString();
    expect(
        currentDart.contains("'termos-de-uso.md': '$newTermosHash'"),
        isTrue);
  });

  test(
      'Deve criar arquivo dart com versão 1 se ele não existir, e gravar os hashes atuais',
      () async {
    final updater = LegalVersionUpdater(tempDir.path, dartFile.path);
    final wasUpdated = await updater.checkAndUpdate();

    expect(wasUpdated, isTrue);
    expect(await dartFile.exists(), isTrue);

    final currentDart = await dartFile.readAsString();

    expect(currentDart.contains('const int kLegalVersion = 1;'), isTrue);
    final newTermosHash =
        sha256.convert(utf8.encode('Conteudo termos')).toString();
    expect(
        currentDart.contains("'termos-de-uso.md': '$newTermosHash'"),
        isTrue);
  });

  test('Deve recriar o arquivo dart se ele estiver corrompido', () async {
    await dartFile.writeAsString('const int kLegalVersion = lalala;');

    final updater = LegalVersionUpdater(tempDir.path, dartFile.path);
    final wasUpdated = await updater.checkAndUpdate();

    expect(wasUpdated, isTrue);

    final currentDart = await dartFile.readAsString();
    expect(currentDart.contains('const int kLegalVersion = 1;'), isTrue);
  });
}
