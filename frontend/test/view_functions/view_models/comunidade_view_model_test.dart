// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/view_functions/view_models/comunidade_view_model.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import '../../mocks/mock_telemetry_service.dart';
import '../../mocks/mock_app_logger.dart';
import '../../pages/comunidade_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockUrlLauncherPlatform mockLauncher;
  late FakeRemoteConfigService fakeRemoteConfig;

  setUp(() {
    mockLauncher = MockUrlLauncherPlatform();
    UrlLauncherPlatform.instance = mockLauncher;
    TelemetryService.instance = MockTelemetryService();
    AppLogger.instance = MockAppLogger();
    fakeRemoteConfig = FakeRemoteConfigService();
  });

  group('ComunidadeViewModel', () {
    test('instanciação direta com valores customizados', () {
      final vm = ComunidadeViewModel(
        whatsapp: const ItemCanalComunidade(
          titulo: 'WHATSAPP TESTE',
          subtitulo: 'Sub Whatsapp',
          url: 'https://chat.whatsapp.com/teste',
          rotulo: 'WhatsApp',
        ),
        instagram: const ItemCanalComunidade(
          titulo: 'INSTAGRAM TESTE',
          subtitulo: 'Sub Insta',
          url: 'https://instagram.com/teste',
          rotulo: 'Instagram',
        ),
        linkedin: const ItemCanalComunidade(
          titulo: 'LINKEDIN TESTE',
          subtitulo: 'Sub Linkedin',
          url: 'https://linkedin.com/teste',
          rotulo: 'LinkedIn',
        ),
        discord: const ItemCanalComunidade(
          titulo: 'DISCORD TESTE',
          subtitulo: 'Sub Discord',
          url: 'https://discord.gg/teste',
          rotulo: 'Discord',
        ),
        github: const ItemCanalComunidade(
          titulo: 'GITHUB TESTE',
          subtitulo: 'Sub Github',
          url: 'https://github.com/teste',
          rotulo: 'GitHub',
        ),
      );

      expect(vm.whatsapp.titulo, 'WHATSAPP TESTE');
      expect(vm.whatsapp.url, 'https://chat.whatsapp.com/teste');
      expect(vm.instagram.url, 'https://instagram.com/teste');
      expect(vm.linkedin.url, 'https://linkedin.com/teste');
      expect(vm.discord.url, 'https://discord.gg/teste');
      expect(vm.github.url, 'https://github.com/teste');
    });

    test('ComunidadeViewModel.doServico carrega URLs do RemoteConfigService', () {
      final vm = ComunidadeViewModel.doServico(servico: fakeRemoteConfig);

      expect(vm.whatsapp.url, fakeRemoteConfig.whatsappCommunityUrl);
      expect(vm.discord.url, fakeRemoteConfig.discordCommunityUrl);
      expect(vm.instagram.url, contains('instagram.com/arestaclimb'));
      expect(vm.linkedin.url, contains('linkedin.com/company/arestaclimb'));
      expect(vm.github.url, contains('github.com/aresta-climb'));
    });

    test('executar em cada canal dispara a URL esperada via launcher', () {
      final vm = ComunidadeViewModel.doServico(servico: fakeRemoteConfig);

      vm.whatsapp.executar();
      expect(mockLauncher.lastLaunchedUrl, fakeRemoteConfig.whatsappCommunityUrl);

      vm.instagram.executar();
      expect(mockLauncher.lastLaunchedUrl, 'https://www.instagram.com/arestaclimb/');

      vm.linkedin.executar();
      expect(mockLauncher.lastLaunchedUrl, 'https://www.linkedin.com/company/arestaclimb/');

      vm.discord.executar();
      expect(mockLauncher.lastLaunchedUrl, fakeRemoteConfig.discordCommunityUrl);

      vm.github.executar();
      expect(mockLauncher.lastLaunchedUrl, 'https://github.com/aresta-climb');
    });
  });
}
