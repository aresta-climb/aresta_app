// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';

void main() {
  group('TipoAscensao', () {
    test('possui os 4 estilos esportivos com os códigos corretos', () {
      expect(TipoAscensao.aVista.codigo, 1);
      expect(TipoAscensao.flash.codigo, 2);
      expect(TipoAscensao.trabalhado.codigo, 3);
      expect(TipoAscensao.tentativa.codigo, 4);
    });

    test('retorna os rótulos amigáveis em português brasileiro', () {
      expect(TipoAscensao.aVista.rotulo, 'À Vista');
      expect(TipoAscensao.flash.rotulo, 'Flash');
      expect(TipoAscensao.trabalhado.rotulo, 'Trabalhado');
      expect(TipoAscensao.tentativa.rotulo, 'Tentativa');
    });

    test('identifica corretamente se o estilo constitui uma cadena esportiva', () {
      expect(TipoAscensao.aVista.isCadena, isTrue);
      expect(TipoAscensao.flash.isCadena, isTrue);
      expect(TipoAscensao.trabalhado.isCadena, isTrue);
      expect(TipoAscensao.tentativa.isCadena, isFalse);
    });

    test('classifica a prioridade visual esportiva corretamente', () {
      expect(TipoAscensao.flash.prioridadeVisual, 3);
      expect(TipoAscensao.aVista.prioridadeVisual, 2);
      expect(TipoAscensao.trabalhado.prioridadeVisual, 1);
      expect(TipoAscensao.tentativa.prioridadeVisual, 0);

      // Flash tem precedência visual sobre À Vista, que tem sobre Trabalhado
      expect(
        TipoAscensao.flash.prioridadeVisual > TipoAscensao.aVista.prioridadeVisual,
        isTrue,
      );
      expect(
        TipoAscensao.aVista.prioridadeVisual > TipoAscensao.trabalhado.prioridadeVisual,
        isTrue,
      );
      expect(
        TipoAscensao.trabalhado.prioridadeVisual > TipoAscensao.tentativa.prioridadeVisual,
        isTrue,
      );
    });

    test('fromCodigo mapeia códigos de banco para a enum com segurança', () {
      expect(TipoAscensao.fromCodigo(1), TipoAscensao.aVista);
      expect(TipoAscensao.fromCodigo(2), TipoAscensao.flash);
      expect(TipoAscensao.fromCodigo(3), TipoAscensao.trabalhado);
      expect(TipoAscensao.fromCodigo(4), TipoAscensao.tentativa);
      expect(TipoAscensao.fromCodigo(null), TipoAscensao.trabalhado);
      expect(TipoAscensao.fromCodigo(99), TipoAscensao.trabalhado);
    });

    test('fromString mapeia nomes textuais com segurança', () {
      expect(TipoAscensao.fromString('aVista'), TipoAscensao.aVista);
      expect(TipoAscensao.fromString('flash'), TipoAscensao.flash);
      expect(TipoAscensao.fromString('trabalhado'), TipoAscensao.trabalhado);
      expect(TipoAscensao.fromString('tentativa'), TipoAscensao.tentativa);
      expect(TipoAscensao.fromString(null), TipoAscensao.trabalhado);
      expect(TipoAscensao.fromString('invalido'), TipoAscensao.trabalhado);
    });
  });
}
