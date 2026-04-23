import 'package:flutter/material.dart';
import '../kmon_api/proto/croqui.pb.dart';
import '../pages/via.dart';
import 'common_functions.dart';
import 'offline_markdown.dart';

/// Constrói o corpo rolável principal da página do Setor.
///
/// Ele extrai a descrição e itera por todas as vias disponíveis
/// ([Escalada]) e subsetores aninhados para renderizá-los.
Widget buildSetorBody(BuildContext context, Setor setor, String cragId) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (setor.descricao.isNotEmpty) ...[
          _buildHeader('Descrição'),
          OfflineMarkdown(data: setor.descricao, cragId: cragId),
          const SizedBox(height: 20),
        ],

        if (setor.mapas.isNotEmpty) ...[
          ...setor.mapas.map((mapa) {
            if (mapa.caminhoImagemMapa.isNotEmpty) {
              String cleanPath = mapa.caminhoImagemMapa;
              if (cleanPath.startsWith('/')) {
                cleanPath = cleanPath.substring(1);
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: OfflineMarkdown(
                  data: '![Mapa do Setor](https://acecmg.github.io/kmon_serving/$cleanPath)',
                  cragId: cragId,
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],

        Builder(
          builder: (context) {
            int boulderCount = 0;
            for (var escalada in setor.escaladas) {
              if (escalada.whichTipo() == Escalada_Tipo.boulder) {
                boulderCount++;
              }
            }
            
            // Se mais da metade das escaladas forem boulders, exiba "Boulders" em vez de "Vias"
            final bool isBoulderArea = setor.escaladas.isNotEmpty && boulderCount >= (setor.escaladas.length / 2);
            final String headerText = isBoulderArea ? 'Boulders' : 'Vias';
            final String emptyText = isBoulderArea ? 'Nenhum boulder disponível.' : 'Nenhuma via disponível.';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(headerText),
                if (setor.escaladas.isEmpty)
                  Text(emptyText, style: const TextStyle(color: fishBone))
                else ...[
                  ...setor.escaladas.map((escalada) => _buildRouteTile(context, escalada, cragId)),
                ],
              ],
            );
          },
        ),
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



/// Constrói um tile interativo para uma única via de escalada.
///
/// Ele determina o tipo da via para buscar o nome e grau apropriados,
/// e configura um botão de toque para navegar para a [ViaPage].
Widget _buildRouteTile(BuildContext context, Escalada escalada, String cragId) {
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
          MaterialPageRoute(builder: (context) => ViaPage(escalada: escalada, cragId: cragId)),
        );
      },
    ),
  );
}
