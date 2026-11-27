// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../idioma/tradutor_app.dart';

Widget buildGPSBody() {
  return Builder(
    builder: (context) => Center(
      child: Text(
        context.tr(ChaveTexto.picoGpsEmBreve),
        style: const TextStyle(color: Colors.white),
      ),
    ),
  );
}
