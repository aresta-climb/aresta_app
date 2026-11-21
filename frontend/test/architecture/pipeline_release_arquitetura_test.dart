// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Arquitetura Transacional dos Workflows de Release', () {
    test(
      'release_new_app_version.yml implementa 4 estágios com publicar_nas_lojas, zero git push em prepare_release e git push --atomic em cortar_versao',
      () {
        final arq = File('../.github/workflows/release_new_app_version.yml');
        expect(arq.existsSync(), isTrue);
        final yaml = arq.readAsStringSync();

        expect(yaml, contains('publicar_nas_lojas:'));
        expect(yaml, contains('build_e_smoke_android:'));
        expect(yaml, contains('build_e_smoke_ios:'));
        expect(yaml, contains('cortar_versao:'));
        expect(yaml, contains('publicar_android:'));
        expect(yaml, contains('publicar_ios:'));
        expect(yaml, contains('git push --atomic origin HEAD'));

        final antesDoBuild = yaml.split('build_e_smoke_android:').first;
        expect(
          antesDoBuild.contains('git push'),
          isFalse,
          reason:
              'prepare_release JAMAIS deve executar git push antes da aprovação dos smoke tests Android e iOS.',
        );
      },
    );

    test(
      'build_android.yml e build_ios.yml separam build_e_smoke e publicar reutilizando tarball aprovado sem recompilar',
      () {
        final androidYaml =
            File('../.github/workflows/build_android.yml').readAsStringSync();
        final iosYaml =
            File('../.github/workflows/build_ios.yml').readAsStringSync();

        expect(androidYaml, contains('android-staging-archive.tar.gz'));
        expect(androidYaml, contains('smoke_test_pacote.dart'));
        expect(androidYaml, contains('ORG_GRADLE_PROJECT_arestaSmokeCi=true'));
        expect(
          androidYaml.split('publicar:').last.contains('flutter build'),
          isFalse,
          reason: 'O job publicar do Android não deve recompilar o AAB.',
        );

        expect(iosYaml, contains('ios-staging-archive.tar.gz'));
        expect(iosYaml, contains('smoke_test_pacote.dart'));
        expect(iosYaml, contains('--simulator'));
        expect(
          iosYaml.split('publicar:').last.contains('flutter build'),
          isFalse,
          reason: 'O job publicar do iOS não deve recompilar o IPA.',
        );
      },
    );
  });
}
