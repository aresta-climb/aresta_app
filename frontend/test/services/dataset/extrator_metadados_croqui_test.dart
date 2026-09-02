// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/dataset/metadados/extrator_metadados_croqui.dart';

void main() {
  late Directory tempDir;
  late ExtratorMetadadosCroqui extrator;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('metadados_test_');
    extrator = ExtratorMetadadosCroqui();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ExtratorMetadadosCroqui', () {
    test('extrairCapaPathFromMarkdown extrai primeira imagem de markdown intitulado capa', () {
      final croqui = Croqui();
      final botaoCapa = Botao(
        texto: 'Capa Principal',
        destino: DestinoBotao(
          secaoTextual: ArquivoMarkdown(
            conteudo: '# Bem-vindo\n![Foto da Capa](imagens/capa.jpg)\nMais texto',
          ),
        ),
      );
      croqui.botoes.add(botaoCapa);

      final capa = extrator.extrairCapaPathFromMarkdown(croqui, 'mg_bau');
      expect(capa, equals('mg_bau/imagens/capa.jpg'));
    });

    test('buscarImagemRecursivamente encontra arquivo em subdiretórios ignorando case', () async {
      final subDir = Directory('${tempDir.path}/sub/imagens');
      await subDir.create(recursive: true);
      final imgFile = File('${subDir.path}/Foto_Setor.webp');
      await imgFile.writeAsBytes([1, 2, 3]);

      final encontrado = extrator.buscarImagemRecursivamente(
        tempDir.path,
        'foto_setor.webp',
      );

      expect(encontrado, isNotNull);
      expect(p.canonicalize(encontrado!.path), equals(p.canonicalize(imgFile.path)));
    });

    test('atualizarMetadadosPico popula capaPath e dados do croqui', () async {
      final picoDir = Directory('${tempDir.path}/pico_1');
      await picoDir.create(recursive: true);

      final imgCapa = File('${picoDir.path}/capa.webp');
      await imgCapa.writeAsBytes([1, 2, 3]);

      final croqui = Croqui(
        id: 'pico_1',
        caminhoThumbnail: 'capa.webp',
      );
      croqui.picos.add(Pico(nome: 'Pico Alpha'));

      final picoData = <String, dynamic>{'id': 'pico_1'};

      await extrator.atualizarMetadadosPico(
        id: 'pico_1',
        picoData: picoData,
        downloadsPath: tempDir.path,
        baseUrl: 'https://exemplo.com',
        parsedCroqui: croqui,
      );

      expect(picoData['capaPath'], equals(imgCapa.path));
      expect(picoData['data'], isNotNull);
    });
  });
}
