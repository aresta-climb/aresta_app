// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/perfil_escalador.dart';

void main() {
  group('PerfilEscalador', () {
    const autorIdValido = 'x8siJek3FiG3aB';

    test('cria uma instância com valores válidos', () {
      final perfil = PerfilEscalador(
        autorIdPublico: autorIdValido,
        autorNomePublico: 'Alex Honnold',
        userId: 'usr-123',
      );

      expect(perfil.autorIdPublico, autorIdValido);
      expect(perfil.autorNomePublico, 'Alex Honnold');
      expect(perfil.userId, 'usr-123');
      expect(perfil.toString(), contains(autorIdValido));
      expect(perfil.toString(), contains('Alex Honnold'));
    });

    test('atribui apelido padrão quando fornecido vazio ou nulo', () {
      final perfilVazio = PerfilEscalador(
        autorIdPublico: autorIdValido,
        autorNomePublico: '   ',
      );

      expect(perfilVazio.autorNomePublico, 'Escalador Aresta');
    });

    test('trunca autorNomePublico que exceda o limite de 50 caracteres', () {
      final nomeLongo = 'X' * 60;
      final perfil = PerfilEscalador(
        autorIdPublico: autorIdValido,
        autorNomePublico: nomeLongo,
      );

      expect(perfil.autorNomePublico.length, 50);
      expect(perfil.autorNomePublico, 'X' * 50);
    });

    test('PerfilEscalador.criarPadrao gera NanoID de 14 caracteres Base62', () {
      final perfil = PerfilEscalador.criarPadrao(
        autorNomePublico: 'Lynn Hill',
      );

      expect(perfil.autorIdPublico.length, 14);
      expect(perfil.autorNomePublico, 'Lynn Hill');
      expect(perfil.userId, isNull);
    });

    test('serialização toMap e fromMap preserva todos os campos', () {
      final original = PerfilEscalador(
        autorIdPublico: autorIdValido,
        autorNomePublico: 'Tommy Caldwell',
        userId: 'uuid-supabase-777',
      );

      final map = original.toMap();
      expect(map['autor_id_publico'], autorIdValido);
      expect(map['autor_nome_publico'], 'Tommy Caldwell');
      expect(map['user_id'], 'uuid-supabase-777');

      final restaurado = PerfilEscalador.fromMap(map);
      expect(restaurado, equals(original));
      expect(restaurado.hashCode, equals(original.hashCode));
    });

    test('serialização toJson e fromJson com String JSON', () {
      final original = PerfilEscalador(
        autorIdPublico: autorIdValido,
        autorNomePublico: 'Chris Sharma',
      );

      final jsonStr = original.toJson();
      final restaurado = PerfilEscalador.fromJson(jsonStr);

      expect(restaurado, equals(original));
    });

    test('fromMap com mapa vazio ou valores nulos adota valores padrão seguros', () {
      final perfil = PerfilEscalador.fromMap(const {});

      expect(perfil.autorIdPublico.length, 14);
      expect(perfil.autorNomePublico, 'Escalador Aresta');
      expect(perfil.userId, isNull);
    });

    test('copyWith clona e atualiza campos específicos', () {
      final original = PerfilEscalador(
        autorIdPublico: autorIdValido,
        autorNomePublico: 'Janja Garnbret',
      );

      final clonado = original.copyWith(
        autorNomePublico: 'Janja G.',
        userId: 'usr-novo',
      );

      expect(clonado.autorIdPublico, original.autorIdPublico);
      expect(clonado.autorNomePublico, 'Janja G.');
      expect(clonado.userId, 'usr-novo');

      final identico = original.copyWith();
      expect(identico, equals(original));
    });
  });
}
