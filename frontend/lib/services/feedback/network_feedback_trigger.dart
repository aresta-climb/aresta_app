/// Este arquivo atua como um gatilho (Trigger) reativo.
/// Ouve mudanças na rede (Wi-Fi/Dados Móveis) e dispara a sincronização da fila quando a internet volta.

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Classe utilitária para ouvir transições de rede do [Connectivity]
/// e disparar um callback com um atraso de estabilização.
class NetworkFeedbackTrigger {
  final Stream<List<ConnectivityResult>> connectivityStream;
  final Future<void> Function() onNetworkRestored;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  NetworkFeedbackTrigger({
    required this.connectivityStream,
    required this.onNetworkRestored,
  }) {
    _subscription = connectivityStream.listen((results) async {
      if (!results.contains(ConnectivityResult.none)) {
        // Aguarda 3 segundos para a rede (DNS/Rotas) estabilizar após a transição
        await Future.delayed(const Duration(seconds: 3));
        try {
          await onNetworkRestored();
        } catch (_) {
          // Captura silenciosamente para não explodir o listener de rede principal
        }
      }
    });
  }

  void dispose() {
    _subscription.cancel();
  }
}
