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
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colors.rustIron,
            inactiveTrackColor: Colors.white12,
            thumbColor: colors.chalkWhite,
            overlayColor: colors.rustIron.withValues(alpha: 0.16),
          ),
          child: RangeSlider(
            values: RangeValues(idxMinBld.toDouble(), idxMaxBld.toDouble()),
            min: 0,
            max: (opcoesBld.length - 1).toDouble(),
            divisions: opcoesBld.length - 1,
            onChanged: (valores) {
              final iMin = valores.start.round();
              final iMax = valores.end.round();
              viewModel.definirFaixaGrauBoulder(
                iMin <= 0 ? null : opcoesBld[iMin].valor,
                iMax >= opcoesBld.length - 1 ? null : opcoesBld[iMax].valor,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Painel modal declarativo de `Filtros e Ordenação` da aba `Explorar` (Dumb UI).
class ModalFiltrosOrdenacaoExplorar extends StatelessWidget {
  final BrowseViewModel viewModel;

  const ModalFiltrosOrdenacaoExplorar({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final totalPicos = viewModel.picosFiltrados.length;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      context.tr(ChaveTexto.explorarFiltrosOrdenacao),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.chalkWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    key: const Key('botao_limpar_todos_filtros'),
                    onPressed: viewModel.limparTodosFiltros,
                    child: Text(
                      context.tr(ChaveTexto.comumLimpar),
                      style: TextStyle(
                        color: colors.rustIron,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: colors.graniteEdge, height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _tituloSecao(
                      colors,
                      context.tr(ChaveTexto.explorarOrdenacaoSecao),
                    ),
                    const SizedBox(height: 8),
                    _opcaoOrdenacao(
                      context,
                      context.tr(ChaveTexto.explorarMaisProximos),
                      OrdemOrdenacaoPico.proximidade,
                    ),
                    _opcaoOrdenacao(
                      context,
                      context.tr(ChaveTexto.explorarAlfabeticoAZ),
                      OrdemOrdenacaoPico.alfabetico,
                    ),
                    _opcaoOrdenacao(
                      context,
                      context.tr(ChaveTexto.explorarMaisEscaladas),
                      OrdemOrdenacaoPico.escaladas,
                    ),
                    const SizedBox(height: 16),
                    _tituloSecao(
                      colors,
                      context.tr(ChaveTexto.explorarModalidadesSecao),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ModalidadeExploracaoPico.values.map((mod) {
                        final ativo = viewModel.modalidadesAtivas.contains(mod);
                        return FilterChip(
                          selected: ativo,
                          label: Text(mod.rotulo),
                          selectedColor:
                              colors.rustIron.withValues(alpha: 0.28),
                          backgroundColor: colors.deepBasalt,
                          checkmarkColor: colors.rustIron,
                          side: BorderSide(
                            color: ativo ? colors.rustIron : Colors.white12,
                          ),
                          labelStyle: TextStyle(
                            color: ativo ? colors.chalkWhite : colors.ashGrey,
                            fontWeight:
                                ativo ? FontWeight.w700 : FontWeight.w500,
                          ),
                          onSelected: (_) => viewModel.alternarModalidade(mod),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    _tituloSecao(
                      colors,
                      context.tr(ChaveTexto.explorarDificuldadeSecao),
                    ),
                    const SizedBox(height: 10),
                    SecaoSlidersGrauExplorar(viewModel: viewModel),
                    const SizedBox(height: 12),
                    _tituloSecao(
                      colors,
                      context.tr(ChaveTexto.explorarAlcanceSecao),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          key: const Key('filtro_raio_150km'),
                          selected: viewModel.raioMaximoKm == 150.0,
                          label: Text(
                            context.tr(
                              ChaveTexto.explorarAteKm,
                              {'km': 150},
                            ),
                          ),
                          selectedColor:
                              colors.rustIron.withValues(alpha: 0.28),
                          backgroundColor: colors.deepBasalt,
                          checkmarkColor: colors.rustIron,
                          side: BorderSide(
                            color: viewModel.raioMaximoKm == 150.0
                                ? colors.rustIron
                                : Colors.white12,
                          ),
                          labelStyle: TextStyle(
                            color: viewModel.raioMaximoKm == 150.0
                                ? colors.chalkWhite
                                : colors.ashGrey,
                          ),
                          onSelected: (v) =>
                              viewModel.definirRaioMaximoKm(v ? 150.0 : null),
                        ),
                        FilterChip(
                          key: const Key('filtro_salvos_offline'),
                          selected: viewModel.apenasSalvosOffline,
                          label: Text(
                            context.tr(ChaveTexto.explorarSalvosOffline),
                          ),
                          selectedColor: colors.dryMoss.withValues(alpha: 0.30),
                          backgroundColor: colors.deepBasalt,
                          checkmarkColor: colors.dryMoss,
                          side: BorderSide(
                            color: viewModel.apenasSalvosOffline
                                ? colors.dryMoss
                                : Colors.white12,
                          ),
                          labelStyle: TextStyle(
                            color: viewModel.apenasSalvosOffline
                                ? colors.chalkWhite
                                : colors.ashGrey,
                          ),
                          onSelected: viewModel.definirApenasSalvosOffline,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: ElevatedButton(
                key: const Key('botao_aplicar_filtros_explorar'),
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.rustIron,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  context.tr(
                    ChaveTexto.explorarVerNPicos,
                    {'total': totalPicos},
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tituloSecao(AppColors colors, String texto) {
    return Text(
      texto,
      style: TextStyle(
        color: colors.rustIron,
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _opcaoOrdenacao(
    BuildContext context,
    String titulo,
    OrdemOrdenacaoPico ordem,
  ) {
    final selecionado = viewModel.ordem == ordem;
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => viewModel.alterarOrdem(ordem),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selecionado ? colors.rustIron : colors.chalkWhite,
                  fontSize: 14.5,
                  fontWeight: selecionado ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            if (selecionado)
              Icon(Icons.check_rounded, color: colors.rustIron, size: 19),
          ],
        ),
      ),
    );
  }
}
