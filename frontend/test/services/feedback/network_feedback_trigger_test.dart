import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/feedback/network_feedback_trigger.dart';

void main() {
  group('NetworkFeedbackTrigger', () {
    test(
      'deve aguardar 3 segundos antes de disparar o callback quando a rede conectar',
      () {
        fakeAsync((async) {
          final streamController = StreamController<List<ConnectivityResult>>();
          int callCount = 0;

          // Instancia o trigger com o stream controlado
          final trigger = NetworkFeedbackTrigger(
            connectivityStream: streamController.stream,
            onNetworkRestored: () async {
              callCount++;
            },
          );

          // Dispara evento de "Conectado ao Wifi"
          streamController.add([ConnectivityResult.wifi]);

          // Avança 2 segundos (ainda não deve ter chamado)
          async.elapse(const Duration(seconds: 2));
          expect(callCount, 0);

          // Avança mais 1 segundo (completou 3, deve chamar)
          async.elapse(const Duration(seconds: 1));
          expect(callCount, 1);

          // Dispara evento de "Sem internet"
          streamController.add([ConnectivityResult.none]);
          async.elapse(const Duration(seconds: 5));

          // Continua sendo 1 chamada, pois ConnectivityResult.none é ignorado
          expect(callCount, 1);

          trigger.dispose();
          streamController.close();
        });
      },
    );

    test('deve capturar exceptions do callback silenciosamente', () {
      fakeAsync((async) {
        final streamController = StreamController<List<ConnectivityResult>>();
        bool exceptionCaught = false;

        final trigger = NetworkFeedbackTrigger(
          connectivityStream: streamController.stream,
          onNetworkRestored: () async {
            throw Exception('Erro de rede simulado');
          },
        );

        streamController.add([ConnectivityResult.mobile]);

        try {
          async.elapse(const Duration(seconds: 3));
          exceptionCaught = true; // Se chegou aqui, não vazou a exceção
        } catch (_) {
          exceptionCaught = false;
        }

        expect(exceptionCaught, isTrue);

        trigger.dispose();
        streamController.close();
      });
    });
  });
}
