// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/interacao_via.dart';

void main() {
  group('CategoriaAlertaSeguranca', () {
    test('mapeia códigos canônicos do banco de dados, emojis e rótulos em português', () {
      expect(CategoriaAlertaSeguranca.abelhasInsetos.codigoBanco, 'ABELHAS_INSETOS');
      expect(CategoriaAlertaSeguranca.abelhasInsetos.emoji, '🐝');
      expect(CategoriaAlertaSeguranca.abelhasInsetos.rotulo, 'Abelhas ou Insetos');

      expect(
        CategoriaAlertaSeguranca.rochaAgarraInstavel.codigoBanco,
        'ROCHA_AGARRA_INSTAVEL',
      );
      expect(CategoriaAlertaSeguranca.rochaAgarraInstavel.emoji, '🪨');

      expect(
        CategoriaAlertaSeguranca.protecaoPrecaria.codigoBanco,
        'PROTECAO_PRECARIA',
      );
      expect(CategoriaAlertaSeguranca.protecaoPrecaria.emoji, '🔩');

      expect(CategoriaAlertaSeguranca.viaMolhada.codigoBanco, 'VIA_MOLHADA');
      expect(CategoriaAlertaSeguranca.viaMolhada.emoji, '💧');

      expect(
        CategoriaAlertaSeguranca.riscoExposicao.codigoBanco,
        'RISCO_EXPOSICAO',
      );
      expect(CategoriaAlertaSeguranca.riscoExposicao.emoji, '⚠️');

      for (final cat in CategoriaAlertaSeguranca.values) {
        expect(
          CategoriaAlertaSeguranca.deCodigoBanco(cat.codigoBanco),
          equals(cat),
        );
        expect(cat.descricaoCurta, isNotEmpty);
      }

      expect(
        () => CategoriaAlertaSeguranca.deCodigoBanco('CODIGO_DESCONHECIDO'),
        throwsArgumentError,
      );
    });
  });

}
