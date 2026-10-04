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

    group('obterPesoDificuldadeUnificado e Mediana de Grau de Setor', () {
      test('obterPesoDificuldadeUnificado retorna peso da via esportiva', () {
        final via = Escalada()
          ..viaEsportiva = (ViaEsportiva()
            ..nome = 'Via Teste'
            ..dificuldade = GrauVia_GrauVia.BR_7A);
        expect(obterPesoDificuldadeUnificado(via), 810);
      });

      test('obterPesoDificuldadeUnificado normaliza boulders na mesma régua que vias', () {
        final boulderV0 = Escalada()
          ..boulder = (Boulder()
            ..nome = 'B0'
            ..dificuldade = GrauBoulder_GrauBoulder.V0);
        final boulderV3 = Escalada()
          ..boulder = (Boulder()
            ..nome = 'B3'
            ..dificuldade = GrauBoulder_GrauBoulder.V3);
        final boulderV7 = Escalada()
          ..boulder = (Boulder()
            ..nome = 'B7'
            ..dificuldade = GrauBoulder_GrauBoulder.V7);

        // V0 deve equivaler a ~4º/5º (faixa de 500-600)
        expect(obterPesoDificuldadeUnificado(boulderV0), inInclusiveRange(500, 600));
        // V3 deve equivaler a ~7a (faixa de 800-820)
        expect(obterPesoDificuldadeUnificado(boulderV3), inInclusiveRange(800, 830));
        // V7 deve equivaler a ~8b/8c (faixa de 920-940)
        expect(obterPesoDificuldadeUnificado(boulderV7), inInclusiveRange(920, 940));
      });

      test('calcularMedianaGrauSetor com quantidade ímpar de vias', () {
        final v1 = Escalada()
          ..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.BR_4); // 500
        final v2 = Escalada()
          ..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.BR_6); // 700
        final v3 = Escalada()
          ..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.BR_8A); // 910

        expect(calcularMedianaGrauSetor([v1, v2, v3]), 700.0);
      });

      test('calcularMedianaGrauSetor com quantidade par de vias calcula a média dos dois centrais', () {
        final v1 = Escalada()
          ..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.BR_5); // 600
        final v2 = Escalada()
          ..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.BR_6); // 700
        final v3 = Escalada()
          ..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.BR_7A); // 810
        final v4 = Escalada()
          ..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.BR_8A); // 910

        // Centrais são 700 e 810 => média 755.0
        expect(calcularMedianaGrauSetor([v1, v2, v3, v4]), 755.0);
      });

      test('calcularMedianaGrauSetor é resiliente a outliers (outlier não distorce a falésia)', () {
        // Falésia com 5 vias fáceis (500 e 600) e 1 projeto isolado de 11a (1210)
        final vias = [
          Escalada()..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.BR_4),
          Escalada()..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.BR_4),
          Escalada()..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.BR_5),
          Escalada()..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.BR_5),
          Escalada()..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.BR_5),
          Escalada()..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.BR_11A),
        ];

        // Pesos: 500, 500, 600, 600, 600, 1210
        // Centrais (índices 2 e 3): 600 e 600 => mediana 600.0 (5º grau!)
        expect(calcularMedianaGrauSetor(vias), 600.0);
      });

      test('calcularMedianaGrauSetor funciona para setor misto com vias e boulders', () {
        final via = Escalada()
          ..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.BR_5); // ~600
        final boulder = Escalada()
          ..boulder = (Boulder()..dificuldade = GrauBoulder_GrauBoulder.V1); // ~600
        final viaDificil = Escalada()
          ..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.BR_8A); // 910

        final mediana = calcularMedianaGrauSetor([via, boulder, viaDificil]);
        expect(mediana, inInclusiveRange(580.0, 650.0));
      });

      test('calcularMedianaGrauSetor para lista vazia ou indefinida retorna sentinela 9998.0', () {
        expect(calcularMedianaGrauSetor([]), 9998.0);

        final indefinida = Escalada()
          ..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.INDEFINIDO);
        expect(calcularMedianaGrauSetor([indefinida]), 9998.0);
      });

      test('formatarFaixaGrausSetor retorna faixa formatada do setor', () {
        final v1 = Escalada()
          ..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.BR_5);
        final v2 = Escalada()
          ..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.BR_8A);

        expect(formatarFaixaGrausSetor([v1, v2]), '5º a 8a');
      });

      test('formatarFaixaGrausSetor com único grau ou vazio', () {
        expect(formatarFaixaGrausSetor([]), '');

        final v1 = Escalada()
          ..viaEsportiva = (ViaEsportiva()..dificuldade = GrauVia_GrauVia.BR_7A);
        expect(formatarFaixaGrausSetor([v1]), '7a');
      });
    });

    group('EstadoFiltrosUnificado', () {
      late List<ItemIndiceEscalada> todasEscaladas;
      late List<SetorOuGrupo> todosSetores;
      late Setor setorFacil;
      late Setor setorForte;
      late Setor setorApenasBoulder;

      setUp(() {
        setorFacil = Setor()..nome = 'Setor Escola';
        setorForte = Setor()..nome = 'Setor Falésia Alta';
        setorApenasBoulder = Setor()..nome = 'Bloco Solitário';

        final via1 = Escalada()
          ..viaEsportiva = (ViaEsportiva()
            ..nome = 'Via Aprendiz'
            ..dificuldade = GrauVia_GrauVia.BR_4
            ..destaque = false
            ..conquistadores.add('Alice'));

        final via2 = Escalada()
          ..viaEsportiva = (ViaEsportiva()
            ..nome = 'Via Desafio'
            ..dificuldade = GrauVia_GrauVia.BR_8A
            ..destaque = true
            ..conquistadores.add('Bob'));

        final boulder1 = Escalada()
          ..boulder = (Boulder()
            ..nome = 'Boulder V1'
            ..dificuldade = GrauBoulder_GrauBoulder.V1
            ..destaque = false
            ..conquistadores.add('Carlos'));

        todasEscaladas = [
          ItemIndiceEscalada(escalada: via1, setor: setorFacil, cragId: 'pico_1'),
          ItemIndiceEscalada(escalada: via2, setor: setorForte, cragId: 'pico_1'),
          ItemIndiceEscalada(escalada: boulder1, setor: setorApenasBoulder, cragId: 'pico_1'),
        ];

        todosSetores = [
          SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setorFacil),
          SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setorForte),
          SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setorApenasBoulder),
        ];
      });

      test('estado inicial sem filtros reporta temFiltrosAtivos false', () {
        const estado = EstadoFiltrosUnificado();
        expect(estado.temFiltrosAtivos, isFalse);
      });

      test('filtra escaladas por modalidade específica e faixa de grau', () {
        final estado = const EstadoFiltrosUnificado(
          minGrauPorModalidade: {'Esportiva': 800},
        );
        expect(estado.temFiltrosAtivos, isTrue);

        final esportivas = estado.filtrarEscaladas(todasEscaladas, modalidadeEspecifica: 'Esportiva');
        expect(esportivas.map((e) => e.nome), ['Via Desafio']);
      });

      test('filtra setores ocultando setores sem escaladas correspondentes', () {
        final estado = const EstadoFiltrosUnificado(
          minGrauPorModalidade: {'Esportiva': 800},
          modalidadesAtivas: {'Esportiva'},
        );

        final setoresFiltrados = estado.filtrarSetores(todosSetores, todasEscaladas);
        // Apenas 'Setor Falésia Alta' possui via esportiva >= 800 (Via Desafio 8a)
        expect(setoresFiltrados.length, 1);
        expect(setoresFiltrados.first.setor.conteudo.nome, 'Setor Falésia Alta');
      });

      test('desativar modalidade oculta setores exclusivos daquela modalidade', () {
        final estado = const EstadoFiltrosUnificado(
          modalidadesAtivas: {'Esportiva'},
        );

        final setoresFiltrados = estado.filtrarSetores(todosSetores, todasEscaladas);
        // 'Bloco Solitário' possui apenas Boulder, logo é excluído quando Boulder está inativo
        expect(setoresFiltrados.map((s) => s.setor.conteudo.nome), [
          'Setor Escola',
          'Setor Falésia Alta',
        ]);
      });

      test('ordenação de setores por GRAU crescente e decrescente', () {
        final estadoCrescente = const EstadoFiltrosUnificado(
          tipoOrdenacao: TipoOrdenacaoExploracao.grau,
          direcaoCrescente: true,
        );
        final setoresCrescentes = estadoCrescente.filtrarSetores(todosSetores, todasEscaladas);
        expect(setoresCrescentes.map((s) => s.setor.conteudo.nome), [
          'Setor Escola', // 4º (peso 500)
          'Bloco Solitário', // V1 (peso 650)
          'Setor Falésia Alta', // 8a (peso 910)
        ]);

        final estadoDecrescente = const EstadoFiltrosUnificado(
          tipoOrdenacao: TipoOrdenacaoExploracao.grau,
          direcaoCrescente: false,
        );
        final setoresDecrescentes = estadoDecrescente.filtrarSetores(todosSetores, todasEscaladas);
        expect(setoresDecrescentes.map((s) => s.setor.conteudo.nome), [
          'Setor Falésia Alta',
          'Bloco Solitário',
          'Setor Escola',
        ]);
      });

      test('ordenação de setores ALFABÉTICA A-Z e Z-A', () {
        final estadoAsc = const EstadoFiltrosUnificado(
          tipoOrdenacao: TipoOrdenacaoExploracao.alfabetico,
          direcaoCrescente: true,
        );
        final setoresAsc = estadoAsc.filtrarSetores(todosSetores, todasEscaladas);
        expect(setoresAsc.map((s) => s.setor.conteudo.nome), [
          'Bloco Solitário',
          'Setor Escola',
          'Setor Falésia Alta',
        ]);

        final estadoDesc = const EstadoFiltrosUnificado(
          tipoOrdenacao: TipoOrdenacaoExploracao.alfabetico,
          direcaoCrescente: false,
        );
        final setoresDesc = estadoDesc.filtrarSetores(todosSetores, todasEscaladas);
        expect(setoresDesc.map((s) => s.setor.conteudo.nome), [
          'Setor Falésia Alta',
          'Setor Escola',
          'Bloco Solitário',
        ]);
      });

      test('formatação de contadores nas abas com e sem filtros', () {
        const estadoSemFiltro = EstadoFiltrosUnificado();
        expect(estadoSemFiltro.obterContadorSetores(todosSetores, todasEscaladas), '(3)');
        expect(estadoSemFiltro.obterContadorModalidade('Esportiva', todasEscaladas), '(2)');
        expect(estadoSemFiltro.obterContadorModalidade('Boulder', todasEscaladas), '(1)');

        final estadoComFiltro = const EstadoFiltrosUnificado(
          minGrauPorModalidade: {'Esportiva': 800},
          modalidadesAtivas: {'Esportiva'},
        );
        expect(estadoComFiltro.obterContadorSetores(todosSetores, todasEscaladas), '(1/3)');
        expect(estadoComFiltro.obterContadorModalidade('Esportiva', todasEscaladas), '(1/2)');
        expect(estadoComFiltro.obterContadorModalidade('Boulder', todasEscaladas), '(0/1)');
      });

      test('copyWith e flags de limpeza de EstadoFiltrosUnificado', () {
        const base = EstadoFiltrosUnificado(
          modalidadesAtivas: {'Esportiva'},
          minGrauPorModalidade: {'Esportiva': 500},
          maxGrauPorModalidade: {'Esportiva': 900},
          setores: {'Setor 1'},
          grupos: {'Grupo 1'},
          conquistadores: {'Carlos'},
          apenasClassicas: true,
          termoBusca: 'via',
          tipoOrdenacao: TipoOrdenacaoExploracao.grau,
          direcaoCrescente: false,
        );

        final atualizado = base.copyWith(
          modalidadesAtivas: {'Boulder'},
          minGrauPorModalidade: {'Boulder': 600},
          maxGrauPorModalidade: {'Boulder': 1000},
          setores: {'Setor 2'},
          grupos: {'Grupo 2'},
          conquistadores: {'Daniel'},
          apenasClassicas: false,
          termoBusca: 'boulder',
          tipoOrdenacao: TipoOrdenacaoExploracao.alfabetico,
          direcaoCrescente: true,
        );

        expect(atualizado.modalidadesAtivas, {'Boulder'});
        expect(atualizado.setores, {'Setor 2'});
        expect(atualizado.grupos, {'Grupo 2'});
        expect(atualizado.conquistadores, {'Daniel'});
        expect(atualizado.apenasClassicas, isFalse);
        expect(atualizado.termoBusca, 'boulder');
        expect(atualizado.tipoOrdenacao, TipoOrdenacaoExploracao.alfabetico);
        expect(atualizado.direcaoCrescente, isTrue);

        final limpo = atualizado.copyWith(
          clearSetores: true,
          clearGrupos: true,
          clearConquistadores: true,
        );
        expect(limpo.setores, isEmpty);
        expect(limpo.grupos, isEmpty);
        expect(limpo.conquistadores, isEmpty);
      });

      test('filtragem de escaladas com conquistadores, clássicas e termo de busca', () {
        final escaladaComConquistador = Escalada(
          viaEsportiva: ViaEsportiva(
            nome: 'Via do André',
            dificuldade: GrauVia_GrauVia.BR_7A,
            conquistadores: ['André'],
            destaque: true,
          ),
        );
        final itemComConq = ItemIndiceEscalada(
          escalada: escaladaComConquistador,
          setor: Setor(nome: 'Setor Alto'),
          cragId: 'crag1',
        );

        const estadoConq = EstadoFiltrosUnificado(conquistadores: {'André'});
        expect(estadoConq.filtrarEscaladas([itemComConq]), hasLength(1));

        const estadoOutroConq = EstadoFiltrosUnificado(conquistadores: {'Outro'});
        expect(estadoOutroConq.filtrarEscaladas([itemComConq]), isEmpty);

        const estadoBusca = EstadoFiltrosUnificado(termoBusca: 'André');
        expect(estadoBusca.filtrarEscaladas([itemComConq]), hasLength(1));

        const estadoBuscaInexistente = EstadoFiltrosUnificado(termoBusca: 'xyz123');
        expect(estadoBuscaInexistente.filtrarEscaladas([itemComConq]), isEmpty);

        const estadoPadraoDesc = EstadoFiltrosUnificado(
          tipoOrdenacao: TipoOrdenacaoExploracao.padrao,
          direcaoCrescente: false,
        );
        final invertido = estadoPadraoDesc.filtrarEscaladas(todasEscaladas);
        expect(invertido.first.nome, todasEscaladas.last.nome);
      });

      test('obterNomeSetorOuGrupo e filtragem com Grupo', () {
        final grupoMsg = Grupo(
          nome: 'Complexo Central',
          setores: [
            ArquivoSetor(
              conteudo: Setor(
                nome: 'Setor Sub 1',
                escaladas: [
                  Escalada(
                    viaEsportiva: ViaEsportiva(
                      nome: 'Via Grupo',
                      dificuldade: GrauVia_GrauVia.BR_6SUP,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        final sgGrupo = SetorOuGrupo(grupo: ArquivoGrupo(conteudo: grupoMsg));
        expect(EstadoFiltrosUnificado.obterNomeSetorOuGrupo(sgGrupo), 'Complexo Central');

        final itemGrupo = ItemIndiceEscalada(
          escalada: grupoMsg.setores.first.conteudo.escaladas.first,
          setor: grupoMsg.setores.first.conteudo,
          grupo: grupoMsg,
          cragId: 'crag1',
        );

        const estadoGrupo = EstadoFiltrosUnificado(grupos: {'Complexo Central'});
        final filtrados = estadoGrupo.filtrarSetores([sgGrupo], [itemGrupo]);
        expect(filtrados, hasLength(1));

        const estadoOutroGrupo = EstadoFiltrosUnificado(grupos: {'Outro Grupo'});
        final filtradosOutro = estadoOutroGrupo.filtrarSetores([sgGrupo], [itemGrupo]);
        expect(filtradosOutro, isEmpty);
      });

      test('filtrarEscaladas unifica filtro de localização quando setores E grupos são selecionados', () {
        final itemSetorA = ItemIndiceEscalada(
          escalada: Escalada(viaEsportiva: ViaEsportiva(nome: 'Via A', dificuldade: GrauVia_GrauVia.BR_5)),
          setor: Setor(nome: 'Setor A'),
          cragId: 'crag1',
        );
        final grupoG = Grupo(nome: 'Grupo G');
        final itemGrupoG = ItemIndiceEscalada(
          escalada: Escalada(viaEsportiva: ViaEsportiva(nome: 'Via G', dificuldade: GrauVia_GrauVia.BR_6SUP)),
          setor: Setor(nome: 'Setor B'),
          grupo: grupoG,
          cragId: 'crag1',
        );
        final itemOutro = ItemIndiceEscalada(
          escalada: Escalada(viaEsportiva: ViaEsportiva(nome: 'Via Outra', dificuldade: GrauVia_GrauVia.BR_7A)),
          setor: Setor(nome: 'Setor C'),
          cragId: 'crag1',
        );

        // Quando o usuário seleciona Setor A e Grupo G no filtro de localização:
        const estadoLocalizacao = EstadoFiltrosUnificado(
          setores: {'Setor A'},
          grupos: {'Grupo G'},
        );

        final filtrados = estadoLocalizacao.filtrarEscaladas([itemSetorA, itemGrupoG, itemOutro]);
        // Deve retornar ambas (Via A e Via G) e excluir Via Outra
        expect(filtrados.map((i) => i.nome).toSet(), {'Via A', 'Via G'});
      });

      test('obterCategoriaGrau mapeia corretamente para Via ou Boulder', () {
        expect(EstadoFiltrosUnificado.obterCategoriaGrau('Esportiva'), 'Via');
        expect(EstadoFiltrosUnificado.obterCategoriaGrau('Tradicional'), 'Via');
        expect(EstadoFiltrosUnificado.obterCategoriaGrau('Top Rope'), 'Via');
        expect(EstadoFiltrosUnificado.obterCategoriaGrau('Artificial'), 'Via');
        expect(EstadoFiltrosUnificado.obterCategoriaGrau('Boulder'), 'Boulder');
        expect(EstadoFiltrosUnificado.obterCategoriaGrau('boulder'), 'Boulder');
      });

      test('filtro de grau com chave "Via" restringe todas as modalidades de via sem afetar boulders', () {
        final viaEspFacil = ItemIndiceEscalada(
          escalada: Escalada(viaEsportiva: ViaEsportiva(nome: 'Esp Fácil', dificuldade: GrauVia_GrauVia.BR_5)),
          setor: Setor(nome: 'Setor 1'),
          cragId: 'c1',
        );
        final viaEspDificil = ItemIndiceEscalada(
          escalada: Escalada(viaEsportiva: ViaEsportiva(nome: 'Esp Difícil', dificuldade: GrauVia_GrauVia.BR_8A)),
          setor: Setor(nome: 'Setor 1'),
          cragId: 'c1',
        );
        final viaTradFacil = ItemIndiceEscalada(
          escalada: Escalada(viaMovel: ViaMovel(nome: 'Trad Fácil', dificuldade: GrauVia_GrauVia.BR_5)),
          setor: Setor(nome: 'Setor 1'),
          cragId: 'c1',
        );
        final boulder = ItemIndiceEscalada(
          escalada: Escalada(boulder: Boulder(nome: 'Bloco', dificuldade: GrauBoulder_GrauBoulder.V2)),
          setor: Setor(nome: 'Setor 1'),
          cragId: 'c1',
        );

        // Filtro de vias exigindo no mínimo 8a (valor 910)
        const estadoVias = EstadoFiltrosUnificado(
          minGrauPorModalidade: {'Via': 910},
        );

        final filtrados = estadoVias.filtrarEscaladas([viaEspFacil, viaEspDificil, viaTradFacil, boulder]);

        // Apenas Esp Difícil e o Boulder devem permanecer (o boulder não tem restrição de grau ativada)
        expect(filtrados.map((e) => e.nome).toSet(), {'Esp Difícil', 'Bloco'});
      });

      test('filtro de grau com chave "Boulder" restringe boulders sem afetar vias', () {
        final via = ItemIndiceEscalada(
          escalada: Escalada(viaEsportiva: ViaEsportiva(nome: 'Via Qualquer', dificuldade: GrauVia_GrauVia.BR_5)),
          setor: Setor(nome: 'Setor 1'),
          cragId: 'c1',
        );
        final boulderFacil = ItemIndiceEscalada(
          escalada: Escalada(boulder: Boulder(nome: 'V1', dificuldade: GrauBoulder_GrauBoulder.V1)),
          setor: Setor(nome: 'Setor 1'),
          cragId: 'c1',
        );
        final boulderDificil = ItemIndiceEscalada(
          escalada: Escalada(boulder: Boulder(nome: 'V5', dificuldade: GrauBoulder_GrauBoulder.V5)),
          setor: Setor(nome: 'Setor 1'),
          cragId: 'c1',
        );

        // Filtro de boulder exigindo no mínimo V4 (valor 500)
        const estadoBoulder = EstadoFiltrosUnificado(
          minGrauPorModalidade: {'Boulder': 500},
        );

        final filtrados = estadoBoulder.filtrarEscaladas([via, boulderFacil, boulderDificil]);

        // Apenas a Via (não afetada) e o V5 devem permanecer
        expect(filtrados.map((e) => e.nome).toSet(), {'Via Qualquer', 'V5'});
      });
    });
  });
}

