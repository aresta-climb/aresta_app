import 'package:flutter/material.dart';
import '../kmon_api/proto/croqui.pb.dart';
import '../functions/common_functions.dart';
import '../functions/grupo_functions.dart';

/// A page that displays detailed information about a specific group of sectors.
///
/// It presents the group's description, properties, and lists all sectors contained within it.
class GrupoPage extends StatelessWidget {
  final Grupo grupo;

  const GrupoPage({super.key, required this.grupo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nobleBlack,
      appBar: buildCommonAppBar(
        grupo.nome,
        actions: [],
      ),
      body: buildGrupoBody(context, grupo),
      bottomNavigationBar: buildSecondaryBottomNav(context),
    );
  }
}
