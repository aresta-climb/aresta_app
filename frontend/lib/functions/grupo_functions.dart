import 'package:flutter/material.dart';
import '../kmon_api/proto/croqui.pb.dart';
import 'common_functions.dart';
import 'pico_functions.dart';
import 'offline_markdown.dart';

/// Constrói o corpo rolável principal da página do Grupo.
///
/// Ele exibe as informações do grupo e uma lista de todos os grupos de setores (setores)
/// disponíveis dentro do pico.
Widget buildGrupoBody(BuildContext context, Grupo grupo, String cragId) {
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
        const SizedBox(height: 20),
        _buildHeader('Subsetores'),
        if (grupo.setores.isEmpty)
          const Text('Nenhum setor disponível.', style: TextStyle(color: fishBone))
        else
          ...grupo.setores.map((arquivoSetor) {
            // Renderiza apenas grupos que possuem conteúdo carregado
            if (arquivoSetor.hasConteudo()) {
              return buildSectorTile(context, arquivoSetor.conteudo, cragId);
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
      style: const TextStyle(
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
