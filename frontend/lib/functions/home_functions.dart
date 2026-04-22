import 'package:flutter/material.dart';
import '../services/dataset_repository.dart';
import '../pages/pico.dart';
import 'common_functions.dart';

/// Uma paleta de cores usada para o fundo dos cartões (cards) de pico.
final List<Color> cardPalette = [
  leatherWork,
  slateStone,
  mossRock,
  clayEarth,
  weatheredIron,
];

/// Navega para a página de detalhes de um pico selecionado.
/// 
/// Ele primeiro mostra um indicador de carregamento enquanto busca os dados completos do Croqui.
void handlePicoSelection(BuildContext context, DatasetRepository datasetRepo, Map<String, dynamic> pico) async {
  final id = pico['id'];
  if (id == null) return;

  // Mostra indicador de carregamento
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator(color: beastHide)),
  );

  final croqui = await datasetRepo.getCroqui(id);

  if (!context.mounted) return;
  
  Navigator.pop(context); // Remove indicador de carregamento

  if (croqui != null && croqui.picos.isNotEmpty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PicoDetailsPage(
          pico: croqui.picos.first,
          croqui: croqui,
          cragId: id,
          datasetRepo: datasetRepo,
        ),
      ),
    );
    
    // Atualiza a lista de prioridades APÓS a conclusão da transição para evitar que o carrossel mude
    // enquanto o usuário ainda está olhando para ele durante a transição.
    Future.delayed(const Duration(milliseconds: 500), () {
      datasetRepo.updatePriorityAfterNavigation(id);
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erro ao abrir o guia.')),
    );
  }
}

/// Constrói o corpo rolável principal da página inicial (Home).
/// 
/// Exibe um carrossel de picos baixados recentemente e uma lista suspensa
/// de todos os guias disponíveis.
Widget buildHomeBody(
  BuildContext context,
  DatasetRepository datasetRepo,
  List<Map<String, dynamic>> downloadedPicos,
  Set<String> downloadingCrags, {
  required VoidCallback onAddCrag,
}) {
  return Container(
    width: double.infinity,
    height: double.infinity,
    // Transformando a cor de fundo em um gradiente para ficar mais bonito
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          nobleBlack, // Cor de fundo principal
          obsidianBrown, // Transições do escuro para um marrom terra
        ],
      ),
    ),
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), // Garante que sempre role/tenha o efeito de rebote
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Guias Recentes',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: fishBone,
                  ),
                ),
                ValueListenableBuilder<SyncStatus>(
                  valueListenable: datasetRepo.syncStatus,
                  builder: (context, status, _) {
                    return buildSyncBadge(status);
                  },
                ),
              ],
            ),
          ),
          // O carrossel agora lida internamente com o limite de 4 cartões
          buildPicosCarousel(
            downloadedPicos, 
            downloadingCrags,
            onPicoSelect: (pico) => handlePicoSelection(context, datasetRepo, pico),
          ),
          const SizedBox(height: 10),
          _buildAllGuidesDropdown(
            downloadedPicos, 
            downloadingCrags,
            onAddCrag: onAddCrag, 
            onPicoSelect: (pico) => handlePicoSelection(context, datasetRepo, pico),
          ),
          const SizedBox(height: 100), // Espaço extra na parte inferior para garantir que tudo seja rolável
        ],
      ),
    ),
  );
}

/// Constrói um emblema (badge) de status de sincronização.
Widget buildSyncBadge(SyncStatus status) {
  String text;
  Color color;
  IconData icon;

  switch (status) {
    case SyncStatus.updated:
      text = 'Atualizados';
      color = Colors.green.shade800;
      icon = Icons.check_circle;
      break;
    case SyncStatus.updating:
      text = 'Atualizando...';
      color = Colors.blue.shade800;
      icon = Icons.sync;
      break;
    case SyncStatus.outdated:
      text = 'Desatualizado';
      color = Colors.orange.shade800;
      icon = Icons.warning;
      break;
    case SyncStatus.error:
      text = 'Sem conexão';
      color = Colors.brown.shade800;
      icon = Icons.error;
      break;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

/// Constrói uma lista expansível mostrando todos os guias baixados.
Widget _buildAllGuidesDropdown(
  List<Map<String, dynamic>> picos,
  Set<String> downloadingCrags, {
  required VoidCallback onAddCrag,
  required Function(Map<String, dynamic>) onPicoSelect,
}) {
  return Theme(
    data: ThemeData(
      dividerColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    ),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 24),
      iconColor: fishBone,
      collapsedIconColor: fishBone,
      title: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: fishBone.withValues(alpha: 0.1), width: 1),
          ),
        ),
        child: const Text(
          'Todos os guias baixados',
          style: TextStyle(
            color: fishBone,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      backgroundColor: Colors.black.withValues(alpha: 0.3), // Mais escuro que o fundo quando expandido para dar ênfase
      collapsedBackgroundColor: Colors.transparent,
      children: [
        ...picos.map((pico) {
          final isDownloading = downloadingCrags.contains(pico['id']);
          
          Widget trailingIcon;
          if (isDownloading) {
            trailingIcon = const SizedBox(
              width: 16, 
              height: 16, 
              child: CircularProgressIndicator(color: fishBone, strokeWidth: 2)
            );
          } else {
            trailingIcon = const Icon(Icons.chevron_right, color: fishBone, size: 18);
          }
          
          Color titleColor;
          if (isDownloading) {
            titleColor = fishBone.withValues(alpha: 0.5);
          } else {
            titleColor = fishBone;
          }

          VoidCallback? onTapCallback;
          if (isDownloading) {
            onTapCallback = null;
          } else {
            onTapCallback = () => onPicoSelect(pico);
          }

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 32),
            title: Text(
              safeString(pico['nome']),
              style: TextStyle(
                color: titleColor, 
                fontSize: 15
              ),
            ),
            trailing: trailingIcon,
            onTap: onTapCallback,
          );
        }),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 32),
          leading: const Icon(Icons.add_circle_outline, color: beastHide, size: 20),
          title: const Text(
            'Adicionar novo local',
            style: TextStyle(
              color: beastHide,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          onTap: onAddCrag,
        ),
      ],
    ),
  );
}

