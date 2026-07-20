import 'dart:io';
import 'package:crypto/crypto.dart';

class LegalVersionUpdater {
  final String repoPath;
  final String outputPath;

  LegalVersionUpdater(this.repoPath, this.outputPath);

  Future<bool> checkAndUpdate() async {
    final File dartFile = File(outputPath);
    final File termosFile = File('$repoPath/TERMOS_DE_USO_ARESTA_CLIMB.md');
    final File politicaFile = File('$repoPath/POLITICA_DE_PRIVACIDADE_ARESTA_CLIMB.md');

    if (!await termosFile.exists() || !await politicaFile.exists()) {
      print('Erro: Arquivos Markdown não encontrados em $repoPath.');
      return false;
    }

    final currentTermosHash = sha256.convert(await termosFile.readAsBytes()).toString();
    final currentPoliticaHash = sha256.convert(await politicaFile.readAsBytes()).toString();

    int oldVersion = 0;
    String oldTermosHash = '';
    String oldPoliticaHash = '';

    if (await dartFile.exists()) {
      try {
        final content = await dartFile.readAsString();
        
        final versionMatch = RegExp(r"const int kLegalVersion = (\d+);").firstMatch(content);
        if (versionMatch != null) oldVersion = int.parse(versionMatch.group(1)!);
        
        final termosMatch = RegExp(r"'TERMOS_DE_USO_ARESTA_CLIMB\.md': '([^']+)'").firstMatch(content);
        if (termosMatch != null) oldTermosHash = termosMatch.group(1)!;
        
        final politicaMatch = RegExp(r"'POLITICA_DE_PRIVACIDADE_ARESTA_CLIMB\.md': '([^']+)'").firstMatch(content);
        if (politicaMatch != null) oldPoliticaHash = politicaMatch.group(1)!;
      } catch (e) {
        print('Erro ao ler dart anterior: $e');
      }
    }

    bool changed = (currentTermosHash != oldTermosHash) || (currentPoliticaHash != oldPoliticaHash);

    if (changed || oldVersion == 0) {
      final newVersion = oldVersion == 0 ? 1 : oldVersion + 1;
      
      final dateStr = DateTime.now().toIso8601String().split('T')[0];

      final dartContent = '''// GERADO AUTOMATICAMENTE. NÃO EDITE.
// Atualizado pelo script update_legal_version.dart

const int kLegalVersion = $newVersion;
const String kLegalLastUpdatedDate = '$dateStr';

const Map<String, String> kLegalHashes = {
  'TERMOS_DE_USO_ARESTA_CLIMB.md': '$currentTermosHash',
  'POLITICA_DE_PRIVACIDADE_ARESTA_CLIMB.md': '$currentPoliticaHash',
};
''';

      // Ensure directory exists
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
      : Platform.script.resolve('../../../lib/constants/legal_version.g.dart').toFilePath();
  
  final updater = LegalVersionUpdater(repoPath, outputPath);
  print('Checking for changes in legal documents...');
  
  final wasUpdated = await updater.checkAndUpdate();
  if (wasUpdated) {
    print('Changes detected. legal_version.g.dart bumped.');
  } else {
    print('No changes detected. legal_version.g.dart remains the same.');
  }
}
