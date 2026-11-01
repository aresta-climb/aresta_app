// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/services/caderneta/resolvedor_metadados_caderneta.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _PathProviderTemporarioFake extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String caminho;
  _PathProviderTemporarioFake(this.caminho);

  @override
  Future<String?> getApplicationDocumentsPath() async => caminho;

  @override
  Future<String?> getTemporaryPath() async => '$caminho/temp';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory dirTemp;
  late RepositorioCadernetaLocal repoCaderneta;
  late RepositorioCatalogo repoCatalogo;

  setUp(() async {
    dirTemp = await Directory.systemTemp.createTemp(
      'resolvedor_metadados_caderneta_test_',
    );
    PathProviderPlatform.instance = _PathProviderTemporarioFake(dirTemp.path);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repoCaderneta = RepositorioCadernetaLocal(preferencias: prefs);
    await repoCaderneta.inicializar();

    repoCatalogo = RepositorioCatalogo(
      provedorCaminhoBanco: () async => '${dirTemp.path}/catalogo.db',
      fabricaBanco: databaseFactoryFfi,
    );
  });

  tearDown(() async {
    await repoCatalogo.fechar();
    if (dirTemp.existsSync()) {
      try {
        dirTemp.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  group('ResolvedorMetadadosCaderneta', () {
    test('retorna zero picos distintos e metadados nulos quando a caderneta está vazia', () async {
      final resolvedor = ResolvedorMetadadosCaderneta(
        repositorioCaderneta: repoCaderneta,
        repositorioCatalogo: repoCatalogo,
      );
      await resolvedor.atualizar();

      expect(resolvedor.obterTotalPicosDistintos(), equals(0));
      expect(resolvedor.obterNomeDaVia('uidInexistente'), isNull);
      expect(resolvedor.obterGrauDaVia('uidInexistente'), isNull);

      resolvedor.dispose();
    });
  });
}
