// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/view_functions/browse_functions.dart';
import 'package:frontend/view_functions/common_functions.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/services/http/servico_download_segundo_plano.dart';
import 'package:frontend/view_functions/home_functions.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/dataset/modelos/metadados_indice.dart';
import 'package:frontend/services/firebase/app_logger.dart';
import 'package:frontend/theme/app_colors.dart';

/// Carrossel horizontal que exibe os picos mais próximos da localização atual do usuário,
/// permitindo rolagem contínua (looping) e limitando a seleção a no máximo 6 picos.
class NearbyCragsCarousel extends StatefulWidget {
  /// Limite padrão de picos exibidos no carrossel de mais próximos.
  static const int kLimitePicosProximos = 6;

  final SyncService syncService;

  const NearbyCragsCarousel({super.key, required this.syncService});

  /// Calcula as distâncias geodésicas entre o usuário e uma lista de picos,
  /// aceitando [List<ResumoPico>], [List<MetadadosIndice>] ou listas dinâmicas,
  /// retornando os [limite] picos mais próximos ordenados por distância crescente.
  static List<ResumoPico> calcularPicosMaisProximos({
    required double userLat,
    required double userLon,
    required List<dynamic> picosDisponiveis,
    int limite = kLimitePicosProximos,
  }) {
    final List<ResumoPico> picosComDistancia = [];

    for (final item in picosDisponiveis) {
      final double? picoLat;
      final double? picoLon;
      final ResumoPico pico;

      if (item is MetadadosIndice) {
        picoLat = item.latitude;
        picoLon = item.longitude;
        pico = item.paraResumoPico();
      } else if (item is ResumoPico) {
        picoLat = item.latitude;
        picoLon = item.longitude;
        pico = item;
      } else if (item is Map) {
        pico = ResumoPico.deMapa(Map<String, dynamic>.from(item));
        picoLat = pico.latitude;
        picoLon = pico.longitude;
      } else {
        continue;
      }

      if (picoLat != null && picoLon != null) {
        final double distanceInMeters = Geolocator.distanceBetween(
          userLat,
          userLon,
          picoLat,
          picoLon,
        );

        picosComDistancia.add(
          pico.copyWith(distanciaKm: distanceInMeters / 1000),
        );
      }
    }

    picosComDistancia.sort(
      (a, b) =>
          (a.distanciaKm ?? double.infinity).compareTo(b.distanciaKm ?? double.infinity),
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
  double? _lastUserLon;
  StreamSubscription<Position>? _positionSubscription;
  List<ResumoPico> _closestCrags = [];

  @visibleForTesting
  List<ResumoPico> get closestCrags => _closestCrags;

  @override
  void initState() {
    super.initState();
    DatasetRepository.instance?.activeDataset.addListener(_onDatasetOrResetChanged);
    DatasetRepository.instance?.homeResetTrigger.addListener(_onDatasetOrResetChanged);
    _initLocation();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    DatasetRepository.instance?.activeDataset.removeListener(_onDatasetOrResetChanged);
    DatasetRepository.instance?.homeResetTrigger.removeListener(_onDatasetOrResetChanged);
    super.dispose();
  }

  void _onDatasetOrResetChanged() {
    if (!mounted) return;
    if (_lastUserLat != null && _lastUserLon != null) {
      _calculateDistances(_lastUserLat!, _lastUserLon!);
    } else {
      _fallbackToCachedLocationOrFinish();
    }
  }

  @visibleForTesting
  void handleDownload(dynamic crag) async {
    final ResumoPico pico = crag is MetadadosIndice
        ? crag.paraResumoPico()
        : (crag is ResumoPico
            ? crag
            : ResumoPico.deMapa(
                crag is Map<String, dynamic>
                    ? crag
                    : Map<String, dynamic>.from(crag as Map),
              ));
    final String name = pico.nome.isEmpty ? 'Pico' : pico.nome;
    final String id = pico.id;

    if (await widget.syncService.isNetworkDisabled()) {
      if (mounted) {
        showDeprecatedAppVersionSnackBar(context);
      }
      return;
    }

    final repo = DatasetRepository.instance;
    if (repo == null) return;

    final indice = repo.indiceData.value;
    if (indice == null) return;

    final resumos = indice.croquis.where((r) => r.id == id).toList();
    if (resumos.isEmpty) return;

    final resumo = resumos.first;

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Baixando $name...')));

    final servicoDownload =
        ServicoDownloadSegundoPlano(syncService: widget.syncService);
    final success = await servicoDownload.executarDownload(resumo);

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
    _lastUserLon = position.longitude;
    _saveLocationToCache(position.latitude, position.longitude);
    _calculateDistances(position.latitude, position.longitude);
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

  /// Tenta resolver a localização por satélite com degradação progressiva de precisão.
  Future<void> _fetchGpsLocation() async {
    if (!mounted) return;

    // 1. Tenta obter a última posição conhecida do SO (instantâneo)
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        _applyPosition(lastKnown);
      }
    } catch (_) {}

    // 2. Se ainda não temos coordenadas, tenta o cache de SharedPreferences
    if (_lastUserLat == null) {
      await _fallbackToCachedLocationOrFinish();
    }

    // 3. Se já temos localização resolvida, encerra a busca inicial
    if (_lastUserLat != null) {
      return;
    }

    // 4. Solicita a posição GPS atual com precisão alta (necessária no Android/Emulador)
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
      // Se a requisição síncrona expirar, inicia o stream contínuo para capturar quando o sinal chegar
      _startPositionStream();
    }

    if (mounted && _lastUserLat == null) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Salva coordenadas de sucesso em disco local (SharedPreferences).
  Future<void> _saveLocationToCache(double lat, double lon) async {
    _lastUserLat = lat;
    _lastUserLon = lon;
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

  /// Lê as coordenadas salvas em cache local ou conclui o carregamento graciosamente.
  Future<void> _fallbackToCachedLocationOrFinish() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedLat = prefs.getDouble(_kLastKnownLatKey);
      final cachedLon = prefs.getDouble(_kLastKnownLonKey);

      if (!mounted) return;

      if (cachedLat != null && cachedLon != null) {
        _lastUserLat = cachedLat;
        _lastUserLon = cachedLon;
        _calculateDistances(cachedLat, cachedLon);
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

  /// Calcula as distâncias geodésicas entre o usuário e todos os picos do índice local.
  void _calculateDistances(double userLat, double userLon) {
    _lastUserLat = userLat;
    _lastUserLon = userLon;

    final datasetRepo = DatasetRepository.instance;
    final dataset = datasetRepo?.activeDataset.value;
    final availablePicos =
        dataset != null && dataset.metadadosDisponiveis.isNotEmpty
            ? dataset.metadadosDisponiveis
            : (dataset?.availablePicos ?? []);

    final picosOrdenados = NearbyCragsCarousel.calcularPicosMaisProximos(
      userLat: userLat,
      userLon: userLon,
      picosDisponiveis: availablePicos,
    );

    if (mounted) {
      setState(() {
        _closestCrags = picosOrdenados;
        _isLoading = false;
        _permissionDenied = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              if (_closestCrags.isNotEmpty) ...[
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
    final isDatasetLoading =
        DatasetRepository.instance?.activeDataset.value == null;

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

    if (_closestCrags.isEmpty) {
      return Center(
        child: Text(
          'Nenhum pico com localização encontrada.',
          style: TextStyle(color: context.colors.ashGrey),
        ),
      );
    }

    return ValueListenableBuilder<TopoDataset?>(
      valueListenable:
          DatasetRepository.instance?.activeDataset ?? ValueNotifier(null),
      builder: (context, dataset, child) {
        final int? totalItens =
            _closestCrags.length > 1 ? null : _closestCrags.length;

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          itemCount: totalItens,
          padding: const EdgeInsets.only(left: 24, right: 8),
          itemBuilder: (context, index) {
            final int indiceReal = NearbyCragsCarousel.calcularIndiceCircular(
              index,
              _closestCrags.length,
            );
            final picoBase = _closestCrags[indiceReal];
            final distanceStr = NearbyCragsCarousel.formatarDistancia(
              (picoBase.distanciaKm ?? 0) * 1000,
            );

            final isDownloaded =
                dataset?.downloadedPicos.any(
                  (p) => p.id == picoBase.id,
                ) ??
                false;
            final pico = picoBase.copyWith(isDownloaded: isDownloaded);

            return Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: SizedBox(
                width: 340,
                child: CragCard(
                  crag: pico,
                  distanceStr: distanceStr,
                  downloadingCrags: widget.syncService.downloadingCrags,
                  onDownload: () => handleDownload(pico),
                  onOpen: () {
                    final repo = DatasetRepository.instance;
                    if (repo != null) {
                      handlePicoSelection(context, repo, pico);
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
