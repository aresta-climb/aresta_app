import 'package:flutter/material.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/view_functions/offline_markdown.dart';
import 'package:frontend/view_functions/common_functions.dart';
import 'package:frontend/navigation/navigation_functions.dart';

/// Encontra o markdown que contém o mapa geral do pico
ArquivoMarkdown getMapaGeralMarkdown(Croqui croqui) {
  final secoesMds = croqui.botoes
      .where((b) => b.hasDestino() && b.destino.hasSecaoTextual())
      .map((b) => MapEntry(b.texto, b.destino.secaoTextual))
      .toList();

  final capaFiles = secoesMds.where((entry) => entry.key.toLowerCase().contains('capa')).toList();
  final otherFiles = secoesMds.where((entry) => !entry.key.toLowerCase().contains('capa')).toList();

  try {
    return capaFiles.firstWhere(
      (entry) => entry.key.toLowerCase().contains('mapa') || entry.value.conteudo.toLowerCase().contains('mapa'),
    ).value;
  } catch (e) {
    try {
      return otherFiles.firstWhere(
        (entry) => entry.key.toLowerCase().contains('mapa') || entry.value.conteudo.toLowerCase().contains('mapa'),
      ).value;
    } catch (e) {
      return ArquivoMarkdown()..conteudo = 'Mapa não encontrado.';
    }
  }
}

/// Constrói o corpo da página de mapa geral do pico, removendo o Center para
/// evitar espaço excessivo abaixo do appbar quando o conteúdo é menor que a tela.
Widget buildMapaGeralPicoBody(BuildContext context, String cragId, ArquivoMarkdown mapMd) {
  return SingleChildScrollView(
    padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 80),
    child: OfflineMarkdown(data: mapMd.conteudo, cragId: cragId),
  );
}

/// Constrói o botão de ação flutuante para retornar ao mapa do setor
Widget? buildMapaGeralPicoFab(BuildContext context, Setor? returnToSetor, String cragId) {
  if (returnToSetor == null || returnToSetor.mapas.isEmpty) return null;

  return FloatingActionButton.extended(
    heroTag: 'btnMapaSetor',
    onPressed: () {
      AppNav.back(context);
    },
    backgroundColor: beastHide,
    label: Text('Voltar para o Mapa do Setor', style: TextStyle(color: nobleBlack, fontWeight: FontWeight.bold)),
    icon: Icon(Icons.map, color: nobleBlack),
  );
}
