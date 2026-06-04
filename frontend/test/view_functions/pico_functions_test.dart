import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/view_functions/pico_functions.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';

void main() {
  test('Pico functions should dispatch logAbrirSetor', () {
    final mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;
    
    TelemetryService.instance.logAbrirSetor('crag1', 'Setor 1');
    expect(mockTelemetry.recordedEvents, contains('abrir_setor'));
    expect(mockTelemetry.recordedParams['abrir_setor']!['nome_setor'], 'Setor 1');
  });

  test('Pico functions should dispatch logAbrirGrupo', () {
    final mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;
    
    TelemetryService.instance.logAbrirGrupo('crag1', 'Grupo 1');
    expect(mockTelemetry.recordedEvents, contains('abrir_grupo'));
    expect(mockTelemetry.recordedParams['abrir_grupo']!['nome_grupo'], 'Grupo 1');
  });

  test('Pico functions should dispatch logAcaoCroqui when a generic button is tapped', () {
    final mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;
    
    TelemetryService.instance.logAcaoCroqui('crag1', 'Sobre o Pico');
    expect(mockTelemetry.recordedEvents, contains('acao_croqui'));
    expect(mockTelemetry.recordedParams['acao_croqui']!['acao'], 'Sobre o Pico');
  });
}
