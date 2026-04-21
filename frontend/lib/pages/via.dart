import 'package:flutter/material.dart';
import '../kmon_api/proto/croqui.pb.dart';
import '../functions/common_functions.dart';
import '../functions/via_functions.dart';

/// A page that displays detailed information about a specific climbing route (Via).
///
/// It dynamically adjusts its content based on the type of route to show the relevant properties 
/// such as difficulty, protections, and descriptions.
class ViaPage extends StatelessWidget {
  final Escalada escalada;

  const ViaPage({super.key, required this.escalada});

  @override
  Widget build(BuildContext context) {
    // Extract name dynamically based on type
    String nome = 'Sem Nome';
    switch (escalada.whichTipo()) {
      case Escalada_Tipo.viaEsportiva:
        nome = escalada.viaEsportiva.nome;
        break;
      case Escalada_Tipo.viaMovel:
        nome = escalada.viaMovel.nome;
        break;
      case Escalada_Tipo.boulder:
        nome = escalada.boulder.nome;
        break;
      case Escalada_Tipo.viaMultiplasEnfiadas:
        nome = escalada.viaMultiplasEnfiadas.nome;
        break;
      case Escalada_Tipo.notSet:
        break;
    }

    return Scaffold(
      backgroundColor: nobleBlack,
      appBar: buildCommonAppBar(nome),
      body: buildViaBody(context, escalada),
      bottomNavigationBar: buildSecondaryBottomNav(context),
    );
  }
}
