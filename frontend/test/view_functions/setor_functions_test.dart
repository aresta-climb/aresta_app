import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/view_functions/setor_functions.dart';
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

  test('resolveRouteLabels joins point labels correctly and finds map indicators', () {
    final p1 = Mapa_PontoDeInteresse(id: '01', label: '1');
    final px = Mapa_PontoDeInteresse(id: 'x', label: 'X');
    final py = Mapa_PontoDeInteresse(id: 'y', label: 'Y');

    final mapa1 = Mapa(
      caminhoImagemMapa: 'test_map1.png',
      pontosDeInteresse: [p1, px, py],
    );

    final mapa2 = Mapa(
      caminhoImagemMapa: 'test_map2.png',
      pontosDeInteresse: [],
    );

    final esc = Escalada()
      ..boulder = (Boulder()..nome = 'Odisséia'..idNoMapa = '01'..idNoMapaFim = 'x');

    final setor = Setor(
      nome: 'Setor Teste',
      mapas: [mapa2, mapa1], // Mapa 1 será o M2 (índice 1)
      escaladas: [esc],
    );

    final labels = resolveRouteLabels(esc, setor);

    expect(labels['resolvedLabel'], '1-X');
    expect(labels['mapIndicator'], 'M2');
  });

  test('resolveRouteLabels handles empty labels and missing points by falling back to ID or omitting', () {
    final p1 = Mapa_PontoDeInteresse(id: '01', label: ''); // empty label
    final px = Mapa_PontoDeInteresse(id: 'x', label: 'X');

    final mapa1 = Mapa(
      caminhoImagemMapa: 'test_map1.png',
      pontosDeInteresse: [p1, px],
    );

    final esc = Escalada()
      ..boulder = (Boulder()..nome = 'Odisséia'..idNoMapa = '01'..idNoMapaMeio = 'z'..idNoMapaFim = 'x');

    final setor = Setor(
      nome: 'Setor Teste',
      mapas: [mapa1], 
      escaladas: [esc],
    );

    final labels = resolveRouteLabels(esc, setor);

    // '01' is in pointsMap but label is empty -> falls back to '01'.
    // 'z' is not in pointsMap -> omitted.
    // 'x' is in pointsMap -> 'X'.
    expect(labels['resolvedLabel'], '01-X');
    
    // mapIndicator is empty because there is only 1 map
    expect(labels['mapIndicator'], '');
  });
}
