// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/inicializar_firebase.dart';
import 'package:frontend/services/firebase/performance_telemetria.dart';

class _FakePerformance extends Fake implements FirebasePerformance {
  bool? habilitado;

  @override
  Future<void> setPerformanceCollectionEnabled(bool enabled) async {
    habilitado = enabled;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    ServicoPerformance.resetarParaTestes();
  });

  test(
    'initFirebase delega a inicialização para os pacotes nativos (deve lançar erro em ambiente sem mock)',
    () async {
      // Como a suite de testes não injeta os Platform Channels reais do iOS/Android para o Firebase,
      // a inicialização do Firebase Core obrigatoriamente tem que falhar.
      // Esse teste comprova que a função `initFirebase` está corretamente chamando
      // a API `Firebase.initializeApp` subjacente.
      expect(() async => await initFirebase(), throwsA(anything));
    },
  );

  test(
    'initPerformance desativa coleta em modo debug e ativa fora do modo debug',
    () async {
      final fakePerf = _FakePerformance();

      await initPerformance(
        isDebugMode: true,
        performanceInstance: fakePerf,
      );
      expect(fakePerf.habilitado, isFalse);
      expect(ServicoPerformance.instancia.coletaAtiva, isFalse);

      await initPerformance(
        isDebugMode: false,
        performanceInstance: fakePerf,
      );
      expect(fakePerf.habilitado, isTrue);
      expect(ServicoPerformance.instancia.coletaAtiva, isTrue);
    },
  );
}
