// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../idioma/tradutor_app.dart';

/// Resultado imutável de uma tentativa de leitura da coordenada GPS real do usuário.
typedef ResultadoLocalizacaoGps = ({
  ({double latitude, double longitude})? coordenada,
  String? aviso,
});

/// Serviço modular responsável por hidratar o cache de última coordenada conhecida
/// (`SharedPreferences`) e negociar permissões/leitura do GPS nativo (`Geolocator`).
///
/// Desacopla o `BrowseViewModel` de detalhes de plataforma e chaves de armazenamento local.
class LocalizadorGpsUsuario {
  static const String chaveCacheLatitude = 'last_known_latitude';
  static const String chaveCacheLongitude = 'last_known_longitude';

  const LocalizadorGpsUsuario();

  /// Lê a última coordenada salva localmente (compartilhada com o carrossel da Home).
  Future<({double latitude, double longitude})?> lerCoordenadaCache() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(chaveCacheLatitude);
    final lon = prefs.getDouble(chaveCacheLongitude);
    if (lat == null || lon == null) return null;
    return (latitude: lat, longitude: lon);
  }

  /// Solicita a posição em tempo real tratando serviço desligado, permissões e timeout indoor.
  Future<ResultadoLocalizacaoGps> obterPosicaoAtual({
    ({double latitude, double longitude})? coordenadaFallback,
  }) async {
    final servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivo) {
      return (
        coordenada: coordenadaFallback,
        aviso: coordenadaFallback != null
            ? tr(ChaveTexto.gpsDesligadoUltimaConhecida)
            : tr(ChaveTexto.gpsAtiveAparelho),
      );
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied ||
        permissao == LocationPermission.deniedForever) {
      if (permissao == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
      }
      return (
        coordenada: coordenadaFallback,
        aviso: tr(ChaveTexto.gpsPermissaoNegada),
      );
    }

    Position? posicao;
    try {
      posicao = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      posicao = await Geolocator.getLastKnownPosition();
    }

    if (posicao != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(chaveCacheLatitude, posicao.latitude);
      await prefs.setDouble(chaveCacheLongitude, posicao.longitude);
      return (
        coordenada: (latitude: posicao.latitude, longitude: posicao.longitude),
        aviso: null,
      );
    }

    return (
      coordenada: coordenadaFallback,
      aviso: tr(ChaveTexto.gpsSinalIndisponivel),
    );
  }
}
