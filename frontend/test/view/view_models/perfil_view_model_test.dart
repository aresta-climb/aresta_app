// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/data/modelos/tipo_escalada.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/view/view_models/perfil_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepositorioCadernetaLocal repositorio;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repositorio = RepositorioCadernetaLocal(preferencias: prefs);
    await repositorio.inicializar();
  });

  group('PerfilViewModel', () {
    test('inicializa com perfil e estatísticas do repositório', () {
      final viewModel = PerfilViewModel(repositorio: repositorio);

      expect(viewModel.perfil.autorIdPublico.length, 14);
      expect(viewModel.perfil.autorNomePublico, 'Escalador Aresta');
      expect(viewModel.modoVias, isTrue);
      expect(viewModel.historicoCadenas, isEmpty);
      expect(viewModel.estatisticas.totalCadenas, 0);
      expect(viewModel.piramideAtiva, isEmpty);

      viewModel.dispose();
    });

    test('construtor padrão utiliza a instância singleton de RepositorioCadernetaLocal', () {
      RepositorioCadernetaLocal.instancia = repositorio;
      final viewModel = PerfilViewModel();
      expect(viewModel.repositorio, equals(repositorio));
      viewModel.dispose();
    });

    test('reage automaticamente a inserções e exclusões no repositório', () async {
      final viewModel = PerfilViewModel(
        repositorio: repositorio,
        resolvedorGrau: (uid) => uid == 'v1' ? '7a' : 'V4',
        resolvedorNomeEscalada: (uid) => uid == 'v1' ? 'Via Alfa' : 'Bloco Beta',
      );

      bool notificado = false;
      viewModel.addListener(() {
        notificado = true;
      });

      final c1 = Cadena.criar(
        escaladaUid: 'v1',
        dataAscensao: DateTime(2026, 9, 10),
        tipoAscensao: TipoAscensao.flash,
        tipoEscalada: TipoEscalada.guiado,
      );

      await repositorio.salvarCadena(c1);

      expect(notificado, isTrue);
      expect(viewModel.historicoCadenas.length, 1);
      expect(viewModel.estatisticas.totalCadenas, 1);
      expect(viewModel.estatisticas.maiorGrauVia, '7a');
      expect(viewModel.obterNomeEscalada('v1'), 'Via Alfa');
      expect(viewModel.obterGrauEscalada('v1'), '7a');

      // Exclui a cadena
      await viewModel.excluirCadena(c1.id);
      expect(viewModel.historicoCadenas, isEmpty);
      expect(viewModel.estatisticas.totalCadenas, 0);

      viewModel.dispose();
    });

    test('alterna a modalidade ativa da pirâmide entre Vias e Boulders', () async {
      final viewModel = PerfilViewModel(
        repositorio: repositorio,
        resolvedorGrau: (uid) => uid == 'v1' ? '8a' : 'V7',
      );

      await repositorio.salvarCadena(
        Cadena.criar(
          escaladaUid: 'v1',
          dataAscensao: DateTime(2026, 9, 1),
          tipoAscensao: TipoAscensao.trabalhado,
          tipoEscalada: TipoEscalada.guiado,
        ),
      );
      await repositorio.salvarCadena(
        Cadena.criar(
          escaladaUid: 'b1',
          dataAscensao: DateTime(2026, 9, 2),
          tipoAscensao: TipoAscensao.flash,
          tipoEscalada: TipoEscalada.boulder,
        ),
      );

      expect(viewModel.modoVias, isTrue);
      expect(viewModel.piramideAtiva.containsKey('8a'), isTrue);
      expect(viewModel.piramideAtiva.containsKey('V7'), isFalse);

      viewModel.alternarModoModalidade(false);
      expect(viewModel.modoVias, isFalse);
      expect(viewModel.piramideAtiva.containsKey('V7'), isTrue);
      expect(viewModel.piramideAtiva.containsKey('8a'), isFalse);

      viewModel.dispose();
    });

    test('permite atualizar o apelido público do escalador', () async {
      final viewModel = PerfilViewModel(repositorio: repositorio);

      await viewModel.atualizarNome('Carlos Escalador');
      expect(viewModel.perfil.autorNomePublico, 'Carlos Escalador');
      expect(repositorio.obterPerfil().autorNomePublico, 'Carlos Escalador');

      viewModel.dispose();
    });

    test('obterNomeEscalada retorna identificador como fallback quando não resolvido', () {
      final viewModel = PerfilViewModel(repositorio: repositorio);
      expect(viewModel.obterNomeEscalada('sem-nome-uid'), 'Via (sem-nome-uid)');
      viewModel.dispose();
    });
  });
}
