// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/data/modelos/tipo_escalada.dart';

void main() {
  group('Cadena', () {
    const escaladaUidValido = 'x8siJek3FiG3aB';
    final dataAscensao = DateTime(2026, 9, 14);
    final criadoEm = DateTime(2026, 9, 14, 15, 30);

    test('cria uma instância de Cadena com todos os campos válidos', () {
      final cadena = Cadena(
        id: '123e4567-e89b-12d3-a456-426614174000',
        userId: 'usr-456',
        escaladaUid: escaladaUidValido,
        dataAscensao: dataAscensao,
        tipoAscensao: TipoAscensao.flash,
        tipoEscalada: TipoEscalada.guiado,
        tentativas: 1,
        grauSugerido: 7,
        notasPrivadas: 'Crux no 3º grampo com calcanhar esquerdo.',
        criadoEm: criadoEm,
      );

      expect(cadena.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(cadena.userId, 'usr-456');
      expect(cadena.escaladaUid, escaladaUidValido);
      expect(cadena.dataAscensao, dataAscensao);
      expect(cadena.tipoAscensao, TipoAscensao.flash);
      expect(cadena.tipoEscalada, TipoEscalada.guiado);
      expect(cadena.tentativas, 1);
      expect(cadena.grauSugerido, 7);
      expect(cadena.notasPrivadas, 'Crux no 3º grampo com calcanhar esquerdo.');
      expect(cadena.criadoEm, criadoEm);
      expect(cadena.isCadena, isTrue);
      expect(cadena.prioridadeVisual, 3);
      expect(cadena.toString(), contains('Cadena'));
      expect(cadena.toString(), contains(escaladaUidValido));
    });

    test('trunca notasPrivadas que ultrapassem 200 caracteres de limite', () {
      final notasLongas = 'A' * 250;
      final cadena = Cadena(
        id: 'uuid-1',
        escaladaUid: escaladaUidValido,
        dataAscensao: dataAscensao,
        tipoAscensao: TipoAscensao.trabalhado,
        tipoEscalada: TipoEscalada.guiado,
        notasPrivadas: notasLongas,
        criadoEm: criadoEm,
      );

      expect(cadena.notasPrivadas.length, 200);
      expect(cadena.notasPrivadas, 'A' * 200);
    });

    test('garante que tentativas seja no mínimo 1', () {
      final cadena = Cadena(
        id: 'uuid-1',
        escaladaUid: escaladaUidValido,
        dataAscensao: dataAscensao,
        tipoAscensao: TipoAscensao.trabalhado,
        tipoEscalada: TipoEscalada.guiado,
        tentativas: 0,
        criadoEm: criadoEm,
      );

      expect(cadena.tentativas, 1);

      final cadenaNegativa = Cadena(
        id: 'uuid-2',
        escaladaUid: escaladaUidValido,
        dataAscensao: dataAscensao,
        tipoAscensao: TipoAscensao.tentativa,
        tipoEscalada: TipoEscalada.topRope,
        tentativas: -5,
        criadoEm: criadoEm,
      );

      expect(cadenaNegativa.tentativas, 1);
    });

    test('Cadena.criar gera id UUID e criadoEm automaticamente quando omitidos', () {
      final cadena = Cadena.criar(
        escaladaUid: escaladaUidValido,
        dataAscensao: dataAscensao,
        tipoAscensao: TipoAscensao.aVista,
        tipoEscalada: TipoEscalada.guiado,
      );

      expect(cadena.id, isNotEmpty);
      expect(cadena.id.length, greaterThanOrEqualTo(32));
      expect(cadena.escaladaUid, escaladaUidValido);
      expect(cadena.tipoAscensao, TipoAscensao.aVista);
      expect(cadena.tentativas, 1);
      expect(cadena.notasPrivadas, isEmpty);
      expect(cadena.criadoEm, isNotNull);
    });

    test('serialização toMap e fromMap preserva todos os dados', () {
      final original = Cadena(
        id: 'uuid-1234',
        userId: 'user-789',
        escaladaUid: escaladaUidValido,
        dataAscensao: dataAscensao,
        tipoAscensao: TipoAscensao.flash,
        tipoEscalada: TipoEscalada.boulder,
        tentativas: 2,
        grauSugerido: 10,
        notasPrivadas: 'Beta da virada de teto',
        criadoEm: criadoEm,
      );

      final map = original.toMap();
      expect(map['id'], 'uuid-1234');
      expect(map['user_id'], 'user-789');
      expect(map['escalada_uid'], escaladaUidValido);
      expect(map['data_ascensao'], dataAscensao.toIso8601String());
      expect(map['tipo_ascensao'], 2);
      expect(map['tipo_escalada'], 3);
      expect(map['tentativas'], 2);
      expect(map['grau_sugerido'], 10);
      expect(map['notas_privadas'], 'Beta da virada de teto');
      expect(map['criado_em'], criadoEm.toIso8601String());

      final restaurada = Cadena.fromMap(map);
      expect(restaurada, equals(original));
      expect(restaurada.hashCode, equals(original.hashCode));
    });

    test('serialização toJson e fromJson com String JSON completa', () {
      final original = Cadena(
        id: 'uuid-json',
        escaladaUid: escaladaUidValido,
        dataAscensao: dataAscensao,
        tipoAscensao: TipoAscensao.aVista,
        tipoEscalada: TipoEscalada.solo,
        tentativas: 1,
        criadoEm: criadoEm,
      );

      final jsonStr = original.toJson();
      final restaurada = Cadena.fromJson(jsonStr);

      expect(restaurada, equals(original));
    });

    test('fromMap lida com campos ausentes ou nulos com fallbacks elegantes', () {
      final mapIncompleto = {
        'id': 'uuid-fallback',
        'escalada_uid': escaladaUidValido,
        'data_ascensao': dataAscensao.toIso8601String(),
      };

      final cadena = Cadena.fromMap(mapIncompleto);
      expect(cadena.id, 'uuid-fallback');
      expect(cadena.escaladaUid, escaladaUidValido);
      expect(cadena.tipoAscensao, TipoAscensao.trabalhado);
      expect(cadena.tipoEscalada, TipoEscalada.guiado);
      expect(cadena.tentativas, 1);
      expect(cadena.notasPrivadas, '');
      expect(cadena.grauSugerido, isNull);
      expect(cadena.userId, isNull);
      expect(cadena.criadoEm, isNotNull);
    });

    test('copyWith clona a entidade permitindo alteração seletiva de campos', () {
      final original = Cadena(
        id: 'uuid-clonar',
        escaladaUid: escaladaUidValido,
        dataAscensao: dataAscensao,
        tipoAscensao: TipoAscensao.tentativa,
        tipoEscalada: TipoEscalada.topRope,
        tentativas: 1,
        notasPrivadas: 'Caiu no meio',
        criadoEm: criadoEm,
      );

      final clonada = original.copyWith(
        tipoAscensao: TipoAscensao.trabalhado,
        tentativas: 3,
        notasPrivadas: 'Encadenou no final da tarde',
      );

      expect(clonada.id, original.id);
      expect(clonada.escaladaUid, original.escaladaUid);
      expect(clonada.tipoAscensao, TipoAscensao.trabalhado);
      expect(clonada.tentativas, 3);
      expect(clonada.notasPrivadas, 'Encadenou no final da tarde');
      expect(clonada.tipoEscalada, original.tipoEscalada);
      expect(clonada.dataAscensao, original.dataAscensao);
      expect(clonada.criadoEm, original.criadoEm);

      // copyWith sem parâmetros deve manter os mesmos valores
      final identica = original.copyWith();
      expect(identica, equals(original));
    });

    test('fromMap gera dataAscensao padrão DateTime.now quando nula', () {
      final mapaSemData = {
        'id': 'uuid-sem-data',
        'escalada_uid': escaladaUidValido,
      };
      final cadena = Cadena.fromMap(mapaSemData);
      expect(cadena.dataAscensao, isNotNull);
      expect(
        DateTime.now().difference(cadena.dataAscensao).inSeconds,
        lessThan(5),
      );
    });
  });
}
