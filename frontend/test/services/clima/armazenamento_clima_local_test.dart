// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/clima/armazenamento_clima_local.dart';
import 'package:frontend/data/modelos/modelos_clima_pico.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _PathProviderDocumentosFake extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String caminho;
  _PathProviderDocumentosFake(this.caminho);

  @override
  Future<String?> getApplicationDocumentsPath() async => caminho;
}

void main() {
  late Directory dirTemp;
  late PathProviderPlatform plataformaOriginal;

  SnapshotClimaAltimetria criarSnapshot(DateTime instante, int altitude) {
    return SnapshotClimaAltimetria(
      geradoEm: instante,
      bolhasChuva: const [],
      chuvaPorPico: const {},
      altimetriaPorPico: {
        'pico_teste': CotaAltimetricaPico(
          altitudeBaseMetros: 800,
          altitudePicoMetros: altitude,
        ),
      },
    );
  }

  setUp(() async {
    plataformaOriginal = PathProviderPlatform.instance;
    dirTemp = await Directory.systemTemp.createTemp('arm_clima_local_test_');
  });

  tearDown(() async {
    PathProviderPlatform.instance = plataformaOriginal;
    if (dirTemp.existsSync()) {
      dirTemp.deleteSync(recursive: true);
    }
  });

  group('ArmazenamentoClimaLocal', () {
    test(
      'deve usar diretorio padrao de documentos, criar subpasta ausente e manter estritamente atual + copia_seguranca',
      () async {
        final subDir = '${dirTemp.path}/aninhado';
        PathProviderPlatform.instance = _PathProviderDocumentosFake(subDir);
        final armazenamento = ArmazenamentoClimaLocal();

