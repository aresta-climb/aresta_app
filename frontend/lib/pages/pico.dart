import 'package:flutter/material.dart';
import '../proto/croqui.pb.dart';
import '../functions/common_functions.dart';
import '../functions/pico_functions.dart';

class PicoDetailsPage extends StatelessWidget {
  final Croqui croqui;

  const PicoDetailsPage({super.key, required this.croqui});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nobleBlack,
      appBar: buildCommonAppBar(croqui.nome),
      body: buildPicoBody(croqui),
    );
  }
}
