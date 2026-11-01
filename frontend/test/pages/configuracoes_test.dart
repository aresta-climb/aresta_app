// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/pages/configuracoes.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/configuracao_recursos.dart';
import 'package:frontend/services/controlador_interacoes_usuario.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/widgets/modal_beta_aberto.dart';
import 'package:frontend/view/view_models/configuracoes_view_model.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String tempPath;
  FakePathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return tempPath;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late DatasetRepository mockRepo;
  late EditorDeCroqui mockEditor;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('settings_test_');
    SharedPreferences.setMockInitialValues({});
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);

    mockEditor = EditorDeCroqui();
    mockRepo = DatasetRepository(editorDeCroqui: mockEditor);

    PackageInfo.setMockInitialValues(
      appName: 'Aresta Climb',
      packageName: 'com.aresta.app',
      version: '1.2.3',
      buildNumber: '42',
      buildSignature: 'buildSignature',
    );
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('SettingsPage deve renderizar o título de configurações', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SettingsPage(
        viewModel: SettingsViewModel(
          datasetRepo: mockRepo,
          editorDeCroqui: mockEditor,
        ),
      ),
    ));
    expect(find.text('Configurações'), findsOneWidget);
  });

  testWidgets('SettingsPage deve exibir a versão com (Beta Aberto) e abrir o modal ao tocar', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        extensions: const [AppColors.dark],
      ),
      home: SettingsPage(
        viewModel: SettingsViewModel(
          datasetRepo: mockRepo,
          editorDeCroqui: mockEditor,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final versaoFinder = find.text('Aresta Climb v1.2.3 (Beta Aberto)');
    expect(versaoFinder, findsOneWidget);

    await tester.tap(versaoFinder);
    await tester.pumpAndSettle();

    expect(find.byType(ModalBetaAberto), findsOneWidget);
  });

  testWidgets(
    'SettingsPage inclui o recuo inferior do sistema (padding.bottom) no preenchimento inferior do ListView',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [AppColors.dark],
          ),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(bottom: 48),
              ),
              child: child!,
            );
          },
          home: SettingsPage(
            viewModel: SettingsViewModel(
              datasetRepo: mockRepo,
              editorDeCroqui: mockEditor,
            ),
          ),
        ),
      );

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(
        listView.padding,
        equals(const EdgeInsets.fromLTRB(16, 16, 16, 64)),
      );
    },
  );

  testWidgets(
    'SettingsPage oculta cartão PERFIL E CADERNETA quando perfilHabilitado é false e permite alternar preferência quando habilitado',
    (tester) async {
      ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(false);
      ControladorInteracoesUsuario.redefinirParaTestes();
      addTearDown(() {
        ConfiguracaoRecursos.redefinirParaTestes();
        ControladorInteracoesUsuario.redefinirParaTestes();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AppColors.dark]),
          home: SettingsPage(
            viewModel: SettingsViewModel(
              datasetRepo: mockRepo,
              editorDeCroqui: mockEditor,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PERFIL E CADERNETA'), findsNothing);
      expect(
        find.byKey(const Key('switch_interacoes_caderneta')),
        findsNothing,
      );

      ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [AppColors.dark]),
          home: SettingsPage(
            viewModel: SettingsViewModel(
              datasetRepo: mockRepo,
              editorDeCroqui: mockEditor,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PERFIL E CADERNETA'), findsOneWidget);
      final switchFinder = find.byKey(const Key('switch_interacoes_caderneta'));
      expect(switchFinder, findsOneWidget);
      expect(ControladorInteracoesUsuario.instancia.interacoesAtivas, isTrue);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(ControladorInteracoesUsuario.instancia.interacoesAtivas, isFalse);
    },
  );
}
