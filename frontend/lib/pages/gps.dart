import 'package:flutter/material.dart';
import '../view_functions/gps_functions.dart';
import '../view_functions/common_functions.dart';
import '../services/dataset_repository.dart';

class GPSPage extends StatelessWidget {
  final DatasetRepository datasetRepo;

  // Exige o repositório no construtor
  const GPSPage({super.key, required this.datasetRepo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: buildCommonAppBar(context, 'GPS'),
      /// TODO: Uma funcionalidade real de GPS
      body: buildGPSBody(),
    );
  }
}

