import 'package:flutter/material.dart';
import '../kmon_api/proto/croqui.pb.dart';
import 'common_functions.dart';

/// Builds the main scrollable body of the Route (Via) page.
///
/// It delegates to specific builder functions depending on the route type.
Widget buildViaBody(BuildContext context, Escalada escalada) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContentForEscalada(escalada),
      ],
    ),
  );
}

/// Builds the detailed content based on the route's specific type 
/// ([ViaEsportiva], [ViaMovel], [Boulder], or [ViaMultiplasEnfiadas]).
Widget _buildContentForEscalada(Escalada escalada) {
  switch (escalada.whichTipo()) {
    case Escalada_Tipo.viaEsportiva:
      return _buildViaEsportiva(escalada.viaEsportiva);
    case Escalada_Tipo.viaMovel:
      return _buildViaMovel(escalada.viaMovel);
    case Escalada_Tipo.boulder:
      return _buildBoulder(escalada.boulder);
    case Escalada_Tipo.viaMultiplasEnfiadas:
      return _buildMultipitch(escalada.viaMultiplasEnfiadas);
    case Escalada_Tipo.highline:
      return _buildHighline(escalada.highline);
    default:
      return const Text('Detalhes não disponíveis.', style: TextStyle(color: fishBone));
  }
}

Widget _buildViaEsportiva(ViaEsportiva via) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildHeader('Informações da Via Esportiva'),
      _buildInfoRow('Dificuldade', via.dificuldade.name.replaceAll('BR_', '').replaceAll('_', ' ')),
      if (via.quantidadeProtecoesIntermediarias > 0)
        _buildInfoRow('Proteções Intermediárias', via.quantidadeProtecoesIntermediarias.toString()),
      if (via.quantidadeProtecoesParada > 0)
        _buildInfoRow('Proteções na Parada', via.quantidadeProtecoesParada.toString()),
      _buildInfoRow('Tipo de Ancoragem', via.tipoAncoragem),
      if (via.descricao.isNotEmpty) ...[
        _buildHeader('Descrição'),
        Text(via.descricao, style: const TextStyle(color: fishBone)),
      ],
      if (via.urlVideoBeta.isNotEmpty)
        _buildInfoRow('Vídeo Beta', via.urlVideoBeta),
    ],
  );
}

Widget _buildViaMovel(ViaMovel via) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildHeader('Informações da Via Móvel'),
      _buildInfoRow('Dificuldade', via.dificuldade.name.replaceAll('BR_', '').replaceAll('_', ' ')),
      if (via.quantidadeProtecoesIntermediarias > 0)
        _buildInfoRow('Proteções Intermediárias', via.quantidadeProtecoesIntermediarias.toString()),
      if (via.quantidadeProtecoesParada > 0)
        _buildInfoRow('Proteções na Parada', via.quantidadeProtecoesParada.toString()),
      _buildInfoRow('Tipo de Ancoragem', via.tipoAncoragem),
      if (via.protecoesMoveis.isNotEmpty)
        _buildInfoRow('Peças Móveis', via.protecoesMoveis),
      if (via.descricao.isNotEmpty) ...[
        _buildHeader('Descrição'),
        Text(via.descricao, style: const TextStyle(color: fishBone)),
      ],
      if (via.urlVideoBeta.isNotEmpty)
        _buildInfoRow('Vídeo Beta', via.urlVideoBeta),
    ],
  );
}

Widget _buildBoulder(Boulder via) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildHeader('Informações do Boulder'),
      _buildInfoRow('Dificuldade', via.dificuldade.name.replaceAll('BR_', '').replaceAll('_', ' ')),
      if (via.descricao.isNotEmpty) ...[
        _buildHeader('Descrição'),
        Text(via.descricao, style: const TextStyle(color: fishBone)),
      ],
    ],
  );
}

Widget _buildMultipitch(ViaMultiplasEnfiadas via) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildHeader('Informações da Multipitch'),
      _buildInfoRow('Dificuldade Máxima', via.dificuldadeMaxima.name.replaceAll('BR_', '').replaceAll('_', ' ')),
      if (via.descricao.isNotEmpty) ...[
        _buildHeader('Descrição'),
        Text(via.descricao, style: const TextStyle(color: fishBone)),
      ],
    ],
  );
}

Widget _buildHighline(Highline via) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildHeader('Informações do Highline'),
      _buildInfoRow('Distância', '${via.distancia}m'),
      if (via.descricao.isNotEmpty) ...[
        _buildHeader('Descrição'),
        Text(via.descricao, style: const TextStyle(color: fishBone)),
      ],
    ],
  );
}

Widget _buildHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
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
