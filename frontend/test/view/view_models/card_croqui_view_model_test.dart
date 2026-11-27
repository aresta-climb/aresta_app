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
      expect(vm.distanciaRotaKm, isNull);

      const vmComTempo = CardCroquiViewModel(
        id: 'pico_2',
        titulo: 'PICO COM TEMPO',
        textoEstatisticas: '1 setor • 5 escaladas',
        caminhoMiniatura: 'thumbnails/pico_2.webp',
        textoDistancia: '~40 min',
        distanciaRotaKm: '42.0 km',
      );
      expect(vmComTempo.distanciaRotaKm, equals('42.0 km'));
      expect(vmComTempo['distanciaRotaKm'], equals('42.0 km'));
      expect(vmComTempo.nome, equals('PICO COM TEMPO'));
      expect(vmComTempo['id'], equals('pico_2'));
      expect(vmComTempo['nome'], equals('PICO COM TEMPO'));
      expect(vmComTempo['local'], isEmpty);
      expect(vmComTempo['descricao'], isEmpty);
      expect(vmComTempo['salvoOffline'], isFalse);
      expect(vmComTempo['stats'], equals('1 setor • 5 escaladas'));
      expect(vmComTempo['thumbnailUrl'], equals('thumbnails/pico_2.webp'));
      expect(vmComTempo['distance'], equals('~40 min'));
      expect(vmComTempo['checksum'], isNull);
      expect(vmComTempo['chave_inexistente'], isNull);
      expect(identical(vmComTempo.comSalvoOffline(false), vmComTempo), isTrue);
      expect(
        vmComTempo.comSalvoOffline(true).distanciaRotaKm,
        equals('42.0 km'),
      );
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
        descricao: 'Descrição Beta',
        precomputados: PrecomputadosResumoCroqui(
          totalSetores: 3,
          totalEscaladas: 18,
          totalBoulders: 10,
          totalEsportivas: 5,
          totalMoveis: 1,
          totalMultiplasEnfiadas: 1,
          totalHighlines: 1,
        ),
      );

      final vm = mapearMetadadosParaCard(
        metadados,
        estatisticasDetalhadas: true,
      );

      expect(vm.descricao, equals('Descrição Beta'));
      expect(vm.caminhoCapa, isNull);
      expect(identical(vm.comSalvoOffline(false), vm), isTrue);
      expect(vm.comSalvoOffline(true).salvoOffline, isTrue);
      expect(
        vm.textoEstatisticas,
        equals(
          '3 setores • 18 escaladas (10 boulders, 5 esportivas, 1 móveis, 1 múltiplas enfiadas, 1 highlines)',
        ),
      );

      final vmSemMod = mapearMetadadosParaCard(
        MetadadosIndice(
          id: 'pico_vazio_mod',
          nome: 'Vazio',
          precomputados: PrecomputadosResumoCroqui(totalSetores: 1, totalEscaladas: 2),
        ),
        estatisticasDetalhadas: true,
      );
      expect(vmSemMod.textoEstatisticas, equals('1 setores • 2 escaladas'));
    });

    test('mapeia a partir de CardCroquiViewModel existente, Croqui, Map, objeto conversível e fallback primitivo', () {
      const jaVm = CardCroquiViewModel(
        id: 'ja_vm',
        titulo: 'JA VM',
        textoEstatisticas: '1 • 1',
        caminhoMiniatura: '',
      );
      expect(identical(mapearMetadadosParaCard(jaVm), jaVm), isTrue);

      final deCroqui = mapearMetadadosParaCard(
        Croqui(id: 'c_dir', descricao: 'Desc C', picos: [Pico()]),
        textoDistancia: '~20 min',
        distanciaRotaKm: '15.0 km',
      );
      expect(deCroqui.titulo, equals('SEM NOME'));
      expect(deCroqui.descricao, equals('Desc C'));
      expect(deCroqui.caminhoCapa, isNull);
      expect(identical(deCroqui.comSalvoOffline(false), deCroqui), isTrue);
      expect(deCroqui.distanciaRotaKm, equals('15.0 km'));

      final deMapa = mapearMetadadosParaCard(<String, dynamic>{
        'id': 'm_1',
        'nome': 'Pico Mapa',
        'local': 'MG',
        'descricao': 'Desc Mapa',
        'stats': '2 • 8',
        'thumbnailUrl': 'thumb_m.webp',
        'distance': '~30 min',
        'distanciaRotaKm': '25.0 km',
        'capaPath': 'capa_m.webp',
        'checksum': 'sha_m',
      });
      expect(deMapa.id, equals('m_1'));
      expect(deMapa.titulo, equals('PICO MAPA'));
      expect(deMapa.localizacao, equals('MG'));
      expect(deMapa.descricao, equals('Desc Mapa'));
      expect(deMapa.textoEstatisticas, equals('2 • 8'));
      expect(deMapa.caminhoMiniatura, equals('thumb_m.webp'));
      expect(deMapa.textoDistancia, equals('~30 min'));
      expect(deMapa.distanciaRotaKm, equals('25.0 km'));
      expect(deMapa.caminhoCapa, equals('capa_m.webp'));
      expect(deMapa.checksumSha256, equals('sha_m'));
      expect(identical(deMapa.comSalvoOffline(false), deMapa), isTrue);
      expect(deMapa.comSalvoOffline(true).salvoOffline, isTrue);

      final deMapaPadrao = CardCroquiViewModel.deMapa(const <String, dynamic>{
        'salvoOffline': true,
      });
      expect(deMapaPadrao.salvoOffline, isTrue);
      expect(deMapaPadrao.textoEstatisticas, contains('0 setores'));
      expect(deMapaPadrao.caminhoMiniatura, equals('thumbnails/.webp'));

      final conversivel = _ObjetoComConversorCard();
      expect(mapearMetadadosParaCard(conversivel).id, equals('conv_1'));

      final fallback = mapearMetadadosParaCard(12345, textoDistancia: '10 km');
      expect(fallback.id, equals('12345'));
      expect(fallback.textoDistancia, equals('10 km'));
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

class _ObjetoComConversorCard {
  CardCroquiViewModel paraCardCroquiViewModel() => const CardCroquiViewModel(
        id: 'conv_1',
        titulo: 'CONVERTIDO',
        textoEstatisticas: '',
        caminhoMiniatura: '',
      );
}
