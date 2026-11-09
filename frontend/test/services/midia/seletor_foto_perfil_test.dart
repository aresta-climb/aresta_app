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

    test('retorna Data URI WebP base64 quando o canal nativo devolve bytes WebP ou converte bytes JPEG', () async {
      // Cabeçalho RIFF....WEBP válido
      final bytesWebpNativo = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00,
        0x57, 0x45, 0x42, 0x50, 0x01, 0x02,
      ]);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, (call) async {
            if (call.method == 'selecionarFotoPerfil') {
              return bytesWebpNativo;
            }
            return null;
          });

      final seletor = SeletorFotoPerfilNativo();
      final dataUri = await seletor.selecionarFotoComoDataUri();

      expect(
        dataUri,
        equals('data:image/webp;base64,${base64Encode(bytesWebpNativo)}'),
      );

      // Quando o canal nativo devolve bytes não-WebP (ex: JPEG no iOS), aciona o conversor WebP
      final bytesJpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x01, 0x02]);
      final bytesConvertidos = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, 0x10, 0x00, 0x00, 0x00,
        0x57, 0x45, 0x42, 0x50, 0xAA,
      ]);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, (_) async => bytesJpeg);

      final seletorComConversor = SeletorFotoPerfilNativo(
        conversorWebp: (bytesOriginais) async {
          expect(bytesOriginais, equals(bytesJpeg));
          return bytesConvertidos;
        },
      );
      final dataUriConvertida = await seletorComConversor
          .selecionarFotoComoDataUri();
      expect(
        dataUriConvertida,
        equals('data:image/webp;base64,${base64Encode(bytesConvertidos)}'),
      );

      // Fallback seguro quando o conversor nativo não está disponível no ambiente de teste
      final seletorFallback = await seletor.selecionarFotoComoDataUri();
      expect(
        seletorFallback,
        equals('data:image/webp;base64,${base64Encode(bytesJpeg)}'),
      );
    });

    test('distingue contêineres RIFF não-WebP e preserva bytes originais quando o conversor devolve lista vazia', () async {
      // Cabeçalho RIFF com fourCC WAVE (não é WEBP)
      final bytesRiffWave = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00,
        0x57, 0x41, 0x56, 0x45, 0x01, 0x02,
      ]);
      var conversorAcionado = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(canal, (_) async => bytesRiffWave);

      final seletorVazio = SeletorFotoPerfilNativo(
        conversorWebp: (_) async {
          conversorAcionado = true;
          return Uint8List(0);
        },
      );
      final resultado = await seletorVazio.selecionarFotoComoDataUri();
      expect(conversorAcionado, isTrue);
      expect(
        resultado,
        equals('data:image/webp;base64,${base64Encode(bytesRiffWave)}'),
      );
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
