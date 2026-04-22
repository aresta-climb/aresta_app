import 'package:flutter/material.dart';
import '../kmon_api/proto/croqui.pb.dart';
import '../pages/setor.dart';
import '../pages/grupo.dart';
import 'common_functions.dart';
import 'offline_markdown.dart';

/// Builds the main scrollable body of the Pico page.
///
/// It extracts the description and iterates through all available sectors to render them.
Widget buildPicoBody(BuildContext context, Pico pico, Croqui croqui, String cragId) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('Informações do Local'),
        _buildInfoRow('Nome', pico.nome),
        if (pico.descricao.isNotEmpty) ...[
          const SizedBox(height: 10),
          OfflineMarkdown(data: pico.descricao, cragId: cragId),
          const SizedBox(height: 10),
        ],
        if (pico.estado.isNotEmpty) _buildInfoRow('Estado', pico.estado),
        const SizedBox(height: 20),
        _buildHeader('Setores'),
        if (pico.setoresOuGrupos.isEmpty)
          const Text('Nenhum elemento disponível.', style: TextStyle(color: fishBone))
        else
          ...pico.setoresOuGrupos.map((setorOuGrupo) {
            if (setorOuGrupo.whichTipo() == SetorOuGrupo_Tipo.setor && setorOuGrupo.setor.hasConteudo()) {
              return buildSectorTile(context, setorOuGrupo.setor.conteudo, cragId);
            } else if (setorOuGrupo.whichTipo() == SetorOuGrupo_Tipo.grupo && setorOuGrupo.grupo.hasConteudo()) {
              return buildGrupoTile(context, setorOuGrupo.grupo.conteudo, cragId);
            }
            return const SizedBox.shrink();
          }),
        if (croqui.arquivosMarkdown.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildHeader('Mais Informações'),
          ...croqui.arquivosMarkdown.map((md) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: OfflineMarkdown(data: md.conteudo, cragId: cragId),
            );
          }),
        ],
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

Widget buildSectorTile(BuildContext context, Setor setor, String cragId) {
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
          MaterialPageRoute(builder: (context) => SetorPage(setor: setor, cragId: cragId)),
        );
      },
    ),
  );
}

Widget buildGrupoTile(BuildContext context, Grupo grupo, String cragId) {
  return Container(
    margin: const EdgeInsets.only(bottom: 15),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: beastHide.withValues(alpha: 0.3)),
    ),
    child: ListTile(
      title: Text(
        grupo.nome,
        style: const TextStyle(color: fishBone, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      subtitle: grupo.descricao.isNotEmpty
          ? Text(grupo.descricao, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fishBone.withValues(alpha: 0.6), fontSize: 13))
          : null,
      trailing: const Icon(Icons.folder, color: beastHide),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GrupoPage(grupo: grupo, cragId: cragId)),
        );
      },
    ),
  );
}
