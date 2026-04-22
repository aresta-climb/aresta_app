import 'package:flutter/material.dart';
import 'common_functions.dart';

/// Constrói a área de conteúdo principal para a página de Explorar (Browse).
///
/// Ela exibe uma barra de pesquisa e uma lista de picos disponíveis que podem ser baixados.
/// O callback [onSearchChanged] é acionado quando o usuário digita na barra de pesquisa.
/// O callback [onDownload] é acionado quando o usuário toca no botão de download em um item de pico.
Widget buildBrowseBody(
  BuildContext context, 
  List<Map<String, dynamic>> availableCrags, 
  {
    required ValueChanged<String> onSearchChanged,
    required Function(Map<String, dynamic>) onDownload,
  }
) {
  return Column(
    children: [
      const SizedBox(height: 10),
      buildSearchBar(onChanged: onSearchChanged),
      Expanded(
        child: _buildCragList(availableCrags, onDownload),
      ),
    ],
  );
}

/// Constrói a lista rolável de picos disponíveis.
///
/// Se [availableCrags] estiver vazio, exibe uma mensagem de fallback indicando que nenhum pico foi encontrado.
Widget _buildCragList(List<Map<String, dynamic>> availableCrags, Function(Map<String, dynamic>) onDownload) {
  if (availableCrags.isEmpty) {
    return const Center(
      child: Text(
        'Nenhum pico encontrado.',
        style: TextStyle(color: fishBone, fontSize: 16),
      ),
    );
  }

  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildBrowseSectionTitle('Picos Disponíveis'),
        const SizedBox(height: 20),
        ...availableCrags.map((crag) => buildCragListItem(crag, () => onDownload(crag))),
      ],
    ),
  );
}

/// Constrói um título de seção estilizado para a lista de exploração.
Widget buildBrowseSectionTitle(String title) {
  return Text(
    title,
    style: const TextStyle(
      color: fishBone,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  );
}

/// Constrói um item de lista individual representando um pico que pode ser baixado.
///
/// Inclui um ícone, o nome e localização do pico e um botão de download.
Widget buildCragListItem(Map<String, dynamic> crag, VoidCallback onDownload) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: fishBone.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildCragIcon(),
          const SizedBox(width: 16),
          _buildCragDetails(crag),
          _buildDownloadButton(onDownload),
        ],
      ),
    ),
  );
}

/// Constrói o ícone visual que lidera o item da lista de picos.
Widget _buildCragIcon() {
  // Ícone de montanha
  // TODO: Implementar imagem de capa em vez do ícone de montanha
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: beastHide.withValues(alpha: 0.2),
      shape: BoxShape.circle,
    ),
    child: const Icon(
      Icons.terrain,
      color: beastHide,
      size: 24,
    ),
  );
}

/// Constrói a coluna de detalhes textuais mostrando o nome e a localização do pico.
Widget _buildCragDetails(Map<String, dynamic> crag) {
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          safeString(crag['nome'], fallback: 'Sem Nome'),
          style: const TextStyle(
            color: fishBone,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          safeString(crag['local'], fallback: 'Local Desconhecido'),
          style: TextStyle(
            color: fishBone.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}

/// Constrói o botão final que inicia o download do pico.
Widget _buildDownloadButton(VoidCallback onPressed) {
  return IconButton(
    onPressed: onPressed,
    icon: const Icon(
      Icons.download_rounded,
      color: beastHide,
    ),
  );
}
