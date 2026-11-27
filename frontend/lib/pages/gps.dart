// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../idioma/tradutor_app.dart';
import '../view/function_library/gps_functions.dart';
import '../view/function_library/biblioteca_funcoes_comuns.dart';

/// Página de GPS do aplicativo (Dumb UI).
class GPSPage extends StatelessWidget {
  const GPSPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<IdiomaApp>(
      valueListenable: ControladorIdiomaApp.instancia.notificadorIdioma,
      builder: (context, _, _) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: buildCommonAppBar(context, context.tr(ChaveTexto.navGps)),
        body: buildGPSBody(),
      ),
    );
  }
}
