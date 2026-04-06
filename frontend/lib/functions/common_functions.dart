import 'package:flutter/material.dart';

// Shared Color Palette
const Color nobleBlack = Color(0xFF1F2128);
const Color beastHide = Color(0xFFAE8F68);
const Color fishBone = Color(0xFFE4DAC5);

PreferredSizeWidget buildCommonAppBar(String title) {
  return AppBar(
    title: Text(
      title,
      style: const TextStyle(
        color: nobleBlack,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    ),
    backgroundColor: beastHide,
    centerTitle: true,
    elevation: 4,
    shadowColor: Colors.black.withValues(alpha: 0.5),
  );
}
