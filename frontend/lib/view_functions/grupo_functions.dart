import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import 'common_functions.dart';
import 'pico_functions.dart';
import 'offline_markdown.dart';
import '../widgets/mapa_thumbnail.dart';
import '../theme/app_colors.dart';

/// Constrói o corpo rolável principal da página do Grupo.
///
/// Ele exibe as informações do grupo e uma lista de todos os grupos de setores (setores)
/// disponíveis dentro do pico.
Widget buildGrupoBody(BuildContext context, Grupo grupo, String cragId, List<ArquivoSetor> sortedSetores, GrupoSortMode currentSortMode, Function(GrupoSortMode) onSortChanged) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (grupo.descricao.isNotEmpty) ...[
          OfflineMarkdown(data: grupo.descricao, cragId: cragId),
          const SizedBox(height: 20),
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
        _buildGrupoSortGrid(context, currentSortMode, onSortChanged),
        const SizedBox(height: 16),
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



Widget _buildGrupoSortGrid(BuildContext context, GrupoSortMode currentMode, Function(GrupoSortMode)? onSortChanged) {
  return GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    childAspectRatio: 3.0,
    children: [
      _buildSortCard(
        context: context,
        label: 'PADRÃO',
        icon: Icons.grid_view_rounded,
        isActive: currentMode == GrupoSortMode.original,
        onTap: () => onSortChanged?.call(GrupoSortMode.original),
      ),
      _buildSortCard(
        context: context,
        label: 'ALFABÉTICO',
        icon: Icons.sort_by_alpha,
        isActive: currentMode == GrupoSortMode.alphaAsc || currentMode == GrupoSortMode.alphaDesc,
        onTap: () {
          if (currentMode == GrupoSortMode.alphaAsc) {
            onSortChanged?.call(GrupoSortMode.alphaDesc);
          } else {
            onSortChanged?.call(GrupoSortMode.alphaAsc);
          }
        },
      ),
    ],
  );
}

Widget _buildSortCard({
  required BuildContext context,
  required String label,
  required IconData icon,
  required bool isActive,
  required VoidCallback onTap,
}) {
  final Color activeColor = AppColors.brandColor;
  final Color inactiveColor = context.colors.fishBone.withValues(alpha: 0.5);
  final Color bgColor = context.colors.caveShadow;

  return GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: isActive ? activeColor : inactiveColor,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? activeColor : inactiveColor, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? activeColor : inactiveColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    ),
  );
}

enum GrupoSortMode { original, alphaAsc, alphaDesc }
