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
}
