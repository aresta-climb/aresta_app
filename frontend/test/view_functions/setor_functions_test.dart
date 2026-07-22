import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/view_functions/setor_functions.dart';

void main() {
  group('Setor Functions Tests', () {
    test(
      'resolveRouteLabels joins point labels correctly and finds map indicators',
      () {
        final mapa = Mapa(
          referencias: [
            Mapa_Referencia(escalada: 'Via 1', ids: ['p1', 'p2']),
          ],
          pontosDeInteresse: [
            Mapa_PontoDeInteresse(id: 'p1', label: '1'),
            Mapa_PontoDeInteresse(id: 'p2', label: 'X'),
          ],
        );

        final setor = Setor(nome: 'Setor A', mapas: [mapa]);

        final escalada = Escalada()
          ..viaEsportiva = (ViaEsportiva()..nome = 'Via 1');

        final result = resolveRouteLabels(escalada, setor);
        expect(result['resolvedLabel'], '1-X');
        expect(result['mapIndicator'], ''); // Only 1 map
      },
    );

    test('resolveRouteLabels handles map indicator for multiple maps', () {
      final mapa1 = Mapa(pontosDeInteresse: []);
      final mapa2 = Mapa(
        referencias: [
          Mapa_Referencia(escalada: 'Via 2', ids: ['p1']),
        ],
        pontosDeInteresse: [Mapa_PontoDeInteresse(id: 'p1', label: '2')],
      );

      final setor = Setor(nome: 'Setor B', mapas: [mapa1, mapa2]);

      final escalada = Escalada()
        ..viaEsportiva = (ViaEsportiva()..nome = 'Via 2');

      final result = resolveRouteLabels(escalada, setor);
      expect(result['resolvedLabel'], '2');
      expect(result['mapIndicator'], 'M2'); // Second map
    });

    test('resolveRouteLabels fallbacks to ID if label is empty', () {
      final mapa = Mapa(
        referencias: [
          Mapa_Referencia(escalada: 'Via 3', ids: ['p1']),
        ],
        pontosDeInteresse: [
          Mapa_PontoDeInteresse(id: 'p1', label: ''), // Empty label
        ],
      );

      final setor = Setor(nome: 'Setor C', mapas: [mapa]);

      final escalada = Escalada()
        ..viaEsportiva = (ViaEsportiva()..nome = 'Via 3');

      final result = resolveRouteLabels(escalada, setor);
      expect(result['resolvedLabel'], 'p1');
    });

    test(
      'resolveRouteLabels usa o indiceMapaPadrao para escolher a label correta quando a via esta em multiplos mapas',
      () {
        final mapa1 = Mapa(
          referencias: [
            Mapa_Referencia(escalada: 'Via 4', ids: ['p1']),
          ],
          pontosDeInteresse: [Mapa_PontoDeInteresse(id: 'p1', label: '1')],
        );
        final mapa2 = Mapa(
          referencias: [
            Mapa_Referencia(escalada: 'Via 4', ids: ['pA']),
          ],
          pontosDeInteresse: [Mapa_PontoDeInteresse(id: 'pA', label: 'A')],
        );

        final setor = Setor(nome: 'Setor D', mapas: [mapa1, mapa2]);

        // Via 4 com indiceMapaPadrao apontando pro mapa 1 (segundo mapa)
        final escalada = Escalada()
          ..viaEsportiva = (ViaEsportiva()
            ..nome = 'Via 4'
            ..indiceMapaPadrao = 1);

        final result = resolveRouteLabels(escalada, setor);
        expect(
          result['resolvedLabel'],
          'A',
        ); // Deve preferir o label 'A' do mapa 2
        expect(result['mapIndicator'], 'M2');
      },
    );
  });
}
