// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/tipo_feedback.dart';

void main() {
  group('TipoFeedback', () {
    test('retorna valores string corretos para cada categoria', () {
      expect(TipoFeedback.croqui.valor, 'croqui');
      expect(TipoFeedback.aplicativo.valor, 'app');
    });

    test('fromString converte strings conhecidas e desconhecidas adequadamente', () {
      expect(TipoFeedback.fromString('croqui'), TipoFeedback.croqui);
      expect(TipoFeedback.fromString('app'), TipoFeedback.aplicativo);
      expect(TipoFeedback.fromString('aplicativo'), TipoFeedback.aplicativo);
      expect(TipoFeedback.fromString(null), TipoFeedback.aplicativo);
      expect(TipoFeedback.fromString('desconhecido'), TipoFeedback.aplicativo);
    });
  });
}
