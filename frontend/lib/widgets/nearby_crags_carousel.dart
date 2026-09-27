// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/dataset/modelos/metadados_indice.dart';
import '../services/dataset/modelos/resumo_pico.dart';
import '../services/firebase/app_logger.dart';
import '../theme/app_colors.dart';
import '../view_functions/view_models/home_view_model.dart';
import '../data/dtos/pico_proximo_dto.dart';
import 'crag_card.dart';

/// Representa um pico de escalada com distância calculada para exibição no carrossel.
class PicoProximo {
  final dynamic pico;
  final double distanciaKm;

  const PicoProximo({
    required this.pico,
    required this.distanciaKm,
  });

  String get id {
    if (pico is MetadadosIndice) return (pico as MetadadosIndice).id;
    if (pico is ResumoPico) return (pico as ResumoPico).id;
    if (pico is PicoProximoDTO) return (pico as PicoProximoDTO).id;
    if (pico is Map) return pico['id']?.toString() ?? '';
    return '';
  }

  String get nome {
    if (pico is MetadadosIndice) return (pico as MetadadosIndice).nome;
    if (pico is ResumoPico) return (pico as ResumoPico).nome;
    if (pico is PicoProximoDTO) return (pico as PicoProximoDTO).nome;
    if (pico is Map) return pico['nome']?.toString() ?? '';
    return '';
  }

  double? get latitude {
    if (pico is MetadadosIndice) return (pico as MetadadosIndice).latitude;
    if (pico is ResumoPico) return (pico as ResumoPico).latitude;
    if (pico is Map) return (pico['latitude'] as num?)?.toDouble();
    return null;
  }

  double? get longitude {
    if (pico is MetadadosIndice) return (pico as MetadadosIndice).longitude;
    if (pico is ResumoPico) return (pico as ResumoPico).longitude;
    if (pico is Map) return (pico['longitude'] as num?)?.toDouble();
    return null;
  }

  PicoProximo copyWith({
    dynamic pico,
    double? distanciaKm,
  }) {
    return PicoProximo(
      pico: pico ?? this.pico,
      distanciaKm: distanciaKm ?? this.distanciaKm,
    );
  }
}

/// Carrossel horizontal que exibe os picos mais próximos da localização atual do usuário (Dumb UI).
///
/// Obtém permissão de GPS e coordenadas, informando ao [HomeViewModel] para que este
/// processe as distâncias e forneça a lista reativa de [PicoProximoDTO].
class NearbyCragsCarousel extends StatefulWidget {
  /// Limite padrão de picos exibidos no carrossel de mais próximos.
  static const int kLimitePicosProximos = 6;

  /// ViewModel que fornece dados calculados e gerencia ações da Home.
  final HomeViewModel viewModel;

  const NearbyCragsCarousel({
    super.key,
    required this.viewModel,
  });

  /// Calcula as distâncias geodésicas entre o usuário e uma lista de picos,
  /// aceitando [List<ResumoPico>], [List<MetadadosIndice>] ou listas dinâmicas,
  /// retornando os [limite] picos mais próximos ordenados por distância crescente.
  static List<PicoProximo> calcularPicosMaisProximos({
    required double userLat,
    required double userLon,
    required List<dynamic> picosDisponiveis,
    int limite = kLimitePicosProximos,
  }) {
    final List<PicoProximo> picosComDistancia = [];

    for (final item in picosDisponiveis) {
      final double? picoLat;
      final double? picoLon;

      if (item is MetadadosIndice) {
        picoLat = item.latitude;
        picoLon = item.longitude;
      } else if (item is ResumoPico) {
        picoLat = item.latitude;
        picoLon = item.longitude;
      } else if (item is Map) {
        final mapa = Map<String, dynamic>.from(item);
        picoLat = (mapa['latitude'] as num?)?.toDouble();
        picoLon = (mapa['longitude'] as num?)?.toDouble();
      } else {
        try {
          picoLat = (item.latitude as num?)?.toDouble();
          picoLon = (item.longitude as num?)?.toDouble();
        } catch (_) {
          continue;
        }
      }

      if (picoLat != null && picoLon != null) {
        final double distanceInMeters = Geolocator.distanceBetween(
          userLat,
          userLon,
          picoLat,
          picoLon,
        );

        picosComDistancia.add(
          PicoProximo(
            pico: item,
            distanciaKm: distanceInMeters / 1000,
          ),
        );
      }
    }

    picosComDistancia.sort(
      (a, b) => a.distanciaKm.compareTo(b.distanciaKm),
    );

    return picosComDistancia.take(limite).toList();
  }

