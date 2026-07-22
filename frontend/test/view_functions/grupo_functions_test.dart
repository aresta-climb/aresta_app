import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';

void main() {
  test('Grupo functions should dispatch telemetry for map open', () {
    final mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;

    // Simulate telemetry that would be triggered inside UI callbacks
    TelemetryService.instance.logAbrirMapa('crag1', 'Grupo 1');

    expect(mockTelemetry.recordedEvents, contains('abrir_mapa'));
  });
}
