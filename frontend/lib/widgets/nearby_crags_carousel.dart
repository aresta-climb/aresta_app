import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/view_functions/browse_functions.dart';
import 'package:frontend/view_functions/common_functions.dart';
import 'package:frontend/services/http/sync_service.dart';
import 'package:frontend/view_functions/home_functions.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/theme/app_colors.dart';

class NearbyCragsCarousel extends StatefulWidget {
  final SyncService syncService;

  const NearbyCragsCarousel({super.key, required this.syncService});

  @override
  State<NearbyCragsCarousel> createState() => _NearbyCragsCarouselState();
}

class _NearbyCragsCarouselState extends State<NearbyCragsCarousel> {
  static const String _kLastKnownLatKey = 'last_known_latitude';
  static const String _kLastKnownLonKey = 'last_known_longitude';

  bool _isLoading = true;
  bool _permissionDenied = false;
  List<Map<String, dynamic>> _closestCrags = [];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  void _handleDownload(Map<String, dynamic> crag) async {
    final name = crag['nome'] ?? 'Pico';
    final String id = crag['id'];

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

    final success = await widget.syncService.downloadCrag(resumo);

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
      await _fallbackToCachedLocationOrFinish();
      return;
    }

    await _fetchGpsLocation();
  }

  Future<void> _requestPermission() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    LocationPermission permission = await Geolocator.requestPermission();
    if (!mounted) return;

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await _fallbackToCachedLocationOrFinish();
    } else {
      await _fetchGpsLocation();
    }
  }

  /// Tenta resolver a localização por satélite com degradação progressiva de precisão.
  Future<void> _fetchGpsLocation() async {
    if (!mounted) return;
    try {
      Position? position;

      try {
        // 1. Tenta GPS de alta precisão (funciona offline via satélites)
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 3),
          ),
        );
      } catch (_) {
        // 2. Se demorar ou falhar, tenta precisão baixa
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 2),
            ),
          );
        } catch (_) {
          // 3. Fallback para última posição conhecida do SO
          position = await Geolocator.getLastKnownPosition();
        }
      }

      if (!mounted) return;

      if (position != null) {
        _saveLocationToCache(position.latitude, position.longitude);
        _calculateDistances(position.latitude, position.longitude);
        return;
      }
    } catch (_) {
      // Falhas no GPS ativo direcionam para o cache local
    }

    if (!mounted) return;
    // 4. Se todas as tentativas ativas falharem, usa coordenadas salvas em disco
    await _fallbackToCachedLocationOrFinish();
  }

  /// Salva coordenadas de sucesso em disco local (SharedPreferences).
  Future<void> _saveLocationToCache(double lat, double lon) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kLastKnownLatKey, lat);
      await prefs.setDouble(_kLastKnownLonKey, lon);
    } catch (e) {
      debugPrint('Erro ao persistir localização em cache: $e');
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
        _calculateDistances(cachedLat, cachedLon);
        return;
      }
    } catch (e) {
      debugPrint('Erro ao ler localização do cache: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Calcula as distâncias geodésicas entre o usuário e todos os picos do índice local.
  void _calculateDistances(double userLat, double userLon) {
    final datasetRepo = DatasetRepository.instance;
    final availablePicos =
        datasetRepo?.activeDataset.value?.availablePicos ?? [];

    List<Map<String, dynamic>> cragsWithDistance = [];

    for (var pico in availablePicos) {
      if (pico.containsKey('latitude') && pico.containsKey('longitude')) {
        double picoLat = (pico['latitude'] as num).toDouble();
        double picoLon = (pico['longitude'] as num).toDouble();

        double distanceInMeters = Geolocator.distanceBetween(
          userLat,
          userLon,
          picoLat,
          picoLon,
        );

        var picoCopy = Map<String, dynamic>.from(pico);
        picoCopy['distanceMeters'] = distanceInMeters;
        cragsWithDistance.add(picoCopy);
      }
    }

    cragsWithDistance.sort(
      (a, b) =>
          (a['distanceMeters'] as double).compareTo(b['distanceMeters'] as double),
    );

    if (mounted) {
      setState(() {
        _closestCrags = cragsWithDistance;
        _isLoading = false;
        _permissionDenied = false;
      });
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      double km = meters / 1000;
      return '${km.toStringAsFixed(1)}km';
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
    if (_isLoading) {
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
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          itemCount: _closestCrags.length,
          padding: const EdgeInsets.only(left: 24, right: 8),
          itemBuilder: (context, index) {
            final picoBase = _closestCrags[index];
            final distanceStr = _formatDistance(
              picoBase['distanceMeters'] as double,
            );

            final isDownloaded =
                dataset?.downloadedPicos.any(
                  (p) => p['id'] == picoBase['id'],
                ) ??
                false;
            final pico = Map<String, dynamic>.from(picoBase)
              ..['isDownloaded'] = isDownloaded;

            return Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: SizedBox(
                width: 340,
                child: CragCard(
                  crag: pico,
                  distanceStr: distanceStr,
                  downloadingCrags: widget.syncService.downloadingCrags,
                  onDownload: () => _handleDownload(pico),
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
