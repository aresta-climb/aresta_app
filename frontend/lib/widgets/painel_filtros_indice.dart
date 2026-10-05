// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../navigation/arvore_navegacao.dart';
import '../navigation/wrapper_navegacao_arvore.dart';
import '../services/firebase/telemetria.dart';
import '../theme/cores_app.dart';
import '../utils/filtro_grau_escalada.dart';
import '../view/function_library/biblioteca_funcoes_comuns.dart';
import 'barra_ordenacao_exploracao.dart';

/// Painel expansível e colapsável (*expando*) para controle de filtros
/// do Índice de Escaladas e da exploração unificada de Setores & Escaladas.
///
/// Suporta o modo superset (quando na aba 'Setores') e modo contextual
/// (quando em abas de modalidades individuais), operando sobre [EstadoFiltrosUnificado]
/// ou sobre [EstadoFiltrosIndice] para retrocompatibilidade.
class PainelFiltrosIndice extends StatefulWidget {
  /// Identificador do croqui/pico para eventos de telemetria.
  final String? cragId;

  /// O estado atual dos filtros ativos no modelo legado (se utilizado).
  final EstadoFiltrosIndice? estado;

  /// O estado unificado global dos filtros (quando utilizado no modelo unificado).
  final EstadoFiltrosUnificado? estadoUnificado;

  /// A modalidade de escalada selecionada na aba ativa (modelo legado).
  final String? modalidade;

  /// Nome da aba ativa na tela de exploração (ex: 'Setores', 'Esportiva', 'Boulder').
  final String? abaAtiva;

  /// Lista de modalidades disponíveis no pico (ex: ['Esportiva', 'Boulder']).
  final List<String> modalidadesDisponiveis;

  /// Lista com os nomes dos setores disponíveis para a visualização ativa.
  final List<String> setoresDisponiveis;

  /// Lista com os nomes dos grupos disponíveis para a visualização ativa.
  final List<String> gruposDisponiveis;

  /// Lista com os nomes dos conquistadores disponíveis para a modalidade ativa.
  final List<String> conquistadoresDisponiveis;

  /// Indica se a modalidade possui conquistadores cadastrados em suas escaladas.
  final bool? possuiConquistadores;

  /// Indica se há escaladas clássicas disponíveis dentro dos filtros atuais.
  final bool temClassicasDisponiveis;

  /// Callback legado emitido sempre que o usuário alterar qualquer critério de filtragem.
  final ValueChanged<EstadoFiltrosIndice>? onFiltrosChanged;

  /// Callback unificado emitido sempre que o usuário alterar qualquer critério de filtragem.
  final ValueChanged<EstadoFiltrosUnificado>? onFiltrosUnificadosChanged;

  /// Se o painel deve ser aberto expandido inicialmente.
  final bool inicialmenteExpandido;

  const PainelFiltrosIndice({
    super.key,
    this.cragId,
    this.estado,
    this.estadoUnificado,
    this.modalidade,
    this.abaAtiva,
    this.modalidadesDisponiveis = const [],
    this.setoresDisponiveis = const [],
    this.gruposDisponiveis = const [],
    this.conquistadoresDisponiveis = const [],
    this.possuiConquistadores,
    this.temClassicasDisponiveis = true,
    this.onFiltrosChanged,
    this.onFiltrosUnificadosChanged,
    this.inicialmenteExpandido = false,
  }) : assert(
          estado != null || estadoUnificado != null,
          'Deve ser fornecido estado ou estadoUnificado',
        );

  @override
  State<PainelFiltrosIndice> createState() => _PainelFiltrosIndiceState();
}

class _PainelFiltrosIndiceState extends State<PainelFiltrosIndice> {
  final ValueNotifier<int> _versaoNotificador = ValueNotifier<int>(0);
  bool _modalAberto = false;

  bool get _isUnificado => widget.estadoUnificado != null;
  String get _abaEfetiva => widget.abaAtiva ?? widget.modalidade ?? 'Esportiva';
  bool get _isModoSetores => _isUnificado && _abaEfetiva.toLowerCase() == 'setores';

  void _logTelemetria(String acao, {String? detalhe}) {
    if (widget.cragId != null && widget.cragId!.isNotEmpty) {
      TelemetryService.instance.logAcaoIndiceEscaladas(
        widget.cragId!,
        acao,
        modalidade: _abaEfetiva,
        detalhe: detalhe,
      );
    }
  }

  /// Registra eventos analíticos de ordenação tanto no funil do índice de escaladas
  /// quanto no monitoramento global de ordenação, permitindo mensurar a preferência
  /// dos escaladores por modo de listagem (padrão, grau, alfabético) e direção (asc, desc).
  void _registrarTelemetriaOrdenacao(TipoOrdenacaoExploracao tipo, bool crescente) {
    final detalhe = '${tipo.name}_${crescente ? 'asc' : 'desc'}';
    _logTelemetria('alterar_ordenacao', detalhe: detalhe);
    TelemetryService.instance.logAlterarOrdenacao(_abaEfetiva.toLowerCase(), detalhe);
  }

