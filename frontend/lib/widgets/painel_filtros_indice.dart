// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../services/firebase/telemetry_service.dart';
import '../theme/app_colors.dart';
import '../utils/filtro_grau_escalada.dart';

/// Painel expansível e colapsável (*expando*) para controle de filtros
/// do Índice de Escaladas, com RangeSlider para graus, seletores dropdown
/// que empilham chips removíveis para setores e conquistadores, e filtro de clássicas.
class PainelFiltrosIndice extends StatefulWidget {
  /// Identificador do croqui/pico para eventos de telemetria.
  final String? cragId;

  /// O estado atual dos filtros ativos.
  final EstadoFiltrosIndice estado;

  /// A modalidade de escalada selecionada na aba ativa (ex: 'Esportiva', 'Boulder').
  final String modalidade;

  /// Lista com os nomes dos setores disponíveis para a modalidade ativa.
  final List<String> setoresDisponiveis;

  /// Lista com os nomes dos conquistadores disponíveis para a modalidade ativa.
  final List<String> conquistadoresDisponiveis;

  /// Indica se a modalidade possui conquistadores cadastrados em suas escaladas.
  final bool? possuiConquistadores;

  /// Indica se há escaladas clássicas disponíveis dentro dos filtros atuais.
  final bool temClassicasDisponiveis;

  /// Callback emitido sempre que o usuário alterar qualquer critério de filtragem.
  final ValueChanged<EstadoFiltrosIndice> onFiltrosChanged;

  /// Se o painel deve ser aberto expandido inicialmente.
  final bool inicialmenteExpandido;

  const PainelFiltrosIndice({
    super.key,
    this.cragId,
    required this.estado,
    required this.modalidade,
    required this.setoresDisponiveis,
    required this.conquistadoresDisponiveis,
    this.possuiConquistadores,
    this.temClassicasDisponiveis = true,
    required this.onFiltrosChanged,
    this.inicialmenteExpandido = false,
  });

  @override
  State<PainelFiltrosIndice> createState() => _PainelFiltrosIndiceState();
}

class _PainelFiltrosIndiceState extends State<PainelFiltrosIndice> {
  late bool _expandido;

