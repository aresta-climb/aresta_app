import 'package:flutter/material.dart';
import '../kmon_api/proto/croqui.pb.dart';
import '../functions/common_functions.dart';
import '../functions/setor_functions.dart';

/// Uma página que fornece uma visão geral de um setor específico.
///
/// Ela exibe a descrição do setor e apresenta uma lista de todas as vias
/// de escalada ([Escalada]) e quaisquer subsetores contidos nele.
class SetorPage extends StatelessWidget {
  final Setor setor;
  final String cragId;

  const SetorPage({super.key, required this.setor, required this.cragId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nobleBlack,
      appBar: buildCommonAppBar(setor.nome),
      body: buildSetorBody(context, setor, cragId),
      bottomNavigationBar: buildSecondaryBottomNav(context),
    );
  }
}
