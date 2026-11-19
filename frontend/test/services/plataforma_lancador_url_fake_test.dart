// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'plataforma_lancador_url_fake.dart';

void main() {
  test('registra URLs abertas, delega launch legado e simula falhas determinísticas', () async {
    final fake = PlataformaLancadorUrlFake();
    expect(fake.linkDelegate, isNull);
    expect(await fake.canLaunch('https://aresta.cc'), isTrue);

    expect(
      await fake.launchUrl('https://youtube.com/watch?v=1', const LaunchOptions()),
      isTrue,
    );
    expect(
      await fake.launch(
        'https://instagram.com/p/2',
        useSafariVC: false,
        useWebView: false,
        enableJavaScript: false,
        enableDomStorage: false,
        universalLinksOnly: false,
        headers: const {},
      ),
      isTrue,
    );
    expect(
      fake.urlsAbertas,
      equals(['https://youtube.com/watch?v=1', 'https://instagram.com/p/2']),
    );

    fake.resultadoSimulado = false;
    expect(await fake.canLaunch('https://aresta.cc'), isFalse);
    expect(await fake.launchUrl('https://aresta.cc', const LaunchOptions()), isFalse);

    fake.erroSimulado = StateError('Navegador indisponível');
    await expectLater(
      () => fake.launchUrl('https://aresta.cc', const LaunchOptions()),
      throwsStateError,
    );
  });
}
