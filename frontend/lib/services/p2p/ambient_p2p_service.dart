import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import '../dataset_repository.dart';

class AmbientP2PService {
  static final AmbientP2PService instance = AmbientP2PService._internal();

  AmbientP2PService._internal();

  late NearbyService nearbyService;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _dataSubscription;

  // Lista de IDs de picos que os aparelhos vizinhos informaram que possuem
  final ValueNotifier<Set<String>> nearbyAvailableCrags = ValueNotifier({});

  // Lista dos nossos próprios picos para anunciarmos
  List<String> _myOfficialCragIds = [];

  bool _isInit = false;
  final Map<String, Device> connectedDevices = {};

  Future<void> init() async {
    if (_isInit) return;
    
    // Configuração do serviço Nearby
    nearbyService = NearbyService();
    await nearbyService.init(
        serviceType: 'aresta',
        strategy: Strategy.P2P_STAR,
        deviceName: 'Aresta_User_${DateTime.now().millisecondsSinceEpoch}',
        callback: (isRunning) async {
          if (isRunning) {
            _isInit = true;
            await _updateMyCrags();
            
            // Inicia o scan e o broadcast
            await nearbyService.startAdvertisingPeer();
            await nearbyService.startBrowsingForPeers();
          }
        });

    _stateSubscription = nearbyService.stateChangedSubscription(callback: handleStateChanged);
    _dataSubscription = nearbyService.dataReceivedSubscription(callback: handleDataReceived);
  }

  @visibleForTesting
  void handleStateChanged(List<Device> devicesList) {
    for (var device in devicesList) {
      if (device.state == SessionState.notConnected) {
        nearbyService.invitePeer(deviceID: device.deviceId, deviceName: device.deviceName);
      } else if (device.state == SessionState.connected) {
        connectedDevices[device.deviceId] = device;
        _broadcastMyCragsTo(device.deviceId);
      }
    }
  }

  @visibleForTesting
  void handleDataReceived(dynamic data) {
    try {
      final Map<String, dynamic> payload = jsonDecode(data['message']);
      if (payload['type'] == 'AVAILABLE_CRAGS') {
        List<dynamic> cragIds = payload['crags'] ?? [];
        final currentSet = nearbyAvailableCrags.value;
        currentSet.addAll(cragIds.map((e) => e.toString()));
        nearbyAvailableCrags.value = Set.from(currentSet);
      }
    } catch (e) {
      // Ignora falhas de parse
    }
  }

  Future<void> _updateMyCrags() async {
    // Busca apenas os picos oficiais que o usuário baixou
    final isExperimental = DatasetRepository.instance!.editorDeCroqui.isExperimentalMode.value;
    if (isExperimental) {
      _myOfficialCragIds = [];
      return;
    }
    final downloaded = DatasetRepository.instance!.activeDataset.value?.downloadedPicos ?? [];
    _myOfficialCragIds = downloaded.map((d) => d['id'] as String).toList();
  }

  void _broadcastMyCragsTo(String deviceId) {
    if (_myOfficialCragIds.isEmpty) return;
    final message = jsonEncode({
      'type': 'AVAILABLE_CRAGS',
      'crags': _myOfficialCragIds,
    });
    nearbyService.sendMessage(deviceId, message);
  }

  void dispose() {
    _stateSubscription?.cancel();
    _dataSubscription?.cancel();
    if (_isInit) {
      nearbyService.stopAdvertisingPeer();
      nearbyService.stopBrowsingForPeers();
    }
    _isInit = false;
  }
}
