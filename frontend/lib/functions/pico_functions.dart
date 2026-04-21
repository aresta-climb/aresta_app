import 'package:flutter/material.dart';
import '../kmon_api/proto/croqui.pb.dart';
import '../pages/setor.dart';
import 'common_functions.dart';

/// Builds the main scrollable body of the Pico page.
///
/// It extracts the description and iterates through all available sectors to render them.
Widget buildPicoBody(BuildContext context, Pico pico) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('Informações do Local'),
        _buildInfoRow('Nome', pico.nome),
        _buildInfoRow('Descrição', pico.descricao),
        if (pico.estado.isNotEmpty) _buildInfoRow('Estado', pico.estado),
        const SizedBox(height: 20),
        _buildHeader('Setores'),
        if (pico.setores.isEmpty)
          const Text('Nenhum setor disponível.', style: TextStyle(color: fishBone))
        else
          ...pico.setores.map((arquivoSetor) {
            if (arquivoSetor.hasConteudo()) {
              return _buildSectorTile(context, arquivoSetor.conteudo);
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

Widget _buildSectorTile(BuildContext context, Setor setor) {
  return Container(
    margin: const EdgeInsets.only(bottom: 15),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: beastHide.withValues(alpha: 0.3)),
    ),
    child: ListTile(
      title: Text(
        setor.nome,
        style: const TextStyle(color: fishBone, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      subtitle: setor.descricao.isNotEmpty
          ? Text(setor.descricao, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fishBone.withValues(alpha: 0.6), fontSize: 13))
          : null,
      trailing: const Icon(Icons.chevron_right, color: beastHide),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SetorPage(setor: setor)),
        );
      },
    ),
  );
}
