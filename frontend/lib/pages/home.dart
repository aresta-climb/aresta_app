import 'package:flutter/material.dart';
import '../view_functions/home_functions.dart';
import '../services/dataset_repository.dart';
import '../services/http/sync_service.dart';
import '../theme/app_colors.dart';

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
        child: buildHomeBody(context, syncService, onSwitchTab),
      ),
    );
  }
}
