import 'package:flutter/material.dart';
import '../kmon_api/proto/croqui.pb.dart';
import '../functions/common_functions.dart';
import '../functions/setor_functions.dart';

/// A page that provides an overview of a specific sector.
///
/// It displays the sector's description and presents a list of all climbing 
/// routes ([Escalada]) and any sub-sectors contained within it.
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
