// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/constants/network_constants.dart';

void main() {
  group('NetworkConstants', () {
    test('possui valores padrão estáticos consistentes e imutáveis', () {
      expect(NetworkConstants.kDataVersion, isPositive);
      expect(
        NetworkConstants.kDefaultServingBaseUrl,
        'https://serving.arestaclimb.com',
      );
      expect(
        NetworkConstants.kDefaultOfficialServerUrl,
        'https://serving.arestaclimb.com/v${NetworkConstants.kDataVersion}',
      );
      expect(
        NetworkConstants.kDefaultFeedbackEdgeFunctionUrl,
        'https://gawgqiqzptckwghgqypt.supabase.co/functions/v1/app-feedback',
      );
      expect(
        NetworkConstants.kDefaultWhatsappCommunityUrl,
        'https://chat.whatsapp.com/JmxWeLSmGTT66AREtrKyjA',
      );
      expect(
        NetworkConstants.kDefaultDiscordCommunityUrl,
        'https://discord.gg/NT9uSKJWYs',
      );
    });

    group('Validação de integridade e formato das URLs', () {
      void validarUriHttps(String urlString, {required String expectedHost}) {
        final uri = Uri.tryParse(urlString);
        expect(uri, isNotNull, reason: 'A URL "$urlString" deve ser um URI válido');
        expect(uri!.isAbsolute, isTrue, reason: 'A URL deve ser absoluta');
        expect(uri.scheme, 'https', reason: 'A URL deve utilizar estritamente o protocolo HTTPS seguro');
        expect(uri.host, expectedHost, reason: 'O host da URL deve corresponder ao esperado');
        expect(uri.hasAuthority, isTrue, reason: 'A URL deve conter autoridade/host válido');
      }

      test('kDefaultServingBaseUrl é uma URL HTTPS válida no domínio arestaclimb.com', () {
        validarUriHttps(
          NetworkConstants.kDefaultServingBaseUrl,
          expectedHost: 'serving.arestaclimb.com',
        );
      });

      test('kDefaultOfficialServerUrl é uma URL HTTPS válida contendo a versão de dados', () {
        validarUriHttps(
          NetworkConstants.kDefaultOfficialServerUrl,
          expectedHost: 'serving.arestaclimb.com',
        );
        final uri = Uri.parse(NetworkConstants.kDefaultOfficialServerUrl);
        expect(uri.pathSegments.last, 'v${NetworkConstants.kDataVersion}');
      });

      test('kDefaultFeedbackEdgeFunctionUrl é uma URL HTTPS válida da Edge Function no Supabase', () {
        validarUriHttps(
          NetworkConstants.kDefaultFeedbackEdgeFunctionUrl,
          expectedHost: 'gawgqiqzptckwghgqypt.supabase.co',
        );
        final uri = Uri.parse(NetworkConstants.kDefaultFeedbackEdgeFunctionUrl);
        expect(uri.path, '/functions/v1/app-feedback');
      });

      test('kDefaultWhatsappCommunityUrl é um link HTTPS de convite do WhatsApp válido', () {
        validarUriHttps(
          NetworkConstants.kDefaultWhatsappCommunityUrl,
          expectedHost: 'chat.whatsapp.com',
        );
        final uri = Uri.parse(NetworkConstants.kDefaultWhatsappCommunityUrl);
        expect(uri.pathSegments, isNotEmpty);
        expect(uri.pathSegments.first, 'JmxWeLSmGTT66AREtrKyjA');
      });

      test('kDefaultDiscordCommunityUrl é um link HTTPS de convite do Discord válido', () {
        validarUriHttps(
          NetworkConstants.kDefaultDiscordCommunityUrl,
          expectedHost: 'discord.gg',
        );
        final uri = Uri.parse(NetworkConstants.kDefaultDiscordCommunityUrl);
        expect(uri.pathSegments, isNotEmpty);
        expect(uri.pathSegments.first, 'NT9uSKJWYs');
      });
    });
  });
}
