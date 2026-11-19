// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/via/bolha_alerta_seguranca_via.dart';
import 'package:frontend/widgets/via/secoes_detalhes_via.dart';

void main() {
  Widget envolver(Widget filho) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: Scaffold(body: SingleChildScrollView(child: filho)),
    );
  }

  testWidgets('CabecalhoIdentidadeVia renderiza título completo, modalidade, selo CLÁSSICA e localização', (tester) async {
    final escalada = Escalada(
      viaEsportiva: ViaEsportiva(nome: 'Aresta do Sol Nascente', destaque: true),
    );
    final setor = Setor(nome: 'Setor Principal');
    final grupo = Grupo(nome: 'Face Norte');

    await tester.pumpWidget(
      envolver(
        CabecalhoIdentidadeVia(
          nomeEscalada: 'Aresta do Sol Nascente',
          modalidade: 'Esportiva',
          ehDestaque: true,
          cragId: 'crag1',
          escalada: escalada,
          setor: setor,
          grupo: grupo,
        ),
      ),
    );

    expect(find.text('Aresta do Sol Nascente'), findsOneWidget);
    expect(find.text('ESPORTIVA'), findsOneWidget);
    expect(find.text('CLÁSSICA'), findsOneWidget);
    expect(find.textContaining('Face Norte > Setor Principal'), findsOneWidget);
  });

  testWidgets('AreaHeroiTopoGrauVia posiciona bolha vermelha flutuante no canto superior direito e renderiza consenso', (tester) async {
    AlertaSegurancaVia? alertaTocado;
    final alerta = AlertaSegurancaVia.criar(
      uid: 'alertaTopo0001',
      escaladaUid: 'x8siJek3FiG3aB',
      categoria: CategoriaAlertaSeguranca.abelhasInsetos,
    );

    await tester.pumpWidget(
      envolver(
        AreaHeroiTopoGrauVia(
          escalada: Escalada(
            uid: 'x8siJek3FiG3aB',
            viaEsportiva: ViaEsportiva(nome: 'Deslize'),
          ),
          cragId: 'crag1',
          exibirCartaoGrau: true,
          rotuloGrauOficial: 'GRAU OFICIAL',
          grauOficial: '7a',
          complementoGrauOficial: 'Guia Oficial / Conquistador',
          consensoGrau: const ConsensoGrauVia(
            grauSugerido: '7b',
            totalVotos: 10,
            distribuicaoDeltas: {1: 8, 0: 2},
          ),
          alertasAtivos: [alerta],
          aoTocarAlerta: (a) => alertaTocado = a,
        ),
      ),
    );

    expect(find.text('GRAU OFICIAL'), findsOneWidget);
    expect(find.text('7a'), findsOneWidget);
    expect(find.text('CONSENSO DA COMUNIDADE'), findsOneWidget);
    expect(find.text('7b'), findsOneWidget);
    expect(find.text('80% sugerem +1'), findsOneWidget);
    expect(find.byType(BolhaEmojiAlertaVia), findsOneWidget);

    await tester.tap(find.byKey(const Key('bolha_alerta_ABELHAS_INSETOS')));
    expect(alertaTocado?.uid, 'alertaTopo0001');
  });

  testWidgets('CartaoGrauVia exibe estado vazio de consenso quando ainda não há votos', (tester) async {
    await tester.pumpWidget(
      envolver(
        const CartaoGrauVia(
          rotuloGrauOficial: 'GRAU OFICIAL',
          grauOficial: null,
          complementoGrauOficial: 'Guia Oficial / Conquistador',
          consensoGrau: ConsensoGrauVia.vazio(),
        ),
      ),
    );

    expect(find.text('—'), findsOneWidget);
    expect(find.text('Sem votos'), findsOneWidget);
  });
}
