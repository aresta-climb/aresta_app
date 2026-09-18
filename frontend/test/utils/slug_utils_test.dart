// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/slug_utils.dart';

void main() {
  group('slugify', () {
    test('converte texto simples com espacos em minusculo com underline', () {
      expect(slugify('Setor Principal'), equals('setor_principal'));
    });

    test('remove acentuacao e diacriticos corretamente', () {
      expect(
        slugify('Falésia da Esperança & Ação - Épico'),
        equals('falesia_da_esperanca_acao_epico'),
      );
    });

    test('remove caracteres especiais e pontuacoes', () {
      expect(
        slugify('Setor A (Bloco 2) / [Via 5+]'),
        equals('setor_a_bloco_2_via_5'),
      );
    });

    test('colapsa underlines multiplos em apenas um e remove das extremidades', () {
      expect(slugify('  __Pedra__Grande__ '), equals('pedra_grande'));
    });

    test('trata hifens convertendo para underline para padronizacao', () {
      expect(slugify('grupo-estacionamento'), equals('grupo_estacionamento'));
    });

    test('retorna string vazia para entrada vazia ou composta apenas de simbolos', () {
      expect(slugify(''), equals(''));
      expect(slugify(r'   !@#$   '), equals(''));
    });
  });

  group('slugsCoincidem', () {
    test('retorna true quando nomes com grafias e acentos diferentes geram mesmo slug', () {
      expect(
        slugsCoincidem('Grupo Estacionamento', 'grupo_estacionamento'),
        isTrue,
      );
      expect(
        slugsCoincidem('Savassinha', 'savassinha'),
        isTrue,
      );
      expect(
        slugsCoincidem('Teto da Aresta', 'teto-da-aresta'),
        isTrue,
      );
    });

    test('retorna false quando nomes geram slugs distintos', () {
      expect(
        slugsCoincidem('Setor A', 'setor_b'),
        isFalse,
      );
    });

    test('retorna true ignorando prefixos de tipo como bloco_, setor_ e grupo_', () {
      expect(
        slugsCoincidem('Bloco Fugitivos I', 'fugitivos_i'),
        isTrue,
      );
      expect(
        slugsCoincidem('Setor Família I', 'familia_i'),
        isTrue,
      );
      expect(
        slugsCoincidem('Grupo Sherpa', 'sherpa'),
        isTrue,
      );
      expect(
        slugsCoincidem('Setor Estacionamento', 'estacionamento'),
        isTrue,
      );
    });
  });
}
