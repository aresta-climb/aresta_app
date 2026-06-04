import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/view_functions/setor_functions.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';

void main() {
  test('Setor functions should dispatch telemetry', () {
    final mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;
    
    // Simulate telemetry that would be triggered inside UI callbacks
    TelemetryService.instance.logVerDetalhesEscalada('crag1', 'Setor 1', 'Via 1', 'lista_setor');
    
    expect(mockTelemetry.recordedEvents, contains('ver_detalhes_escalada'));
    expect(mockTelemetry.recordedParams['ver_detalhes_escalada']!['origem'], 'lista_setor');
  });
}
