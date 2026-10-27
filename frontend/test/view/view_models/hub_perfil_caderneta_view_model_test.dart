// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/data/modelos/tipo_escalada.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/view/view_models/hub_perfil_caderneta_view_model.dart';
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

  group('HubPerfilCadernetaViewModel', () {
    test('expõe dados padrão do perfil e métricas zeradas quando não há cadenas', () {
      final vm = HubPerfilCadernetaViewModel(repositorio: repositorio);

      expect(vm.nomeAtleta, 'Escalador Aresta');
      expect(vm.autorIdPublico.length, 14);
      expect(vm.funcaoAtleta, 'Escalador');
      expect(vm.totalCadenas, 0);
      expect(vm.totalTentativas, 0);
      expect(vm.totalPicos, 0);
      expect(vm.totalVias, 0);

      vm.dispose();
    });

    test('permite customizar a função do atleta e os resolvedores de picos e vias', () {
      final vm = HubPerfilCadernetaViewModel(
        repositorio: repositorio,
        funcaoAtleta: 'Escaladora',
        obterTotalPicos: () => 18,
        obterTotalVias: () => 64,
      );

      expect(vm.funcaoAtleta, 'Escaladora');
      expect(vm.totalPicos, 18);
      expect(vm.totalVias, 64);

      vm.dispose();
    });

    test('calcula métricas reativamente ao salvar e atualizar cadenas no repositório', () async {
      final vm = HubPerfilCadernetaViewModel(repositorio: repositorio);

      var notificou = false;
      vm.addListener(() => notificou = true);

      // Adiciona 1 cadena flash e 1 cadena trabalhada na via-1
      final c1 = Cadena.criar(
        escaladaUid: 'via-1',
        dataAscensao: DateTime(2026, 9, 20),
        tipoAscensao: TipoAscensao.flash,
        tipoEscalada: TipoEscalada.guiado,
      );
      final c2 = Cadena.criar(
        escaladaUid: 'via-1',
        dataAscensao: DateTime(2026, 9, 21),
        tipoAscensao: TipoAscensao.trabalhado,
        tipoEscalada: TipoEscalada.guiado,
      );
      // Adiciona 1 tentativa na via-2
      final c3 = Cadena.criar(
        escaladaUid: 'via-2',
        dataAscensao: DateTime(2026, 9, 22),
        tipoAscensao: TipoAscensao.tentativa,
        tipoEscalada: TipoEscalada.boulder,
      );

      await repositorio.salvarCadena(c1);
      await repositorio.salvarCadena(c2);
      await repositorio.salvarCadena(c3);

      expect(notificou, isTrue);
      expect(vm.totalCadenas, 2);
      expect(vm.totalTentativas, 1);
      // Vias únicas registradas (via-1 e via-2)
      expect(vm.totalVias, 2);

      vm.dispose();
    });

    test('atualiza o nome do atleta e notifica os ouvintes', () async {
      final vm = HubPerfilCadernetaViewModel(repositorio: repositorio);

      var notificou = false;
      vm.addListener(() => notificou = true);

      await vm.atualizarNome('Fernanda Rocha');

      expect(notificou, isTrue);
      expect(vm.nomeAtleta, 'Fernanda Rocha');
      expect(repositorio.obterPerfil().autorNomePublico, 'Fernanda Rocha');

      vm.dispose();
    });

    test('copia o autorIdPublico para a área de transferência', () async {
      final vm = HubPerfilCadernetaViewModel(repositorio: repositorio);

      String? textoCopiado;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            final args = methodCall.arguments as Map<dynamic, dynamic>?;
            textoCopiado = args?['text'] as String?;
            return null;
          }
          return null;
        },
      );

      await vm.copiarIdPublico();

      expect(textoCopiado, vm.autorIdPublico);
      expect(textoCopiado?.length, 14);

      vm.dispose();
    });

    test('executa callbacks de navegação injetados', () {
      var cadernetaAberta = false;
      var configuracoesAberta = false;
      var dadosPrivacidadeAberto = false;
      var saidaConfirmada = false;
      var editarPerfilAberto = false;

      final vm = HubPerfilCadernetaViewModel(
        repositorio: repositorio,
        aoAbrirCaderneta: () => cadernetaAberta = true,
        aoAbrirConfiguracoes: () => configuracoesAberta = true,
        aoAbrirDadosPrivacidade: () => dadosPrivacidadeAberto = true,
        aoConfirmarSaida: () => saidaConfirmada = true,
        aoEditarPerfil: () => editarPerfilAberto = true,
      );

      vm.abrirCaderneta();
      vm.abrirConfiguracoes();
      vm.abrirDadosPrivacidade();
      vm.confirmarSaida();
      vm.editarPerfil();

      expect(cadernetaAberta, isTrue);
      expect(configuracoesAberta, isTrue);
      expect(dadosPrivacidadeAberto, isTrue);
      expect(saidaConfirmada, isTrue);
      expect(editarPerfilAberto, isTrue);

      vm.dispose();
    });
  });
}
