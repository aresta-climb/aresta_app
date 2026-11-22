// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/services/configuracao_recursos.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/utils/consulta_dataset.dart';
import 'package:frontend/view/view_models/alertas_mapa_interativo_view_model.dart';
import 'package:frontend/widgets/via/bolha_alerta_seguranca_via.dart';
import 'package:frontend/widgets/via/camada_bolhas_alerta_mapa.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/comunidade/repositorio_interacoes_via_fake.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);
  });

  tearDown(ConfiguracaoRecursos.redefinirParaTestes);

  testWidgets(
    'CamadaBolhasAlertaMapa renderiza bolhas estilo Waze ancoradas no mapa e permite confirmar ou Desfazer',
    (tester) async {
      const uidVia = 'viaMapaAlerta1';
      final alerta = AlertaSegurancaVia.criar(
        uid: 'alertaMapa0001',
        escaladaUid: uidVia,
        categoria: CategoriaAlertaSeguranca.abelhasInsetos,
        detalhe: 'Marimbondos no diedro',
      );
      final repoFake = RepositorioInteracoesViaFake()
        ..semearDados(uidVia, DadosComunidadeVia(alertasAtivos: [alerta]));

      final ref = Mapa_Referencia(alvoUid: uidVia, pontosUids: ['p1']);
      final mapa = Mapa(
        caminhoImagemMapa: 'mapas/setor.webp',
        larguraMapa: 400,
        alturaMapa: 400,
        pontosDeInteresse: [
          Mapa_PontoDeInteresse(
            uid: 'p1',
            circulo: BoundingCirculo(x: 200, y: 200, raio: 20),
          ),
        ],
        referencias: [ref],
      );

      final vm = AlertasMapaInterativoViewModel(
        mapa: mapa,
        referenciasResolvidas: {
          ref: ResolvedDataset(
            tipo: TipoEntidadeResolved.escalada,
            escalada: Escalada(
              uid: uidVia,
              viaEsportiva: ViaEsportiva(nome: 'Faraó'),
            ),
          ),
        },
        repositorioInteracoes: repoFake,
        duracaoJanelaDesfazer: const Duration(seconds: 4),
      );
      final transformController = TransformationController();
      addTearDown(() {
        transformController.dispose();
        vm.dispose();
      });

      // Dimensão zero retorna SizedBox.shrink
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
          home: Scaffold(
            body: CamadaBolhasAlertaMapa(
              viewModel: vm,
              transformationController: transformController,
              larguraCanvas: 0,
              alturaCanvas: 400,
            ),
          ),
        ),
      );
      expect(find.byType(BolhaEmojiAlertaVia), findsNothing);

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 800);
      tester.view.viewPadding = const FakeViewPadding(bottom: 48);
      tester.view.padding = FakeViewPadding.zero;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewPadding();
        tester.view.resetPadding();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: Stack(
                children: [
                  CamadaBolhasAlertaMapa(
                    viewModel: vm,
                    transformationController: transformController,
                    larguraCanvas: 400,
                    alturaCanvas: 400,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BolhaEmojiAlertaVia), findsOneWidget);
      expect(find.text('🐝'), findsOneWidget);

      // 1. Confirmar que ainda está lá (+1)
      await tester.tap(find.byType(BolhaEmojiAlertaVia));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('btn_confirmar_alerta_ativo')));
      await tester.pumpAndSettle();
      expect(
        repoFake.obterDadosEscalada(uidVia).alertasAtivos.single.confirmacoesAtivas,
        2,
      );

      // 2. Resolver com Desfazer e restaurar (sem invadir os 48px inferiores do SO)
      await tester.tap(find.byType(BolhaEmojiAlertaVia));
      await tester.pumpAndSettle();
      expect(find.text('Ainda está lá?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_confirmar_alerta_resolvido')));
      await tester.pumpAndSettle();
      expect(find.byType(BolhaEmojiAlertaVia), findsNothing);
      expect(find.text('Desfazer'), findsOneWidget);
      final pillSnackMapa = tester.getRect(
        find
            .descendant(
              of: find.byType(SnackBar),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(pillSnackMapa.bottom, lessThanOrEqualTo(800.0 - 48.0 - 16.0));

      await tester.tap(find.text('Desfazer'));
      await tester.pumpAndSettle();
      expect(find.byType(BolhaEmojiAlertaVia), findsOneWidget);
    },
  );
}
