import 'package:flutter/material.dart';
import '../proto/croqui.pb.dart';
import '../functions/common_functions.dart';
import '../functions/pico_functions.dart';

/// A page that displays detailed information about a specific pico.
///
/// It presents the pico's description and lists all sectors contained within it.
class PicoDetailsPage extends StatelessWidget {
  final Pico pico;

  const PicoDetailsPage({super.key, required this.pico});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nobleBlack,
      appBar: buildCommonAppBar(pico.nome),
      body: buildPicoBody(context, pico),
    );
  }
}
