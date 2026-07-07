import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/p2p/ambient_p2p_service.dart';
import 'package:frontend/services/p2p/p2p_transfer_manager.dart';

void main() {
  group('AmbientP2PService Tests', () {
    test('handleDataReceived parses AVAILABLE_CRAGS correctly', () {
      final service = AmbientP2PService.instance;
      // Limpa os dados iniciais
      service.nearbyAvailableCrags.value.clear();

      final payload = {
        'type': 'AVAILABLE_CRAGS',
        'crags': ['crag123', 'crag456'],
      };

      final data = {
        'message': jsonEncode(payload),
      };

      service.handleDataReceived(data);

      expect(service.nearbyAvailableCrags.value.contains('crag123'), isTrue);
      expect(service.nearbyAvailableCrags.value.contains('crag456'), isTrue);
    });

    test('handleDataReceived ignores invalid messages safely', () {
      final service = AmbientP2PService.instance;
      service.nearbyAvailableCrags.value.clear();

      final data = {
        'message': 'invalid_json',
      };

      // Não deve estourar erro
      service.handleDataReceived(data);

      expect(service.nearbyAvailableCrags.value.isEmpty, isTrue);
    });
  });

  group('P2PTransferManager Tests', () {
    test('handleDataReceived ignores invalid messages safely', () {
      final manager = P2PTransferManager.instance;
      
      final data = {
        'message': 'invalid_json',
      };

      // Não deve estourar erro
      expect(() => manager.handleDataReceived(data), returnsNormally);
    });
  });
}
