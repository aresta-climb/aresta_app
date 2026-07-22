import 'package:flutter/material.dart';
import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../view_functions/pico_functions.dart';
import '../../view_functions/common_functions.dart';
import '../../widgets/pico_menu_card.dart';
import '../../theme/app_colors.dart';
import '../../navigation/navigation_functions.dart';
import '../../navigation/navigation_tree.dart';

class SetoresPage extends StatelessWidget {
  final Pico pico;
  final String cragId;

  const SetoresPage({super.key, required this.pico, required this.cragId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: buildCommonAppBar(context, 'SETORES', subtitle: pico.nome),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pico.hasMapasGerais() &&
                pico.mapasGerais.hasConteudo() &&
                pico.mapasGerais.conteudo.mapas.isNotEmpty) ...[
              PicoMenuCard(
                title: 'Mapas gerais',
                subtitle:
                    'Visualização cartográfica, setores físicos e panorama das paredes.',
                icon: Icons.map,
                iconColor: context.colors.rustIron,
                backgroundColor: context.colors.caveShadow,
                titleColor: context.colors.chalkWhite,
                subtitleColor: context.colors.chalkWhite.withValues(alpha: 0.7),
                onTap: () {
                  AppNav.toMapas(
                    context,
                    cragId: cragId,
                    mapas: pico.mapasGerais.conteudo.mapas
                        .map(
                          (mapa) => CarrosselItemData(
                            mapaCaminhoImagem: mapa.caminhoImagemMapa,
                            setorContextNome: pico.nome,
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            if (pico.setoresOuGrupos.isEmpty)
              Text(
                'Nenhum elemento disponível.',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              )
            else
              ...pico.setoresOuGrupos.map((setorOuGrupo) {
                if (setorOuGrupo.whichTipo() == SetorOuGrupo_Tipo.setor &&
                    setorOuGrupo.setor.hasConteudo()) {
                  return buildSectorTile(
                    context,
                    setorOuGrupo.setor.conteudo,
                    cragId,
                  );
                } else if (setorOuGrupo.whichTipo() ==
                        SetorOuGrupo_Tipo.grupo &&
                    setorOuGrupo.grupo.hasConteudo()) {
                  return buildGrupoTile(
                    context,
                    setorOuGrupo.grupo.conteudo,
                    cragId,
                  );
                }
                return const SizedBox.shrink();
              }),
          ],
        ),
      ),
    );
  }
}
