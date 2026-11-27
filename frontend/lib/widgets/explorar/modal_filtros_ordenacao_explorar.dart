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

