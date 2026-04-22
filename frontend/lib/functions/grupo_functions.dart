import 'package:flutter/material.dart';
import '../kmon_api/proto/croqui.pb.dart';
import 'common_functions.dart';
import 'pico_functions.dart';
import 'offline_markdown.dart';

/// Builds the main scrollable body of the Grupo page.
///
/// It displays the group's information and a list of all available groups of sectors (setores)
/// within the crag (pico).
Widget buildGrupoBody(BuildContext context, Grupo grupo) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('Informações do Grupo'),
        _buildInfoRow('Nome', grupo.nome),
        if (grupo.descricao.isNotEmpty) ...[
          const SizedBox(height: 10),
          OfflineMarkdown(data: grupo.descricao),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 20),
        _buildHeader('Subsetores'),
        if (grupo.setores.isEmpty)
          const Text('Nenhum setor disponível.', style: TextStyle(color: fishBone))
        else
          ...grupo.setores.map((arquivoSetor) {
            // Only render grupos that have content loaded
            if (arquivoSetor.hasConteudo()) {
              return buildSectorTile(context, arquivoSetor.conteudo);
            }
            return const SizedBox.shrink();
          }),
      ],
    ),
  );
}

/// Builds a styled header for sections within the Grupo page.
Widget _buildHeader(String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      title,
      style: const TextStyle(
        color: beastHide,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

/// Builds a row displaying a label and its corresponding value.
/// 
/// Returns an empty space if the value is empty.
Widget _buildInfoRow(String label, String value) {
  if (value.isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: beastHide, fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(color: fishBone),
          ),
        ],
      ),
    ),
  );
}
