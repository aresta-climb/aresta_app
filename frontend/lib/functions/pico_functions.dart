import 'package:flutter/material.dart';
import '../proto/croqui.pb.dart';
import 'common_functions.dart';

/// Builds the main body of the Pico page.
Widget buildPicoBody(Croqui croqui) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('Informações Gerais'),
        _buildInfoRow('ID', croqui.id),
        _buildInfoRow('Nome', croqui.nome),
        _buildInfoRow('Descrição', croqui.descricao),
        const SizedBox(height: 20),
        
        if (croqui.creditos.isNotEmpty) ...[
          _buildHeader('Créditos'),
          ...croqui.creditos.map((c) => Text(c, style: const TextStyle(color: fishBone))),
          const SizedBox(height: 20),
        ],

        if (croqui.picos.isNotEmpty) ...[
          ...croqui.picos.map((pico) => _buildPicoCard(pico)),
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
            text: value.isNotEmpty ? value : 'N/A',
            style: const TextStyle(color: fishBone),
          ),
        ],
      ),
    ),
  );
}

Widget _buildPicoCard(Pico pico) {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: beastHide.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pico.nome,
          style: const TextStyle(color: fishBone, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        if (pico.descricao.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(pico.descricao, style: TextStyle(color: fishBone.withValues(alpha: 0.7))),
          ),
        const Divider(color: beastHide, thickness: 0.5),
        const SizedBox(height: 10),
        Text('Setores:', style: const TextStyle(color: beastHide, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 10),
        ...pico.setores.map((arquivoSetor) {
          if (arquivoSetor.hasConteudo()) {
            return _buildSectorWidget(arquivoSetor.conteudo);
          }
          return const SizedBox.shrink();
        }),
      ],
    ),
  );
}

Widget _buildSectorWidget(Setor setor) {
  return Padding(
    padding: const EdgeInsets.only(left: 10, bottom: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          setor.nome,
          style: const TextStyle(color: fishBone, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        if (setor.descricao.isNotEmpty)
          Text(setor.descricao, style: TextStyle(color: fishBone.withValues(alpha: 0.6), fontSize: 13)),
        const SizedBox(height: 8),
        if (setor.escaladas.isNotEmpty) ...[
          const Text('Vias:', style: TextStyle(color: beastHide, fontSize: 14, fontWeight: FontWeight.bold)),
          ...setor.escaladas.map((escalada) => _buildRouteWidget(escalada)),
        ],
        // Recursively build sub-sectors if they exist
        ...setor.subSetores.map((arquivoSubSetor) {
          if (arquivoSubSetor.hasConteudo()) {
            return Padding(
              padding: const EdgeInsets.only(left: 15, top: 10),
              child: _buildSectorWidget(arquivoSubSetor.conteudo),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    ),
  );
}

Widget _buildRouteWidget(Escalada escalada) {
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
      info = 'Boulder | ${escalada.boulder.dificuldade.name}';
      break;
    case Escalada_Tipo.viaMultiplasEnfiadas:
      nome = escalada.viaMultiplasEnfiadas.nome;
      info = 'Multipitch | ${escalada.viaMultiplasEnfiadas.dificuldadeMaxima.name.replaceAll('BR_', '').replaceAll('_', ' ')}';
      break;
    case Escalada_Tipo.notSet:
      nome = 'Sem Nome';
      break;
  }

  return Padding(
    padding: const EdgeInsets.only(left: 10, top: 4),
    child: Row(
      children: [
        const Icon(Icons.terrain_outlined, size: 14, color: fishBone),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nome, style: const TextStyle(color: fishBone, fontSize: 14)),
              Text(info, style: TextStyle(color: fishBone.withValues(alpha: 0.5), fontSize: 11)),
            ],
          ),
        ),
      ],
    ),
  );
}
