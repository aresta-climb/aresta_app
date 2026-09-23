// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/utils/indexador_escaladas.dart';
import 'package:frontend/utils/filtro_grau_escalada.dart';

void main() {
  group('FiltroGrauEscalada', () {
    late List<ItemIndiceEscalada> itens;

    setUp(() {
      final setor1 = Setor()..nome = 'Falésia Norte';
      final setor2 = Setor()..nome = 'Setor Central';
      final setor3 = Setor()..nome = 'Vale Escondido';

      final via1 = Escalada()
        ..viaEsportiva = (ViaEsportiva()
          ..nome = 'Via Fácil'
          ..dificuldade = GrauVia_GrauVia.BR_4
          ..destaque = false
          ..conquistadores.add('Alice'));

      final via2 = Escalada()
        ..viaEsportiva = (ViaEsportiva()
          ..nome = 'Via Clássica'
          ..dificuldade = GrauVia_GrauVia.BR_7A
          ..destaque = true
          ..conquistadores.addAll(['Bob', 'Carlos']));

      final via3 = Escalada()
        ..viaEsportiva = (ViaEsportiva()
          ..nome = 'Via Extrema'
          ..dificuldade = GrauVia_GrauVia.BR_9A
          ..destaque = false
          ..conquistadores.add('Alice'));

      final boulder1 = Escalada()
        ..boulder = (Boulder()
          ..nome = 'Bloco Simples'
          ..dificuldade = GrauBoulder_GrauBoulder.V2
          ..destaque = false
          ..conquistadores.add('Carlos'));

      final boulder2 = Escalada()
        ..boulder = (Boulder()
          ..nome = 'Bloco Forte'
          ..dificuldade = GrauBoulder_GrauBoulder.V7
          ..destaque = true
          ..conquistadores.add('Daniel'));

      final viaOutroSetor = Escalada()
        ..viaEsportiva = (ViaEsportiva()
          ..nome = 'Via Isolada'
          ..dificuldade = GrauVia_GrauVia.BR_5
          ..destaque = false
          ..conquistadores.add('Eduardo'));

      itens = [
        ItemIndiceEscalada(escalada: via1, setor: setor1, cragId: 'c1'),
        ItemIndiceEscalada(escalada: via2, setor: setor1, cragId: 'c1'),
        ItemIndiceEscalada(escalada: via3, setor: setor2, cragId: 'c1'),
        ItemIndiceEscalada(escalada: boulder1, setor: setor2, cragId: 'c1'),
        ItemIndiceEscalada(escalada: boulder2, setor: setor2, cragId: 'c1'),
        ItemIndiceEscalada(escalada: viaOutroSetor, setor: setor3, cragId: 'c1'),
      ];
    });

    test('filtra vias por intervalo contínuo de grau (RangeSlider)', () {
      final vias = itens.where((i) => i.modalidade == 'Esportiva').toList();

      // Intervalo entre 500 (4º) e 810 (7a)
      final estado = const EstadoFiltrosIndice(
        minGrauValor: 500,
        maxGrauValor: 810,
      );
      final resultado = estado.aplicar(vias);
      expect(resultado.map((i) => i.nome), ['Via Fácil', 'Via Isolada', 'Via Clássica']);
    });

    test('filtra boulders por intervalo contínuo de grau (RangeSlider)', () {
      final boulders = itens.where((i) => i.modalidade == 'Boulder').toList();

      // Intervalo entre 300 (V2) e 600 (V5)
      final estado = const EstadoFiltrosIndice(
        minGrauValor: 300,
        maxGrauValor: 600,
      );
      final resultado = estado.aplicar(boulders);
      expect(resultado.map((i) => i.nome), ['Bloco Simples']);
    });

    test('filtra apenas clássicas / estreladas', () {
      final estado = const EstadoFiltrosIndice(apenasClassicas: true);
      final resultado = estado.aplicar(itens);
      expect(resultado.map((i) => i.nome), ['Bloco Forte', 'Via Clássica']);
    });

    test('filtra por múltiplos setores simultaneamente (multi-seleção)', () {
      final estado = const EstadoFiltrosIndice(
        setores: {'Falésia Norte', 'Vale Escondido'},
      );
      final resultado = estado.aplicar(itens);
      expect(
        resultado.map((i) => i.nome),
        ['Via Fácil', 'Via Isolada', 'Via Clássica'],
      );
    });

    test('filtra por múltiplos conquistadores simultaneamente (multi-seleção)', () {
      final estado = const EstadoFiltrosIndice(
        conquistadores: {'Daniel', 'Bob'},
      );
      final resultado = estado.aplicar(itens);
      expect(resultado.map((i) => i.nome), ['Bloco Forte', 'Via Clássica']);
    });

    test('combina múltiplos filtros simultaneamente com setores e conquistadores múltiplos', () {
      final estado = const EstadoFiltrosIndice(
        setores: {'Falésia Norte', 'Setor Central'},
        conquistadores: {'Alice'},
        minGrauValor: 800,
      );
      final resultado = estado.aplicar(itens);
      expect(resultado.map((i) => i.nome), ['Via Extrema']);
    });

    test('identifica corretamente se possui filtros ativos', () {
      const estadoVazio = EstadoFiltrosIndice();
      expect(estadoVazio.temFiltrosAtivos, isFalse);

      const estadoComClassica = EstadoFiltrosIndice(apenasClassicas: true);
      expect(estadoComClassica.temFiltrosAtivos, isTrue);

      const estadoComSetores = EstadoFiltrosIndice(setores: {'Falésia Norte'});
      expect(estadoComSetores.temFiltrosAtivos, isTrue);

      const estadoComConquistador = EstadoFiltrosIndice(conquistadores: {'Alice'});
      expect(estadoComConquistador.temFiltrosAtivos, isTrue);

      const estadoComGrau = EstadoFiltrosIndice(minGrauValor: 500);
      expect(estadoComGrau.temFiltrosAtivos, isTrue);
    });

    group('obterSetoresDisponiveis e obterConquistadoresDisponiveis', () {
      late List<ItemIndiceEscalada> vias;

      setUp(() {
        vias = itens.where((i) => i.modalidade == 'Esportiva').toList();
      });

      test('retorna todos os setores e conquistadores quando nenhum filtro está ativo', () {
        const estado = EstadoFiltrosIndice();
        expect(
          estado.obterSetoresDisponiveis(vias),
          ['Falésia Norte', 'Setor Central', 'Vale Escondido'],
        );
        expect(
          estado.obterConquistadoresDisponiveis(vias),
          ['Alice', 'Bob', 'Carlos', 'Eduardo'],
        );
      });

      test('filtra setores e conquistadores disponíveis por faixa de grau', () {
        // Faixa entre 500 (4º) e 700 (6º): inclui 'Via Fácil' (Alice, Falésia Norte)
        // e 'Via Isolada' (Eduardo, Vale Escondido). Exclui 7a e 9a.
        const estado = EstadoFiltrosIndice(minGrauValor: 500, maxGrauValor: 700);

        expect(
          estado.obterSetoresDisponiveis(vias),
          ['Falésia Norte', 'Vale Escondido'],
        );
        expect(
          estado.obterConquistadoresDisponiveis(vias),
          ['Alice', 'Eduardo'],
        );
      });

      test('filtra conquistadores disponíveis baseado no setor selecionado', () {
        // Falésia Norte possui Alice (Via Fácil) e Bob/Carlos (Via Clássica)
        const estado = EstadoFiltrosIndice(setores: {'Falésia Norte'});

        expect(
          estado.obterConquistadoresDisponiveis(vias),
          ['Alice', 'Bob', 'Carlos'],
        );
      });

      test('filtra conquistadores combinando restrição de grau E setor selecionado', () {
        // Falésia Norte + faixa 500 a 700: apenas 'Via Fácil' (Alice)
        const estado = EstadoFiltrosIndice(
          setores: {'Falésia Norte'},
          minGrauValor: 500,
          maxGrauValor: 700,
        );

        expect(
          estado.obterConquistadoresDisponiveis(vias),
          ['Alice'],
        );
      });

      test('filtra setores disponíveis baseado no conquistador selecionado', () {
        // Alice tem vias em Falésia Norte (Via Fácil) e Setor Central (Via Extrema)
        const estado = EstadoFiltrosIndice(conquistadores: {'Alice'});

        expect(
          estado.obterSetoresDisponiveis(vias),
          ['Falésia Norte', 'Setor Central'],
        );
      });

      test('filtra setores e conquistadores por apenas clássicas', () {
        // Apenas 'Via Clássica' (Falésia Norte, Bob, Carlos)
        const estado = EstadoFiltrosIndice(apenasClassicas: true);

        expect(
          estado.obterSetoresDisponiveis(vias),
          ['Falésia Norte'],
        );
        expect(
          estado.obterConquistadoresDisponiveis(vias),
          ['Bob', 'Carlos'],
        );
      });

      test('temClassicasDisponiveis verifica presença de vias clássicas nos filtros atuais', () {
        // Inicialmente há 'Via Clássica' na modalidade
        const estadoInicial = EstadoFiltrosIndice();
        expect(estadoInicial.temClassicasDisponiveis(vias), isTrue);

        // Ao filtrar por 'Setor Central', que só tem 'Via Extrema' (não clássica), retorna false
        const estadoSetorSemClassica = EstadoFiltrosIndice(setores: {'Setor Central'});
        expect(estadoSetorSemClassica.temClassicasDisponiveis(vias), isFalse);

        // Ao filtrar por faixa de grau 500 a 700 (4º a 6º), nenhuma é clássica
        const estadoGrauSemClassica = EstadoFiltrosIndice(minGrauValor: 500, maxGrauValor: 700);
        expect(estadoGrauSemClassica.temClassicasDisponiveis(vias), isFalse);

        // Se apenasClassicas já estiver ativo, sempre retorna true para manter o botão visível para desmarcar
        const estadoJaAtivo = EstadoFiltrosIndice(
          setores: {'Setor Central'},
          apenasClassicas: true,
        );
        expect(estadoJaAtivo.temClassicasDisponiveis(vias), isTrue);
      });
    });
  });
}

