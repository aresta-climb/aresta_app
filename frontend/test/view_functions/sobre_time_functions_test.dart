// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/view_functions/sobre_time_functions.dart';

void main() {
  group('MembroTime', () {
    test('instancia corretamente com valores obrigatórios e padrões vazios', () {
      const membro = MembroTime(
        role: 'Desenvolvedor',
        name: 'Fulano de Tal',
        image: 'assets/team/fulano.webp',
      );

      expect(membro.role, 'Desenvolvedor');
      expect(membro.name, 'Fulano de Tal');
      expect(membro.image, 'assets/team/fulano.webp');
      expect(membro.collapsedRole, isNull);
      expect(membro.linkedin, isEmpty);
      expect(membro.github, isEmpty);
    });

    test('instancia corretamente com todos os campos informados', () {
      const membro = MembroTime(
        role: 'Designer',
        collapsedRole: 'Design',
        name: 'Beltrana',
        linkedin: 'https://linkedin.com/in/beltrana',
        github: 'https://github.com/beltrana',
        image: 'assets/team/beltrana.webp',
      );

      expect(membro.role, 'Designer');
      expect(membro.collapsedRole, 'Design');
      expect(membro.name, 'Beltrana');
      expect(membro.linkedin, 'https://linkedin.com/in/beltrana');
      expect(membro.github, 'https://github.com/beltrana');
      expect(membro.image, 'assets/team/beltrana.webp');
    });
  });

  group('Validação dos links e integridade do teamData', () {
    test('todos os membros do time possuem links externos HTTPS válidos quando configurados', () {
      expect(teamData, isNotEmpty);
      for (final membro in teamData) {
        expect(membro.name, isNotEmpty);
        expect(membro.role, isNotEmpty);
        expect(membro.image, isNotEmpty);

        if (membro.linkedin.isNotEmpty) {
          final uri = Uri.tryParse(membro.linkedin);
          expect(uri, isNotNull, reason: 'LinkedIn de ${membro.name} deve ser um URI válido');
          expect(uri!.isAbsolute, isTrue);
          expect(uri.scheme, 'https');
          expect(uri.host, contains('linkedin.com'));
        }

        if (membro.github.isNotEmpty) {
          final uri = Uri.tryParse(membro.github);
          expect(uri, isNotNull, reason: 'GitHub de ${membro.name} deve ser um URI válido');
          expect(uri!.isAbsolute, isTrue);
          expect(uri.scheme, 'https');
          expect(uri.host, contains('github.com'));
        }
      }
    });
  });
}
