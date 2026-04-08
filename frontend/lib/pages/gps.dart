import 'package:flutter/material.dart';
import '../functions/gps_functions.dart';
import '../functions/common_functions.dart';
import '../services/dataset_repository.dart';

class GPSPage extends StatelessWidget {
  final DatasetRepository datasetRepo;

  // Require the repo in the constructor
  const GPSPage({super.key, required this.datasetRepo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nobleBlack,
      appBar: buildCommonAppBar('GPS'),
      body: buildGPSBody(),
    );
  }
}