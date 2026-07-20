import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
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
  bool _isLoading = true;
  bool _permissionDenied = false;
  Position? _currentPosition;
  Map<String, dynamic>? _ipLocation;
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
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Baixando $name...')),
    );

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
    setState(() {
      _isLoading = true;
    });

    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _fetchIpLocationFallback();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Don't request immediately, wait for user interaction
      setState(() {
        _isLoading = false;
        _permissionDenied = true;
      });
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      await _fetchIpLocationFallback();
      return;
    }

    // Permission already granted
    await _fetchGpsLocation();
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
    });

    LocationPermission permission = await Geolocator.requestPermission();
    
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      await _fetchIpLocationFallback();
    } else {
      await _fetchGpsLocation();
    }
  }

  Future<void> _fetchGpsLocation() async {
    try {
      Position? position;
      
      try {
        // 1. First try high accuracy (GPS) which works offline in airplane mode
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
      } catch (_) {
        // 2. If it times out or fails, fallback to low accuracy (Network/Cell)
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 5),
            ),
          );
        } catch (_) {
          // 3. If that also fails, try grabbing the last known cached position
          position = await Geolocator.getLastKnownPosition();
        }
      }

      if (position != null) {
        _currentPosition = position;
        _calculateDistances(position.latitude, position.longitude);
      } else {
        // 4. If all local methods fail, fallback to IP location
        await _fetchIpLocationFallback();
      }
    } catch (e) {
      await _fetchIpLocationFallback();
    }
  }

  Future<void> _fetchIpLocationFallback() async {
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          _ipLocation = data;
          _calculateDistances(data['lat'], data['lon']);
          return;
        }
      }
    } catch (e) {
      debugPrint('Erro ao obter IP location: $e');
    }
    
    // Total failure
    setState(() {
      _isLoading = false;
    });
  }

  void _calculateDistances(double userLat, double userLon) {
    final datasetRepo = DatasetRepository.instance;
    final availablePicos = datasetRepo?.activeDataset.value?.availablePicos ?? [];
    
    List<Map<String, dynamic>> cragsWithDistance = [];

    for (var pico in availablePicos) {
      if (pico.containsKey('latitude') && pico.containsKey('longitude')) {
        double picoLat = pico['latitude'];
        double picoLon = pico['longitude'];
        
        double distanceInMeters = Geolocator.distanceBetween(userLat, userLon, picoLat, picoLon);
        
        // Cópia do mapa para poder adicionar a distância sem mutar o original
        Map<String, dynamic> picoComDistancia = Map.from(pico);
        picoComDistancia['distanceMeters'] = distanceInMeters;
        cragsWithDistance.add(picoComDistancia);
      }
    }

    cragsWithDistance.sort((a, b) => (a['distanceMeters'] as double).compareTo(b['distanceMeters'] as double));

    setState(() {
      _closestCrags = cragsWithDistance.take(5).toList();
      _isLoading = false;
      _permissionDenied = false;
    });
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
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
              if (_ipLocation != null && _closestCrags.isNotEmpty) ...[
                const SizedBox(width: 8),
                Icon(Icons.wifi, color: context.colors.ashGrey, size: 14),
              ] else if (_currentPosition != null && _closestCrags.isNotEmpty) ...[
                const SizedBox(width: 8),
                Icon(Icons.location_on, color: context.colors.ashGrey, size: 14),
              ]
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: _buildContent(),
        ),
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
            Icon(Icons.location_off_outlined, color: context.colors.ashGrey, size: 48),
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
              child: const Text('Permitir Localização', style: TextStyle(fontWeight: FontWeight.bold)),
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
      valueListenable: DatasetRepository.instance?.activeDataset ?? ValueNotifier(null),
      builder: (context, dataset, child) {
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          itemCount: _closestCrags.length,
          padding: const EdgeInsets.only(left: 24, right: 8),
          itemBuilder: (context, index) {
            final picoBase = _closestCrags[index];
            final distanceStr = _formatDistance(picoBase['distanceMeters'] as double);
            
            // Re-evaluate isDownloaded from the active dataset
            final isDownloaded = dataset?.downloadedPicos.any((p) => p['id'] == picoBase['id']) ?? false;
            final pico = Map<String, dynamic>.from(picoBase)..['isDownloaded'] = isDownloaded;
            
            return Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: SizedBox(
                width: 320,
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
