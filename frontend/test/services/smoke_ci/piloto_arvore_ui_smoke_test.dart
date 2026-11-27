// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/smoke_ci/piloto_arvore_ui_smoke.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PilotoArvoreUiSmoke', () {
    testWidgets(
      'localiza widgets fora de vista, rola até o alvo, toca via hit-test físico e digita respeitando inputFormatters',
      (WidgetTester tester) async {
        String? valorDigitadoOtp;
        var modalAberto = false;
        var confirmadoNoModal = false;

        final piloto = PilotoArvoreUiSmoke();
        final controllerOtp = TextEditingController();
        addTearDown(controllerOtp.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [
                  TextField(
                    key: const Key('campo_teste_otp_piloto'),
                    controller: controllerOtp,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onChanged: (v) => valorDigitadoOtp = v,
                  ),
                  const SizedBox(height: 1200),
                  Builder(
                    builder: (context) {
                      return ElevatedButton(
                        key: const Key('btn_abrir_modal_piloto'),
                        onPressed: () {
                          modalAberto = true;
                          showModalBottomSheet<void>(
                            context: context,
                            builder: (modalCtx) => Padding(
                              padding: const EdgeInsets.all(24),
                              child: ElevatedButton(
                                key: const Key('btn_confirmar_modal_piloto'),
                                onPressed: () {
                                  confirmadoNoModal = true;
                                  Navigator.of(modalCtx).pop();
                                },
                                child: const Text('Confirmar'),
                              ),
                            ),
                          );
                        },
                        child: const Text('Abrir modal'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        await tester.runAsync(() async {
          await piloto.digitarPorKey('campo_teste_otp_piloto', '65ab432199');
          expect(valorDigitadoOtp, equals('654321'));
          expect(controllerOtp.text, equals('654321'));

          await piloto.tocarPorKey('btn_abrir_modal_piloto');
          expect(modalAberto, isTrue);

          await piloto.aguardarElementoPorKey('btn_confirmar_modal_piloto');
          expect(
            piloto.existeElementoVisivelPorKey('btn_confirmar_modal_piloto'),
            isTrue,
          );

          await piloto.tocarPorKey('btn_confirmar_modal_piloto');
          await piloto.aguardarAusenciaPorKey('btn_confirmar_modal_piloto');
          expect(confirmadoNoModal, isTrue);
          expect(
            piloto.existeElementoVisivelPorKey('btn_confirmar_modal_piloto'),
            isFalse,
          );
        });
      },
    );

    testWidgets(
      'lança StateError descritivo quando o elemento não aparece dentro do timeout',
      (WidgetTester tester) async {
        final piloto = PilotoArvoreUiSmoke();
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: Text('Tela vazia'))),
        );
        await tester.pump();

        await tester.runAsync(() async {
          await expectLater(
            () => piloto.aguardarElementoPorKey(
              'chave_inexistente',
              timeout: const Duration(milliseconds: 90),
            ),
            throwsStateError,
          );
        });
      },
    );
  });
}
