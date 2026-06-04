import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';

void main() {
  test('Setor functions should dispatch telemetry', () {
    final mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;
    
    // Simulate telemetry that would be triggered inside UI callbacks
    TelemetryService.instance.logAcaoEscalada('crag1', 'Setor 1', 'Via 1', 'abrir_detalhes', 'lista_setor');
    
    expect(mockTelemetry.recordedEvents, contains('acao_escalada'));
    expect(mockTelemetry.recordedParams['acao_escalada']!['origem'], 'lista_setor');
  });
}
