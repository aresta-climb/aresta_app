// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/data/modelos/tipo_escalada.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/view/function_library/funcoes_caderneta.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final cadeiaExemplo = Cadena(
    id: 'cadena-123',
    escaladaUid: 'via-abc',
    dataAscensao: DateTime(2026, 10, 24, 15, 30),
    tipoAscensao: TipoAscensao.aVista,
    tipoEscalada: TipoEscalada.guiado,
    tentativas: 1,
    notasPrivadas: 'Aderência perfeita no entardecer',
  );

  Widget montarComTema(Widget child) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('Biblioteca de Funções da Caderneta (funcoes_caderneta.dart)', () {
    testWidgets('buildSecaoHistoricoCadenas exibe estado informativo vazio quando não há registros', (tester) async {
      await tester.pumpWidget(
        montarComTema(
          Builder(
            builder: (context) => buildSecaoHistoricoCadenas(
              context,
              historico: const [],
              obterNomeVia: (_) => 'Via Desconhecida',
              obterGrauVia: (_) => null,
              formatarData: (_) => '24/10/2026',
              onExcluirCadena: (_) {},
            ),
          ),
        ),
      );

  });
}
