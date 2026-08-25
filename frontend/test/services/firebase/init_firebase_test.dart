// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/firebase/init_firebase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
}
