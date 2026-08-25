// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../view_functions/home_functions.dart';
import '../services/dataset_repository.dart';
import '../services/http/sync_service.dart';
import '../theme/app_colors.dart';
import '../view_functions/common_functions.dart';

/// A página inicial do aplicativo (nova versão).
class HomePage extends StatelessWidget {
  final DatasetRepository datasetRepo;
  final SyncService syncService;
  final Function(int) onSwitchTab;

  const HomePage({
    super.key,
    required this.datasetRepo,
    required this.syncService,
    required this.onSwitchTab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.deepBasalt,
      body: SafeArea(
        child: RefreshIndicator(
          color: context.colors.dryMoss,
          backgroundColor: context.colors.caveShadow,
          onRefresh: () async {
            await handleManualSync(context, datasetRepo, syncService);
          },
          child: buildHomeBody(context, datasetRepo, syncService, onSwitchTab),
        ),
      ),
    );
  }
}
