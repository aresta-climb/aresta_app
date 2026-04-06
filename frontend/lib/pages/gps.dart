import 'package:flutter/material.dart';
import '../functions/gps_functions.dart';
import '../functions/common_functions.dart';

class GPSPage extends StatelessWidget {
  const GPSPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nobleBlack,
      appBar: buildCommonAppBar('GPS'),
      body: buildGPSBody(),
    );
  }
}
