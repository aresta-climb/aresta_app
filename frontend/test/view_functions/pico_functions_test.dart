import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/view_functions/pico_functions.dart';
import 'package:frontend/view_functions/via_functions.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import '../mocks/mock_telemetry_service.dart';

void main() {
  test('Pico functions should dispatch logAbrirSetor', () {
    final mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;

    TelemetryService.instance.logAbrirSetor('crag1', 'Setor 1');
    expect(mockTelemetry.recordedEvents, contains('abrir_setor'));
    expect(
      mockTelemetry.recordedParams['abrir_setor']!['nome_setor'],
      'Setor 1',
    );
  });

  test('Pico functions should dispatch logAbrirGrupo', () {
    final mockTelemetry = MockTelemetryService();
    TelemetryService.instance = mockTelemetry;

    TelemetryService.instance.logAbrirGrupo('crag1', 'Grupo 1');
    expect(mockTelemetry.recordedEvents, contains('abrir_grupo'));
    expect(
      mockTelemetry.recordedParams['abrir_grupo']!['nome_grupo'],
      'Grupo 1',
    );
  });

  test(
    'Pico functions should dispatch logAcaoCroqui when a generic button is tapped',
    () {
      final mockTelemetry = MockTelemetryService();
      TelemetryService.instance = mockTelemetry;

      TelemetryService.instance.logAcaoCroqui('crag1', 'Sobre o Pico');
      expect(mockTelemetry.recordedEvents, contains('acao_croqui'));
      expect(
        mockTelemetry.recordedParams['acao_croqui']!['acao'],
        'Sobre o Pico',
      );
    },
  );

  test(
    'PicoSearchDelegate fetches setores and escaladas and sets correct label',
    () {
      final pico = Pico()
        ..setoresOuGrupos.add(
          SetorOuGrupo()
            ..setor = (ArquivoSetor()
              ..conteudo = (Setor()
                ..nome = 'Setor A'
                ..escaladas.add(
                  Escalada()..viaEsportiva = (ViaEsportiva()..nome = 'Via 1'),
                ))),
        );

      final delegate = PicoSearchDelegate(pico, 'crag1');

      expect(delegate.allEscaladas.length, 1);
      expect(getEscaladaNome(delegate.allEscaladas.first), 'Via 1');

      expect(delegate.allSetores.length, 1);
      expect(delegate.allSetores.first.nome, 'Setor A');

      expect(delegate.searchFieldLabel, 'Buscar escalada (ex: 7a) ou setor...');
    },
  );
}
