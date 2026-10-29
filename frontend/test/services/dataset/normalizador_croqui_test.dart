// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/services/dataset/normalizador_croqui.dart';

void main() {
  group('NormalizadorCroqui', () {
    test('sintetiza UIDs canônicos para grupos, setores e escaladas sem UID', () {
      final pico = Pico();

      // Grupo com setor e escalada
      final grupo = Grupo()..nome = 'Falésia dos Ventos';
      final setorComGrupo = Setor()..nome = 'Setor Principal';
      final escaladaComGrupo = Escalada()
        ..viaEsportiva = (ViaEsportiva()..nome = 'Brisa Suave');
      setorComGrupo.escaladas.add(escaladaComGrupo);
      grupo.setores.add(ArquivoSetor()..conteudo = setorComGrupo);

      pico.setoresOuGrupos.add(
        SetorOuGrupo(grupo: ArquivoGrupo(conteudo: grupo)),
      );

      // Setor direto sob o pico
      final setorDireto = Setor()..nome = 'Bloco Isolado';
      final escaladaDireta = Escalada()
        ..boulder = (Boulder()..nome = 'Fenda da Lua');
      setorDireto.escaladas.add(escaladaDireta);

      pico.setoresOuGrupos.add(
        SetorOuGrupo(setor: ArquivoSetor(conteudo: setorDireto)),
      );

      // Botão no croqui
      final botao = Botao()..texto = 'Regras de Acesso';
      final croqui = Croqui()
        ..picos.add(pico)
        ..botoes.add(botao);

      NormalizadorCroqui.normalizarCroqui(croqui);

      expect(grupo.uid, equals('sintetico:grupo:Falésia dos Ventos'));
      expect(
        setorComGrupo.uid,
        equals('sintetico:setor:Falésia dos Ventos:Setor Principal'),
      );
      expect(
        escaladaComGrupo.uid,
        equals('sintetico:escalada:Falésia dos Ventos:Setor Principal:Brisa Suave'),
      );

      expect(setorDireto.uid, equals('sintetico:setor::Bloco Isolado'));
      expect(
        escaladaDireta.uid,
        equals('sintetico:escalada::Bloco Isolado:Fenda da Lua'),
      );

      // Botões legados não devem receber UID sintético
      expect(botao.uid, isEmpty);
    });

    test('normaliza pontos de interesse e referências em mapas de setor com grupo', () {
      final mapa = Mapa()
        ..caminhoImagemMapa = 'mapa1.webp'
        ..pontosDeInteresse.add(
          Mapa_PontoDeInteresse()
            ..id = 'p1'
            ..label = '11',
        )
        ..referencias.add(
          Mapa_Referencia()
            ..escalada = 'Via Teste'
            ..ids.add('p1'),
        );

      final setor = Setor()
        ..nome = 'Setor Sol'
        ..escaladas.add(
          Escalada()..viaEsportiva = (ViaEsportiva()..nome = 'Via Teste'),
        )
        ..mapas.add(mapa);

      final grupo = Grupo()
        ..nome = 'Vale Perdido'
        ..setores.add(ArquivoSetor()..conteudo = setor);

      final pico = Pico()
        ..setoresOuGrupos.add(
          SetorOuGrupo(grupo: ArquivoGrupo(conteudo: grupo)),
        );

      NormalizadorCroqui.normalizarPico(pico);

      // Ponto de interesse deve ter uid e rotulo preenchidos
      final ponto = mapa.pontosDeInteresse.first;
      expect(ponto.uid, equals('p1'));
      expect(ponto.rotulo, equals('11'));

      // Referência deve ter pontosUids e alvoUid sintetizado
      final ref = mapa.referencias.first;
      expect(ref.pontosUids, equals(['p1']));
      expect(ref.alvoUid, equals('sintetico:escalada:Vale Perdido:Setor Sol:Via Teste'));
    });

    test('normaliza referências para setores e grupos em mapas gerais', () {
      final mapaGeral = Mapa()
        ..referencias.addAll([
          Mapa_Referencia()
            ..grupo = 'Vale Perdido'
            ..ids.add('p_grp'),
          Mapa_Referencia()
            ..grupo = 'Vale Perdido'
            ..setor = 'Setor Sol'
            ..ids.add('p_set'),
        ]);

      final pico = Pico()
        ..mapasGerais = (ArquivoMapas()
          ..conteudo = (ColecaoDeMapas()..mapas.add(mapaGeral)));

      NormalizadorCroqui.normalizarPico(pico);

      expect(mapaGeral.referencias[0].alvoUid, equals('sintetico:grupo:Vale Perdido'));
      expect(mapaGeral.referencias[0].pontosUids, equals(['p_grp']));

      expect(mapaGeral.referencias[1].alvoUid, equals('sintetico:setor:Vale Perdido:Setor Sol'));
      expect(mapaGeral.referencias[1].pontosUids, equals(['p_set']));
    });

    test('normaliza mapas próprios de escalada', () {
      final mapaProprio = Mapa()
        ..pontosDeInteresse.add(
          Mapa_PontoDeInteresse()
            ..id = 'no_crux'
            ..label = 'C',
        );

      final escalada = Escalada()
        ..viaEsportiva = (ViaEsportiva()..nome = 'Via Autônoma')
        ..mapas.add(mapaProprio);

      final setor = Setor()
        ..nome = 'Parede Sul'
        ..escaladas.add(escalada);

      final pico = Pico()
        ..setoresOuGrupos.add(
          SetorOuGrupo(setor: ArquivoSetor(conteudo: setor)),
        );

      NormalizadorCroqui.normalizarPico(pico);

      expect(mapaProprio.pontosDeInteresse.first.uid, equals('no_crux'));
      expect(mapaProprio.pontosDeInteresse.first.rotulo, equals('C'));
    });

    test('preserva UIDs, rótulos e alvos que já estejam no padrão nativo v5', () {
      final escalada = Escalada()
        ..uid = 'nativo_esc_999'
        ..viaEsportiva = (ViaEsportiva()..nome = 'Via Moderna');

      final mapa = Mapa()
        ..pontosDeInteresse.add(
          Mapa_PontoDeInteresse()
            ..uid = 'nativo_poi_123'
            ..rotulo = 'R1',
        )
        ..referencias.add(
          Mapa_Referencia()
            ..alvoUid = 'nativo_esc_999'
            ..pontosUids.add('nativo_poi_123'),
        );

      final setor = Setor()
        ..uid = 'nativo_set_456'
        ..nome = 'Setor Novo'
        ..escaladas.add(escalada)
        ..mapas.add(mapa);

      final pico = Pico()
        ..setoresOuGrupos.add(
          SetorOuGrupo(setor: ArquivoSetor(conteudo: setor)),
        );

      NormalizadorCroqui.normalizarPico(pico);

      expect(setor.uid, equals('nativo_set_456'));
      expect(escalada.uid, equals('nativo_esc_999'));
      expect(mapa.pontosDeInteresse.first.uid, equals('nativo_poi_123'));
      expect(mapa.pontosDeInteresse.first.rotulo, equals('R1'));
      expect(mapa.referencias.first.alvoUid, equals('nativo_esc_999'));
      expect(mapa.referencias.first.pontosUids, equals(['nativo_poi_123']));
    });

    test('extrai nome de todas as modalidades de escalada corretamente', () {
      final viaMovel = Escalada()..viaMovel = (ViaMovel()..nome = 'Fissura Móvel');
      final enfiadas = Escalada()..viaMultiplasEnfiadas = (ViaMultiplasEnfiadas()..nome = 'Paredão');
      final highline = Escalada()..highline = (Highline()..nome = 'Linha Alta');
      final indefinida = Escalada();

      expect(NormalizadorCroqui.extrairNomeEscalada(viaMovel), equals('Fissura Móvel'));
      expect(NormalizadorCroqui.extrairNomeEscalada(enfiadas), equals('Paredão'));
      expect(NormalizadorCroqui.extrairNomeEscalada(highline), equals('Linha Alta'));
      expect(NormalizadorCroqui.extrairNomeEscalada(indefinida), isEmpty);
    });

    test('deBuffer desserializa e aplica normalização in-place', () {
      final croquiOriginal = Croqui()
        ..nome = 'Croqui Teste'
        ..picos.add(
          Pico()
            ..setoresOuGrupos.add(
              SetorOuGrupo(
                setor: ArquivoSetor(
                  conteudo: Setor()..nome = 'Setor Binário',
                ),
              ),
            ),
        );

      final bytes = croquiOriginal.writeToBuffer();
      final croquiNormalizado = NormalizadorCroqui.deBuffer(bytes);

      final setor = croquiNormalizado.picos.first.setoresOuGrupos.first.setor.conteudo;
      expect(setor.uid, equals('sintetico:setor::Setor Binário'));
    });

    test('normalizarMapa normaliza um único mapa in-place', () {
      final mapa = Mapa()
        ..pontosDeInteresse.add(Mapa_PontoDeInteresse(id: 'poi_1', label: '1'))
        ..referencias.add(Mapa_Referencia(escalada: 'Via Solo', ids: ['poi_1']));

      NormalizadorCroqui.normalizarMapa(
        mapa,
        setorNomeContexto: 'Setor Solo',
      );

      expect(mapa.pontosDeInteresse.first.uid, equals('poi_1'));
      expect(mapa.pontosDeInteresse.first.rotulo, equals('1'));
      expect(mapa.referencias.first.alvoUid, equals('sintetico:escalada::Setor Solo:Via Solo'));
      expect(mapa.referencias.first.pontosUids, equals(['poi_1']));
    });

    test('garante idempotência O(1) sem reprocessar instâncias de Croqui, Pico e Mapa já normalizadas', () {
      final mapa = Mapa()
        ..pontosDeInteresse.add(Mapa_PontoDeInteresse(id: 'poi_1', label: '1'));
      final setor = Setor()
        ..nome = 'Setor Idempotente'
        ..mapas.add(mapa);
      final pico = Pico()
        ..setoresOuGrupos.add(
          SetorOuGrupo(setor: ArquivoSetor(conteudo: setor)),
        );
      final croqui = Croqui()..picos.add(pico);

      expect(NormalizadorCroqui.estaNormalizado(croqui), isFalse);
      expect(NormalizadorCroqui.estaNormalizado(pico), isFalse);
      expect(NormalizadorCroqui.estaNormalizado(mapa), isFalse);

      NormalizadorCroqui.normalizarCroqui(croqui);

      expect(NormalizadorCroqui.estaNormalizado(croqui), isTrue);
      expect(NormalizadorCroqui.estaNormalizado(pico), isTrue);
      expect(NormalizadorCroqui.estaNormalizado(mapa), isTrue);
      expect(setor.uid, equals('sintetico:setor::Setor Idempotente'));
      expect(mapa.pontosDeInteresse.first.uid, equals('poi_1'));

      // Se limpamos o uid na mesma instância já normalizada, chamadas subsequentes
      // devem retornar imediatamente em O(1) sem revarrer a árvore.
      setor.uid = '';
      mapa.pontosDeInteresse.first.uid = '';
      NormalizadorCroqui.normalizarCroqui(croqui);
      NormalizadorCroqui.normalizarPico(pico);
      NormalizadorCroqui.normalizarMapa(mapa);

      expect(setor.uid, isEmpty);
      expect(mapa.pontosDeInteresse.first.uid, isEmpty);

      // Uma nova instância de Pico não está marcada e deve ser normalizada normalmente
      final novoPico = Pico()
        ..setoresOuGrupos.add(
          SetorOuGrupo(
            setor: ArquivoSetor(conteudo: Setor()..nome = 'Novo Setor'),
          ),
        );
      expect(NormalizadorCroqui.estaNormalizado(novoPico), isFalse);
      NormalizadorCroqui.normalizarPico(novoPico);
      expect(NormalizadorCroqui.estaNormalizado(novoPico), isTrue);
      expect(
        novoPico.setoresOuGrupos.first.setor.conteudo.uid,
        equals('sintetico:setor::Novo Setor'),
      );
    });
  });
}
