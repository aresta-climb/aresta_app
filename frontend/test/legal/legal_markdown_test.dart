import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Legal Markdown Verification', () {
    test('TERMOS_DE_USO_ARESTA_CLIMB.md contains link to privacy policy', () {
      final file = File('legal/repo/TERMOS_DE_USO_ARESTA_CLIMB.md');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'Arquivo de termos não encontrado',
      );

      final content = file.readAsStringSync();

      expect(
        content.contains('[Política de Privacidade]'),
        isTrue,
        reason:
            'O texto do link da Política de Privacidade foi removido. O modal no app depende deste texto para interceptar o clique.',
      );

      expect(
        content.contains('POLITICA_DE_PRIVACIDADE_ARESTA_CLIMB.html'),
        isTrue,
        reason:
            'A URL do link da Política de Privacidade foi removida ou alterada. Ela precisa estar presente para manter a estrutura do Markdown correta.',
      );
    });
  });
}
