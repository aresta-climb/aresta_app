import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../view_functions/common_functions.dart';
import '../view_functions/via_functions.dart';

/// Uma página que exibe informações detalhadas sobre uma via de escalada específica.
///
/// Ela ajusta dinamicamente seu conteúdo com base no tipo de rota para mostrar as propriedades relevantes,
/// como dificuldade, proteções e descrições.
class ViaPage extends StatelessWidget {
  final Escalada escalada;
  final String cragId;
  final Setor? setor;
  final bool fromSetorPage; // FIXME: Hack "band-aid" para evitar loop infinito de navegação ao apertar "go back" vindo da SetorPage
  final bool fromMapaPage; // FIXME: Hack "band-aid" para evitar loop infinito de navegação ao apertar "go back" vindo da MapaPage

  const ViaPage({
    super.key, 
    required this.escalada, 
    required this.cragId, 
    this.setor,
    this.fromSetorPage = false,
    this.fromMapaPage = false,
  });

  @override
  Widget build(BuildContext context) {
    // Extrai o nome dinamicamente com base no tipo
    String nome = getEscaladaNome(escalada);

    return Scaffold(
      backgroundColor: nobleBlack,
      appBar: buildCommonAppBar(context, nome),
      body: buildViaBody(context, escalada, cragId, setor: setor, fromSetorPage: fromSetorPage, fromMapaPage: fromMapaPage),
      // bottomNavigationBar: buildSecondaryBottomNav(context),
    );
  }
}

