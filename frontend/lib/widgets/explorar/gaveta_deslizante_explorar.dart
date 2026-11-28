// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:flutter/material.dart';

import '../../idioma/tradutor_app.dart';
import '../../theme/cores_app.dart';
import '../../view/view_models/card_croqui_view_model.dart';
import '../../view/view_models/explorar_view_model.dart';
import 'cartao_item_gaveta_explorar.dart';

export 'cartao_item_gaveta_explorar.dart';

/// Posições discretas de encaixe vertical da gaveta deslizante sobre o globo.
enum PosicaoEncaixeGaveta {
  /// Borda mínima na base da tela deixando apenas a alça visível e ~96% da tela livre para o mapa.
  mapa(0.038),

  /// Divisão equilibrada entre globo/relevo superior e cards de picos abaixo.
  dividir(0.48),

  /// Catálogo em tela cheia encostando na barra de pesquisa e cobrindo todo o mapa.
  lista(0.93);

  final double fracaoAltura;

  const PosicaoEncaixeGaveta(this.fracaoAltura);

  /// Rótulo localizado exibido nos botões da alça da gaveta.
  String get rotulo => switch (this) {
        PosicaoEncaixeGaveta.mapa => tr(ChaveTexto.explorarModoMapa),
        PosicaoEncaixeGaveta.dividir => tr(ChaveTexto.explorarModoDividir),
        PosicaoEncaixeGaveta.lista => tr(ChaveTexto.explorarModoLista),
      };
}

/// Gaveta inferior ajustável em 3 estágios (`Mapa`, `Dividir`, `Lista`) sincronizada ao globo.
///
/// Propaga continuamente sua altura em pixels em [alturaGavetaPx] para compensar o centro
/// óptico da câmera 3D/2D e realiza auto-scroll animado até o card correspondente quando um
/// pino é tocado no mapa.
class GavetaDeslizanteExplorar extends StatefulWidget {
  final BrowseViewModel viewModel;
  final ValueNotifier<double> alturaGavetaPx;
  final void Function(CardCroquiViewModel card) aoAbrirPico;
  final void Function(String picoId)? aoFocarPicoNaLista;
  final PosicaoEncaixeGaveta posicaoInicial;
  final ScrollController? scrollControllerExterno;
  final GlobalKey? chaveSetimoPicoExterna;

  const GavetaDeslizanteExplorar({
    super.key,
    required this.viewModel,
    required this.alturaGavetaPx,
    required this.aoAbrirPico,
    this.aoFocarPicoNaLista,
    this.posicaoInicial = PosicaoEncaixeGaveta.dividir,
    this.scrollControllerExterno,
    this.chaveSetimoPicoExterna,
  });

  @override
  State<GavetaDeslizanteExplorar> createState() =>
      _GavetaDeslizanteExplorarState();
}

