import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/telemetry_service.dart';
import '../mocks/mock_telemetry_service.dart';

void main() {
  group('TelemetryService Mock Tests', () {
    late MockTelemetryService mockTelemetry;

    setUp(() {
      mockTelemetry = MockTelemetryService();
      TelemetryService.instance = mockTelemetry;
    });

    test('logAbrirApp', () async {
      await TelemetryService.instance.logAbrirApp();
      expect(mockTelemetry.recordedEvents, contains('abrir_app'));
    });

    test('logBaixarCroqui', () async {
      await TelemetryService.instance.logBaixarCroqui('crag1');
      expect(mockTelemetry.recordedEvents, contains('baixar_croqui'));
      expect(mockTelemetry.recordedParams['baixar_croqui']!['id_croqui'], 'crag1');
    });

    test('logAtualizarCroqui', () async {
      await TelemetryService.instance.logAtualizarCroqui('crag1', 'sha123');
      expect(mockTelemetry.recordedEvents, contains('atualizar_croqui'));
      expect(mockTelemetry.recordedParams['atualizar_croqui']!['id_croqui'], 'crag1');
      expect(mockTelemetry.recordedParams['atualizar_croqui']!['versao'], 'sha123');
      // O mock atualmente não grava timestamp pq o método mockado não adiciona,
      // mas isso valida que a chamada mockada foi realizada corretamente.
    });

    test('logAbrirCroqui', () async {
      await TelemetryService.instance.logAbrirCroqui('crag1', 'Pico Teste');
      expect(mockTelemetry.recordedEvents, contains('abrir_croqui'));
      expect(mockTelemetry.recordedParams['abrir_croqui']!['nome_pico'], 'Pico Teste');
    });

    test('logAcaoCroqui', () async {
      await TelemetryService.instance.logAcaoCroqui('crag1', 'excluir');
      expect(mockTelemetry.recordedEvents, contains('acao_croqui'));
      expect(mockTelemetry.recordedParams['acao_croqui']!['acao'], 'excluir');
    });

    test('logAbrirSetor', () async {
      await TelemetryService.instance.logAbrirSetor('crag1', 'Setor 1');
      expect(mockTelemetry.recordedEvents, contains('abrir_setor'));
    });

    test('logAbrirGrupo', () async {
      await TelemetryService.instance.logAbrirGrupo('crag1', 'Grupo 1');
      expect(mockTelemetry.recordedEvents, contains('abrir_grupo'));
    });

    test('logAbrirMapa', () async {
      await TelemetryService.instance.logAbrirMapa('crag1', 'Grupo 1');
      expect(mockTelemetry.recordedEvents, contains('abrir_mapa'));
    });

    test('logClicarEscaladaMapa', () async {
      await TelemetryService.instance.logClicarEscaladaMapa('crag1', 'Setor 1', 'Via 1');
      expect(mockTelemetry.recordedEvents, contains('clicar_escalada_mapa'));
      expect(mockTelemetry.recordedParams['clicar_escalada_mapa']!['nome_escalada'], 'Via 1');
    });

    test('logVerDetalhesEscalada', () async {
      await TelemetryService.instance.logVerDetalhesEscalada('crag1', 'Setor 1', 'Via 1', 'busca');
      expect(mockTelemetry.recordedEvents, contains('ver_detalhes_escalada'));
      expect(mockTelemetry.recordedParams['ver_detalhes_escalada']!['origem'], 'busca');
    });
  });
}
