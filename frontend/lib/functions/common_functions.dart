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

/// A search bar widget that handles real-time filtering
Widget buildSearchBar({
  required ValueChanged<String> onChanged,
  String hintText = 'Pesquisar...',
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
    child: TextField(
      onChanged: onChanged,
      style: const TextStyle(color: nobleBlack),
      cursorColor: nobleBlack,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: nobleBlack.withValues(alpha: 0.6)),
        prefixIcon: const Icon(Icons.search, color: nobleBlack),
        filled: true,
        fillColor: fishBone,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}
