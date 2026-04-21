import 'package:flutter/material.dart';
import '../kmon_api/proto/croqui.pb.dart';
import 'common_functions.dart';
import 'pico_functions.dart';

/// Builds the main scrollable body of the Grupo page.
///
/// It extracts the description and iterates through all available sectors within the group.
Widget buildGrupoBody(BuildContext context, Grupo grupo) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('Informações do Grupo'),
        _buildInfoRow('Nome', grupo.nome),
        if (grupo.descricao.isNotEmpty) _buildInfoRow('Descrição', grupo.descricao),
        const SizedBox(height: 20),
        _buildHeader('Setores'),
        if (grupo.setores.isEmpty)
          const Text('Nenhum setor disponível.', style: TextStyle(color: fishBone))
        else
          ...grupo.setores.map((arquivoSetor) {
            if (arquivoSetor.hasConteudo()) {
              return buildSectorTile(context, arquivoSetor.conteudo);
            }
            return const SizedBox.shrink();
          }),
      ],
    ),
  );
}

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
