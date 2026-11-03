// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../data/modelos/cadena.dart';
import '../../services/caderneta/estatisticas_caderneta.dart';
import '../../theme/cores_app.dart';
import '../../widgets/caderneta/card_estatistica.dart';

/// Constrói o painel de resumo estatístico da caderneta com 4 cartões em grade 2x2.
Widget buildPainelResumoEstatisticas(EstatisticasCaderneta estatisticas) {
  return PainelResumoEstatisticasCaderneta(estatisticas: estatisticas);
}

/// Seção declarativa (Dumb UI) que exibe o título do histórico de ascensões e a lista
/// de cartões [ItemHistoricoCadena] ou o estado vazio [EstadoVazioHistoricoCaderneta].
class SecaoHistoricoCadenas extends StatelessWidget {
  /// Título já formatado da seção (ex.: `'Histórico de Ascensões (3)'`).
  final String tituloSecao;

  /// Lista de ascensões a serem renderizadas.
  final List<Cadena> historico;

  /// Resolvedor do nome legível da via para cada `escaladaUid`.
  final String Function(String escaladaUid) obterNomeVia;

  /// Resolvedor opcional da graduação da via para cada `escaladaUid`.
  final String? Function(String escaladaUid) obterGrauVia;

  /// Formatador do subtítulo descritivo de cada [Cadena].
  final String Function(Cadena cadena) formatarSubtitulo;

  /// Formatador opcional da citação de notas privadas de cada [Cadena].
  final String? Function(Cadena cadena) formatarCitacaoNotas;

  /// Callback acionado ao solicitar a exclusão de uma [Cadena].
  final ValueChanged<Cadena> onExcluirCadena;

  /// Callback opcional acionado ao solicitar a edição de uma [Cadena].
  final ValueChanged<Cadena>? onEditarCadena;

  /// Callback opcional acionado ao tocar no card para abrir a página da via.
  final ValueChanged<Cadena>? onTocarVia;

  const SecaoHistoricoCadenas({
    super.key,
    required this.tituloSecao,
    required this.historico,
    required this.obterNomeVia,
    required this.obterGrauVia,
    required this.formatarSubtitulo,
    required this.formatarCitacaoNotas,
    required this.onExcluirCadena,
    this.onEditarCadena,
    this.onTocarVia,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tituloSecao,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: cores.chalkWhite,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (historico.isEmpty)
          const EstadoVazioHistoricoCaderneta()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: historico.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final cadena = historico[index];
              return ItemHistoricoCadena(
                cadena: cadena,
                nomeVia: obterNomeVia(cadena.escaladaUid),
                grauVia: obterGrauVia(cadena.escaladaUid),
                subtituloFormatado: formatarSubtitulo(cadena),
                citacaoNotas: formatarCitacaoNotas(cadena),
                onExcluir: () => onExcluirCadena(cadena),
                onEditar: onEditarCadena != null
                    ? () => onEditarCadena!(cadena)
                    : null,
                onTocarVia: onTocarVia != null
                    ? () => onTocarVia!(cadena)
                    : null,
              );
            },
          ),
      ],
    );
  }
}

/// Constrói a seção de histórico cronológico de ascensões ou o estado vazio informativo.
Widget buildSecaoHistoricoCadenas(
  BuildContext context, {
  required List<Cadena> historico,
  required String Function(String escaladaUid) obterNomeVia,
  required String? Function(String escaladaUid) obterGrauVia,
  required String Function(DateTime data) formatarData,
  required ValueChanged<Cadena> onExcluirCadena,
  ValueChanged<Cadena>? onEditarCadena,
  ValueChanged<Cadena>? onTocarVia,
  String? tituloSecao,
  String Function(Cadena cadena)? formatarSubtitulo,
  String? Function(Cadena cadena)? formatarCitacaoNotas,
}) {
  return SecaoHistoricoCadenas(
    tituloSecao: tituloSecao ?? 'Histórico de Ascensões (${historico.length})',
    historico: historico,
    obterNomeVia: obterNomeVia,
    obterGrauVia: obterGrauVia,
    formatarSubtitulo:
        formatarSubtitulo ??
        (cadena) =>
            '${formatarData(cadena.dataAscensao)} • ${cadena.tipoEscalada.rotulo} • ${cadena.tentativas} ${cadena.tentativas == 1 ? 'tentativa' : 'tentativas'}',
    formatarCitacaoNotas:
        formatarCitacaoNotas ??
        (cadena) =>
            cadena.notasPrivadas.isNotEmpty ? '“${cadena.notasPrivadas}”' : null,
    onExcluirCadena: onExcluirCadena,
    onEditarCadena: onEditarCadena,
    onTocarVia: onTocarVia,
  );
}

