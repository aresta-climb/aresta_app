import 'package:flutter/material.dart';
import '../functions/home_functions.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> downloadedPicos = getDownloadedPicos();

    return Scaffold(
      backgroundColor: nobleBlack,
      appBar: buildHomeAppBar(),
      body: buildHomeBody(downloadedPicos),
    );
  }
}
