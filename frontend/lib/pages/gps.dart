// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../view_functions/gps_functions.dart';
import '../view_functions/common_functions.dart';

/// Página de GPS do aplicativo (Dumb UI).
class GPSPage extends StatelessWidget {
  const GPSPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: buildCommonAppBar(context, 'GPS'),
      body: buildGPSBody(),
    );
  }
}
