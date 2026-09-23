// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/utils/indexador_escaladas.dart';

void main() {
  group('IndexadorEscaladas', () {
    test('indexa escaladas de setores diretos e de grupos com localização completa', () {
      final pico = Pico()..nome = 'Pico de Teste';

      // Setor direto
      final viaEsportiva = ViaEsportiva()
        ..nome = 'Via Direta'
        ..dificuldade = GrauVia_GrauVia.BR_7A
        ..destaque = true
        ..conquistadores.addAll(['Ana', 'Beto']);
      final escalada1 = Escalada()..viaEsportiva = viaEsportiva;

      final setor1 = Setor()
        ..nome = 'Setor Sol'
        ..escaladas.add(escalada1);

      pico.setoresOuGrupos.add(
        SetorOuGrupo(setor: ArquivoSetor(conteudo: setor1)),
      );

      // Grupo com setor
      final boulder = Boulder()
        ..nome = 'Bloco Laranja'
        ..dificuldade = GrauBoulder_GrauBoulder.V4
        ..conquistadores.add('Carlos');
      final escalada2 = Escalada()..boulder = boulder;

      final setor2 = Setor()
        ..nome = 'Setor da Mata'
        ..escaladas.add(escalada2);

      final grupo = Grupo()
        ..nome = 'Complexo Norte'
        ..setores.add(ArquivoSetor(conteudo: setor2));

      pico.setoresOuGrupos.add(
        SetorOuGrupo(grupo: ArquivoGrupo(conteudo: grupo)),
      );

      final itens = indexarEscaladasDoPico(pico, 'crag-1');

      expect(itens.length, 2);

      // Item 1 (Setor direto)
      final item1 = itens[0];
      expect(item1.nome, 'Via Direta');
      expect(item1.grau, '7a');
      expect(item1.modalidade, 'Esportiva');
      expect(item1.isDestaque, isTrue);
      expect(item1.conquistadores, ['Ana', 'Beto']);
      expect(item1.setor.nome, 'Setor Sol');
      expect(item1.grupo, isNull);
      expect(item1.localizacaoFormatada, 'Setor Sol');
      expect(item1.cragId, 'crag-1');

      // Item 2 (Setor dentro de Grupo)
      final item2 = itens[1];
      expect(item2.nome, 'Bloco Laranja');
      expect(item2.grau, 'v4');
      expect(item2.modalidade, 'Boulder');
      expect(item2.isDestaque, isFalse);
      expect(item2.conquistadores, ['Carlos']);
      expect(item2.setor.nome, 'Setor da Mata');
      expect(item2.grupo?.nome, 'Complexo Norte');
      expect(item2.localizacaoFormatada, 'Complexo Norte › Setor da Mata');
      expect(item2.cragId, 'crag-1');
    });

    test('retorna lista vazia para pico sem setores ou sem escaladas', () {
      final pico = Pico()..nome = 'Pico Vazio';
      final itens = indexarEscaladasDoPico(pico, 'crag-vazio');
      expect(itens, isEmpty);
    });

    test('lida com outros tipos de escalada: móvel, multienfiada e highline', () {
      final pico = Pico()..nome = 'Pico Misto';

      final viaMovel = ViaMovel()
        ..nome = 'Fenda da Ilusão'
        ..dificuldade = GrauVia_GrauVia.BR_6
        ..destaque = true
        ..conquistadores.add('Danilo');
      final escaladaMovel = Escalada()..viaMovel = viaMovel;

      final viaMulti = ViaMultiplasEnfiadas()
        ..nome = 'Paredão dos Sonhos'
        ..dificuldadeMaxima = GrauVia_GrauVia.BR_7C
        ..destaque = false
        ..conquistadores.addAll(['Edu', 'Fabio']);
      final escaladaMulti = Escalada()..viaMultiplasEnfiadas = viaMulti;

      final highline = Highline()
        ..nome = 'Linha do Vento'
        ..distancia = 50
        ..destaque = false;
      final escaladaHigh = Escalada()..highline = highline;

      final setor = Setor()
        ..nome = 'Setor das Alturas'
        ..escaladas.addAll([escaladaMovel, escaladaMulti, escaladaHigh]);

      pico.setoresOuGrupos.add(
        SetorOuGrupo(setor: ArquivoSetor(conteudo: setor)),
      );

      final itens = indexarEscaladasDoPico(pico, 'crag-misto');
      expect(itens.length, 3);

      expect(itens[0].modalidade, 'Móvel');
      expect(itens[0].isDestaque, isTrue);
      expect(itens[0].conquistadores, ['Danilo']);

      expect(itens[1].modalidade, 'Multienfiada');
      expect(itens[1].isDestaque, isFalse);
      expect(itens[1].conquistadores, ['Edu', 'Fabio']);

      expect(itens[2].modalidade, 'Highline');
      expect(itens[2].isDestaque, isFalse);
      expect(itens[2].conquistadores, isEmpty);
    });
  });
}
