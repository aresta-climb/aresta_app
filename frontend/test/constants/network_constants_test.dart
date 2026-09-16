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
  });
}
