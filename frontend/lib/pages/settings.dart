import 'package:flutter/material.dart';
import '../view_functions/common_functions.dart';
import '../view_functions/settings_functions.dart';
import '../services/dataset_repository.dart';
/// Página de Configurações do aplicativo.
class SettingsPage extends StatefulWidget {
  final DatasetRepository datasetRepo;

  const SettingsPage({super.key, required this.datasetRepo});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _clickCount = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildCommonAppBar(context, 'Configurações'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              buildThemeSelectionCard(context),
              const SizedBox(height: 16),
              buildEditorCard(
                context: context,
                datasetRepo: widget.datasetRepo,
                clickCount: _clickCount,
                onSetClickCount: (val) => setState(() => _clickCount = val),
              ),
              const SizedBox(height: 16),
              buildAppVersionCard(context),
              const SizedBox(height: 24),
              buildLegalLinks(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

