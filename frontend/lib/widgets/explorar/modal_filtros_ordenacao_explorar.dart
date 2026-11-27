// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';

import '../../idioma/tradutor_app.dart';
import '../../theme/cores_app.dart';
import '../../utils/filtro_grau_escalada.dart';
import '../../view/view_models/explorar_view_model.dart';

/// Localiza o índice mais próximo em [opcoes] para [valorAlvo] (retornando [padrao] quando nulo).
int indiceParaValorGrauExplorar(
  List<OpcaoGrauFiltro> opcoes,
  int? valorAlvo, {
  required int padrao,
}) {
  if (valorAlvo == null) return padrao;
  var melhorIdx = padrao;
  var menorDif = 999999;
  for (var i = 0; i < opcoes.length; i++) {
    final dif = (opcoes[i].valor - valorAlvo).abs();
    if (dif < menorDif) {
      menorDif = dif;
      melhorIdx = i;
    }
  }
  return melhorIdx;
}

/// Formata uma faixa de graduação (`1º–12a` ou `V0–V15`) para exibição compacta em chips.
String formatarResumoGrauExplorar(
  List<OpcaoGrauFiltro> opcoes,
  int? minVal,
  int? maxVal,
) {
  final idxMin = indiceParaValorGrauExplorar(opcoes, minVal, padrao: 0);
  final idxMax = indiceParaValorGrauExplorar(
    opcoes,
    maxVal,
    padrao: opcoes.length - 1,
  );
  return '${opcoes[idxMin].rotulo}–${opcoes[idxMax].rotulo}';
}

/// Abre o painel modal deslizante completo de `Filtros e Ordenação` da aba `Explorar`.
Future<void> exibirModalFiltrosOrdenacaoExplorar({
  required BuildContext context,
  required BrowseViewModel viewModel,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: context.colors.caveShadow,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ListenableBuilder(
      listenable: viewModel,
      builder: (ctx, _) => ModalFiltrosOrdenacaoExplorar(viewModel: viewModel),
    ),
  );
}

/// Seção de controles `RangeSlider` para filtragem por grau de Via (sistema brasileiro) e Boulder (`V`).
class SecaoSlidersGrauExplorar extends StatelessWidget {
  final BrowseViewModel viewModel;

  const SecaoSlidersGrauExplorar({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final opcoesVia = OpcoesGrau.grausVia;
    final opcoesBld = OpcoesGrau.grausBoulder;

    final idxMinVia = indiceParaValorGrauExplorar(
      opcoesVia,
      viewModel.minGrauVia,
      padrao: 0,
    );
    final idxMaxVia = indiceParaValorGrauExplorar(
      opcoesVia,
      viewModel.maxGrauVia,
      padrao: opcoesVia.length - 1,
    );

    final idxMinBld = indiceParaValorGrauExplorar(
      opcoesBld,
      viewModel.minGrauBoulder,
      padrao: 0,
    );
    final idxMaxBld = indiceParaValorGrauExplorar(
      opcoesBld,
      viewModel.maxGrauBoulder,
      padrao: opcoesBld.length - 1,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr(ChaveTexto.explorarViasBrasileiro),
              style: TextStyle(
                color: colors.chalkWhite,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${opcoesVia[idxMinVia].rotulo} – ${opcoesVia[idxMaxVia].rotulo}',
              style: TextStyle(
                color: viewModel.temFiltroGrauVia
                    ? colors.rustIron
                    : colors.ashGrey,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colors.rustIron,
            inactiveTrackColor: Colors.white12,
            thumbColor: colors.chalkWhite,
            overlayColor: colors.rustIron.withValues(alpha: 0.16),
          ),
          child: RangeSlider(
            values: RangeValues(idxMinVia.toDouble(), idxMaxVia.toDouble()),
            min: 0,
            max: (opcoesVia.length - 1).toDouble(),
            divisions: opcoesVia.length - 1,
            onChanged: (valores) {
              final iMin = valores.start.round();
              final iMax = valores.end.round();
              viewModel.definirFaixaGrauVia(
                iMin <= 0 ? null : opcoesVia[iMin].valor,
                iMax >= opcoesVia.length - 1 ? null : opcoesVia[iMax].valor,
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr(ChaveTexto.explorarBoulderEscalaV),
              style: TextStyle(
                color: colors.chalkWhite,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${opcoesBld[idxMinBld].rotulo} – ${opcoesBld[idxMaxBld].rotulo}',
              style: TextStyle(
                color: viewModel.temFiltroGrauBoulder
                    ? colors.rustIron
                    : colors.ashGrey,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
