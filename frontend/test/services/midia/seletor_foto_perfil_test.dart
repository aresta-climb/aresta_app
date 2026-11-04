// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/midia/seletor_foto_perfil.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const canal = MethodChannel('app.escalada.croquis/seletor_midia');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, null);
    SeletorFotoPerfilNativo.redefinirParaTestes();
  });

  group('SeletorFotoPerfilNativo', () {
    test('expõe instância singleton configurável e redefinível para testes', () {
      final padrao = SeletorFotoPerfilNativo.instancia;
      final custom = SeletorFotoPerfilNativo();
      SeletorFotoPerfilNativo.instancia = custom;
      expect(identical(SeletorFotoPerfilNativo.instancia, custom), isTrue);

      SeletorFotoPerfilNativo.redefinirParaTestes();
      expect(identical(SeletorFotoPerfilNativo.instancia, custom), isFalse);
      expect(SeletorFotoPerfilNativo.instancia, isA<SeletorFotoPerfil>());
      expect(padrao, isA<SeletorFotoPerfil>());
    });

    test('retorna Data URI base64 quando o canal nativo devolve bytes JPEG válidos', () async {
      final bytesSimulados = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x01, 0x02]);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, (call) async {
            if (call.method == 'selecionarFotoPerfil') {
              return bytesSimulados;
            }
            return null;
          });

      final seletor = SeletorFotoPerfilNativo();
      final dataUri = await seletor.selecionarFotoComoDataUri();

      expect(dataUri, equals('data:image/jpeg;base64,${base64Encode(bytesSimulados)}'));
    });

    test('retorna null quando o usuário cancela a seleção, bytes vêm vazios ou ocorre exceção de plataforma', () async {
      final seletor = SeletorFotoPerfilNativo();

      // 1. Sem handler (MissingPluginException) -> null
      expect(await seletor.selecionarFotoComoDataUri(), isNull);

      // 2. Retorno nulo (usuário cancelou) -> null
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, (_) async => null);
      expect(await seletor.selecionarFotoComoDataUri(), isNull);

      // 3. Retorno de lista vazia -> null
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, (_) async => Uint8List(0));
      expect(await seletor.selecionarFotoComoDataUri(), isNull);

      // 4. PlatformException -> null
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            canal,
            (_) async => throw PlatformException(code: 'ERRO_GALERIA'),
          );
      expect(await seletor.selecionarFotoComoDataUri(), isNull);
    });
  });
}

