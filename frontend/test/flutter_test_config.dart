// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:app_links_platform_interface/app_links_platform_interface.dart';
import 'mocks/mock_app_links_platform.dart';

/// Configuração global executada pelo executor de testes do Flutter antes de cada arquivo de teste.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppLinksPlatform.instance = MockAppLinksPlatform();
  await testMain();
}
