// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/perfil_escalador.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/services/caderneta/armazenamento_local_caderneta.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ArmazenamentoLocalCaderneta', () {
    test(
      'cria, persiste e recarrega perfil padrão inicializando SharedPreferences sob demanda',
      () async {
        final armazenamento = ArmazenamentoLocalCaderneta();
        final perfilGerado = await armazenamento.carregarOuCriarPerfil();

        expect(perfilGerado.autorIdPublico.length, 14);
        expect(perfilGerado.autorNomePublico, 'Escalador Aresta');

        final prefs = await SharedPreferences.getInstance();
        final outroArmazenamento = ArmazenamentoLocalCaderneta(
          preferencias: prefs,
        );
        final perfilRecarregado =
            await outroArmazenamento.carregarOuCriarPerfil();

        expect(
          perfilRecarregado.autorIdPublico,
          equals(perfilGerado.autorIdPublico),
        );
        expect(
          perfilRecarregado.autorNomePublico,
          equals(perfilGerado.autorNomePublico),
        );
      },
    );

    test(
      'persiste atualizações de perfil e regenera perfil padrão quando JSON salvo está corrompido',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final armazenamento = ArmazenamentoLocalCaderneta(preferencias: prefs);

        final personalizado = PerfilEscalador.criarPadrao(
          autorNomePublico: 'Escaladora Cipó',
        );
        await armazenamento.salvarPerfil(personalizado);

        final carregado = await armazenamento.carregarOuCriarPerfil();
        expect(carregado.autorNomePublico, equals('Escaladora Cipó'));

        await prefs.setString(
          ArmazenamentoLocalCaderneta.chavePerfil,
          '{json_corrompido',
        );
        final recuperado = await armazenamento.carregarOuCriarPerfil();
        expect(recuperado.autorNomePublico, equals('Escalador Aresta'));
      },
    );

    test(
      'persiste e recarrega lista de cadenas, retornando lista vazia quando ausente',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final armazenamento = ArmazenamentoLocalCaderneta(preferencias: prefs);

        expect(await armazenamento.carregarCadenas(), isEmpty);

        final cadena = Cadena.criar(
          escaladaUid: 'via-armazenamento-1',
          dataAscensao: DateTime(2026, 10, 5),
          tipoAscensao: TipoAscensao.aVista,
          notasPrivadas: 'Reglete técnico',
        );

        await armazenamento.salvarCadenas([cadena]);

        final recarregadas = await armazenamento.carregarCadenas();
        expect(recarregadas.length, 1);
        expect(recarregadas.first, equals(cadena));
      },
    );

    test(
      'ignora entradas não estruturadas e retorna lista vazia quando JSON de cadenas está corrompido',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final armazenamento = ArmazenamentoLocalCaderneta(preferencias: prefs);

        final cadenaValida = Cadena.criar(
          escaladaUid: 'via-valida',
          dataAscensao: DateTime(2026, 10, 10),
        );
        await prefs.setString(
          ArmazenamentoLocalCaderneta.chaveCadenas,
          json.encode([cadenaValida.toMap(), 'item_invalido', 42]),
        );

        final filtradas = await armazenamento.carregarCadenas();
        expect(filtradas.length, 1);
        expect(filtradas.first.id, equals(cadenaValida.id));

        await prefs.setString(
          ArmazenamentoLocalCaderneta.chaveCadenas,
          'json_nao_lista{{{',
        );
        expect(await armazenamento.carregarCadenas(), isEmpty);
      },
    );

    test(
      'opera como no-op seguro em memória ao salvar antes da inicialização sem SharedPreferences injetado',
      () async {
        final armazenamentoEmMemoria = ArmazenamentoLocalCaderneta();

        await armazenamentoEmMemoria.salvarPerfil(
          PerfilEscalador.criarPadrao(autorNomePublico: 'Apenas Memória'),
        );
        await armazenamentoEmMemoria.salvarCadenas([
          Cadena.criar(
            escaladaUid: 'via-mem',
            dataAscensao: DateTime(2026, 11, 1),
          ),
        ]);

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString(ArmazenamentoLocalCaderneta.chavePerfil),
          isNull,
        );
        expect(
          prefs.getString(ArmazenamentoLocalCaderneta.chaveCadenas),
          isNull,
        );
      },
    );
  });
}