  void _notificarMudanca() {
    if (mounted) {
      _versaoNotificador.value++;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.inicialmenteExpandido) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _abrirModalControles(context);
        }
      });
    }
  }

  @override
  void didUpdateWidget(PainelFiltrosIndice oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificarMudanca();
    });
  }

  @override
  void dispose() {
    _versaoNotificador.dispose();
    super.dispose();
  }

  int _contarFiltrosAtivos() {
    if (_isUnificado) {
      final u = widget.estadoUnificado!;
      int total = 0;
      if (u.tipoOrdenacao != TipoOrdenacaoExploracao.padrao || !u.direcaoCrescente) {
        total++;
      }
      if (_isModoSetores) {
        final bool temFiltroModalidade = u.modalidadesAtivas.isNotEmpty &&
            (widget.modalidadesDisponiveis.isEmpty ||
                u.modalidadesAtivas.length < widget.modalidadesDisponiveis.length);
        if (temFiltroModalidade) total++;
        final categoriasComFiltroGrau = {
          ...u.minGrauPorModalidade.keys.map(EstadoFiltrosUnificado.obterCategoriaGrau),
          ...u.maxGrauPorModalidade.keys.map(EstadoFiltrosUnificado.obterCategoriaGrau),
        };
        total += categoriasComFiltroGrau.length;
      } else {
        final catAba = EstadoFiltrosUnificado.obterCategoriaGrau(_abaEfetiva);
        final temFiltroGrauCategoria = u.minGrauPorModalidade.keys
                .any((k) => EstadoFiltrosUnificado.obterCategoriaGrau(k) == catAba) ||
            u.maxGrauPorModalidade.keys
                .any((k) => EstadoFiltrosUnificado.obterCategoriaGrau(k) == catAba);
        if (temFiltroGrauCategoria) total++;
      }
      total += u.setores.length;
      total += u.grupos.length;
      total += u.conquistadores.length;
      if (u.apenasClassicas) total++;
      if (u.termoBusca.trim().isNotEmpty) total++;
      return total;
    } else {
      final e = widget.estado!;
      int total = 0;
      if (e.minGrauValor != null || e.maxGrauValor != null) {
        total++;
      }
      total += e.setores.length;
      total += e.conquistadores.length;
      if (e.apenasClassicas) {
        total++;
      }
      return total;
    }
  }

  void _atualizarFiltros({
    Set<String>? modalidadesAtivas,
    bool clearModalidadesAtivas = false,
    Map<String, int>? minGrauPorModalidade,
    Map<String, int>? maxGrauPorModalidade,
    Set<String>? setores,
    Set<String>? grupos,
    Set<String>? conquistadores,
    bool? apenasClassicas,
    int? minGrauValor,
    bool clearMinGrau = false,
    int? maxGrauValor,
    bool clearMaxGrau = false,
    TipoOrdenacaoExploracao? tipoOrdenacao,
    bool? direcaoCrescente,
  }) {
    if (_isUnificado) {
      final u = widget.estadoUnificado!;
      final normalizarModalidades = modalidadesAtivas != null &&
          (modalidadesAtivas.isEmpty ||
              (widget.modalidadesDisponiveis.isNotEmpty &&
                  modalidadesAtivas.length >= widget.modalidadesDisponiveis.length));
      final novo = u.copyWith(
        modalidadesAtivas: normalizarModalidades ? const {} : modalidadesAtivas,
        clearModalidadesAtivas: clearModalidadesAtivas || normalizarModalidades,
        minGrauPorModalidade: minGrauPorModalidade,
        maxGrauPorModalidade: maxGrauPorModalidade,
        setores: setores,
        grupos: grupos,
        conquistadores: conquistadores,
        apenasClassicas: apenasClassicas,
        tipoOrdenacao: tipoOrdenacao,
        direcaoCrescente: direcaoCrescente,
      );
      widget.onFiltrosUnificadosChanged?.call(novo);
    } else if (widget.estado != null) {
      final e = widget.estado!;
      final novo = e.copyWith(
        minGrauValor: minGrauValor,
        clearMinGrau: clearMinGrau,
        maxGrauValor: maxGrauValor,
        clearMaxGrau: clearMaxGrau,
        setores: setores,
        conquistadores: conquistadores,
        apenasClassicas: apenasClassicas,
      );
      widget.onFiltrosChanged?.call(novo);
    }
    _notificarMudanca();
  }

  void _limparFiltros() {
    _logTelemetria('limpar_filtros');
    if (_isUnificado) {
      if (_isModoSetores) {
        widget.onFiltrosUnificadosChanged?.call(const EstadoFiltrosUnificado());
      } else {
        final u = widget.estadoUnificado!;
        final catAba = EstadoFiltrosUnificado.obterCategoriaGrau(_abaEfetiva);
        final mins = Map<String, int>.from(u.minGrauPorModalidade)
          ..remove(catAba)
          ..removeWhere((k, _) => EstadoFiltrosUnificado.obterCategoriaGrau(k) == catAba);
        final maxs = Map<String, int>.from(u.maxGrauPorModalidade)
          ..remove(catAba)
          ..removeWhere((k, _) => EstadoFiltrosUnificado.obterCategoriaGrau(k) == catAba);
        final limpo = u.copyWith(
          minGrauPorModalidade: mins,
          maxGrauPorModalidade: maxs,
          clearSetores: true,
          clearGrupos: true,
          clearConquistadores: true,
          apenasClassicas: false,
          termoBusca: '',
          tipoOrdenacao: TipoOrdenacaoExploracao.padrao,
          direcaoCrescente: true,
        );
        widget.onFiltrosUnificadosChanged?.call(limpo);
      }
    } else if (widget.estado != null) {
      widget.onFiltrosChanged?.call(const EstadoFiltrosIndice());
    }
    _notificarMudanca();
  }

  /// Aciona a abertura do Modal Bottom Sheet contendo as seções de Ordenação e Filtros.
  Future<void> _abrirModalControles(BuildContext context) async {
    if (_modalAberto) return;
    _modalAberto = true;
    _logTelemetria('expandir_filtros');

    TreeNavigationController? ctrl;
    try {
      ctrl = TreeNavigationWrapper.maybeOf(context)?.treeController ??
          TreeNavigationWrapper.currentTreeController;
    } catch (_) {
      ctrl = TreeNavigationWrapper.currentTreeController;
    }
    if (ctrl != null) {
      ctrl.navigateTo(ControlesNode(cragId: widget.cragId, parent: ctrl.currentNode));
    }

    final bool Function()? interceptorAnterior = ctrl?.onBackInterceptor;
    BuildContext? sheetContextRef;
    bool fechandoModal = false;

    if (ctrl != null) {
      ctrl.onBackInterceptor = () {
        if (fechandoModal) return true;
        if (sheetContextRef != null && sheetContextRef!.mounted) {
          fechandoModal = true;
          Navigator.of(sheetContextRef!).pop();
          return true;
        }
        return false;
      };
    }

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.colors.deepBasalt,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) {
          sheetContextRef = sheetContext;
          return PopScope(
            canPop: true,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop && ctrl != null && ctrl.onBackInterceptor != null) {
                fechandoModal = true;
                ctrl.onBackInterceptor = interceptorAnterior;
              }
            },
            child: ValueListenableBuilder<int>(
              valueListenable: _versaoNotificador,
              builder: (context, versao, child) {
                return _buildModalControlesConteudo(sheetContext);
              },
            ),
          );
        },
      );
    } finally {
      if (ctrl != null) {
        ctrl.onBackInterceptor = interceptorAnterior;
      }
      _modalAberto = false;
      if (ctrl != null && ctrl.currentNode is ControlesNode) {
        ctrl.goBack();
      }
      _logTelemetria('colapsar_filtros');
    }
  }

  /// Renderiza o conteúdo estruturado do Modal Bottom Sheet com Ordenação e Filtros.
  Widget _buildModalControlesConteudo(BuildContext context) {
    final colors = context.colors;
    final totalAtivos = _contarFiltrosAtivos();
    final temConquistadoresCadastrados = widget.possuiConquistadores ??
        (widget.conquistadoresDisponiveis.isNotEmpty ||
            (_isUnificado
                ? widget.estadoUnificado!.conquistadores.isNotEmpty
                : widget.estado!.conquistadores.isNotEmpty));

    final bool apenasClassicasAtivo = _isUnificado
        ? widget.estadoUnificado!.apenasClassicas
        : widget.estado!.apenasClassicas;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.graniteEdge,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 20, color: colors.rustIron),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Filtros e Ordenação',
                            style: TextStyle(
                              color: colors.chalkWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (totalAtivos > 0) ...[
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
                          const SizedBox(width: 6),
                          TextButton(
                            onPressed: _limparFiltros,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Limpar',
                              style: TextStyle(
                                color: colors.ashGrey,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  buildFeedbackButton(context, color: colors.ashGrey),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: colors.ashGrey),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Fechar',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.graniteEdge),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSecaoTitulo(context, 'ORDENAÇÃO'),
                    const SizedBox(height: 10),
                    BarraOrdenacaoExploracao(
                      ordenacaoAtual: _isUnificado
                          ? widget.estadoUnificado!.tipoOrdenacao
                          : TipoOrdenacaoExploracao.padrao,
                      direcaoCrescente: _isUnificado
                          ? widget.estadoUnificado!.direcaoCrescente
                          : true,
                      onOrdenacaoChanged: (tipo) {
                        final direcaoAtual = _isUnificado
                            ? widget.estadoUnificado!.direcaoCrescente
                            : true;
                        _registrarTelemetriaOrdenacao(tipo, direcaoAtual);
                        _atualizarFiltros(tipoOrdenacao: tipo);
                      },
                      onDirecaoChanged: (crescente) {
                        final ordenacaoAtual = _isUnificado
                            ? widget.estadoUnificado!.tipoOrdenacao
                            : TipoOrdenacaoExploracao.padrao;
                        _registrarTelemetriaOrdenacao(ordenacaoAtual, crescente);
                        _atualizarFiltros(direcaoCrescente: crescente);
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildSecaoTitulo(context, 'FILTROS'),
                    const SizedBox(height: 12),

                    if (_isModoSetores && widget.modalidadesDisponiveis.isNotEmpty) ...[
                      _buildSecaoTitulo(context, 'Modalidades'),
                      const SizedBox(height: 8),
                      _buildSeletorModalidadesAtivas(context),
                      const SizedBox(height: 16),
                    ],

                    if (_isModoSetores) ...[
                      ..._obterCategoriasParaSliders().map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildSliderParaCategoria(
                            context,
                            cat,
                            temAmbasCategorias: _obterCategoriasParaSliders().length > 1,
                          ),
                        );
                      }),
                    ] else ...[
                      _buildSliderParaCategoria(
                        context,
                        _isUnificado
                            ? EstadoFiltrosUnificado.obterCategoriaGrau(_abaEfetiva)
                            : _abaEfetiva,
                        temAmbasCategorias: false,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (!_isModoSetores) ...[
                      _buildSecaoTitulo(context, 'Localização'),
                      const SizedBox(height: 8),
                      _buildSeletorLocalizacao(context),
                      const SizedBox(height: 16),
                    ],

                    if (temConquistadoresCadastrados) ...[
                      _buildSecaoTitulo(context, 'Conquista (Autores)'),
                      const SizedBox(height: 8),
                      _buildSeletorConquistadores(context),
                      const SizedBox(height: 16),
                    ],

                    if (widget.temClassicasDisponiveis) ...[
                      FilterChip(
                        selected: apenasClassicasAtivo,
                        label: Text(
                          'Apenas Clássicas (★)',
                          style: TextStyle(
                            color: apenasClassicasAtivo
                                ? colors.deepBasalt
                                : colors.chalkWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        selectedColor: Colors.amber,
                        backgroundColor: colors.deepBasalt,
                        side: BorderSide(
                          color: apenasClassicasAtivo
                              ? Colors.amber
                              : colors.graniteEdge,
                        ),
                        onSelected: (selecionado) {
                          _logTelemetria(
                            'filtrar_classicas',
                            detalhe: selecionado ? 'true' : 'false',
                          );
                          _atualizarFiltros(apenasClassicas: selecionado);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final totalAtivos = _contarFiltrosAtivos();
    final chips = _obterListaChips(context);

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
      child: Row(
        children: [
          InkWell(
            onTap: () => _abrirModalControles(context),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: totalAtivos > 0 ? colors.rustIron : colors.chalkWhite,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filtros e Ordenação',
                    style: TextStyle(
                      color: colors.chalkWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (totalAtivos > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
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
                        '$totalAtivos',
                        style: TextStyle(
                          color: colors.rustIron,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (chips.isNotEmpty) ...[
            Container(
              width: 1,
              height: 24,
              color: colors.graniteEdge,
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: chips
                      .map((chip) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: chip,
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _obterCategoriasParaSliders() {
    if (!_isUnificado) {
      return [EstadoFiltrosUnificado.obterCategoriaGrau(_abaEfetiva)];
    }
    final u = widget.estadoUnificado!;
    final modalidadesBase = u.modalidadesAtivas.isNotEmpty
        ? widget.modalidadesDisponiveis.where((m) => u.modalidadesAtivas.contains(m)).toList()
        : widget.modalidadesDisponiveis;

    final temVias = modalidadesBase.isEmpty ||
        modalidadesBase.any((m) => EstadoFiltrosUnificado.obterCategoriaGrau(m) == 'Via');
    final temBoulders =
        modalidadesBase.any((m) => EstadoFiltrosUnificado.obterCategoriaGrau(m) == 'Boulder');

    final List<String> categorias = [];
    if (temVias) categorias.add('Via');
    if (temBoulders) categorias.add('Boulder');
    return categorias.isEmpty ? ['Via'] : categorias;
  }

  Widget _buildSeletorModalidadesAtivas(BuildContext context) {
    final colors = context.colors;
    final ativas = _isUnificado ? widget.estadoUnificado!.modalidadesAtivas : <String>{};

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.modalidadesDisponiveis.map((mod) {
        final isSelected = ativas.isEmpty || ativas.contains(mod);
        return FilterChip(
          selected: isSelected,
          showCheckmark: true,
          checkmarkColor: colors.rustIron,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          label: Text(
            mod,
            style: TextStyle(
              color: isSelected ? colors.chalkWhite : colors.ashGrey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
          selectedColor: colors.rustIron.withValues(alpha: 0.18),
          backgroundColor: colors.deepBasalt,
          side: BorderSide(
            color: isSelected ? colors.rustIron : colors.graniteEdge.withValues(alpha: 0.6),
            width: isSelected ? 1.4 : 1.0,
          ),
          onSelected: (selected) {
            _logTelemetria(
              'filtrar_modalidade',
              detalhe: '$mod:${selected ? 'ativo' : 'inativo'}',
            );
            final novas = Set<String>.from(
              ativas.isEmpty ? widget.modalidadesDisponiveis : ativas,
            );
            if (selected) {
              novas.add(mod);
            } else {
              if (novas.length > 1) {
                novas.remove(mod);
              }
            }
            if (novas.length >= widget.modalidadesDisponiveis.length) {
              _atualizarFiltros(clearModalidadesAtivas: true);
            } else {
              _atualizarFiltros(modalidadesAtivas: novas);
            }
          },
        );
      }).toList(),
    );
  }

  String _obterRotuloChipOrdenacao(EstadoFiltrosUnificado u) {
    final seta = u.direcaoCrescente ? '▲' : '▼';
    switch (u.tipoOrdenacao) {
      case TipoOrdenacaoExploracao.padrao:
        return 'Padrão $seta';
      case TipoOrdenacaoExploracao.grau:
        return 'Grau $seta';
      case TipoOrdenacaoExploracao.alfabetico:
        return u.direcaoCrescente ? 'A-Z ▲' : 'Z-A ▼';
    }
  }

  List<Widget> _obterListaChips(BuildContext context) {
    final colors = context.colors;
    final chips = <Widget>[];

    if (_isUnificado) {
      final u = widget.estadoUnificado!;

      // Chip dinâmico de Ordenação (quando fora do padrão Padrão ▲)
      if (u.tipoOrdenacao != TipoOrdenacaoExploracao.padrao || !u.direcaoCrescente) {
        chips.add(
          Chip(
            label: Text(
              _obterRotuloChipOrdenacao(u),
              style: TextStyle(color: colors.chalkWhite, fontSize: 12),
            ),
            backgroundColor: colors.rustIron.withValues(alpha: 0.3),
            side: BorderSide(color: colors.rustIron),
            deleteIcon: Icon(Icons.close, size: 16, color: colors.chalkWhite),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            onDeleted: () {
              _registrarTelemetriaOrdenacao(
                TipoOrdenacaoExploracao.padrao,
                true,
              );
              _atualizarFiltros(
                tipoOrdenacao: TipoOrdenacaoExploracao.padrao,
                direcaoCrescente: true,
              );
            },
          ),
        );
      }

      // Modalidades (apenas se for filtro restritivo na aba Setores)
      if (_isModoSetores &&
          u.modalidadesAtivas.isNotEmpty &&
          (widget.modalidadesDisponiveis.isEmpty ||
              u.modalidadesAtivas.length < widget.modalidadesDisponiveis.length)) {
        for (final mod in widget.modalidadesDisponiveis.where((m) => u.modalidadesAtivas.contains(m))) {
          chips.add(
            Chip(
              label: Text(mod, style: TextStyle(color: colors.chalkWhite, fontSize: 12)),
              backgroundColor: colors.rustIron.withValues(alpha: 0.3),
              side: BorderSide(color: colors.rustIron),
              deleteIcon: Icon(Icons.close, size: 16, color: colors.chalkWhite),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              onDeleted: () {
                _logTelemetria('filtrar_modalidade', detalhe: '$mod:inativo');
                final novas = Set<String>.from(u.modalidadesAtivas)..remove(mod);
                if (novas.isEmpty || novas.length >= widget.modalidadesDisponiveis.length) {
                  _atualizarFiltros(clearModalidadesAtivas: true);
                } else {
                  _atualizarFiltros(modalidadesAtivas: novas);
                }
              },
            ),
          );
        }
      }

      // Grau (agrupado por categoria: Via e/ou Boulder)
      var categoriasGrau = {
        ...u.minGrauPorModalidade.keys.map(EstadoFiltrosUnificado.obterCategoriaGrau),
        ...u.maxGrauPorModalidade.keys.map(EstadoFiltrosUnificado.obterCategoriaGrau),
      };
      if (!_isModoSetores) {
        final catAba = EstadoFiltrosUnificado.obterCategoriaGrau(_abaEfetiva);
        categoriasGrau = categoriasGrau.where((c) => c == catAba).toSet();
      }
      final bool temMultiplasCategorias = widget.modalidadesDisponiveis
              .map(EstadoFiltrosUnificado.obterCategoriaGrau)
              .toSet()
              .length >
          1;

      for (final cat in categoriasGrau) {
        final minVal = u.minGrauPorModalidade[cat] ??
            (cat == 'Via' ? u.minGrauPorModalidade['Esportiva'] : null);
        final maxVal = u.maxGrauPorModalidade[cat] ??
            (cat == 'Via' ? u.maxGrauPorModalidade['Esportiva'] : null);
        final opcoes = OpcoesGrau.opcoesParaModalidade(cat);
        final maxIndex = opcoes.length - 1;
        int startIdx = 0;
        if (minVal != null) {
          final sIdx = opcoes.indexWhere((o) => o.valor >= minVal);
          if (sIdx != -1) startIdx = sIdx;
        }
        int endIdx = maxIndex;
        if (maxVal != null) {
          final eIdx = opcoes.lastIndexWhere((o) => o.valor <= maxVal);
          if (eIdx != -1) endIdx = eIdx;
        }
        if (startIdx > endIdx) startIdx = endIdx;
        final rotulo = startIdx == endIdx
            ? opcoes[startIdx].rotulo
            : '${opcoes[startIdx].rotulo} a ${opcoes[endIdx].rotulo}';
        final textoRotulo = (_isModoSetores && temMultiplasCategorias)
            ? (cat == 'Via' ? 'Vias: $rotulo' : 'Boulders: $rotulo')
            : rotulo;

        chips.add(
          Chip(
            label: Text(textoRotulo,
                style: TextStyle(color: colors.chalkWhite, fontSize: 12)),
            backgroundColor: colors.rustIron.withValues(alpha: 0.3),
            side: BorderSide(color: colors.rustIron),
            deleteIcon: Icon(Icons.close, size: 16, color: colors.chalkWhite),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            onDeleted: () {
              _logTelemetria('filtrar_grau', detalhe: 'Todos os graus');
              final mins = Map<String, int>.from(u.minGrauPorModalidade)
                ..remove(cat)
                ..removeWhere((k, _) => EstadoFiltrosUnificado.obterCategoriaGrau(k) == cat);
              final maxs = Map<String, int>.from(u.maxGrauPorModalidade)
                ..remove(cat)
                ..removeWhere((k, _) => EstadoFiltrosUnificado.obterCategoriaGrau(k) == cat);
              _atualizarFiltros(minGrauPorModalidade: mins, maxGrauPorModalidade: maxs);
            },
          ),
        );
      }

      // Setores
      for (final s in u.setores) {
        chips.add(
          Chip(
            label: Text(s, style: TextStyle(color: colors.chalkWhite, fontSize: 12)),
            backgroundColor: colors.rustIron.withValues(alpha: 0.3),
            side: BorderSide(color: colors.rustIron),
            deleteIcon: Icon(Icons.close, size: 16, color: colors.chalkWhite),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            onDeleted: () {
              final novos = Set<String>.from(u.setores)..remove(s);
              _atualizarFiltros(setores: novos);
            },
          ),
        );
      }

      // Grupos
      for (final g in u.grupos) {
        chips.add(
          Chip(
            label: Text(g, style: TextStyle(color: colors.chalkWhite, fontSize: 12)),
            backgroundColor: colors.rustIron.withValues(alpha: 0.3),
            side: BorderSide(color: colors.rustIron),
            deleteIcon: Icon(Icons.close, size: 16, color: colors.chalkWhite),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            onDeleted: () {
              final novos = Set<String>.from(u.grupos)..remove(g);
              _atualizarFiltros(grupos: novos);
            },
          ),
        );
      }

      // Conquistadores
      for (final c in u.conquistadores) {
        chips.add(
          Chip(
            label: Text(c, style: TextStyle(color: colors.chalkWhite, fontSize: 12)),
            backgroundColor: colors.rustIron.withValues(alpha: 0.3),
            side: BorderSide(color: colors.rustIron),
            deleteIcon: Icon(Icons.close, size: 16, color: colors.chalkWhite),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            onDeleted: () {
              final novos = Set<String>.from(u.conquistadores)..remove(c);
              _atualizarFiltros(conquistadores: novos);
            },
          ),
        );
      }

      // Clássicas
      if (u.apenasClassicas) {
        chips.add(
          Chip(
            label: const Text('Clássicas (★)',
                style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.amber.withValues(alpha: 0.15),
            side: const BorderSide(color: Colors.amber),
            deleteIcon: const Icon(Icons.close, size: 16, color: Colors.amber),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            onDeleted: () => _atualizarFiltros(apenasClassicas: false),
          ),
        );
      }
    } else {
      // Modo Legado
      final e = widget.estado!;
      if (e.minGrauValor != null || e.maxGrauValor != null) {
        final opcoes = OpcoesGrau.opcoesParaModalidade(_abaEfetiva);
        final maxIndex = opcoes.length - 1;
        int startIdx = 0;
        if (e.minGrauValor != null) {
          final idx = opcoes.indexWhere((o) => o.valor >= e.minGrauValor!);
          if (idx != -1) startIdx = idx;
        }
        int endIdx = maxIndex;
        if (e.maxGrauValor != null) {
          final idx = opcoes.lastIndexWhere((o) => o.valor <= e.maxGrauValor!);
          if (idx != -1) endIdx = idx;
        }
        if (startIdx > endIdx) startIdx = endIdx;

        final rotulo = startIdx == endIdx
            ? opcoes[startIdx].rotulo
            : '${opcoes[startIdx].rotulo} a ${opcoes[endIdx].rotulo}';

        chips.add(
          Chip(
            label: Text(rotulo, style: TextStyle(color: colors.chalkWhite, fontSize: 12)),
            backgroundColor: colors.rustIron.withValues(alpha: 0.3),
            side: BorderSide(color: colors.rustIron),
            deleteIcon: Icon(Icons.close, size: 16, color: colors.chalkWhite),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            onDeleted: () {
              _logTelemetria('limpar_grau');
              _atualizarFiltros(clearMinGrau: true, clearMaxGrau: true);
            },
          ),
        );
      }

      for (final s in e.setores) {
        chips.add(
          Chip(
            label: Text(s, style: TextStyle(color: colors.chalkWhite, fontSize: 12)),
            backgroundColor: colors.rustIron.withValues(alpha: 0.3),
            side: BorderSide(color: colors.rustIron),
            deleteIcon: Icon(Icons.close, size: 16, color: colors.chalkWhite),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            onDeleted: () {
              final novos = Set<String>.from(e.setores)..remove(s);
              _atualizarFiltros(setores: novos);
            },
          ),
        );
      }

      for (final c in e.conquistadores) {
        chips.add(
          Chip(
            label: Text(c, style: TextStyle(color: colors.chalkWhite, fontSize: 12)),
            backgroundColor: colors.rustIron.withValues(alpha: 0.3),
            side: BorderSide(color: colors.rustIron),
            deleteIcon: Icon(Icons.close, size: 16, color: colors.chalkWhite),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            onDeleted: () {
              final novos = Set<String>.from(e.conquistadores)..remove(c);
              _atualizarFiltros(conquistadores: novos);
            },
          ),
        );
      }

      if (e.apenasClassicas) {
        chips.add(
          Chip(
            label: const Text('Clássicas (★)',
                style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.amber.withValues(alpha: 0.15),
            side: const BorderSide(color: Colors.amber),
            deleteIcon: const Icon(Icons.close, size: 16, color: Colors.amber),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            onDeleted: () => _atualizarFiltros(apenasClassicas: false),
          ),
        );
      }
    }

    return chips;
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

  Widget _buildSliderParaCategoria(
    BuildContext context,
    String categoria, {
    bool temAmbasCategorias = false,
  }) {
    final colors = context.colors;
    final opcoes = OpcoesGrau.opcoesParaModalidade(categoria);
    final maxIndex = opcoes.length - 1;

    int? minGrauAtual;
    int? maxGrauAtual;

    if (_isUnificado) {
      minGrauAtual = widget.estadoUnificado!.minGrauPorModalidade[categoria] ??
          (categoria == 'Via' ? widget.estadoUnificado!.minGrauPorModalidade['Esportiva'] : null);
      maxGrauAtual = widget.estadoUnificado!.maxGrauPorModalidade[categoria] ??
          (categoria == 'Via' ? widget.estadoUnificado!.maxGrauPorModalidade['Esportiva'] : null);
    } else {
      minGrauAtual = widget.estado!.minGrauValor;
      maxGrauAtual = widget.estado!.maxGrauValor;
    }

    int startIdx = 0;
    if (minGrauAtual != null) {
      final idx = opcoes.indexWhere((o) => o.valor >= minGrauAtual!);
      if (idx != -1) startIdx = idx;
    }

    int endIdx = maxIndex;
    if (maxGrauAtual != null) {
      final idx = opcoes.lastIndexWhere((o) => o.valor <= maxGrauAtual!);
      if (idx != -1) endIdx = idx;
    }

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

    final String tituloSecao;
    if (_isModoSetores && temAmbasCategorias) {
      tituloSecao = categoria == 'Via'
          ? 'Faixa de Grau (Vias)'
          : 'Faixa de Grau (Boulders)';
    } else {
      tituloSecao = 'Faixa de Grau';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSecaoTitulo(context, tituloSecao),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cobreTudo
                    ? colors.graniteEdge.withValues(alpha: 0.5)
                    : colors.rustIron.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: cobreTudo ? colors.graniteEdge : colors.rustIron,
                ),
              ),
              child: Text(
                textoRotulo,
                style: TextStyle(
                  color: cobreTudo ? colors.ashGrey : colors.rustIron,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // RangeSlider
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
          onChanged: (values) {
            final s = values.start.round();
            final e = values.end.round();
            final minVal = s == 0 ? null : opcoes[s].valor;
            final maxVal = e == maxIndex ? null : opcoes[e].valor;

            if (_isUnificado) {
              final mins = Map<String, int>.from(widget.estadoUnificado!.minGrauPorModalidade);
              final maxs = Map<String, int>.from(widget.estadoUnificado!.maxGrauPorModalidade);
              if (s == 0 && e == maxIndex) {
                mins.remove(categoria);
                maxs.remove(categoria);
                if (categoria == 'Via') {
                  mins.removeWhere((k, _) => EstadoFiltrosUnificado.obterCategoriaGrau(k) == 'Via');
                  maxs.removeWhere((k, _) => EstadoFiltrosUnificado.obterCategoriaGrau(k) == 'Via');
                } else if (categoria == 'Boulder') {
                  mins.removeWhere((k, _) => EstadoFiltrosUnificado.obterCategoriaGrau(k) == 'Boulder');
                  maxs.removeWhere((k, _) => EstadoFiltrosUnificado.obterCategoriaGrau(k) == 'Boulder');
                }
              } else {
                if (minVal != null) {
                  mins[categoria] = minVal;
                } else {
                  mins.remove(categoria);
                }
                if (maxVal != null) {
                  maxs[categoria] = maxVal;
                } else {
                  maxs.remove(categoria);
                }
              }
              _atualizarFiltros(minGrauPorModalidade: mins, maxGrauPorModalidade: maxs);
            } else {
              if (s == 0 && e == maxIndex) {
                _atualizarFiltros(clearMinGrau: true, clearMaxGrau: true);
              } else {
                _atualizarFiltros(minGrauValor: minVal, maxGrauValor: maxVal);
              }
            }
          },
          onChangeEnd: (values) {
            final s = values.start.round();
            final e = values.end.round();
            _logTelemetria(
              'filtrar_grau',
              detalhe: '${opcoes[s].rotulo}_a_${opcoes[e].rotulo}',
            );
          },
        ),
      ],
    );
  }

  Widget _buildSeletorLocalizacao(BuildContext context) {
    final colors = context.colors;
    final setoresAtivos = _isUnificado
        ? widget.estadoUnificado!.setores
        : widget.estado!.setores;
    final gruposAtivos = _isUnificado
        ? widget.estadoUnificado!.grupos
        : <String>{};

    final setoresDisponiveis = widget.setoresDisponiveis
        .where((s) => !setoresAtivos.contains(s))
        .toList();
    final gruposDisponiveis = widget.gruposDisponiveis
        .where((g) => !gruposAtivos.contains(g))
        .toList();

    final int totalDisponivel = setoresDisponiveis.length + gruposDisponiveis.length;
    final int totalAtivos = setoresAtivos.length + gruposAtivos.length;

    final String hintTexto;
    if (totalDisponivel > 0) {
      if (widget.gruposDisponiveis.isNotEmpty) {
        hintTexto = 'Adicionar setor ou grupo...';
      } else {
        hintTexto = 'Adicionar setor...';
      }
    } else if (totalAtivos > 0) {
      hintTexto = widget.gruposDisponiveis.isNotEmpty
          ? 'Todos os setores ou grupos adicionados'
          : 'Todos os setores adicionados';
    } else {
      hintTexto = widget.gruposDisponiveis.isNotEmpty
          ? 'Nenhum local nos filtros atuais'
          : 'Nenhum setor nos filtros atuais';
    }

    final bool habilitado = totalDisponivel > 0;

    final List<DropdownMenuItem<String>> itens = [];

    // Primeiro grupos
    for (final g in gruposDisponiveis) {
      itens.add(
        DropdownMenuItem<String>(
          value: 'grupo:$g',
          child: Text(
            '$g (Grupo)',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.chalkWhite, fontSize: 13),
          ),
        ),
      );
    }

    // Depois setores
    for (final s in setoresDisponiveis) {
      itens.add(
        DropdownMenuItem<String>(
          value: 'setor:$s',
          child: Text(
            s,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.chalkWhite, fontSize: 13),
          ),
        ),
      );
    }

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
              items: habilitado ? itens : null,
              onChanged: habilitado
                  ? (valor) {
                      if (valor == null) return;
                      if (valor.startsWith('grupo:')) {
                        final nome = valor.substring('grupo:'.length);
                        _logTelemetria('filtrar_grupo', detalhe: nome);
                        final novos = Set<String>.from(gruposAtivos)..add(nome);
                        _atualizarFiltros(grupos: novos);
                      } else if (valor.startsWith('setor:')) {
                        final nome = valor.substring('setor:'.length);
                        _logTelemetria('filtrar_setor', detalhe: nome);
                        final novos = Set<String>.from(setoresAtivos)..add(nome);
                        _atualizarFiltros(setores: novos);
                      }
                    }
                  : null,
            ),
          ),
        ),
        if (totalAtivos > 0) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...gruposAtivos.map((g) {
                return Chip(
                  label: Text('$g (Grupo)', style: TextStyle(color: colors.chalkWhite, fontSize: 12)),
                  backgroundColor: colors.rustIron.withValues(alpha: 0.3),
                  side: BorderSide(color: colors.rustIron),
                  deleteIcon: Icon(Icons.close, size: 16, color: colors.chalkWhite),
                  onDeleted: () {
                    _logTelemetria('filtrar_grupo', detalhe: g);
                    final novos = Set<String>.from(gruposAtivos)..remove(g);
                    _atualizarFiltros(grupos: novos);
                  },
                );
              }),
              ...setoresAtivos.map((s) {
                return Chip(
                  label: Text(s, style: TextStyle(color: colors.chalkWhite, fontSize: 12)),
                  backgroundColor: colors.rustIron.withValues(alpha: 0.3),
                  side: BorderSide(color: colors.rustIron),
                  deleteIcon: Icon(Icons.close, size: 16, color: colors.chalkWhite),
                  onDeleted: () {
                    _logTelemetria('filtrar_setor', detalhe: s);
                    final novos = Set<String>.from(setoresAtivos)..remove(s);
                    _atualizarFiltros(setores: novos);
                  },
                );
              }),
            ],
          ),
        ],
      ],
    );
  }



  Widget _buildSeletorConquistadores(BuildContext context) {
    final colors = context.colors;
    final conquistadoresAtivos = _isUnificado
        ? widget.estadoUnificado!.conquistadores
        : widget.estado!.conquistadores;

    final disponiveis = widget.conquistadoresDisponiveis
        .where((c) => !conquistadoresAtivos.contains(c))
        .toList();

    final String hintTexto;
    if (disponiveis.isNotEmpty) {
      hintTexto = 'Adicionar conquistador...';
    } else if (conquistadoresAtivos.isNotEmpty) {
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
                        final novos = Set<String>.from(conquistadoresAtivos)..add(novo);
                        _atualizarFiltros(conquistadores: novos);
                      }
                    }
                  : null,
            ),
          ),
        ),
        if (conquistadoresAtivos.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: conquistadoresAtivos.map((c) {
              return Chip(
                label: Text(c, style: TextStyle(color: colors.chalkWhite, fontSize: 12)),
                backgroundColor: colors.rustIron.withValues(alpha: 0.3),
                side: BorderSide(color: colors.rustIron),
                deleteIcon: Icon(Icons.close, size: 16, color: colors.chalkWhite),
                onDeleted: () {
                  _logTelemetria('filtrar_conquistador', detalhe: c);
                  final novos = Set<String>.from(conquistadoresAtivos)..remove(c);
                  _atualizarFiltros(conquistadores: novos);
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
