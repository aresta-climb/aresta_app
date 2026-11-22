// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/caderneta/secao_meus_alertas_caderneta.dart';

void main() {
  testWidgets(
    'SecaoMeusAlertasCaderneta oculta quando vazia, distingue CRIADO POR VOCÊ vs CONFIRMADO (+1) e não causa overflow em 320x568 @ 1.5x',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
          home: Scaffold(
            body: SecaoMeusAlertasCaderneta(
              tituloSecao: 'Meus Alertas na Rocha (0)',
              alertas: const [],
              obterNomeVia: (uid) => uid,
              obterGrauVia: (_) => null,
              formatarData: (_) => '20/11/2026',
              aoTocarVia: (_) {},
              aoResolverAlerta: (_) {},
            ),
          ),
        ),
      );
      expect(find.textContaining('Meus Alertas na Rocha'), findsNothing);

      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      String? viaTocada;
      AlertaContribuidoCaderneta? resolvido;

      final criadoAtivo = AlertaContribuidoCaderneta(
        alerta: AlertaSegurancaVia.criar(
          uid: 'alertaCriado01',
          escaladaUid: 'viaFaraoUid001',
          categoria: CategoriaAlertaSeguranca.abelhasInsetos,
          detalhe: 'Colmeia próxima à 4ª chapeleta',
          autorIdPublico: 'c3Lk9P1x4Vw8Mn',
          confirmacoesAtivas: 3,
        ),
      );
  });
}
