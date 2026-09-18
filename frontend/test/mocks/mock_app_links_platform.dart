// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:app_links_platform_interface/app_links_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Implementação mock de [AppLinksPlatform] para uso em testes de unidade e widget.
class MockAppLinksPlatform extends AppLinksPlatform with MockPlatformInterfaceMixin {
  Uri? initialLink;
  final StreamController<Uri> uriStreamController = StreamController<Uri>.broadcast();

  @override
  Future<Uri?> getInitialLink() async => initialLink;

  @override
  Future<String?> getInitialLinkString() async => initialLink?.toString();

  @override
  Future<Uri?> getLatestLink() async => initialLink;

  @override
  Future<String?> getLatestLinkString() async => initialLink?.toString();

  @override
  Stream<String> get stringLinkStream =>
      uriStreamController.stream.map((uri) => uri.toString());

  @override
  Stream<Uri> get uriLinkStream => uriStreamController.stream;

  void dispose() {
    uriStreamController.close();
  }
}
