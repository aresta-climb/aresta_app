// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/data/modelos/tipo_escalada.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/view/view_models/registro_cadena_view_model.dart';
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

  group('RegistroCadenaViewModel', () {
    test('inicializa com valores padrão seguros', () {
      final vm = RegistroCadenaViewModel(
        escaladaUid: 'via-001',
        nomeEscalada: 'Fenda da Ilusão',
        repositorio: repositorio,
      );

      expect(vm.escaladaUid, 'via-001');
      expect(vm.nomeEscalada, 'Fenda da Ilusão');
      expect(vm.tipoEscalada, TipoEscalada.guiado);
      expect(vm.tipoAscensao, TipoAscensao.trabalhado);
      expect(vm.tentativas, 1);
      expect(vm.podeDecrementarTentativas, isFalse);
      expect(vm.notasPrivadas, isEmpty);
      expect(vm.contadorNotasTexto, '0/200');
      expect(vm.atingiuLimiteNotas, isFalse);
      expect(vm.dataAscensaoFormatada, isNotEmpty);
    });

    test('respeita valores iniciais customizados fornecidos no construtor', () {
      final data = DateTime(2026, 5, 20);
      final vm = RegistroCadenaViewModel(
        escaladaUid: 'boulder-002',
        nomeEscalada: 'Dinamite Pura',
        tipoEscaladaPadrao: TipoEscalada.boulder,
        tipoAscensaoPadrao: TipoAscensao.flash,
        tentativasIniciais: 3,
        dataAscensaoInicial: data,
        notasIniciais: 'Passada de calcanhar',
        grauSugerido: 4,
        repositorio: repositorio,
      );

      expect(vm.tipoEscalada, TipoEscalada.boulder);
      expect(vm.tipoAscensao, TipoAscensao.flash);
      expect(vm.tentativas, 3);
      expect(vm.podeDecrementarTentativas, isTrue);
      expect(vm.dataAscensaoFormatada, '20/05/2026');
      expect(vm.notasPrivadas, 'Passada de calcanhar');
      expect(vm.grauSugerido, 4);
    });

    test('incrementa e decrementa tentativas notificando ouvintes', () {
      final vm = RegistroCadenaViewModel(
        escaladaUid: 'via-001',
        nomeEscalada: 'Via Teste',
        repositorio: repositorio,
      );

      int notificacoes = 0;
      vm.addListener(() => notificacoes++);

      vm.incrementarTentativas();
      expect(vm.tentativas, 2);
      expect(vm.podeDecrementarTentativas, isTrue);
      expect(notificacoes, 1);

      vm.decrementarTentativas();
      expect(vm.tentativas, 1);
      expect(vm.podeDecrementarTentativas, isFalse);
      expect(notificacoes, 2);

      // Não deve decrementar abaixo de 1 nem disparar notificação desnecessária
      vm.decrementarTentativas();
      expect(vm.tentativas, 1);
      expect(notificacoes, 2);
    });

    test('atualiza estilo esportivo e modalidade', () {
      final vm = RegistroCadenaViewModel(
        escaladaUid: 'via-001',
        nomeEscalada: 'Via Teste',
        repositorio: repositorio,
      );

      int notificacoes = 0;
      vm.addListener(() => notificacoes++);

      vm.definirTipoAscensao(TipoAscensao.aVista);
      expect(vm.tipoAscensao, TipoAscensao.aVista);
      expect(notificacoes, 1);

      // Reatribuir mesmo valor não notifica
      vm.definirTipoAscensao(TipoAscensao.aVista);
      expect(notificacoes, 1);

      vm.definirTipoEscalada(TipoEscalada.topRope);
      expect(vm.tipoEscalada, TipoEscalada.topRope);
      expect(notificacoes, 2);
    });

    test('atualiza data da ascensão e formatação', () {
      final vm = RegistroCadenaViewModel(
        escaladaUid: 'via-001',
        nomeEscalada: 'Via Teste',
        repositorio: repositorio,
      );

      vm.definirDataAscensao(DateTime(2026, 12, 5));
      expect(vm.dataAscensaoFormatada, '05/12/2026');
    });

    test('atualiza notas privadas truncando a 200 caracteres', () {
      final vm = RegistroCadenaViewModel(
        escaladaUid: 'via-001',
        nomeEscalada: 'Via Teste',
        repositorio: repositorio,
      );

      vm.definirNotasPrivadas('Crux no 2º grampo');
      expect(vm.notasPrivadas, 'Crux no 2º grampo');
      expect(vm.contadorNotasTexto, '17/200');
      expect(vm.atingiuLimiteNotas, isFalse);

      final textoLongo = 'A' * 250;
      vm.definirNotasPrivadas(textoLongo);
      expect(vm.notasPrivadas.length, 200);
      expect(vm.contadorNotasTexto, '200/200');
      expect(vm.atingiuLimiteNotas, isTrue);
    });

    test('salvar persiste a ascensão no repositório com dados consistentes', () async {
      final vm = RegistroCadenaViewModel(
        escaladaUid: 'via-salvar-123',
        nomeEscalada: 'Via de Fenda',
        tipoEscaladaPadrao: TipoEscalada.guiado,
        tipoAscensaoPadrao: TipoAscensao.flash,
        tentativasIniciais: 1,
        notasIniciais: 'Excelente linha',
        repositorio: repositorio,
      );

      final cadena = await vm.salvar();

      expect(cadena.escaladaUid, 'via-salvar-123');
      expect(cadena.tipoAscensao, TipoAscensao.flash);
      expect(cadena.tipoEscalada, TipoEscalada.guiado);
      expect(cadena.notasPrivadas, 'Excelente linha');
      expect(cadena.tentativas, 1);
      expect(cadena.isCadena, isTrue);

      final salvas = repositorio.obterCadenasPorEscalada('via-salvar-123');
      expect(salvas.length, 1);
      expect(salvas.first.id, cadena.id);
    });
  });
}
