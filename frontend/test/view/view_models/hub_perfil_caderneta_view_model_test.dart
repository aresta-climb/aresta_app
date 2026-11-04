// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/data/modelos/tipo_escalada.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/midia/seletor_foto_perfil.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/view/view_models/hub_perfil_caderneta_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _SeletorFotoPerfilFake implements SeletorFotoPerfil {
  String? proximaFoto;

  @override
  Future<String?> selecionarFotoComoDataUri() async => proximaFoto;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

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
      expect(vm.estaAutenticado, isFalse);
      expect(vm.totalCadenas, 0);
      expect(vm.totalTentativas, 0);
      expect(vm.totalPicos, 0);
      expect(vm.totalVias, 0);

      vm.dispose();
    });

    test('permite customizar a função do atleta e as consultas de picos e vias', () {
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

    test('atualiza o nome e a foto de perfil do atleta e notifica os ouvintes', () async {
      final seletorFake = _SeletorFotoPerfilFake();
      final vm = HubPerfilCadernetaViewModel(
        repositorio: repositorio,
        seletorFotoPerfil: seletorFake,
      );

      var notificou = false;
      vm.addListener(() => notificou = true);

      // Ignora atualização vazia ou igual ao nome atual
      await vm.atualizarNome('   ');
      await vm.atualizarNome('Escalador Aresta');

      await vm.atualizarNome('Fernanda Rocha');

      expect(notificou, isTrue);
      expect(vm.nomeAtleta, 'Fernanda Rocha');
      expect(repositorio.obterPerfil().autorNomePublico, 'Fernanda Rocha');
      expect(vm.fotoUrl, isNull);

      // Seleção cancelada pelo usuário retorna false e null
      seletorFake.proximaFoto = null;
      expect(await vm.selecionarEAtualizarFoto(), isFalse);
      expect(await vm.selecionarEObterNovaFoto(), isNull);
      expect(vm.fotoUrl, isNull);

      // Seleção bem-sucedida atualiza fotoUrl e persiste no repositório
      const dataUriTeste = 'data:image/jpeg;base64,/9j/4AAQ';
      seletorFake.proximaFoto = dataUriTeste;
      expect(await vm.selecionarEObterNovaFoto(), equals(dataUriTeste));
      expect(vm.fotoUrl, equals(dataUriTeste));
      expect(repositorio.obterPerfil().fotoUrl, equals(dataUriTeste));

      // Ignora foto vazia ou idêntica à atual
      await vm.atualizarFotoPerfil('   ');
      await vm.atualizarFotoPerfil(dataUriTeste);
      expect(vm.fotoUrl, equals(dataUriTeste));

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

    test('gerencia encerrarSessao limpando autenticação e preservando ID público', () async {
      final vm = HubPerfilCadernetaViewModel(repositorio: repositorio);
      final idOriginal = vm.autorIdPublico;

      await repositorio.salvarPerfil(
        repositorio.obterPerfil().copyWith(userId: 'usr-logado-1'),
      );
      expect(vm.estaAutenticado, isTrue);

      await vm.encerrarSessao();
      expect(vm.estaAutenticado, isFalse);
      expect(vm.autorIdPublico, equals(idOriginal));

      vm.dispose();
    });

    test('notifica ouvintes reativamente quando escutaMetadados emite atualização e remove listener no dispose', () {
      final gatilhoMetadados = ChangeNotifier();
      var picosAtuais = 1;
      final vm = HubPerfilCadernetaViewModel(
        repositorio: repositorio,
        obterTotalPicos: () => picosAtuais,
        escutaMetadados: gatilhoMetadados,
      );

      var notificacoes = 0;
      vm.addListener(() => notificacoes++);

      picosAtuais = 3;
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      gatilhoMetadados.notifyListeners();

      expect(notificacoes, equals(1));
      expect(vm.totalPicos, equals(3));

      vm.dispose();
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      gatilhoMetadados.notifyListeners();
      expect(notificacoes, equals(1));
      gatilhoMetadados.dispose();
    });

    test(
      'comCatalogo hidrata totalPicos a partir de DatasetRepository real e descarta catálogo próprio no dispose',
      () async {
        final croqui = Croqui(
          id: 'cipo',
          uid: 'croqui_cipo_uid',
          picos: [
            Pico(
              nome: 'Serra do Cipó',
              setoresOuGrupos: [
                SetorOuGrupo(
                  setor: ArquivoSetor(
                    conteudo: Setor(
                      nome: 'Fenda',
                      escaladas: [
                        Escalada(
                          uid: 'via_cipo_1',
                          viaEsportiva: ViaEsportiva(nome: 'Via 1'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
        final tempDir = await Directory.systemTemp.createTemp(
          'hub_vm_catalogo_test_',
        );
        addTearDown(() async {
          if (tempDir.existsSync()) {
            try {
              await tempDir.delete(recursive: true);
            } catch (_) {}
          }
        });
        final datasetRepo = DatasetRepository(
          editorDeCroqui: EditorDeCroqui(),
          repositorioCatalogo: RepositorioCatalogo(
            provedorCaminhoBanco: () async => '${tempDir.path}/catalogo.db',
            fabricaBanco: databaseFactoryFfi,
          ),
        );
        datasetRepo.activeDataset.value = ConjuntoDadosCroqui(
          croquisBaixados: [croqui],
        );

        await repositorio.salvarCadena(
          Cadena.criar(
            escaladaUid: 'via_cipo_1',
            dataAscensao: DateTime(2026, 10, 1),
            tipoAscensao: TipoAscensao.aVista,
          ),
        );

        final vm = HubPerfilCadernetaViewModel.comCatalogo(
          repositorio: repositorio,
          datasetRepo: datasetRepo,
        );

        expect(vm.totalPicos, equals(1));
        expect(vm.totalCadenas, equals(1));

        vm.dispose();
      },
    );
  });
}
