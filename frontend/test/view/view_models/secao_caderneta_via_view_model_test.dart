// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/data/modelos/tipo_escalada.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/services/configuracao_recursos.dart';
import 'package:frontend/services/controlador_interacoes_usuario.dart';
import 'package:frontend/view/view_models/secao_caderneta_via_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RepositorioCadernetaLocal repositorio;
  late ControladorInteracoesUsuario controladorInteracoes;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);
    final prefs = await SharedPreferences.getInstance();
    repositorio = RepositorioCadernetaLocal(preferencias: prefs);
    await repositorio.inicializar();
    controladorInteracoes = ControladorInteracoesUsuario(preferencias: prefs);
    await controladorInteracoes.inicializar();
  });

  tearDown(() {
    ConfiguracaoRecursos.redefinirParaTestes();
    ControladorInteracoesUsuario.redefinirParaTestes();
  });

  group('SecaoCadernetaViaViewModel', () {
    test(
      'expõe estado inicial sem ascensão e utiliza instâncias padrão quando dependências são omitidas',
      () {
        RepositorioCadernetaLocal.instancia = repositorio;
        ControladorInteracoesUsuario.instancia = controladorInteracoes;

        final escaladaSemUid = Escalada()
          ..viaEsportiva = (ViaEsportiva()..nome = 'Via Sem UID');
        final vm = SecaoCadernetaViaViewModel(escalada: escaladaSemUid);

        expect(vm.visivel, isTrue);
        expect(vm.possuiAscensao, isFalse);
        expect(vm.isCadena, isFalse);
        expect(vm.resumoAscensao, isNull);
        expect(vm.citacaoNotasPrivadas, isNull);
        expect(vm.rotuloBotao, equals('Registrar Cadena / Tentativa'));

        vm.dispose();
      },
    );

    test(
      'reage à alternância de visibilidade no ControladorInteracoesUsuario e remove listeners no dispose',
      () async {
        final escalada = Escalada()
          ..uid = 'via_visibilidade'
          ..viaEsportiva = (ViaEsportiva()..nome = 'Via Teste');
        final vm = SecaoCadernetaViaViewModel(
          escalada: escalada,
          repositorio: repositorio,
          controladorInteracoes: controladorInteracoes,
        );

        var notificacoes = 0;
        vm.addListener(() => notificacoes++);

        await controladorInteracoes.definirInteracoesAtivas(false);
        expect(vm.visivel, isFalse);
        expect(notificacoes, equals(1));

        vm.dispose();
        await controladorInteracoes.definirInteracoesAtivas(true);
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
          controladorInteracoes: controladorInteracoes,
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
          controladorInteracoes: controladorInteracoes,
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
          controladorInteracoes: controladorInteracoes,
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
