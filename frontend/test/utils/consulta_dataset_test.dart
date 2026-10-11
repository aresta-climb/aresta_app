// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/utils/consulta_dataset.dart';

void main() {
  group('ResolvedDataset', () {
    test('deve armazenar e recuperar entidade do tipo botão com ancestrais corretos', () {
      final botao = Botao(uid: 'btn-1', texto: 'Regras do Pico');
      final resolved = ResolvedDataset(
        tipo: TipoEntidadeResolved.botao,
        botao: botao,
      );

      expect(resolved.tipo, TipoEntidadeResolved.botao);
      expect(resolved.botao, botao);
      expect(resolved.grupo, isNull);
      expect(resolved.setor, isNull);
      expect(resolved.escalada, isNull);
      expect(resolved.nome, 'Regras do Pico');
      expect(resolved.referencias, isEmpty);
    });

    test('deve armazenar e recuperar entidade do tipo grupo', () {
      final grupo = Grupo(uid: 'grp-1', nome: 'Falésia Principal');
      final resolved = ResolvedDataset(
        tipo: TipoEntidadeResolved.grupo,
        grupo: grupo,
      );

      expect(resolved.tipo, TipoEntidadeResolved.grupo);
      expect(resolved.grupo, grupo);
      expect(resolved.setor, isNull);
      expect(resolved.escalada, isNull);
      expect(resolved.botao, isNull);
      expect(resolved.nome, 'Falésia Principal');
    });

    test('deve armazenar e recuperar setor com seu grupo ancestral quando houver', () {
      final grupo = Grupo(uid: 'grp-1', nome: 'Falésia Principal');
      final setor = Setor(uid: 'set-1', nome: 'Setor Central');
      final resolved = ResolvedDataset(
        tipo: TipoEntidadeResolved.setor,
        grupo: grupo,
        setor: setor,
      );

      expect(resolved.tipo, TipoEntidadeResolved.setor);
      expect(resolved.grupo, grupo);
      expect(resolved.setor, setor);
      expect(resolved.escalada, isNull);
      expect(resolved.nome, 'Setor Central');
    });

    test('deve armazenar e recuperar escalada com setor e grupo ancestrais e referências em mapas', () {
      final grupo = Grupo(uid: 'grp-1', nome: 'Falésia Principal');
      final setor = Setor(uid: 'set-1', nome: 'Setor Central');
      final escalada = Escalada(
        uid: 'esc-1',
        viaEsportiva: ViaEsportiva(nome: 'Fissura da Tarde'),
      );
      final mapa = Mapa(caminhoImagemMapa: 'mapa_geral.jpg');
      final ref = Mapa_Referencia(alvoUid: 'esc-1');
      final refNoMapa = ReferenciaNoMapa(mapa: mapa, referencia: ref);

      final resolved = ResolvedDataset(
        tipo: TipoEntidadeResolved.escalada,
        grupo: grupo,
        setor: setor,
        escalada: escalada,
        referencias: [refNoMapa],
      );

      expect(resolved.tipo, TipoEntidadeResolved.escalada);
      expect(resolved.grupo, grupo);
      expect(resolved.setor, setor);
      expect(resolved.escalada, escalada);
      expect(resolved.nome, 'Fissura da Tarde');
      expect(resolved.referencias, hasLength(1));
      expect(resolved.referencias.first.mapa, mapa);
      expect(resolved.referencias.first.referencia, ref);
    });

    test('deve suportar igualdade de valor e hashCode entre instâncias idênticas', () {
      final grupo = Grupo(uid: 'grp-1', nome: 'Falésia Principal');
      final r1 = ResolvedDataset(tipo: TipoEntidadeResolved.grupo, grupo: grupo);
      final r2 = ResolvedDataset(tipo: TipoEntidadeResolved.grupo, grupo: grupo);
      final r3 = ResolvedDataset(tipo: TipoEntidadeResolved.grupo, grupo: Grupo(uid: 'grp-2', nome: 'Outro Grupo'));

      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
      expect(r1, isNot(equals(r3)));

      final ref1 = ReferenciaNoMapa(mapa: Mapa(caminhoImagemMapa: 'm1'), referencia: Mapa_Referencia(alvoUid: '1'));
      final ref2 = ReferenciaNoMapa(mapa: Mapa(caminhoImagemMapa: 'm2'), referencia: Mapa_Referencia(alvoUid: '2'));
      final rComRef1 = ResolvedDataset(tipo: TipoEntidadeResolved.grupo, grupo: grupo, referencias: [ref1]);
      final rComRef2 = ResolvedDataset(tipo: TipoEntidadeResolved.grupo, grupo: grupo, referencias: [ref2]);
      expect(rComRef1, isNot(equals(rComRef2)));
    });

    test('deve calcular nome corretamente para diferentes tipos de escalada', () {
      final viaMovel = Escalada(uid: 'esc-2', viaMovel: ViaMovel(nome: 'Diedro Amarelo'));
      final boulder = Escalada(uid: 'esc-3', boulder: Boulder(nome: 'Teto Solar'));
      final multiplas = Escalada(uid: 'esc-4', viaMultiplasEnfiadas: ViaMultiplasEnfiadas(nome: 'Face Leste'));
      final highline = Escalada(uid: 'esc-5', highline: Highline(nome: 'Linha do Vento'));

      expect(ResolvedDataset(tipo: TipoEntidadeResolved.escalada, escalada: viaMovel).nome, 'Diedro Amarelo');
      expect(ResolvedDataset(tipo: TipoEntidadeResolved.escalada, escalada: boulder).nome, 'Teto Solar');
      expect(ResolvedDataset(tipo: TipoEntidadeResolved.escalada, escalada: multiplas).nome, 'Face Leste');
      expect(ResolvedDataset(tipo: TipoEntidadeResolved.escalada, escalada: highline).nome, 'Linha do Vento');
      expect(ResolvedDataset(tipo: TipoEntidadeResolved.escalada, escalada: Escalada(uid: 'esc-6')).nome, '');
    });
  });

  group('ReferenciaNoMapa', () {
    test('deve implementar igualdade de valor e hashCode', () {
      final mapa1 = Mapa(caminhoImagemMapa: 'mapa1.png');
      final ref1 = Mapa_Referencia(alvoUid: 'esc-1');
      final ref2 = Mapa_Referencia(alvoUid: 'esc-1');

      final refNoMapa1 = ReferenciaNoMapa(mapa: mapa1, referencia: ref1);
      final refNoMapa2 = ReferenciaNoMapa(mapa: mapa1, referencia: ref2);
      final refNoMapa3 = ReferenciaNoMapa(mapa: Mapa(caminhoImagemMapa: 'mapa2.png'), referencia: ref1);

      expect(refNoMapa1, equals(refNoMapa2));
      expect(refNoMapa1.hashCode, equals(refNoMapa2.hashCode));
      expect(refNoMapa1, isNot(equals(refNoMapa3)));

      final setor = Setor(nome: 'Setor A');
      final grupo = Grupo(nome: 'Grupo A');
      final refComContexto1 = ReferenciaNoMapa(
        mapa: mapa1,
        referencia: ref1,
        setorContexto: setor,
        grupoContexto: grupo,
      );
      final refComContexto2 = ReferenciaNoMapa(
        mapa: mapa1,
        referencia: ref1,
        setorContexto: setor,
        grupoContexto: grupo,
      );
      final refComContexto3 = ReferenciaNoMapa(
        mapa: mapa1,
        referencia: ref1,
        setorContexto: setor,
      );

      expect(refComContexto1, equals(refComContexto2));
      expect(refComContexto1.hashCode, equals(refComContexto2.hashCode));
      expect(refComContexto1, isNot(equals(refComContexto3)));
    });
  });

  group('ResolvedDataset.resolverCarrosselUnificado', () {
    test('deve retornar lista vazia se escalada for nula', () {
      final resolved = ResolvedDataset(
        tipo: TipoEntidadeResolved.setor,
        setor: Setor(nome: 'Setor A'),
      );
      expect(resolved.resolverCarrosselUnificado(), isEmpty);
    });

    test('deve unificar mapas próprios e mapas referenciados na ordem correta', () {
      final mapaProprio = Mapa(
        caminhoImagemMapa: 'mapa_proprio.webp',
        larguraMapa: 800,
        alturaMapa: 600,
      );
      final mapaInvalido = Mapa(
        caminhoImagemMapa: '',
        larguraMapa: 0,
        alturaMapa: 0,
      );
      final escalada = Escalada(
        uid: 'esc-10',
        viaEsportiva: ViaEsportiva(nome: 'Via Estelar'),
        mapas: [mapaProprio, mapaInvalido],
      );

      final mapaReferenciado = Mapa(
        caminhoImagemMapa: 'mapa_setor.webp',
        larguraMapa: 1200,
        alturaMapa: 900,
      );
      final ref = Mapa_Referencia(alvoUid: 'esc-10', pontosUids: ['poi-1']);
      final setor = Setor(nome: 'Setor Sul');
      final grupo = Grupo(nome: 'Falésia');

      final resolved = ResolvedDataset(
        tipo: TipoEntidadeResolved.escalada,
        escalada: escalada,
        setor: setor,
        grupo: grupo,
        referencias: [
          ReferenciaNoMapa(
            mapa: mapaReferenciado,
            referencia: ref,
            setorContexto: setor,
            grupoContexto: grupo,
          ),
          ReferenciaNoMapa(
            mapa: mapaInvalido,
            referencia: ref,
          ),
        ],
      );

      final itens = resolved.resolverCarrosselUnificado();
      expect(itens, hasLength(2));

      // Mapa próprio primeiro, sem initialSelectedId
      expect(itens[0].mapaCaminhoImagem, 'mapa_proprio.webp');
      expect(itens[0].setorContextNome, 'Setor Sul');
      expect(itens[0].grupoContextNome, 'Falésia');
      expect(itens[0].escaladaContextNome, 'Via Estelar');
      expect(itens[0].initialSelectedId, isNull);

      // Mapa referenciado depois, com initialSelectedId
      expect(itens[1].mapaCaminhoImagem, 'mapa_setor.webp');
      expect(itens[1].setorContextNome, 'Setor Sul');
      expect(itens[1].grupoContextNome, 'Falésia');
      expect(itens[1].escaladaContextNome, 'Via Estelar');
      expect(itens[1].initialSelectedId, 'poi-1');
    });
  });

  group('DatasetResolver - Resolução O(1) por UID', () {
    late Pico pico;
    late Croqui croqui;
    late Botao botaoCapa;
    late Grupo grupoFalesia;
    late Setor setorComGrupo;
    late Setor setorDireto;
    late Escalada viaNoGrupo;
    late Escalada viaNoSetorDireto;
    late Mapa mapaGeral;
    late Mapa mapaSetor;

    setUp(() {
      botaoCapa = Botao(uid: 'btn-capa', texto: 'Capa do Pico');
      croqui = Croqui(uid: 'crq-1', nome: 'Croqui Itatiaia', botoes: [botaoCapa]);

      viaNoGrupo = Escalada(
        uid: 'esc-grupo-1',
        viaEsportiva: ViaEsportiva(nome: 'Via do Grupo'),
      );
      setorComGrupo = Setor(
        uid: 'set-grupo-1',
        nome: 'Setor das Sombras',
        escaladas: [viaNoGrupo],
      );
      grupoFalesia = Grupo(
        uid: 'grp-falesia-1',
        nome: 'Falésia do Sol',
        setores: [ArquivoSetor(conteudo: setorComGrupo)],
      );

      viaNoSetorDireto = Escalada(
        uid: 'esc-direta-1',
        viaMovel: ViaMovel(nome: 'Via Direta'),
      );
      setorDireto = Setor(
        uid: 'set-direto-1',
        nome: 'Setor da Entrada',
        escaladas: [viaNoSetorDireto],
      );

      mapaGeral = Mapa(
        caminhoImagemMapa: 'geral.png',
        referencias: [
          Mapa_Referencia(alvoUid: 'grp-falesia-1'),
          Mapa_Referencia(alvoUid: 'set-direto-1'),
        ],
      );

      mapaSetor = Mapa(
        caminhoImagemMapa: 'setor.png',
        referencias: [
          Mapa_Referencia(alvoUid: 'esc-direta-1'),
        ],
      );
      setorDireto.mapas.add(mapaSetor);

      pico = Pico(
        nome: 'Pedra Filosofal',
        mapasGerais: ArquivoMapas(conteudo: ColecaoDeMapas(mapas: [mapaGeral])),
        setoresOuGrupos: [
          SetorOuGrupo(grupo: ArquivoGrupo(conteudo: grupoFalesia)),
          SetorOuGrupo(setor: ArquivoSetor(conteudo: setorDireto)),
        ],
      );
    });

    test('deve indexar e resolver Botao por UID em O(1)', () {
      final resolver = DatasetResolver(pico: pico, croqui: croqui);
      final resolved = resolver.obterPorUid('btn-capa');

      expect(resolved, isNotNull);
      expect(resolved!.tipo, TipoEntidadeResolved.botao);
      expect(resolved.botao, botaoCapa);
      expect(resolved.nome, 'Capa do Pico');
    });

    test('deve indexar e resolver Grupo por UID com suas referências mapeadas', () {
      final resolver = DatasetResolver(pico: pico, croqui: croqui);
      final resolved = resolver.obterPorUid('grp-falesia-1');

      expect(resolved, isNotNull);
      expect(resolved!.tipo, TipoEntidadeResolved.grupo);
      expect(resolved.grupo, grupoFalesia);
      expect(resolved.nome, 'Falésia do Sol');
      expect(resolved.referencias, hasLength(1));
      expect(resolved.referencias.first.mapa.caminhoImagemMapa, 'geral.png');
    });

    test('deve indexar e resolver Setor filho de Grupo por UID com ancestrais corretos', () {
      final resolver = DatasetResolver(pico: pico, croqui: croqui);
      final resolved = resolver.obterPorUid('set-grupo-1');

      expect(resolved, isNotNull);
      expect(resolved!.tipo, TipoEntidadeResolved.setor);
      expect(resolved.setor, setorComGrupo);
      expect(resolved.grupo, grupoFalesia);
      expect(resolved.nome, 'Setor das Sombras');
    });

    test('deve indexar e resolver Setor raiz por UID com suas referências mapeadas', () {
      final resolver = DatasetResolver(pico: pico, croqui: croqui);
      final resolved = resolver.obterPorUid('set-direto-1');

      expect(resolved, isNotNull);
      expect(resolved!.tipo, TipoEntidadeResolved.setor);
      expect(resolved.setor, setorDireto);
      expect(resolved.grupo, isNull);
      expect(resolved.referencias, hasLength(1));
      expect(resolved.referencias.first.mapa.caminhoImagemMapa, 'geral.png');
    });

    test('deve indexar e resolver Escalada filha de Grupo e Setor por UID', () {
      final resolver = DatasetResolver(pico: pico, croqui: croqui);
      final resolved = resolver.obterPorUid('esc-grupo-1');

      expect(resolved, isNotNull);
      expect(resolved!.tipo, TipoEntidadeResolved.escalada);
      expect(resolved.escalada, viaNoGrupo);
      expect(resolved.setor, setorComGrupo);
      expect(resolved.grupo, grupoFalesia);
      expect(resolved.nome, 'Via do Grupo');
    });

    test('deve indexar e resolver Escalada em Setor direto com suas referências em mapas', () {
      final resolver = DatasetResolver(pico: pico, croqui: croqui);
      final resolved = resolver['esc-direta-1'];

      expect(resolved, isNotNull);
      expect(resolved!.tipo, TipoEntidadeResolved.escalada);
      expect(resolved.escalada, viaNoSetorDireto);
      expect(resolved.setor, setorDireto);
      expect(resolved.grupo, isNull);
      expect(resolved.referencias, hasLength(1));
      expect(resolved.referencias.first.mapa.caminhoImagemMapa, 'setor.png');
    });

    test('deve resolver entidade através de Mapa_Referencia com alvoUid populado', () {
      final resolver = DatasetResolver(pico: pico, croqui: croqui);
      final ref = Mapa_Referencia(alvoUid: 'esc-direta-1');
      final resolved = resolver.resolverReferencia(ref);

      expect(resolved, isNotNull);
      expect(resolved!.escalada, viaNoSetorDireto);
    });

    test('deve retornar nulo ao buscar UID inexistente', () {
      final resolver = DatasetResolver(pico: pico, croqui: croqui);
      expect(resolver.obterPorUid('uid-que-nao-existe'), isNull);
    });

    test('deve lançar exceção no método estático resolveReferencia com referência vazia', () {
      final refVazia = Mapa_Referencia();
      expect(
        () => DatasetResolver.resolveReferencia(pico: pico, referencia: refVazia),
        throwsException,
      );
    });

    test('deve lançar exceção no método estático resolveReferencia se entidade não existir', () {
      final refInexistente = Mapa_Referencia(alvoUid: 'uid-fantasma');
      expect(
        () => DatasetResolver.resolveReferencia(pico: pico, referencia: refInexistente),
        throwsException,
      );
    });

    test('método estático resolve por nomes deve manter compatibilidade para PageListenableBuilder', () {
      final resSetor = DatasetResolver.resolve(pico: pico, setorNome: 'Setor da Entrada');
      expect(resSetor.setor?.nome, 'Setor da Entrada');
      expect(resSetor.grupo, isNull);

      // Busca setor sem especificar grupo, quando setor reside dentro de grupo
      final resSetorNoGrupo = DatasetResolver.resolve(pico: pico, setorNome: 'Setor das Sombras');
      expect(resSetorNoGrupo.setor?.nome, 'Setor das Sombras');
      expect(resSetorNoGrupo.grupo?.nome, 'Falésia do Sol');

      final resVia = DatasetResolver.resolve(
        pico: pico,
        grupoNome: 'Falésia do Sol',
        setorNome: 'Setor das Sombras',
        escaladaNome: 'Via do Grupo',
      );
      expect(resVia.grupo?.nome, 'Falésia do Sol');
      expect(resVia.setor?.nome, 'Setor das Sombras');
      expect(resVia.escalada?.viaEsportiva.nome, 'Via do Grupo');
    });

    test('método estático resolve deve lançar exceção se entidade nomeada não existir', () {
      expect(
        () => DatasetResolver.resolve(pico: pico, grupoNome: 'Grupo Inexistente'),
        throwsException,
      );
      expect(
        () => DatasetResolver.resolve(pico: pico, setorNome: 'Setor Inexistente'),
        throwsException,
      );
      expect(
        () => DatasetResolver.resolve(
          pico: pico,
          setorNome: 'Setor da Entrada',
          escaladaNome: 'Via Inexistente',
        ),
        throwsException,
      );
    });

    test('buscarPorNome deve localizar entidade resolvida pela hierarquia de nomes ou retornar nulo', () {
      final resolver = DatasetResolver(pico: pico, croqui: croqui);

      final resVia = resolver.buscarPorNome(
        grupoNome: 'Falésia do Sol',
        setorNome: 'Setor das Sombras',
        escaladaNome: 'Via do Grupo',
      );
      expect(resVia, isNotNull);
      expect(resVia!.escalada?.viaEsportiva.nome, 'Via do Grupo');

      final resSetor = resolver.buscarPorNome(
        grupoNome: 'Falésia do Sol',
        setorNome: 'Setor das Sombras',
      );
      expect(resSetor, isNotNull);
      expect(resSetor!.setor?.nome, 'Setor das Sombras');

      final resGrupo = resolver.buscarPorNome(grupoNome: 'Falésia do Sol');
      expect(resGrupo, isNotNull);
      expect(resGrupo!.grupo?.nome, 'Falésia do Sol');

      expect(resolver.buscarPorNome(escaladaNome: 'Via Inexistente'), isNull);
      expect(resolver.buscarPorNome(setorNome: 'Setor Inexistente'), isNull);
      expect(resolver.buscarPorNome(grupoNome: 'Grupo Inexistente'), isNull);
      expect(resolver.buscarPorNome(), isNull);
    });
  });
}
