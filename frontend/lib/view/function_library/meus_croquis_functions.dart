// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../view_models/card_croqui_view_model.dart';
import '../../theme/cores_app.dart';
import '../../widgets/provedor_imagem_aresta.dart';

/// Card interativo para exibição de um croqui baixado na aba Meus Croquis a partir de [CardCroquiViewModel] (Dumb UI).
///
/// Não contém regras de negócio ou de persistência de dados, apenas renderiza visualmente
/// as informações já preparadas e delega ações do usuário via callbacks.
class OfflineCragCard extends StatelessWidget {
  final CardCroquiViewModel dados;
  final VoidCallback onAbrir;
  final VoidCallback onExcluir;

  const OfflineCragCard({
    super.key,
    required this.dados,
    required this.onAbrir,
    required this.onExcluir,
  });

  /// Construtor de conveniência que recebe diretamente a entidade [Croqui] e mapeia para [CardCroquiViewModel].
  factory OfflineCragCard.deCroqui({
    Key? key,
    required Croqui crag,
    required VoidCallback onAbrir,
    required VoidCallback onExcluir,
  }) {
    return OfflineCragCard(
      key: key,
      dados: mapearCroquiParaCard(crag),
      onAbrir: onAbrir,
      onExcluir: onExcluir,
    );
  }

  /// Constrói a capa padrão com a logo do Aresta preenchendo 100% do espaço sobre fundo preto.
  /// Usado exclusivamente quando o croqui não possui miniatura declarada no Protobuf.
  Widget _construirCapaPadraoAresta() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.black,
      child: Image.asset(
        'assets/logo_in_app.jpg',
        fit: BoxFit.contain,
        width: 60,
        height: 60,
      ),
    );
  }

  /// Constrói o container com ícone de imagem indisponível ([Icons.broken_image]).
  /// Usado quando o croqui possui miniatura declarada no Protobuf mas ela não foi baixada ou falhou.
  Widget _construirImagemIndisponivel(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      color: context.colors.graniteEdge,
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey,
          size: 24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String id = dados.id;
    final String nome = dados.titulo;
    final String local = dados.localizacao;
    final String statsText = dados.textoEstatisticas;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.colors.caveShadow,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Miniatura unificada com downsampling para 300px via ProvedorImagemAresta
              // com capa padrão do Aresta quando ausente no protobuf ou broken_image se falhar o carregamento
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 60,
                  height: 60,
                  color: context.colors.graniteEdge,
                  child: dados.caminhoMiniatura.trim().isEmpty
                      ? _construirCapaPadraoAresta()
                      : FutureBuilder<ImageProvider?>(
                          future: ProvedorImagemAresta.resolver(
                            picoId: id,
                            caminho: dados.caminhoMiniatura,
                            checksumSha256: dados.checksumSha256,
                            larguraAlvo: 300,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Container(
                                width: 60,
                                height: 60,
                                color: context.colors.graniteEdge,
                              );
                            }
                            if (snapshot.hasData && snapshot.data != null) {
                              return Image(
                                image: snapshot.data!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _construirImagemIndisponivel(context),
                              );
                            }
                            return _construirImagemIndisponivel(context);
                          },
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      local,
                      style: TextStyle(
                        color: context.colors.dryMoss,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      statsText,
                      style: TextStyle(
                        color: context.colors.ashGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onAbrir,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC04F34),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text(
                    'ABRIR OFFLINE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildIconButton(
                context,
                icon: Icons.delete_outline,
                onPressed: onExcluir,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: context.colors.graniteEdge),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: context.colors.ashGrey, size: 20),
        onPressed: onPressed,
      ),
    );
  }
}
