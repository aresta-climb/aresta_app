// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';
import 'package:frontend/services/dataset_repository.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/view_functions/pico_view_model.dart';

class _FakeDatasetRepository extends DatasetRepository {
  bool deleteCalled = false;
  String? deletedCragId;

  _FakeDatasetRepository() : super(editorDeCroqui: EditorDeCroqui());

  @override
  Future<bool> deleteCrag(String id) async {
    deleteCalled = true;
    deletedCragId = id;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeDatasetRepository repositorio;
  late Pico pico;
  late Croqui croqui;
  const cragId = 'crag_teste_1';

  setUp(() {
    repositorio = _FakeDatasetRepository();
    pico = Pico()
      ..nome = 'Pedra do Baú'
      ..estado = 'SP';
    croqui = Croqui();
  });

  group('PicoViewModel - Estatísticas e Formatação de UI', () {
    test('calcula total de setores, modalidades e subtítulo corretamente', () {
      final setor1 = Setor(
        nome: 'Setor 1',
        escaladas: [
          Escalada(viaEsportiva: ViaEsportiva(nome: 'Via Normal')),
          Escalada(boulder: Boulder(nome: 'Boulder Teste')),
        ],
      );

      final setor2 = Setor(
        nome: 'Setor 2',
        escaladas: [
          Escalada(viaMovel: ViaMovel(nome: 'Fissura Móvel')),
        ],
      );

      final grupo1 = Grupo(
        nome: 'Complexo Norte',
        setores: [ArquivoSetor(conteudo: setor2)],
      );

      pico.setoresOuGrupos.addAll([
        SetorOuGrupo(setor: ArquivoSetor(conteudo: setor1)),
        SetorOuGrupo(grupo: ArquivoGrupo(conteudo: grupo1)),
      ]);

      final vm = PicoViewModel(
        pico: pico,
        croqui: croqui,
        cragId: cragId,
        datasetRepo: repositorio,
      );

      expect(vm.totalSetores, 2);
      expect(
        vm.subtitulo,
        'SP • 2 SETORES • 3 escaladas (1 esportivas, 1 boulders, 1 móveis)',
      );
      expect(vm.tooltipBusca, 'Buscar via');
      vm.dispose();
    });

    test('define tooltipBusca como boulder quando pico é focado em boulders', () {
      final setor = Setor(
        nome: 'Setor Boulder',
        escaladas: [
          Escalada(boulder: Boulder(nome: 'V3 dos Sonhos')),
        ],
      );
      pico.setoresOuGrupos.add(
        SetorOuGrupo(setor: ArquivoSetor(conteudo: setor)),
      );

      final vm = PicoViewModel(
        pico: pico,
        croqui: croqui,
        cragId: cragId,
        datasetRepo: repositorio,
      );

      expect(vm.tooltipBusca, 'Buscar boulder');
      vm.dispose();
    });

    test('obtém tamanhoFormatado e data de atualização do dataset', () {
      repositorio.activeDataset.value = TopoDataset(
        availablePicos: [
          {
            'id': cragId,
            'nome': 'Pedra do Baú',
            'tamanho_bytes': 15 * 1024 * 1024,
            'tamanhoFormatado': '15.0 MB',
            'url': 'https://exemplo.com/bau.zip',
          },
        ],
        downloadedPicos: [],
      );

      repositorio.indiceData.value = Indice()
        ..croquis.add(
          ResumoCroqui()
            ..id = cragId
            ..nome = 'Pedra do Baú'
            ..timestampUpdate = Timestamp.fromDateTime(DateTime(2026, 5, 20, 14, 30)),
        );

      final vm = PicoViewModel(
        pico: pico,
        croqui: croqui,
        cragId: cragId,
        datasetRepo: repositorio,
      );

      expect(vm.tamanhoFormatado, '15.0 MB');
      expect(vm.textoUltimaAtualizacao, contains('20/05/2026 às 14:30'));
      vm.dispose();
    });
  });

  group('PicoViewModel - Interceptação e Ciclo de Vida de Download', () {
    test('deveInterceptarSaida retorna falso quando permanece no mesmo croqui', () {
      final vm = PicoViewModel(
        pico: pico,
        croqui: croqui,
        cragId: cragId,
        datasetRepo: repositorio,
      );

      expect(vm.deveInterceptarSaida(staysInSameCroqui: true), isFalse);
      vm.dispose();
    });

    test('deveInterceptarSaida retorna falso quando croqui está baixado', () {
      repositorio.activeDataset.value = TopoDataset(
        availablePicos: [],
        downloadedPicos: [
          {'id': cragId, 'nome': 'Pedra do Baú'},
        ],
      );

      final vm = PicoViewModel(
        pico: pico,
        croqui: croqui,
        cragId: cragId,
        datasetRepo: repositorio,
      );

      expect(vm.isDownloaded, isTrue);
      expect(vm.deveInterceptarSaida(staysInSameCroqui: false), isFalse);
      vm.dispose();
    });

    test('deveInterceptarSaida retorna verdadeiro quando não baixado e sai do croqui', () {
      repositorio.activeDataset.value = TopoDataset(
        availablePicos: [
          {'id': cragId, 'nome': 'Pedra do Baú'},
        ],
        downloadedPicos: [],
      );

      final vm = PicoViewModel(
        pico: pico,
        croqui: croqui,
        cragId: cragId,
        datasetRepo: repositorio,
      );

      expect(vm.isDownloaded, isFalse);
      expect(vm.deveInterceptarSaida(staysInSameCroqui: false), isTrue);
      vm.dispose();
    });
  });
}
