import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Apenas os arquivos dentro da pasta lib/services/firebase podem importar pacotes do Firebase',
    () {
      final libDirectory = Directory('lib');

      // Pega todos os arquivos .dart recursivamente em lib/
      final dartFiles = libDirectory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();

      final infringingFiles = <String>[];

      for (final file in dartFiles) {
        final normalizedPath = file.path.replaceAll('\\', '/');

        // Ignora o firebase_options gerado pelo FlutterFire
        if (normalizedPath.endsWith('firebase_options.dart')) continue;

        // Ignora arquivos que estão legitimamente dentro de lib/services/firebase
        if (normalizedPath.contains('lib/services/firebase/')) continue;

        final content = file.readAsStringSync();

        // Procura por imports de firebase_ (exceto as nossas próprias abstrações)
        // O padrão import 'package:firebase_ vai pegar firebase_core, firebase_analytics, etc.
        if (content.contains("import 'package:firebase_") ||
            content.contains('import "package:firebase_')) {
          infringingFiles.add(normalizedPath);
        }
      }

      expect(
        infringingFiles,
        isEmpty,
        reason:
            'Os seguintes arquivos estão violando a arquitetura isolada do Firebase importando os pacotes nativos do Firebase diretamente:\n${infringingFiles.join('\n')}\n'
            'Solução: Remova esses imports e utilize ou adicione métodos nas classes da pasta lib/services/firebase/.',
      );
    },
  );
}
