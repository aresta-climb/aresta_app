import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import 'common_functions.dart';
import 'pico_functions.dart';
import 'offline_markdown.dart';
import '../widgets/mapa_thumbnail.dart';

/// Constrói o corpo rolável principal da página do Grupo.
///
/// Ele exibe as informações do grupo e uma lista de todos os grupos de setores (setores)
/// disponíveis dentro do pico.
Widget buildGrupoBody(BuildContext context, Grupo grupo, String cragId, List<ArquivoSetor> sortedSetores, [Widget? sortButton]) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader('Informações do Grupo'),
        _buildInfoRow('Nome', grupo.nome),
        if (grupo.descricao.isNotEmpty) ...[
          const SizedBox(height: 10),
          OfflineMarkdown(data: grupo.descricao, cragId: cragId),
          const SizedBox(height: 10),
        ],
        if (grupo.mapas.isNotEmpty) ...[
          ...grupo.mapas.map((mapa) {
            if (mapa.caminhoImagemMapa.isNotEmpty && mapa.larguraMapa > 0 && mapa.alturaMapa > 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: mapa.larguraMapa / mapa.alturaMapa,
                    child: MapaThumbnail(
                      mapa: mapa,
                      cragId: cragId,
                      grupoContext: grupo,
                      nomeContexto: grupo.nome,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildHeader('Subsetores'),
            ?sortButton,
          ],
        ),
        if (sortedSetores.isEmpty)
          Text('Nenhum setor disponível.', style: TextStyle(color: fishBone))
        else
          ...sortedSetores.map((arquivoSetor) {
            if (arquivoSetor.hasConteudo()) {
              return buildSectorTile(context, arquivoSetor.conteudo, cragId, grupoContext: grupo);
            }
            return const SizedBox.shrink();
          }),
      ],
    ),
  );
}

/// Constrói um cabeçalho estilizado para seções dentro da página do Grupo.
Widget _buildHeader(String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      title,
      style: TextStyle(
        color: beastHide,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

/// Constrói uma linha exibindo um rótulo e seu valor correspondente.
/// 
/// Retorna um espaço vazio se o valor estiver vazio.
Widget _buildInfoRow(String label, String value) {
  if (value.isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(color: beastHide, fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: value,
            style: TextStyle(color: fishBone),
          ),
        ],
      ),
    ),
  );
}

enum GrupoSortMode { original, alphaAsc, alphaDesc }