class _GavetaDeslizanteExplorarState extends State<GavetaDeslizanteExplorar>
    with SingleTickerProviderStateMixin {
  static const List<ModalidadeExploracaoPico> _modalidadesRapidas = [
    ModalidadeExploracaoPico.esportiva,
    ModalidadeExploracaoPico.boulder,
    ModalidadeExploracaoPico.movel,
    ModalidadeExploracaoPico.paredao,
  ];

  late final AnimationController _animadorAltura;
  late ScrollController _scrollController;
  late bool _gerenciaScrollInterno;
  late GlobalKey _chaveSetimoInterna;

  final Map<String, GlobalKey> _chavesCardsPorId = {};
  PosicaoEncaixeGaveta _encaixeAtual = PosicaoEncaixeGaveta.dividir;
  double _fracaoAtual = PosicaoEncaixeGaveta.dividir.fracaoAltura;
  double _fracaoInicioAnim = PosicaoEncaixeGaveta.dividir.fracaoAltura;
  double _fracaoAlvoAnim = PosicaoEncaixeGaveta.dividir.fracaoAltura;
  double _alturaTotalDisponivel = 760.0;
  double _ultimaAlturaLayoutPublicada = -1.0;

  String? _picoComPulsoDestaque;
  String? _picoScrollPendentePosEncaixe;
  Timer? _timerPulsoDestaque;

  GlobalKey get _chaveSetimoEfetiva =>
      widget.chaveSetimoPicoExterna ?? _chaveSetimoInterna;

  @override
  void initState() {
    super.initState();
    _encaixeAtual = widget.posicaoInicial;
    _fracaoAtual = widget.posicaoInicial.fracaoAltura;
    _fracaoInicioAnim = _fracaoAtual;
    _fracaoAlvoAnim = _fracaoAtual;
    _chaveSetimoInterna = GlobalKey();
    _gerenciaScrollInterno = widget.scrollControllerExterno == null;
    _scrollController = widget.scrollControllerExterno ?? ScrollController();

    _animadorAltura = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )
      ..addListener(() {
        final t = Curves.easeOutCubic.transform(_animadorAltura.value);
        setState(() {
          _fracaoAtual =
              _fracaoInicioAnim + (_fracaoAlvoAnim - _fracaoInicioAnim) * t;
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _publicarAlturaEmPixels();
          final pendente = _picoScrollPendentePosEncaixe;
          if (pendente != null) {
            _picoScrollPendentePosEncaixe = null;
            _rolarAteCardId(pendente);
          }
        }
      });

    _registrarOuvintes(widget.viewModel);
    if (widget.viewModel.solicitacaoScrollSetimoPico.value > 0) {
      _aoSolicitarScrollSetimoPico();
    }
  }

  @override
  void didUpdateWidget(covariant GavetaDeslizanteExplorar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      _removerOuvintes(oldWidget.viewModel);
      _registrarOuvintes(widget.viewModel);
      if (widget.viewModel.solicitacaoScrollSetimoPico.value > 0) {
        _aoSolicitarScrollSetimoPico();
      }
    }
  }

  @override
  void dispose() {
    _timerPulsoDestaque?.cancel();
    _removerOuvintes(widget.viewModel);
    _animadorAltura.dispose();
    if (_gerenciaScrollInterno) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _registrarOuvintes(BrowseViewModel vm) {
    vm.solicitacaoAutoScrollPicoSelecionado
        .addListener(_aoSolicitarAutoScrollMapa);
    vm.solicitacaoModoDivididoAutoScroll
        .addListener(_aoSolicitarModoDivididoAutoScroll);
    vm.solicitacaoScrollSetimoPico.addListener(_aoSolicitarScrollSetimoPico);
  }

  void _removerOuvintes(BrowseViewModel vm) {
    vm.solicitacaoAutoScrollPicoSelecionado
        .removeListener(_aoSolicitarAutoScrollMapa);
    vm.solicitacaoModoDivididoAutoScroll
        .removeListener(_aoSolicitarModoDivididoAutoScroll);
    vm.solicitacaoScrollSetimoPico.removeListener(_aoSolicitarScrollSetimoPico);
  }

  void _publicarAlturaEmPixels() {
    final px = (_alturaTotalDisponivel * _fracaoAtual)
        .clamp(28.0, _alturaTotalDisponivel);
    if ((widget.alturaGavetaPx.value - px).abs() > 0.2) {
      widget.alturaGavetaPx.value = px;
    }
  }

  void _animarParaEncaixe(PosicaoEncaixeGaveta destino) {
    _encaixeAtual = destino;
    _fracaoInicioAnim = _fracaoAtual;
    _fracaoAlvoAnim = destino.fracaoAltura;
    _animadorAltura.forward(from: 0.0);
  }

  void _aoSolicitarAutoScrollMapa() {
    final idSelecionado = widget.viewModel.picoSelecionadoId;
    if (idSelecionado == null) return;

    if (_encaixeAtual == PosicaoEncaixeGaveta.mapa) {
      _picoScrollPendentePosEncaixe = idSelecionado;
      _animarParaEncaixe(PosicaoEncaixeGaveta.dividir);
    }
    _destacarERolarAtePico(idSelecionado);
  }

  void _aoSolicitarModoDivididoAutoScroll() {
    final idSelecionado = widget.viewModel.picoSelecionadoId;
    if (idSelecionado == null) return;

    if (_encaixeAtual != PosicaoEncaixeGaveta.dividir) {
      _picoScrollPendentePosEncaixe = idSelecionado;
      _animarParaEncaixe(PosicaoEncaixeGaveta.dividir);
    }
    _destacarERolarAtePico(idSelecionado);
  }

  void _destacarERolarAtePico(String idSelecionado) {
    _timerPulsoDestaque?.cancel();
    setState(() => _picoComPulsoDestaque = idSelecionado);
    _timerPulsoDestaque = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) {
        setState(() => _picoComPulsoDestaque = null);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _rolarAteCardId(idSelecionado);
    });
  }

  void _rolarAteCardId(String idSelecionado) {
    final chave = _chavesCardsPorId[idSelecionado];
    final ctx = chave?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
        alignment: 0.06,
      );
    }
  }

  void _aoSolicitarScrollSetimoPico() {
    if (_encaixeAtual == PosicaoEncaixeGaveta.mapa) {
      _animarParaEncaixe(PosicaoEncaixeGaveta.dividir);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _chaveSetimoEfetiva.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: 0.0,
        );
      }
    });
  }

  GlobalKey _obterChaveCard(String id, int indice) {
    if (indice == 6) {
      final chave7 = _chaveSetimoEfetiva;
      _chavesCardsPorId[id] = chave7;
      return chave7;
    }
    final existente = _chavesCardsPorId[id];
    if (existente != null && existente != _chaveSetimoEfetiva) {
      return existente;
    }
    final nova = GlobalKey();
    _chavesCardsPorId[id] = nova;
    return nova;
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final colors = context.colors;

    return LayoutBuilder(
      builder: (context, restricoes) {
        _alturaTotalDisponivel = restricoes.maxHeight;
        final alturaPx = (_alturaTotalDisponivel * _fracaoAtual).clamp(
          28.0,
          _alturaTotalDisponivel,
        );
        if ((_ultimaAlturaLayoutPublicada - _alturaTotalDisponivel).abs() >
            0.5) {
          _ultimaAlturaLayoutPublicada = _alturaTotalDisponivel;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _publicarAlturaEmPixels();
          });
        }

        final raioTopo = ((1.0 - _fracaoAtual) * 260.0).clamp(0.0, 24.0);

        return Align(
          alignment: Alignment.bottomCenter,
          child: RepaintBoundary(
            child: Container(
            height: alturaPx,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: const Color(0xF514181E),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(raioTopo),
              ),
              border: const Border(top: BorderSide(color: Colors.white12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ListenableBuilder(
              listenable: vm,
              builder: (context, _) {
                final cards = vm.picosCards;
                final mostraCabecalho = alturaPx >= 52.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _construirAlcaCabecalho(
                      context: context,
                      colors: colors,
                      totalCards: cards.length,
                      mostraCabecalho: mostraCabecalho,
                    ),
                    Expanded(
                      child: Opacity(
                        opacity: mostraCabecalho ? 1.0 : 0.0,
                        child: IgnorePointer(
                          ignoring: !mostraCabecalho,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _construirPilulasModalidadeRapida(vm, colors),
                                const SizedBox(height: 10),
                                if (cards.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 24),
                                    child: Center(
                                      child: Text(
                                        context.tr(
                                          ChaveTexto
                                              .explorarNenhumPicoEncontrado,
                                        ),
                                        style: TextStyle(
                                          color: colors.ashGrey,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  for (var i = 0; i < cards.length; i++)
                                    Padding(
                                      key: _obterChaveCard(cards[i].id, i),
                                      padding:
                                          const EdgeInsets.only(bottom: 14),
                                      child: CartaoItemGavetaExplorar(
                                        card: cards[i],
                                        altitudeMetros:
                                            vm.obterAltitudePico(cards[i].id),
                                        umidade:
                                            vm.obterUmidadePico(cards[i].id),
                                        selecionado: vm.picoSelecionadoId ==
                                            cards[i].id,
                                        emPulsoDestaque:
                                            _picoComPulsoDestaque ==
                                                cards[i].id,
                                        downloadingCrags: vm.downloadingCrags,
                                        aoAbrir: () =>
                                            widget.aoAbrirPico(cards[i]),
                                        aoFocarNoGlobo: () {
                                          if (_encaixeAtual ==
                                              PosicaoEncaixeGaveta.lista) {
                                            _animarParaEncaixe(
                                              PosicaoEncaixeGaveta.dividir,
                                            );
                                          }
                                          vm.selecionarPico(
                                            cards[i].id,
                                            origemMapa: false,
                                          );
                                          widget.aoFocarPicoNaLista
                                              ?.call(cards[i].id);
                                        },
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            ),
          ),
        );
      },
    );
  }

  Widget _construirAlcaCabecalho({
    required BuildContext context,
    required AppColors colors,
    required int totalCards,
    required bool mostraCabecalho,
  }) {
    return GestureDetector(
      key: const Key('alca_gaveta_explorar'),
      behavior: HitTestBehavior.opaque,
      onTap: _encaixeAtual == PosicaoEncaixeGaveta.mapa
          ? () => _animarParaEncaixe(PosicaoEncaixeGaveta.dividir)
          : null,
      onVerticalDragUpdate: (detalhes) {
        _animadorAltura.stop();
        setState(() {
          _fracaoAtual =
              (_fracaoAtual - detalhes.delta.dy / _alturaTotalDisponivel)
                  .clamp(0.034, 1.0);
        });
      },
      onVerticalDragEnd: (_) {
        var maisProximo = PosicaoEncaixeGaveta.dividir;
        var menorDist = 999.0;
        for (final p in PosicaoEncaixeGaveta.values) {
          final d = (p.fracaoAltura - _fracaoAtual).abs();
          if (d < menorDist) {
            menorDist = d;
            maisProximo = p;
          }
        }
        _animarParaEncaixe(maisProximo);
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 6, 16, mostraCabecalho ? 4 : 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (mostraCabecalho) ...[
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr(
                      ChaveTexto.explorarContagemPicos,
                      {'n': totalCards},
                    ),
                    style: TextStyle(
                      color: colors.dryMoss,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.3,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colors.deepBasalt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: PosicaoEncaixeGaveta.values.map((pos) {
                        final ativo = _encaixeAtual == pos;
                        return InkWell(
                          key: Key('encaixe_gaveta_${pos.name}'),
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _animarParaEncaixe(pos),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: ativo
                                  ? colors.rustIron.withValues(alpha: 0.24)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              pos.rotulo,
                              style: TextStyle(
                                color: ativo ? colors.rustIron : colors.ashGrey,
                                fontSize: 11,
                                fontWeight:
                                    ativo ? FontWeight.w800 : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _construirPilulasModalidadeRapida(
    BrowseViewModel vm,
    AppColors colors,
  ) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final mod in _modalidadesRapidas)
          InkWell(
            key: Key('pilula_modalidade_${mod.name}'),
            borderRadius: BorderRadius.circular(16),
            onTap: () => vm.alternarModalidade(mod),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: vm.modalidadesAtivas.contains(mod)
                    ? colors.rustIron.withValues(alpha: 0.24)
                    : colors.deepBasalt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: vm.modalidadesAtivas.contains(mod)
                      ? colors.rustIron
                      : Colors.white12,
                ),
              ),
              child: Text(
                mod.rotulo,
                style: TextStyle(
                  color: vm.modalidadesAtivas.contains(mod)
                      ? colors.chalkWhite
                      : colors.ashGrey,
                  fontSize: 11,
                  fontWeight: vm.modalidadesAtivas.contains(mod)
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
