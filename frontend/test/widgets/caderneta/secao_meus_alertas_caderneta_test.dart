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
        papel: PapelContribuicaoAlerta.criadoPorMim,
        ativo: true,
        ultimaInteracaoEm: DateTime(2026, 11, 20),
      );

      final confirmadoResolvido = AlertaContribuidoCaderneta(
        alerta: AlertaSegurancaVia.criar(
          uid: 'alertaConf0002',
          escaladaUid: 'viaLunarUid002',
          categoria: CategoriaAlertaSeguranca.rochaAgarraInstavel,
          autorIdPublico: 'outroAutor0001',
          confirmacoesAtivas: 1,
        ),
        papel: PapelContribuicaoAlerta.confirmadoPorMim,
        ativo: false,
        ultimaInteracaoEm: DateTime(2026, 11, 18),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.5),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SecaoMeusAlertasCaderneta(
                tituloSecao: 'Meus Alertas na Rocha (2)',
                alertas: [criadoAtivo, confirmadoResolvido],
                obterNomeVia: (uid) =>
                    uid == 'viaFaraoUid001' ? 'Faraó' : 'Bloco Lunar',
                obterGrauVia: (uid) => uid == 'viaFaraoUid001' ? '8a' : null,
                formatarData: (_) => '20/11/2026',
                aoTocarVia: (uid) => viaTocada = uid,
                aoResolverAlerta: (item) => resolvido = item,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Meus Alertas na Rocha (2)'), findsOneWidget);
      expect(find.text('CRIADO POR VOCÊ'), findsOneWidget);
      expect(find.text('CONFIRMADO (+1)'), findsOneWidget);
      expect(find.text('Ativo • 3 confirmações'), findsOneWidget);
      expect(find.text('Resolvido'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('item_meu_alerta_alertaCriado01')),
      );
      expect(viaTocada, 'viaFaraoUid001');

      final btnResolver = find.byKey(
        const Key('btn_resolver_meu_alerta_alertaCriado01'),
      );
      await tester.ensureVisible(btnResolver);
      await tester.tap(btnResolver);
      expect(resolvido?.alerta.uid, 'alertaCriado01');
      expect(
        find.byKey(const Key('btn_resolver_meu_alerta_alertaConf0002')),
        findsNothing,
      );
    },
  );
}
