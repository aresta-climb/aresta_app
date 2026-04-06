import 'package:flutter/material.dart';

const Color nobleBlack = Color(0xFF1F2128);
const Color beastHide = Color(0xFFAE8F68);

PreferredSizeWidget buildGPSAppBar() {
  return AppBar(
    title: const Text(
      'GPS',
      style: TextStyle(
        color: nobleBlack,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    backgroundColor: beastHide,
    centerTitle: true,
  );
}

Widget buildGPSBody() {
  // TODO: An actual gps page
  return const Center(
    child: Text(
      'Funcionalidades GPS em breve',
      style: TextStyle(color: Colors.white),
    ),
  );
}
