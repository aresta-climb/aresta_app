import 'package:flutter/material.dart';
import '../kmon_api/proto/croqui.pb.dart';
import '../functions/common_functions.dart';
import '../functions/via_functions.dart';

/// Uma página que exibe informações detalhadas sobre uma via de escalada específica.
///
/// Ela ajusta dinamicamente seu conteúdo com base no tipo de rota para mostrar as propriedades relevantes,
/// como dificuldade, proteções e descrições.
class ViaPage extends StatelessWidget {
  final Escalada escalada;
  final String cragId;

  const ViaPage({super.key, required this.escalada, required this.cragId});

  @override
  Widget build(BuildContext context) {
    // Extrai o nome dinamicamente com base no tipo
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
      case Escalada_Tipo.highline:
        nome = escalada.highline.nome;
        break;
      case Escalada_Tipo.notSet:
        break;
    }

    return Scaffold(
      backgroundColor: nobleBlack,
      appBar: buildCommonAppBar(nome),
      body: buildViaBody(context, escalada, cragId),
      bottomNavigationBar: buildSecondaryBottomNav(context),
    );
  }
}
