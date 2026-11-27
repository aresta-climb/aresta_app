// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/compartilhamento/capturador_imagem_cartao.dart';

void main() {
  group('CapturadorImagemCartao', () {
    testWidgets('capturarPng renderiza RepaintBoundary em bytes PNG válidos', (tester) async {
      final chave = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RepaintBoundary(
                key: chave,
                child: Container(
                  width: 120,
                  height: 80,
                  color: Colors.teal,
                  alignment: Alignment.center,
                  child: const Text('Aresta'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final bytes = await tester.runAsync(
        () => CapturadorImagemCartao.capturarPng(chave, pixelRatio: 1.0),
      );

      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(8));
      // Assinatura mágica oficial de arquivos PNG: 89 50 4E 47 0D 0A 1A 0A
      expect(
        bytes.sublist(0, 8),
        equals([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
      );
    });

    testWidgets('capturarPng falha explicitamente quando a chave não pertence a um RepaintBoundary', (tester) async {
      final chaveSemBoundary = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(key: chaveSemBoundary, width: 10, height: 10),
          ),
        ),
      );
      await tester.pump();

      await expectLater(
        () => CapturadorImagemCartao.capturarPng(chaveSemBoundary),
        throwsA(isA<StateError>()),
      );
    });
  });
}
