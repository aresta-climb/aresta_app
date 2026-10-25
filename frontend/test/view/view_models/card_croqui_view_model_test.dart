// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/services/dataset/modelos/metadados_indice.dart';
import 'package:frontend/view/view_models/card_croqui_view_model.dart';

void main() {
  group('CardCroquiViewModel', () {
    test('instanciação com valores obrigatórios e padrões', () {
      const vm = CardCroquiViewModel(
        id: 'pico_1',
        titulo: 'PICO TESTE',
        textoEstatisticas: '2 setores • 10 escaladas',
        caminhoMiniatura: 'thumbnails/pico_1.webp',
      );

      expect(vm.id, equals('pico_1'));
      expect(vm.titulo, equals('PICO TESTE'));
      expect(vm.localizacao, isEmpty);
      expect(vm.textoEstatisticas, equals('2 setores • 10 escaladas'));
      expect(vm.caminhoMiniatura, equals('thumbnails/pico_1.webp'));
      expect(vm.salvoOffline, isFalse);
      expect(vm.textoDistancia, isNull);
    });
  });

  group('mapearMetadadosParaCard', () {
    test('mapeia informações básicas e estatísticas resumidas quando possui checksumSha256Thumbnail', () {
      final metadados = MetadadosIndice(
        id: 'pico_alpha',
        nome: 'Pico Alpha',
        caminhoRelativo: 'brasil/mg/serra_do_cipo/croqui.binarypb',
        checksumSha256Thumbnail: 'hash_thumb_alpha',
        precomputados: PrecomputadosResumoCroqui(
          totalSetores: 4,
          totalEscaladas: 20,
        ),
      );

      final vm = mapearMetadadosParaCard(metadados, salvoOffline: true, textoDistancia: '1.5km');

      expect(vm.id, equals('pico_alpha'));
      expect(vm.titulo, equals('PICO ALPHA'));
      expect(vm.localizacao, equals('SERRA DO CIPO'));
      expect(vm.textoEstatisticas, equals('4 setores • 20 escaladas'));
      expect(vm.caminhoMiniatura, equals('thumbnails/pico_alpha.webp'));
      expect(vm.salvoOffline, isTrue);
      expect(vm.textoDistancia, equals('1.5km'));
    });

    test('retorna caminhoMiniatura vazio quando ResumoCroqui não possui checksumSha256Thumbnail', () {
      final metadados = MetadadosIndice(
        id: 'pico_sem_thumb',
        nome: 'Pico Sem Thumb',
      );
      final vm = mapearMetadadosParaCard(metadados);

      expect(vm.caminhoMiniatura, isEmpty);
    });

    test('aplica fallback SEM NOME quando nome estiver vazio', () {
      final metadados = MetadadosIndice(id: 'sem_nome');
      final vm = mapearMetadadosParaCard(metadados);

      expect(vm.titulo, equals('SEM NOME'));
      expect(vm.textoEstatisticas, equals('0 setores • 0 escaladas'));
      expect(vm.salvoOffline, isFalse);
    });

    test('inclui modalidades detalhadas quando estatisticasDetalhadas for true', () {
      final metadados = MetadadosIndice(
        id: 'pico_beta',
        nome: 'Pico Beta',
        precomputados: PrecomputadosResumoCroqui(
          totalSetores: 3,
          totalEscaladas: 15,
          totalBoulders: 10,
          totalEsportivas: 5,
        ),
      );

      final vm = mapearMetadadosParaCard(
        metadados,
        estatisticasDetalhadas: true,
      );

      expect(
        vm.textoEstatisticas,
        equals('3 setores • 15 escaladas (10 boulders, 5 esportivas)'),
      );
    });
  });

  group('mapearCroquiParaCard', () {
    test('mapeia Croqui offline completo usando caminhoThumbnail quando preenchido', () {
      final croqui = Croqui(
        id: 'croqui_1',
        nome: 'Pedra do Baú',
        caminhoThumbnail: 'imagens/thumbnail.webp',
        picos: [
          Pico(
            nome: 'Baú',
            estado: 'São Paulo',
            precomputados: PrecomputadosPico(
              totalSetores: 5,
              totalEscaladas: 42,
            ),
          ),
        ],
      );

      final vm = mapearCroquiParaCard(croqui);

      expect(vm.id, equals('croqui_1'));
      expect(vm.titulo, equals('PEDRA DO BAÚ'));
      expect(vm.localizacao, equals('SÃO PAULO'));
      expect(vm.textoEstatisticas, equals('5 setores • 42 escaladas'));
      expect(vm.caminhoMiniatura, equals('imagens/thumbnail.webp'));
      expect(vm.salvoOffline, isTrue);
    });

    test('retorna caminhoMiniatura vazio quando Croqui não possui caminhoThumbnail nem hash no índice', () {
      final croqui = Croqui(
        id: 'croqui_sem_thumb_total',
        nome: 'Croqui Sem Capa',
      );

      final vm = mapearCroquiParaCard(croqui);

      expect(vm.caminhoMiniatura, isEmpty);
    });

    test('prioriza thumbnails/<id>.webp quando seu hash está indexado no repositório', () {
      final repo = DatasetRepository(editorDeCroqui: EditorDeCroqui());
      repo.indiceData.value = Indice()
        ..croquis.add(
          ResumoCroqui(
            id: 'croqui_com_thumb_catalogo',
            checksumSha256Thumbnail: 'hash_catalogo_999',
          ),
        );

      final croqui = Croqui(
        id: 'croqui_com_thumb_catalogo',
        nome: 'Pico Com Miniatura',
        caminhoThumbnail: 'imagens/capa_alta_resolucao.webp',
      );

      final vm = mapearCroquiParaCard(croqui);

      expect(vm.caminhoMiniatura, equals('thumbnails/croqui_com_thumb_catalogo.webp'));
      expect(vm.checksumSha256, equals('hash_catalogo_999'));
    });

    test('faz fallback para croqui.caminhoThumbnail quando a miniatura de catálogo não possui hash indexado', () {
      final repo = DatasetRepository(editorDeCroqui: EditorDeCroqui());
      repo.indiceData.value = Indice();

      final croqui = Croqui(
        id: 'croqui_sem_thumb_catalogo',
        nome: 'Pico Sem Miniatura Catálogo',
        caminhoThumbnail: 'imagens/capa_alta_resolucao.webp',
      )..arquivosExternos.add(
          ArquivoExterno(
            caminho: 'imagens/capa_alta_resolucao.webp',
            checksumSha256: 'hash_capa_hd_456',
          ),
        );
      repo.indexarMidiasDoCroqui('croqui_sem_thumb_catalogo', croqui);

      final vm = mapearCroquiParaCard(croqui);

      expect(vm.caminhoMiniatura, equals('imagens/capa_alta_resolucao.webp'));
      expect(vm.checksumSha256, equals('hash_capa_hd_456'));
    });

    test('usa nome do primeiro pico e fallback de localização quando nome for vazio', () {
      final croqui = Croqui(
        id: 'croqui_2',
        picos: [
          Pico(
            nome: 'Pico Secundário',
          ),
        ],
      );

      final vm = mapearCroquiParaCard(croqui);

      expect(vm.titulo, equals('PICO SECUNDÁRIO'));
      expect(vm.localizacao, equals('LOCAL DESCONHECIDO'));
      expect(vm.textoEstatisticas, equals('0 setores • 0 escaladas'));
    });
  });
}