  void _logTelemetria(String acao, {String? detalhe}) {
    if (widget.cragId != null && widget.cragId!.isNotEmpty) {
      TelemetryService.instance.logAcaoIndiceEscaladas(
        widget.cragId!,
        acao,
        modalidade: widget.modalidade,
        detalhe: detalhe,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _expandido = widget.inicialmenteExpandido;
  }

  int _contarFiltrosAtivos() {
    int total = 0;
    if (widget.estado.minGrauValor != null || widget.estado.maxGrauValor != null) {
      total++;
    }
    total += widget.estado.setores.length;
    total += widget.estado.conquistadores.length;
    if (widget.estado.apenasClassicas) {
      total++;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final totalAtivos = _contarFiltrosAtivos();
    final temConquistadoresCadastrados = widget.possuiConquistadores ??
        (widget.conquistadoresDisponiveis.isNotEmpty ||
            widget.estado.conquistadores.isNotEmpty);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.caveShadow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: totalAtivos > 0
              ? colors.rustIron.withValues(alpha: 0.5)
              : colors.graniteEdge,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho acionável (colapsa / expande)
          InkWell(
            onTap: () {
              final novoExpandido = !_expandido;
              _logTelemetria(
                novoExpandido ? 'expandir_filtros' : 'colapsar_filtros',
              );
              setState(() {
                _expandido = novoExpandido;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 20,
                    color: totalAtivos > 0 ? colors.rustIron : colors.chalkWhite,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filtros',
                    style: TextStyle(
                      color: colors.chalkWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (_expandido && totalAtivos > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.rustIron.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colors.rustIron.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '$totalAtivos ativo${totalAtivos > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: colors.rustIron,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    _expandido ? Icons.expand_less : Icons.expand_more,
                    color: colors.ashGrey,
                  ),
                ],
              ),
            ),
          ),

          // Chips com os filtros ativos visíveis quando colapsado
          if (!_expandido && totalAtivos > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _buildChipsFiltrosAtivos(context),
            ),

          // Conteúdo detalhado quando expandido
          if (_expandido) ...[
            Divider(height: 1, color: colors.graniteEdge),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 380,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. RangeSlider de Grau
                    _buildSliderGrau(context),

                  const SizedBox(height: 16),

                  // 2. Setor (Dropdown + Wrap de Chips)
                  _buildSecaoTitulo(context, 'Localização (Setores)'),
                  const SizedBox(height: 8),
                  _buildSeletorSetores(context),

                  // 3. Conquistadores (Dropdown + Wrap de Chips)
                  if (temConquistadoresCadastrados) ...[
                    const SizedBox(height: 16),
                    _buildSecaoTitulo(context, 'Conquista (Autores)'),
                    const SizedBox(height: 8),
                    _buildSeletorConquistadores(context),
                  ],

                  if (widget.temClassicasDisponiveis || totalAtivos > 0) ...[
                    const SizedBox(height: 16),

                    // 4. Apenas Clássicas e Botão Limpar
                    Row(
                      children: [
                        if (widget.temClassicasDisponiveis)
                          FilterChip(
                            selected: widget.estado.apenasClassicas,
                            label: Text(
                              'Apenas Clássicas (★)',
                              style: TextStyle(
                                color: widget.estado.apenasClassicas
                                    ? colors.deepBasalt
                                    : colors.chalkWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            selectedColor: Colors.amber,
                            backgroundColor: colors.deepBasalt,
                            side: BorderSide(
                              color: widget.estado.apenasClassicas
                                  ? Colors.amber
                                  : colors.graniteEdge,
                            ),
                            onSelected: (selecionado) {
                              _logTelemetria(
                                'filtrar_classicas',
                                detalhe: selecionado ? 'true' : 'false',
                              );
                              widget.onFiltrosChanged(
                                widget.estado.copyWith(apenasClassicas: selecionado),
                              );
                            },
                          ),
                        const Spacer(),
                        if (totalAtivos > 0)
                          TextButton.icon(
                            onPressed: () {
                              _logTelemetria('limpar_filtros');
                              widget.onFiltrosChanged(
                                const EstadoFiltrosIndice(),
                              );
                            },
                            icon: Icon(Icons.clear, size: 16, color: colors.ashGrey),
                            label: Text(
                              'Limpar',
                              style: TextStyle(
                                color: colors.ashGrey,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        ],
      ),
    );
  }

  /// Renderiza os chips de filtros ativos quando o painel está colapsado.
  Widget _buildChipsFiltrosAtivos(BuildContext context) {
    final colors = context.colors;
    final chips = <Widget>[];

    // Chip de Faixa de Grau
    if (widget.estado.minGrauValor != null || widget.estado.maxGrauValor != null) {
      final opcoes = OpcoesGrau.opcoesParaModalidade(widget.modalidade);
      final maxIndex = opcoes.length - 1;
      int startIdx = 0;
      if (widget.estado.minGrauValor != null) {
        final idx = opcoes.indexWhere((o) => o.valor >= widget.estado.minGrauValor!);
        if (idx != -1) startIdx = idx;
      }
      int endIdx = maxIndex;
      if (widget.estado.maxGrauValor != null) {
        final idx = opcoes.lastIndexWhere((o) => o.valor <= widget.estado.maxGrauValor!);
        if (idx != -1) endIdx = idx;
      }
      if (startIdx > endIdx) startIdx = endIdx;

      final rotulo = startIdx == endIdx
          ? opcoes[startIdx].rotulo
          : '${opcoes[startIdx].rotulo} a ${opcoes[endIdx].rotulo}';

      chips.add(
        Chip(
          label: Text(
            rotulo,
            style: TextStyle(color: colors.chalkWhite, fontSize: 12),
          ),
          backgroundColor: colors.rustIron.withValues(alpha: 0.3),
          side: BorderSide(color: colors.rustIron),
          deleteIcon: Icon(Icons.close, size: 16, color: colors.chalkWhite),
          onDeleted: () {
            _logTelemetria('filtrar_grau', detalhe: 'Todos os graus');
            widget.onFiltrosChanged(
              widget.estado.copyWith(
                clearMinGrau: true,
                clearMaxGrau: true,
              ),
            );
          },
        ),
      );
    }

    // Chips de Setores
    for (final s in widget.estado.setores) {
      chips.add(
        Chip(
          label: Text(
            s,
            style: TextStyle(color: colors.chalkWhite, fontSize: 12),
          ),
          backgroundColor: colors.rustIron.withValues(alpha: 0.3),
          side: BorderSide(color: colors.rustIron),
          deleteIcon: Icon(Icons.close, size: 16, color: colors.chalkWhite),
          onDeleted: () {
            _logTelemetria('filtrar_setor', detalhe: s);
            final novos = Set<String>.from(widget.estado.setores)..remove(s);
            widget.onFiltrosChanged(widget.estado.copyWith(setores: novos));
          },
        ),
      );
    }

    // Chips de Conquistadores
    for (final c in widget.estado.conquistadores) {
      chips.add(
        Chip(
          label: Text(
            c,
            style: TextStyle(color: colors.chalkWhite, fontSize: 12),
          ),
          backgroundColor: colors.rustIron.withValues(alpha: 0.3),
          side: BorderSide(color: colors.rustIron),
          deleteIcon: Icon(Icons.close, size: 16, color: colors.chalkWhite),
          onDeleted: () {
            _logTelemetria('filtrar_conquistador', detalhe: c);
            final novos = Set<String>.from(widget.estado.conquistadores)..remove(c);
            widget.onFiltrosChanged(widget.estado.copyWith(conquistadores: novos));
          },
        ),
      );
    }

    // Chip de Apenas Clássicas
    if (widget.estado.apenasClassicas) {
      chips.add(
        Chip(
          label: const Text(
            'Clássicas (★)',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.amber.withValues(alpha: 0.15),
          side: const BorderSide(color: Colors.amber),
          deleteIcon: const Icon(Icons.close, size: 16, color: Colors.amber),
          onDeleted: () {
            _logTelemetria('filtrar_classicas', detalhe: 'false');
            widget.onFiltrosChanged(
              widget.estado.copyWith(apenasClassicas: false),
            );
          },
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _buildSecaoTitulo(BuildContext context, String titulo) {
    return Text(
      titulo,
      style: TextStyle(
        color: context.colors.ashGrey,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSliderGrau(BuildContext context) {
    final colors = context.colors;
    final opcoes = OpcoesGrau.opcoesParaModalidade(widget.modalidade);
    final maxIndex = opcoes.length - 1;

    int startIdx = 0;
    if (widget.estado.minGrauValor != null) {
      final idx = opcoes.indexWhere((o) => o.valor >= widget.estado.minGrauValor!);
      if (idx != -1) startIdx = idx;
    }

    int endIdx = maxIndex;
    if (widget.estado.maxGrauValor != null) {
      final idx = opcoes.lastIndexWhere((o) => o.valor <= widget.estado.maxGrauValor!);
      if (idx != -1) endIdx = idx;
    }

    // Garante que startIdx <= endIdx
    if (startIdx > endIdx) startIdx = endIdx;

    final bool cobreTudo = startIdx == 0 && endIdx == maxIndex;
    final String textoRotulo;
    if (cobreTudo) {
      textoRotulo = 'Todos os graus';
    } else if (startIdx == endIdx) {
      textoRotulo = 'Grau: ${opcoes[startIdx].rotulo}';
    } else {
      textoRotulo = 'Grau: ${opcoes[startIdx].rotulo} a ${opcoes[endIdx].rotulo}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSecaoTitulo(context, 'Faixa de Grau'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cobreTudo
                    ? colors.graniteEdge
                    : colors.rustIron.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: cobreTudo ? colors.ashGrey : colors.rustIron,
                ),
              ),
              child: Text(
                textoRotulo,
                style: TextStyle(
                  color: cobreTudo ? colors.ashGrey : colors.rustIron,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        RangeSlider(
          values: RangeValues(startIdx.toDouble(), endIdx.toDouble()),
          min: 0,
          max: maxIndex.toDouble(),
          divisions: maxIndex > 0 ? maxIndex : 1,
          activeColor: colors.rustIron,
          inactiveColor: colors.graniteEdge,
          labels: RangeLabels(
            opcoes[startIdx].rotulo,
            opcoes[endIdx].rotulo,
          ),
          onChangeEnd: (novos) {
            final s = novos.start.round();
            final e = novos.end.round();
            final rotulo = (s == 0 && e == maxIndex)
                ? 'Todos os graus'
                : (s == e
                    ? opcoes[s].rotulo
                    : '${opcoes[s].rotulo} a ${opcoes[e].rotulo}');
            _logTelemetria('filtrar_grau', detalhe: rotulo);
          },
          onChanged: (novos) {
            final s = novos.start.round();
            final e = novos.end.round();

            if (s == 0 && e == maxIndex) {
              widget.onFiltrosChanged(
                widget.estado.copyWith(
                  clearMinGrau: true,
                  clearMaxGrau: true,
                ),
              );
            } else {
              widget.onFiltrosChanged(
                widget.estado.copyWith(
                  minGrauValor: opcoes[s].valor,
                  maxGrauValor: opcoes[e].valor,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildSeletorSetores(BuildContext context) {
    final colors = context.colors;
    final disponiveis = widget.setoresDisponiveis
        .where((s) => !widget.estado.setores.contains(s))
        .toList();

    final String hintTexto;
    if (disponiveis.isNotEmpty) {
      hintTexto = 'Adicionar setor...';
    } else if (widget.estado.setores.isNotEmpty) {
      hintTexto = 'Todos os setores adicionados';
    } else {
      hintTexto = 'Nenhum setor nos filtros atuais';
    }

    final bool habilitado = disponiveis.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colors.deepBasalt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: habilitado
                  ? colors.graniteEdge
                  : colors.graniteEdge.withValues(alpha: 0.5),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: null,
              hint: Text(
                hintTexto,
                style: TextStyle(
                  color: habilitado
                      ? colors.ashGrey
                      : colors.ashGrey.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              disabledHint: Text(
                hintTexto,
                style: TextStyle(
                  color: colors.ashGrey.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              dropdownColor: colors.deepBasalt,
              icon: Icon(
                Icons.arrow_drop_down,
                color: habilitado
                    ? colors.ashGrey
                    : colors.ashGrey.withValues(alpha: 0.4),
              ),
              style: TextStyle(color: colors.chalkWhite, fontSize: 13),
              items: habilitado
                  ? disponiveis.map((s) {
                      return DropdownMenuItem<String>(
                        value: s,
                        child: Text(s, overflow: TextOverflow.ellipsis),
                      );
                    }).toList()
                  : null,
              onChanged: habilitado
                  ? (novo) {
                      if (novo != null) {
                        _logTelemetria('filtrar_setor', detalhe: novo);
                        final novos = Set<String>.from(widget.estado.setores)
                          ..add(novo);
                        widget.onFiltrosChanged(
                          widget.estado.copyWith(setores: novos),
                        );
                      }
                    }
                  : null,
            ),
          ),
        ),
        if (widget.estado.setores.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.estado.setores.map((s) {
              return Chip(
                label: Text(
                  s,
                  style: TextStyle(color: colors.chalkWhite, fontSize: 12),
                ),
                backgroundColor: colors.rustIron.withValues(alpha: 0.3),
                side: BorderSide(color: colors.rustIron),
                deleteIcon: Icon(Icons.close, size: 16, color: colors.chalkWhite),
                onDeleted: () {
                  _logTelemetria('filtrar_setor', detalhe: s);
                  final novos = Set<String>.from(widget.estado.setores)..remove(s);
                  widget.onFiltrosChanged(widget.estado.copyWith(setores: novos));
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSeletorConquistadores(BuildContext context) {
    final colors = context.colors;
    final disponiveis = widget.conquistadoresDisponiveis
        .where((c) => !widget.estado.conquistadores.contains(c))
        .toList();

    final String hintTexto;
    if (disponiveis.isNotEmpty) {
      hintTexto = 'Adicionar conquistador...';
    } else if (widget.estado.conquistadores.isNotEmpty) {
      hintTexto = 'Todos os conquistadores adicionados';
    } else {
      hintTexto = 'Nenhum conquistador nos filtros atuais';
    }

    final bool habilitado = disponiveis.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colors.deepBasalt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: habilitado
                  ? colors.graniteEdge
                  : colors.graniteEdge.withValues(alpha: 0.5),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: null,
              hint: Text(
                hintTexto,
                style: TextStyle(
                  color: habilitado
                      ? colors.ashGrey
                      : colors.ashGrey.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              disabledHint: Text(
                hintTexto,
                style: TextStyle(
                  color: colors.ashGrey.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              dropdownColor: colors.deepBasalt,
              icon: Icon(
                Icons.arrow_drop_down,
                color: habilitado
                    ? colors.ashGrey
                    : colors.ashGrey.withValues(alpha: 0.4),
              ),
              style: TextStyle(color: colors.chalkWhite, fontSize: 13),
              items: habilitado
                  ? disponiveis.map((c) {
                      return DropdownMenuItem<String>(
                        value: c,
                        child: Text(c, overflow: TextOverflow.ellipsis),
                      );
                    }).toList()
                  : null,
              onChanged: habilitado
                  ? (novo) {
                      if (novo != null) {
                        _logTelemetria('filtrar_conquistador', detalhe: novo);
                        final novos = Set<String>.from(widget.estado.conquistadores)
                          ..add(novo);
                        widget.onFiltrosChanged(
                          widget.estado.copyWith(conquistadores: novos),
                        );
                      }
                    }
                  : null,
            ),
          ),
        ),
        if (widget.estado.conquistadores.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.estado.conquistadores.map((c) {
              return Chip(
                label: Text(
                  c,
                  style: TextStyle(color: colors.chalkWhite, fontSize: 12),
                ),
                backgroundColor: colors.rustIron.withValues(alpha: 0.3),
                side: BorderSide(color: colors.rustIron),
                deleteIcon: Icon(Icons.close, size: 16, color: colors.chalkWhite),
                onDeleted: () {
                  _logTelemetria('filtrar_conquistador', detalhe: c);
                  final novos = Set<String>.from(widget.estado.conquistadores)
                    ..remove(c);
                  widget.onFiltrosChanged(
                    widget.estado.copyWith(conquistadores: novos),
                  );
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

