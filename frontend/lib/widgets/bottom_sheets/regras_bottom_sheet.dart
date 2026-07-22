import 'package:flutter/material.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../view_functions/offline_markdown.dart';
import '../../theme/app_colors.dart';

class RegrasBottomSheet extends StatelessWidget {
  final List<Botao> regrasBotoes;
  final String cragId;

  const RegrasBottomSheet({
    super.key,
    required this.regrasBotoes,
    required this.cragId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle for bottom sheet
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: context.colors.graniteEdge.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: context.colors.dryMoss,
                ),
                const SizedBox(width: 12),
                Text(
                  'REGRAS E RECOMENDAÇÕES',
                  style: TextStyle(
                    color: context.colors.fishBone,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (regrasBotoes.isEmpty)
                      Text(
                        'Nenhuma regra específica cadastrada para este local. Por favor, siga as normas de conduta ética e ambiental padrão.',
                        style: TextStyle(
                          color: context.colors.fishBone.withValues(alpha: 0.8),
                        ),
                      )
                    else
                      ...regrasBotoes.map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: OfflineMarkdown(
                            data: b.destino.secaoTextual.conteudo,
                            cragId: cragId,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Back Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.graniteEdge.withValues(
                    alpha: 0.1,
                  ),
                  foregroundColor: context.colors.fishBone,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'VOLTAR',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showRegrasBottomSheet(
  BuildContext context,
  List<Botao> regrasBotoes,
  String cragId,
) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.85,
      child: RegrasBottomSheet(regrasBotoes: regrasBotoes, cragId: cragId),
    ),
  );
}
