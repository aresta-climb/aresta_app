import 'package:flutter/material.dart';
import '../kmon_api/proto/croqui.pb.dart';
import '../pages/via.dart';
import 'common_functions.dart';

/// Builds the main scrollable body of the Sector page.
///
/// It extracts the description and iterates through all available routes 
/// ([Escalada]) and nested sub-sectors to render them.
Widget buildSetorBody(BuildContext context, Setor setor) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (setor.descricao.isNotEmpty) ...[
          _buildHeader('Descrição'),
          Text(setor.descricao, style: const TextStyle(color: fishBone)),
          const SizedBox(height: 20),
        ],

        _buildHeader('Vias'),
        if (setor.escaladas.isEmpty)
          const Text('Nenhuma via disponível.', style: TextStyle(color: fishBone))
        else ...[
          ...setor.escaladas.map((escalada) => _buildRouteTile(context, escalada)),
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



/// Builds an interactive tile for a single climbing route.
///
/// It determines the route's type to fetch the appropriate name and grade, 
/// and configures a tap button to navigate to the [ViaPage].
Widget _buildRouteTile(BuildContext context, Escalada escalada) {
  String nome = '';
  String info = '';

  switch (escalada.whichTipo()) {
    case Escalada_Tipo.viaEsportiva:
      nome = escalada.viaEsportiva.nome;
      info = 'Esportiva | ${escalada.viaEsportiva.dificuldade.name.replaceAll('BR_', '').replaceAll('_', ' ')}';
      break;
    case Escalada_Tipo.viaMovel:
      nome = escalada.viaMovel.nome;
      info = 'Móvel | ${escalada.viaMovel.dificuldade.name.replaceAll('BR_', '').replaceAll('_', ' ')}';
      break;
    case Escalada_Tipo.boulder:
      nome = escalada.boulder.nome;
      info = 'Boulder | ${escalada.boulder.dificuldade.name.replaceAll('BR_', '')}';
      break;
    case Escalada_Tipo.viaMultiplasEnfiadas:
      nome = escalada.viaMultiplasEnfiadas.nome;
      info = 'Multipitch | ${escalada.viaMultiplasEnfiadas.dificuldadeMaxima.name.replaceAll('BR_', '').replaceAll('_', ' ')}';
      break;
    case Escalada_Tipo.highline:
      nome = escalada.highline.nome;
      info = 'Highline | ${escalada.highline.distancia}m';
      break;
    case Escalada_Tipo.notSet:
      nome = 'Sem Nome';
      break;
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: beastHide.withValues(alpha: 0.2)),
    ),
    child: ListTile(
      leading: const Icon(Icons.terrain_outlined, color: beastHide),
      title: Text(nome, style: const TextStyle(color: fishBone, fontSize: 16)),
      subtitle: Text(info, style: TextStyle(color: fishBone.withValues(alpha: 0.6), fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: beastHide),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ViaPage(escalada: escalada)),
        );
      },
    ),
  );
}
