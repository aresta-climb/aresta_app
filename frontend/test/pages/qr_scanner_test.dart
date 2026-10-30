// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/pages/qr_scanner.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  testWidgets(
    'QRScannerPage soma o recuo inferior do sistema (padding.bottom) à margem de 40 dp da instrução',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            extensions: const [AppColors.dark],
          ),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(bottom: 48),
              ),
              child: child!,
            );
          },
          home: const QRScannerPage(),
        ),
      );

      final textoInstrucao = find.text(
        'Aponte a câmera para o QR Code\ndo repositório',
      );
      expect(textoInstrucao, findsOneWidget);

      final positioned = tester.widget<Positioned>(
        find.ancestor(
          of: textoInstrucao,
          matching: find.byType(Positioned),
        ),
      );
      expect(positioned.bottom, equals(88.0));
    },
  );

  testWidgets(
    'QRScannerPage retorna o valor lido no Navigator.pop ao detectar um QR Code válido e ignora leituras duplicadas',
    (tester) async {
      String? codigoRetornado;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            extensions: const [AppColors.dark],
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  codigoRetornado = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QRScannerPage(),
                    ),
                  );
                },
                child: const Text('Abrir Scanner'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Scanner'));
      await tester.pumpAndSettle();

      final scanner = tester.widget<MobileScanner>(find.byType(MobileScanner));
      expect(scanner.onDetect, isNotNull);

      // Código vazio deve ser ignorado
      scanner.onDetect!(
        const BarcodeCapture(
          barcodes: [Barcode(rawValue: '')],
        ),
      );
      await tester.pump();
      expect(codigoRetornado, isNull);

      // Primeiro código válido fecha a tela e retorna o valor
      scanner.onDetect!(
        const BarcodeCapture(
          barcodes: [Barcode(rawValue: 'https://aresta.cc/teste123')],
        ),
      );
      // Chamada subsequente enquanto fecha é ignorada pela trava _isScanned
      scanner.onDetect!(
        const BarcodeCapture(
          barcodes: [Barcode(rawValue: 'https://aresta.cc/ignorado')],
        ),
      );
      await tester.pumpAndSettle();

      expect(codigoRetornado, equals('https://aresta.cc/teste123'));
    },
  );
}