/// Card informativo (Dumb UI) exibido quando não há ascensões registradas na caderneta.
class EstadoVazioHistoricoCaderneta extends StatelessWidget {
  const EstadoVazioHistoricoCaderneta({super.key});

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: cores.caveShadow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cores.graniteEdge),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cores.deepBasalt,
            ),
            child: Icon(
              Icons.menu_book_outlined,
              color: cores.ashGrey,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhuma ascensão registrada ainda',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cores.chalkWhite,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Suas cadenas salvas nas páginas das vias aparecerão aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cores.ashGrey, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Constrói o card informativo exibido quando não há ascensões registradas.
Widget buildEstadoVazioHistorico(BuildContext context) {
  return const EstadoVazioHistoricoCaderneta();
}

/// Card individual (Dumb UI) de exibição de uma ascensão esportiva no histórico.
class ItemHistoricoCadena extends StatelessWidget {
  /// Registro da ascensão exibida.
  final Cadena cadena;

  /// Nome legível da via ou boulder.
  final String nomeVia;

  /// Graduação esportiva opcional da via ou boulder.
  final String? grauVia;

  /// Subtítulo já formatado com data, estilo e número de tentativas.
  final String subtituloFormatado;

  /// Citação opcional de notas privadas já formatada para exibição.
  final String? citacaoNotas;

  /// Callback acionado ao tocar no botão de exclusão.
  final VoidCallback onExcluir;

  /// Callback opcional acionado ao tocar no botão de edição.
  final VoidCallback? onEditar;

  /// Callback opcional acionado ao tocar no card para abrir a via.
  final VoidCallback? onTocarVia;

  const ItemHistoricoCadena({
    super.key,
    required this.cadena,
    required this.nomeVia,
    this.grauVia,
    required this.subtituloFormatado,
    this.citacaoNotas,
    required this.onExcluir,
    this.onEditar,
    this.onTocarVia,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('item_historico_cadena_${cadena.id}'),
        onTap: onTocarVia,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cores.caveShadow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cores.graniteEdge),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cadena.isCadena
                      ? cores.fernGreen.withValues(alpha: 0.2)
                      : cores.rustIron.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cadena.tipoAscensao.rotulo,
                  style: TextStyle(
                    color: cadena.isCadena ? cores.fernGreen : cores.rustIron,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            nomeVia,
                            style: TextStyle(
                              color: cores.chalkWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (grauVia != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cores.deepBasalt,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              grauVia!,
                              style: TextStyle(
                                color: cores.rustIron,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtituloFormatado,
                      style: TextStyle(color: cores.ashGrey, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (citacaoNotas != null && citacaoNotas!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        citacaoNotas!,
                        style: TextStyle(
                          color: cores.ashGrey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEditar != null)
                    IconButton(
                      key: Key('btn_editar_cadena_${cadena.id}'),
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: cores.ashGrey,
                      ),
                      tooltip: 'Editar ascensão',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: onEditar,
                    ),
                  IconButton(
                    key: Key('btn_excluir_cadena_${cadena.id}'),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: cores.ashGrey,
                    ),
                    tooltip: 'Excluir ascensão',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: onExcluir,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Constrói o card individual de exibição de uma ascensão esportiva no histórico.
Widget buildItemHistoricoCadena(
  BuildContext context, {
  required Cadena cadena,
  required String nomeVia,
  String? grauVia,
  required String dataFormatada,
  required VoidCallback onExcluir,
  VoidCallback? onEditar,
  VoidCallback? onTocarVia,
  String? subtituloFormatado,
  String? citacaoNotas,
}) {
  return ItemHistoricoCadena(
    cadena: cadena,
    nomeVia: nomeVia,
    grauVia: grauVia,
    subtituloFormatado:
        subtituloFormatado ??
        '$dataFormatada • ${cadena.tipoEscalada.rotulo} • ${cadena.tentativas} ${cadena.tentativas == 1 ? 'tentativa' : 'tentativas'}',
    citacaoNotas:
        citacaoNotas ??
        (cadena.notasPrivadas.isNotEmpty ? '“${cadena.notasPrivadas}”' : null),
    onExcluir: onExcluir,
    onEditar: onEditar,
    onTocarVia: onTocarVia,
  );
}

/// Diálogo declarativo (Dumb UI) de confirmação para exclusão permanente de uma ascensão.
class DialogoConfirmarExclusaoCadena extends StatelessWidget {
  const DialogoConfirmarExclusaoCadena({super.key});

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return AlertDialog(
      backgroundColor: cores.deepBasalt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cores.graniteEdge),
      ),
      title: Text(
        'Excluir Ascensão?',
        style: TextStyle(color: cores.chalkWhite, fontWeight: FontWeight.bold),
      ),
      content: Text(
        'Esta ação removerá este registro esportivo permanentemente da sua caderneta.',
        style: TextStyle(color: cores.ashGrey, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancelar', style: TextStyle(color: cores.ashGrey)),
        ),
        ElevatedButton(
          key: const Key('btn_confirmar_exclusao'),
          style: ElevatedButton.styleFrom(
            backgroundColor: cores.rustIron,
            foregroundColor: cores.chalkWhite,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Excluir'),
        ),
      ],
    );
  }
}

/// Exibe o diálogo de confirmação para exclusão permanente de uma ascensão esportiva.
Future<bool?> exibirDialogoConfirmarExclusao(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (_) => const DialogoConfirmarExclusaoCadena(),
  );
}
