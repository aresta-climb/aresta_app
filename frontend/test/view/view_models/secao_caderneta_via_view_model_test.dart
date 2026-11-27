// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/data/modelos/tipo_escalada.dart';
import 'package:frontend/idioma/tradutor_app.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/view/view_models/secao_caderneta_via_view_model.dart';
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

  tearDown(() {
    ControladorIdiomaApp.instancia.restaurarPadraoEmMemoria();
  });

  group('SecaoCadernetaViaViewModel', () {
    test(
      'expõe estado inicial sem ascensão e utiliza instâncias padrão quando dependências são omitidas',
      () {
        RepositorioCadernetaLocal.instancia = repositorio;

        final escaladaSemUid = Escalada()
          ..viaEsportiva = (ViaEsportiva()..nome = 'Via Sem UID');
        final vm = SecaoCadernetaViaViewModel(escalada: escaladaSemUid);

        expect(vm.possuiAscensao, isFalse);
        expect(vm.isCadena, isFalse);
        expect(vm.resumoAscensao, isNull);
        expect(vm.citacaoNotasPrivadas, isNull);
        expect(vm.rotuloBotao, equals('Registrar Cadena / Tentativa'));

        vm.dispose();
      },
    );

    test(
      'reage à troca de idioma e remove ouvintes ao descartar',
      () {
        final escalada = Escalada()
          ..uid = 'via_idioma'
          ..viaEsportiva = (ViaEsportiva()..nome = 'Via Teste');
        final vm = SecaoCadernetaViaViewModel(
          escalada: escalada,
          repositorio: repositorio,
        );

        var notificacoes = 0;
        vm.addListener(() => notificacoes++);

        ControladorIdiomaApp.instancia.notificadorIdioma.value =
            IdiomaApp.ingles;
        expect(notificacoes, equals(1));
        expect(vm.rotuloBotao, isNot(equals('Registrar Cadena / Tentativa')));

        vm.dispose();
        ControladorIdiomaApp.instancia.notificadorIdioma.value =
            IdiomaApp.portugues;
        expect(notificacoes, equals(1));
      },
    );

    test(
      'formata resumo de tentativa e de cadena com notas privadas reativamente ao salvar no repositório',
      () async {
        final escalada = Escalada()
          ..uid = 'via_progresso'
          ..viaEsportiva = (ViaEsportiva()..nome = 'Via Master');
        final vm = SecaoCadernetaViaViewModel(
          escalada: escalada,
          repositorio: repositorio,
        );

        await repositorio.salvarCadena(
          Cadena.criar(
            escaladaUid: 'via_progresso',
            dataAscensao: DateTime(2026, 5, 3),
            tipoAscensao: TipoAscensao.tentativa,
          ),
        );

        expect(vm.possuiAscensao, isTrue);
        expect(vm.isCadena, isFalse);
        expect(vm.resumoAscensao, equals('Tentativa em 03/05'));
        expect(vm.citacaoNotasPrivadas, isNull);
        expect(vm.rotuloBotao, equals('Nova Ascensão / Tentativa'));

        await repositorio.salvarCadena(
          Cadena.criar(
            escaladaUid: 'via_progresso',
            dataAscensao: DateTime(2026, 9, 14),
            tipoAscensao: TipoAscensao.flash,
            notasPrivadas: 'Costurou leve',
          ),
        );

        expect(vm.isCadena, isTrue);
        expect(vm.resumoAscensao, equals('Encadenada em 14/09 (Flash)'));
        expect(vm.citacaoNotasPrivadas, equals('“Costurou leve”'));

        vm.dispose();
      },
    );

    test(
      'criarViewModelRegistro prepara RegistroCadenaViewModel com modalidade e grau oficial extraídos da Escalada',
      () {
        final via = Escalada()
          ..uid = 'via_7a_uid'
          ..viaEsportiva = (ViaEsportiva()
            ..nome = 'Aresta Clássica'
            ..dificuldade = GrauVia_GrauVia.BR_7A);
        final vmVia = SecaoCadernetaViaViewModel(
          escalada: via,
          repositorio: repositorio,
        );
        final registroVia = vmVia.criarViewModelRegistro();
        expect(registroVia.escaladaUid, equals('via_7a_uid'));
        expect(registroVia.nomeEscalada, equals('Aresta Clássica'));
        expect(registroVia.tipoEscalada, equals(TipoEscalada.guiado));
        expect(registroVia.grauSugerido, equals(GrauVia_GrauVia.BR_7A.value));
        expect(registroVia.repositorio, same(repositorio));
        registroVia.dispose();
        vmVia.dispose();

        final boulder = Escalada()
          ..uid = 'boulder_v4_uid'
          ..boulder = (Boulder()
            ..nome = 'Teto Solar'
            ..dificuldade = GrauBoulder_GrauBoulder.V4);
        final vmBoulder = SecaoCadernetaViaViewModel(
          escalada: boulder,
          repositorio: repositorio,
        );
        final registroBoulder = vmBoulder.criarViewModelRegistro();
        expect(registroBoulder.tipoEscalada, equals(TipoEscalada.boulder));
        expect(
          registroBoulder.grauSugerido,
          equals(GrauBoulder_GrauBoulder.V4.value),
        );
        registroBoulder.dispose();
        vmBoulder.dispose();
      },
    );
  });
}
