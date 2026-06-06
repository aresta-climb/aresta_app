import 'package:flutter/material.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../view_functions/common_functions.dart';
import '../view_functions/pico_functions.dart';
import '../view_functions/via_functions.dart';
import '../services/dataset_repository.dart';
import '../navigation/navigation_functions.dart';
import '../services/firebase/telemetry_service.dart';

/// Uma página que exibe informações detalhadas sobre um pico específico.
///
/// Ela apresenta a descrição do pico e lista todos os setores contidos nele.
class PicoDetailsPage extends StatefulWidget {
  final Pico pico;
  final Croqui croqui;
  final String cragId;
  final DatasetRepository datasetRepo;
  final bool scrollToMapaGeral;
  final Setor? returnToSetor;

  const PicoDetailsPage({
    super.key, 
    required this.pico,
    required this.croqui,
    required this.cragId,
    required this.datasetRepo,
    this.scrollToMapaGeral = false,
    this.returnToSetor,
  });

  @override
  State<PicoDetailsPage> createState() => _PicoDetailsPageState();
}

class _PicoDetailsPageState extends State<PicoDetailsPage> {
  final GlobalKey _mapaKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.scrollToMapaGeral) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _mapaKey.currentContext != null) {
          Scrollable.ensureVisible(
            _mapaKey.currentContext!,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            alignment: 0.1, // Scroll so the map is near the top
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String searchTooltip = 'Buscar via';
    if (isPicoBoulderArea(widget.pico)) {
      searchTooltip = 'Buscar boulder';
    }

    return Scaffold(
      backgroundColor: nobleBlack,
      appBar: buildCommonAppBar(context, 
        widget.pico.nome,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: nobleBlack),
            tooltip: searchTooltip,
            onPressed: () async {
              TelemetryService.instance.logAcaoCroqui(widget.cragId, 'buscar');
              final result = await showSearch<Escalada?>(
                context: context,
                delegate: ViaSearchDelegate(widget.pico, widget.cragId),
              );

              if (result != null && context.mounted) {
                final setor = findSetorForEscalada(widget.pico, result);
                if (setor != null) {
                  AppNav.toSetor(context, setor: setor, scrollToEscalada: result);
                }
                TelemetryService.instance.logAcaoEscalada(widget.cragId, setor?.nome ?? 'Geral', getEscaladaNome(result), 'abrir_detalhes', 'busca');
                AppNav.toVia(context, escalada: result, setor: setor);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: nobleBlack),
            tooltip: 'Excluir guia',
            onPressed: () async {
              TelemetryService.instance.logAcaoCroqui(widget.cragId, 'excluir');
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: nobleBlack,
                  title: Text('Excluir?', style: TextStyle(color: beastHide)),
                  content: Text('Deseja excluir o guia de ${widget.pico.nome}?', style: TextStyle(color: fishBone)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('CANCELAR', style: TextStyle(color: fishBone)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('EXCLUIR', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                final success = await widget.datasetRepo.deleteCrag(widget.cragId);
                if (context.mounted) {
                  AppNav.home(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Guia excluído com sucesso.' : 'Erro ao excluir guia.'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: buildPicoBody(context, widget.pico, widget.croqui, widget.cragId, _mapaKey),
      floatingActionButton: widget.returnToSetor != null ? FloatingActionButton.extended(
        onPressed: () {
          TelemetryService.instance.logAcaoCroqui(widget.cragId, 'voltar_mapa_setor');
          AppNav.toSetor(context, setor: widget.returnToSetor!);
          // Then immediately push the map!
          Future.delayed(const Duration(milliseconds: 300), () {
            if (context.mounted) {
              AppNav.toMapaInterativo(
                context,
                mapa: widget.returnToSetor!.mapas.first,
                cragId: widget.cragId,
                escaladas: widget.returnToSetor!.escaladas,
                setores: const [],
                setorContext: widget.returnToSetor,
              );
            }
          });
        },
        backgroundColor: beastHide,
        icon: Icon(Icons.map, color: nobleBlack),
        label: Text('Voltar para o Mapa do Setor', style: TextStyle(color: nobleBlack, fontWeight: FontWeight.bold)),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // bottomNavigationBar: buildSecondaryBottomNav(context),
    );
  }
}