  /// Formata uma distância em metros para uma string amigável ao usuário (ex: '350m' ou '12.4km').
  static String formatarDistancia(double metros) {
    if (metros < 1000) {
      return '${metros.round()}m';
    } else {
      final double km = metros / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  /// Calcula o índice circular para permitir rolagem contínua (loop infinito) no carrossel.
  static int calcularIndiceCircular(int index, int totalItens) {
    if (totalItens <= 0) return 0;
    return index % totalItens;
  }

  @override
  State<NearbyCragsCarousel> createState() => _NearbyCragsCarouselState();
}

class _NearbyCragsCarouselState extends State<NearbyCragsCarousel> {
  static const String _kLastKnownLatKey = 'last_known_latitude';
  static const String _kLastKnownLonKey = 'last_known_longitude';

  bool _isLoading = true;
  bool _permissionDenied = false;
  double? _lastUserLat;
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_aoAtualizarViewModel);
    _initLocation();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    widget.viewModel.removeListener(_aoAtualizarViewModel);
    super.dispose();
  }

  void _aoAtualizarViewModel() {
    if (mounted) setState(() {});
  }

  Future<void> _handleDownload(String id, String name) async {
    if (await widget.viewModel.syncService.isNetworkDisabled()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sua versão do Aresta está desatualizada. Atualize para continuar baixando croquis.',
            ),
          ),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Baixando $name...')));
    }

    final success = await widget.viewModel.baixarPico(id);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '$name baixado' : 'Falha ao baixar $name'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @visibleForTesting
  List<PicoProximo> get closestCrags {
    return widget.viewModel.picosProximos
        .map((p) => PicoProximo(pico: p, distanciaKm: p.distanciaKm ?? 0.0))
        .toList();
  }

  @visibleForTesting
  void handleDownload(dynamic crag) async {
    final String id;
    final String name;

    if (crag is MetadadosIndice) {
      id = crag.id;
      name = crag.nome.isEmpty ? 'Pico' : crag.nome;
    } else if (crag is PicoProximo) {
      id = crag.id;
      name = crag.nome.isEmpty ? 'Pico' : crag.nome;
    } else if (crag is PicoProximoDTO) {
      id = crag.id;
      name = crag.nome.isEmpty ? 'Pico' : crag.nome;
    } else if (crag is ResumoPico) {
      id = crag.id;
      name = crag.nome.isEmpty ? 'Pico' : crag.nome;
    } else if (crag is Map) {
      id = crag['id']?.toString() ?? '';
      name = crag['nome']?.toString() ?? 'Pico';
    } else {
      return;
    }
    await _handleDownload(id, name);
  }

  Future<void> _initLocation() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      await _fallbackToCachedLocationOrFinish();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (!mounted) return;
    if (permission == LocationPermission.denied) {
      setState(() {
        _isLoading = false;
        _permissionDenied = true;
      });
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _permissionDenied = true;
      });
      await _fallbackToCachedLocationOrFinish();
      return;
    }

    setState(() {
      _permissionDenied = false;
    });

    await _fetchGpsLocation();
  }

  Future<void> _requestPermission() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    LocationPermission permission = await Geolocator.requestPermission();
    if (!mounted) return;

    if (permission == LocationPermission.denied) {
      setState(() {
        _isLoading = false;
        _permissionDenied = true;
      });
      await _fallbackToCachedLocationOrFinish();
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoading = false;
        _permissionDenied = true;
      });
      await Geolocator.openAppSettings();
      await _fallbackToCachedLocationOrFinish();
      return;
    }

    setState(() {
      _permissionDenied = false;
    });
    await _fetchGpsLocation();
  }

  void _applyPosition(Position position) {
    if (!mounted) return;
    _lastUserLat = position.latitude;
    _saveLocationToCache(position.latitude, position.longitude);
    widget.viewModel.atualizarLocalizacaoUsuario(position.latitude, position.longitude);
    setState(() {
      _isLoading = false;
      _permissionDenied = false;
    });
  }

  void _startPositionStream() {
    _positionSubscription?.cancel();
    try {
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
        (Position position) {
          _applyPosition(position);
        },
        onError: (_) {},
        cancelOnError: false,
      );
    } catch (_) {}
  }

  Future<void> _fetchGpsLocation() async {
    if (!mounted) return;

    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        _applyPosition(lastKnown);
      }
    } catch (_) {}

    if (_lastUserLat == null) {
      await _fallbackToCachedLocationOrFinish();
    }

    if (_lastUserLat != null) {
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        _applyPosition(position);
        return;
      }
    } catch (_) {
      _startPositionStream();
    }

    if (mounted && _lastUserLat == null) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLocationToCache(double lat, double lon) async {
    _lastUserLat = lat;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kLastKnownLatKey, lat);
      await prefs.setDouble(_kLastKnownLonKey, lon);
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Erro ao persistir localização em cache',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _fallbackToCachedLocationOrFinish() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedLat = prefs.getDouble(_kLastKnownLatKey);
      final cachedLon = prefs.getDouble(_kLastKnownLonKey);

      if (!mounted) return;

      if (cachedLat != null && cachedLon != null) {
        _lastUserLat = cachedLat;
        widget.viewModel.atualizarLocalizacaoUsuario(cachedLat, cachedLon);
        setState(() {
          _isLoading = false;
          _permissionDenied = false;
        });
        return;
      }
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Erro ao ler localização do cache',
        error: e,
        stackTrace: stackTrace,
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final picos = widget.viewModel.picosProximos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Text(
                'MAIS PRÓXIMOS DE VOCÊ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              if (picos.isNotEmpty) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.location_on,
                  color: context.colors.ashGrey,
                  size: 14,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(height: 280, child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    final isDatasetLoading = widget.viewModel.carregando;

    if (_isLoading || isDatasetLoading) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.rustIron),
      );
    }

    if (_permissionDenied) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.colors.caveShadow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.colors.graniteEdge),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              color: context.colors.ashGrey,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Permita o acesso à localização para ver os picos mais próximos de você.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _requestPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.rustIron,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Permitir Localização',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    if (_lastUserLat == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Aguardando sinal de GPS...',
              style: TextStyle(color: context.colors.ashGrey),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _initLocation,
              icon: Icon(Icons.refresh, size: 16, color: context.colors.rustIron),
              label: Text(
                'Tentar novamente',
                style: TextStyle(color: context.colors.rustIron, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final picos = widget.viewModel.picosProximos;
    if (picos.isEmpty) {
      return Center(
        child: Text(
          'Nenhum pico com localização encontrada.',
          style: TextStyle(color: context.colors.ashGrey),
        ),
      );
    }

    final int? totalItens = picos.length > 1 ? null : picos.length;

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      itemCount: totalItens,
      padding: const EdgeInsets.only(left: 24, right: 8),
      itemBuilder: (context, index) {
        final int indiceReal = NearbyCragsCarousel.calcularIndiceCircular(
          index,
          picos.length,
        );
        final pico = picos[indiceReal];

        return Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: SizedBox(
            width: 340,
            child: CragCard(
              dados: pico.paraCardCroquiDTO(),
              downloadingCrags: widget.viewModel.downloadingCrags,
              onDownload: () => _handleDownload(pico.id, pico.nome),
              onOpen: () => widget.viewModel.abrirPico(context, pico.id),
            ),
          ),
        );
      },
    );
  }
}
