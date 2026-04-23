import 'package:flutter/material.dart';
import '../kmon_api/proto/croqui.pb.dart';
import '../functions/common_functions.dart';
import '../functions/grupo_functions.dart';

/// Uma página que exibe informações detalhadas sobre um grupo específico de setores.
///
/// Ela apresenta a descrição, propriedades do grupo e lista todos os setores contidos nele.
class GrupoPage extends StatelessWidget {
  final Grupo grupo;
  final String cragId;

  const GrupoPage({super.key, required this.grupo, required this.cragId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nobleBlack,
      appBar: buildCommonAppBar(
        grupo.nome,
        actions: [],
      ),
      body: buildGrupoBody(context, grupo, cragId),
      bottomNavigationBar: buildSecondaryBottomNav(context),
    );
  }
}
