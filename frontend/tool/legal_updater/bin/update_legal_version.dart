// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:crypto/crypto.dart';

/// Utilitário responsável por monitorar alterações nos documentos legais
/// em `public/docs/` e atualizar a versão compilada em `legal_version.g.dart`.
class LegalVersionUpdater {
  final String repoPath;
  final String outputPath;

  LegalVersionUpdater(this.repoPath, this.outputPath);

  Future<bool> checkAndUpdate() async {
    final File dartFile = File(outputPath);
    final File termosFile = File('$repoPath/public/docs/termos-de-uso.md');
    final File politicaFile =
        File('$repoPath/public/docs/politica-de-privacidade.md');

    if (!await termosFile.exists() || !await politicaFile.exists()) {
      print('Erro: Arquivos Markdown não encontrados em $repoPath/public/docs/.');
      return false;
    }

    final currentTermosHash =
        sha256.convert(await termosFile.readAsBytes()).toString();
    final currentPoliticaHash =
        sha256.convert(await politicaFile.readAsBytes()).toString();

    int oldVersion = 0;
    String oldTermosHash = '';
    String oldPoliticaHash = '';

    if (await dartFile.exists()) {
      try {
        final content = await dartFile.readAsString();

        final versionMatch =
            RegExp(r"const int kLegalVersion = (\d+);").firstMatch(content);
        if (versionMatch != null) {
          oldVersion = int.parse(versionMatch.group(1)!);
        }

        final termosMatch =
            RegExp(r"'termos-de-uso\.md': '([^']+)'").firstMatch(content);
        if (termosMatch != null) oldTermosHash = termosMatch.group(1)!;

        final politicaMatch =
            RegExp(r"'politica-de-privacidade\.md': '([^']+)'")
                .firstMatch(content);
        if (politicaMatch != null) oldPoliticaHash = politicaMatch.group(1)!;
      } catch (e) {
        print('Erro ao ler dart anterior: $e');
      }
    }

    bool changed = (currentTermosHash != oldTermosHash) ||
        (currentPoliticaHash != oldPoliticaHash);

    if (changed || oldVersion == 0) {
      final newVersion = oldVersion == 0 ? 1 : oldVersion + 1;

      final dateStr = DateTime.now().toIso8601String().split('T')[0];

      final dartContent = '''// GERADO AUTOMATICAMENTE. NÃO EDITE.
// Atualizado pelo script update_legal_version.dart

const int kLegalVersion = $newVersion;
const String kLegalLastUpdatedDate = '$dateStr';

const Map<String, String> kLegalHashes = {
  'termos-de-uso.md': '$currentTermosHash',
  'politica-de-privacidade.md': '$currentPoliticaHash',
};
''';

      // Garante que o diretório de destino existe
      if (!dartFile.parent.existsSync()) {
        dartFile.parent.createSync(recursive: true);
      }

      await dartFile.writeAsString(dartContent);
      return true;
    }

    return false;
  }
}

Future<void> main(List<String> args) async {
  final String repoPath = args.isNotEmpty
      ? args[0]
      : Platform.script.resolve('../../../legal/repo').toFilePath();

  final String outputPath = args.length > 1
      ? args[1]
      : Platform.script
          .resolve('../../../lib/constants/legal_version.g.dart')
          .toFilePath();

  final updater = LegalVersionUpdater(repoPath, outputPath);
  print('Checking for changes in legal documents...');

  final wasUpdated = await updater.checkAndUpdate();
  if (wasUpdated) {
    print('Changes detected. legal_version.g.dart bumped.');
  } else {
    print('No changes detected. legal_version.g.dart remains the same.');
  }
}
