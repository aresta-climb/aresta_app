// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:frontend/view_functions/sobre_time_functions.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_app_logger.dart';
import '../mocks/mock_telemetry_service.dart';

class MockUrlLauncherPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  String? lastLaunchedUrl;
  bool shouldThrow = false;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUrl = url;
    if (shouldThrow) {
      throw Exception('Falha ao abrir URL nativa');
    }
    return true;
  }
}

void main() {
  group('MembroTime', () {
    test('instancia corretamente com valores obrigatórios e padrões vazios', () {
      const membro = MembroTime(
        role: 'Desenvolvedor',
        name: 'Fulano de Tal',
        image: 'assets/team/fulano.webp',
      );

      expect(membro.role, 'Desenvolvedor');
      expect(membro.name, 'Fulano de Tal');
      expect(membro.image, 'assets/team/fulano.webp');
      expect(membro.collapsedRole, isNull);
      expect(membro.linkedin, isEmpty);
      expect(membro.github, isEmpty);
    });

    test('instancia corretamente com todos os campos informados', () {
      const membro = MembroTime(
        role: 'Designer',
        collapsedRole: 'Design',
        name: 'Beltrana',
        linkedin: 'https://linkedin.com/in/beltrana',
        github: 'https://github.com/beltrana',
        image: 'assets/team/beltrana.webp',
      );

      expect(membro.role, 'Designer');
      expect(membro.collapsedRole, 'Design');
      expect(membro.name, 'Beltrana');
      expect(membro.linkedin, 'https://linkedin.com/in/beltrana');
      expect(membro.github, 'https://github.com/beltrana');
      expect(membro.image, 'assets/team/beltrana.webp');
    });
  });

  group('Validação dos links e integridade do teamData', () {
    test('todos os membros do time possuem links externos HTTPS válidos quando configurados', () {
      expect(teamData, isNotEmpty);
      for (final membro in teamData) {
        expect(membro.name, isNotEmpty);
        expect(membro.role, isNotEmpty);
        expect(membro.image, isNotEmpty);

        if (membro.linkedin.isNotEmpty) {
          final uri = Uri.tryParse(membro.linkedin);
          expect(uri, isNotNull, reason: 'LinkedIn de ${membro.name} deve ser um URI válido');
          expect(uri!.isAbsolute, isTrue);
          expect(uri.scheme, 'https');
          expect(uri.host, contains('linkedin.com'));
        }

        if (membro.github.isNotEmpty) {
          final uri = Uri.tryParse(membro.github);
          expect(uri, isNotNull, reason: 'GitHub de ${membro.name} deve ser um URI válido');
          expect(uri!.isAbsolute, isTrue);
          expect(uri.scheme, 'https');
          expect(uri.host, contains('github.com'));
        }
      }
    });
  });

  group('abrirLinkSobreTime', () {
    late MockAppLogger mockLogger;
    late MockTelemetryService mockTelemetria;
    late MockUrlLauncherPlatform mockLauncher;

    setUp(() {
      mockLogger = MockAppLogger();
      AppLogger.instance = mockLogger;
      mockTelemetria = MockTelemetryService();
      TelemetryService.instance = mockTelemetria;
      mockLauncher = MockUrlLauncherPlatform();
      UrlLauncherPlatform.instance = mockLauncher;
    });

    test('abre link com sucesso e registra evento de telemetria sobre_time', () async {
      const url = 'https://discord.gg/NT9uSKJWYs';
      await abrirLinkSobreTime(url, 'Discord');

      expect(mockLauncher.lastLaunchedUrl, equals(url));
      expect(mockTelemetria.recordedEvents, contains('link_externo'));
      final params = mockTelemetria.recordedParams['link_externo']!;
      expect(params['acao'], equals('abrir_link_externo'));
      expect(params['origem'], equals('sobre_time'));
      expect(params['detalhe'], equals(url));
      expect(mockLogger.recordedErrors, isEmpty);
    });

    test('trata exceção ao abrir link registrando erro no AppLogger', () async {
      mockLauncher.shouldThrow = true;
      const url = 'https://github.com/invalido';
      await abrirLinkSobreTime(url, 'GitHub');

      expect(mockTelemetria.recordedEvents, contains('link_externo'));
      expect(
        mockLogger.recordedErrors.any(
          (e) => e['contextMessage'].contains('Erro ao abrir link do GitHub em sobre_time_functions ($url)'),
        ),
        isTrue,
      );
    });
  });
}