/// Um cabeçalho estilizado para seções.
Widget buildSectionHeader(String title) {
  return Padding(
    // Preenchimento (padding) no texto para dar algum espaço
    padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: fishBone, // Texto claro para visibilidade
      ),
    ),
  );
}

/// Constrói um carrossel horizontal de cartões de picos.
/// Limitado aos 4 picos mais recentes.
/// Permite loop infinito se houver exatamente 4 itens.
Widget buildPicosCarousel(
  List<Map<String, dynamic>> allPicos,
  Set<String> downloadingCrags, {
  required Function(Map<String, dynamic>) onPicoSelect,
}) {
  if (allPicos.isEmpty) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text(
          'Nenhum guia baixado ainda.',
          style: TextStyle(color: fishBone, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  // LIMITADOR: Pega no máximo 4 cartões para o carrossel para evitar acúmulo de informações
  final List<Map<String, dynamic>> picosToShow = allPicos.take(4).toList();
  final int count = picosToShow.length;
  final bool shouldLoop = count >= 4;

  return Column(
    children: [
      SizedBox(
        height: 350,
        child: PageView.builder(
          itemCount: shouldLoop ? null : count,
          controller: PageController(
            viewportFraction: shouldLoop ? 0.85 : 0.9,
            initialPage: shouldLoop ? count * 100 : 0,
          ),
          physics: count > 1
              ? const BouncingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final int actualIndex = shouldLoop ? (index % count) : index;
            final Color cardColor = cardPalette[actualIndex % cardPalette.length];
            final double rightPadding = (!shouldLoop && actualIndex == count - 1) ? 0.0 : 10.0;

            final pico = picosToShow[actualIndex];
            final isDownloading = downloadingCrags.contains(pico['id']);

            VoidCallback? onTapCallback;
            if (isDownloading) {
              onTapCallback = null;
            } else {
              onTapCallback = () => onPicoSelect(pico);
            }
            
            double cardOpacity;
            if (isDownloading) {
              cardOpacity = 0.6;
            } else {
              cardOpacity = 1.0;
            }

            return GestureDetector(
              onTap: onTapCallback,
              child: Opacity(
                opacity: cardOpacity,
                child: buildPicoCard(pico, rightPadding, cardColor, isDownloading),
              ),
            );
          },
        ),
      ),
      if (count > 1)
        buildFooterInstructions('Deslize para ver seus downloads'),
    ],
  );
}

/// Constrói um cartão individual para um pico no carrossel.
Widget buildPicoCard(Map<String, dynamic> pico, double rightPadding, Color cardColor, bool isDownloading) {
  return Padding(
    padding: EdgeInsets.only(left: 10, right: rightPadding, top: 20, bottom: 20),
    child: Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              safeString(pico['nome'], fallback: 'Sem Nome'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: nobleBlack,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on, color: nobleBlack, size: 18),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    safeString(pico['local'], fallback: 'Local Desconhecido'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: nobleBlack.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (isDownloading)
              const Row(
                children: [
                   SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: nobleBlack, strokeWidth: 2)),
                   SizedBox(width: 8),
                   Text('BAIXANDO...', style: TextStyle(color: nobleBlack, fontSize: 12, fontWeight: FontWeight.bold)),
                ]
              )
            else
              buildVerGuiaButton(),
          ],
        ),
      ),
    ),
  );
}

/// Um pequeno botão no cartão para indicar que pode ser aberto.
Widget buildVerGuiaButton() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: nobleBlack.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Text(
      'VER GUIA',
      style: TextStyle(
        color: nobleBlack,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    ),
  );
}

/// Texto de instruções na parte inferior do carrossel.
Widget buildFooterInstructions(String text) {
  return Padding(
    padding: const EdgeInsets.all(20.0),
    child: Center(
      child: Text(
        text,
        style: const TextStyle(
          color: fishBone,
          fontStyle: FontStyle.italic,
          fontSize: 14,
        ),
      ),
    ),
  );
}
