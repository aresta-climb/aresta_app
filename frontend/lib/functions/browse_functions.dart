import 'package:flutter/material.dart';
import 'common_functions.dart';

Widget buildBrowseBody(BuildContext context, List<Map<String, String>> availableCrags, {required ValueChanged<String> onSearchChanged}) {
  return Column(
    children: [
      const SizedBox(height: 10),
      buildSearchBar(onChanged: onSearchChanged),
      Expanded(
        child: _buildCragList(availableCrags),
      ),
    ],
  );
}

Widget _buildCragList(List<Map<String, String>> availableCrags) {
  if (availableCrags.isEmpty) {
    return const Center(
      child: Text(
        'Nenhum pico encontrado.',
        style: TextStyle(color: fishBone, fontSize: 16),
      ),
    );
  }

  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildBrowseSectionTitle('Picos Disponíveis'),
        const SizedBox(height: 20),
        ...availableCrags.map((crag) => buildCragListItem(crag)),
      ],
    ),
  );
}

Widget buildBrowseSectionTitle(String title) {
  return Text(
    title,
    style: const TextStyle(
      color: fishBone,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  );
}

Widget buildCragListItem(Map<String, String> crag) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: fishBone.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildCragIcon(),
          const SizedBox(width: 16),
          _buildCragDetails(crag),
          _buildDownloadButton(),
        ],
      ),
    ),
  );
}

Widget _buildCragIcon() {
  // Montain icon
  // TODO: Implement cover image instead of mountain icon
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: beastHide.withValues(alpha: 0.2),
      shape: BoxShape.circle,
    ),
    child: const Icon(
      Icons.terrain,
      color: beastHide,
      size: 24,
    ),
  );
}

Widget _buildCragDetails(Map<String, String> crag) {
  // Crag name and details updated to use safe fallbacks and Portuguese keys via safeString
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          safeString(crag['nome'], fallback: 'Sem Nome'),
          style: const TextStyle(
            color: fishBone,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          safeString(crag['local'], fallback: 'Local Desconhecido'),
          style: TextStyle(
            color: fishBone.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}

Widget _buildDownloadButton() {
  // Download icon button
  return IconButton(
    onPressed: () {
      // TODO: Implement download functionality
    },
    icon: const Icon(
      Icons.download_rounded,
      color: beastHide,
    ),
  );
}