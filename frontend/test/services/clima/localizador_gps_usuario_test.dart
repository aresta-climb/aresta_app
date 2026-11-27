// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/clima/localizador_gps_usuario.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/mock_geolocator_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalizadorGpsUsuario', () {
    test(
      'deve ler e gravar cache local e tratar GPS desligado, permissoes negadas, fallback lastKnown e sucesso',
      () async {
        final geo = MockGeolocatorPlatform();
        GeolocatorPlatform.instance = geo;
        const localizador = LocalizadorGpsUsuario();

        SharedPreferences.setMockInitialValues({});
        expect(await localizador.lerCoordenadaCache(), isNull);

        // 1. GPS desligado sem e com fallback
        geo.isLocationServiceEnabledResult = false;
        final semFallback = await localizador.obterPosicaoAtual();
        expect(semFallback.coordenada, isNull);
        expect(semFallback.aviso, contains('Ative o GPS'));

        final comFallback = await localizador.obterPosicaoAtual(
          coordenadaFallback: (latitude: -19.9, longitude: -43.9),
        );
        expect(comFallback.coordenada?.latitude, closeTo(-19.9, 0.001));
        expect(comFallback.aviso, contains('GPS desligado'));

        // 2. Permissao negada permanentemente -> abre configuracoes do app
        geo.isLocationServiceEnabledResult = true;
        geo.checkPermissionResult = LocationPermission.denied;
        geo.requestPermissionResult = LocationPermission.deniedForever;
        final negada = await localizador.obterPosicaoAtual();
        expect(negada.coordenada, isNull);
        expect(geo.openAppSettingsCalled, isTrue);

        // 3. Timeout em getCurrentPosition e lastKnown nulo -> aviso sem sinal
        geo.checkPermissionResult = LocationPermission.whileInUse;
        geo.currentPositionException = Exception('Timeout indoor');
        geo.lastKnownPositionResult = null;
        final semSinal = await localizador.obterPosicaoAtual();
        expect(semSinal.coordenada, isNull);
        expect(semSinal.aviso, contains('sinal de GPS'));

        // 4. Fallback via getLastKnownPosition grava no cache SharedPreferences
        geo.lastKnownPositionResult = Position(
          latitude: -19.55,
          longitude: -43.75,
          timestamp: DateTime.utc(2026, 11, 25),
          accuracy: 8.0,
          altitude: 800.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
        final viaLastKnown = await localizador.obterPosicaoAtual();
        expect(viaLastKnown.aviso, isNull);
        expect(viaLastKnown.coordenada?.latitude, closeTo(-19.55, 0.001));
        final salvo = await localizador.lerCoordenadaCache();
        expect(salvo?.latitude, closeTo(-19.55, 0.001));

        // 5. Posicao direta de alta precisao
        geo.currentPositionException = null;
        geo.currentPositionResult = Position(
          latitude: -20.12,
          longitude: -44.22,
          timestamp: DateTime.utc(2026, 11, 25),
          accuracy: 4.0,
          altitude: 950.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
        final atual = await localizador.obterPosicaoAtual();
        expect(atual.coordenada?.latitude, closeTo(-20.12, 0.001));
      },
    );
  });
}
