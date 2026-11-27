// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Piloto de árvore de widgets para o Smoke Test pós-build em binários reais (`--release --obfuscate`).
///
/// Opera exclusivamente sobre as APIs de runtime do Flutter (`WidgetsBinding`, `GestureBinding`
/// e `SchedulerBinding`), sem depender de `flutter_test`, localizando widgets por `ValueKey<String>`,
/// garantindo visibilidade em rolagem, disparando toques físicos por *hit-test* e inserindo texto
/// diretamente no `EditableTextState` respeitando os `inputFormatters` configurados.
class PilotoArvoreUiSmoke {
  int _proximoPonteiro = 9000;
  bool _vsyncNativoAtivo = false;
  int _tentativasSemVsync = 0;

  /// Cria uma instância de [PilotoArvoreUiSmoke].
  PilotoArvoreUiSmoke();

  /// Avança um ciclo de quadro de interface compatível tanto com VSync nativo (Android/iOS)
  /// quanto com o ambiente de `tester.runAsync` em testes unitários.
  Future<void> avancarQuadro() async {
    final scheduler = SchedulerBinding.instance;
    final completer = Completer<void>();
    scheduler.addPostFrameCallback((_) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    scheduler.scheduleFrame();

    final esperaVsync = _vsyncNativoAtivo
        ? const Duration(milliseconds: 150)
        : (_tentativasSemVsync == 0
              ? const Duration(milliseconds: 80)
              : const Duration(milliseconds: 2));

    await Future.any<void>([
      completer.future,
      Future<void>.delayed(esperaVsync),
    ]);

    if (completer.isCompleted) {
      _vsyncNativoAtivo = true;
    } else {
      _tentativasSemVsync++;
      if (!_vsyncNativoAtivo && scheduler.hasScheduledFrame) {
        final proximo =
            scheduler.currentSystemFrameTimeStamp +
            const Duration(milliseconds: 25);
        scheduler.handleBeginFrame(proximo);
        scheduler.handleDrawFrame();
      }
    }
    await Future<void>.delayed(Duration.zero);
  }

  /// Avança múltiplos quadros ao longo de [duracao] para concluir transições de rotas e modais.
  Future<void> bombarDurante(Duration duracao) async {
    if (_vsyncNativoAtivo) {
      final limite = DateTime.now().add(duracao);
      final quadrosMin = (duracao.inMilliseconds / 20).ceil().clamp(2, 60);
      var quadros = 0;
      while (quadros < quadrosMin || DateTime.now().isBefore(limite)) {
        await avancarQuadro();
        quadros++;
      }
      return;
    }
    final passos = (duracao.inMilliseconds / 25).ceil().clamp(2, 60);
    for (var i = 0; i < passos; i++) {
      await avancarQuadro();
    }
  }

  /// Aguarda até que um widget visível com `ValueKey<String>(valorKey)` esteja montado na árvore.
  ///
  /// Caso não apareça no viewport inicial, realiza rolagem progressiva nos [ScrollableState]s
  /// ativos para revelar itens construídos sob demanda em listas (`ListView`).
  Future<Element> aguardarElementoPorKey(
    String valorKey, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final limite = DateTime.now().add(timeout);
    var ciclosSemEncontrar = 0;
    while (DateTime.now().isBefore(limite)) {
      final encontrado = _encontrarElementoVisivelPorKey(valorKey);
      if (encontrado != null) {
        return encontrado;
      }
      ciclosSemEncontrar++;
      if (ciclosSemEncontrar % 4 == 0) {
        _rolarScrollablesAtivosParaRevelar();
      }
      await avancarQuadro();
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    throw StateError(
      'Elemento com Key("$valorKey") não encontrado na árvore visível após ${timeout.inMilliseconds}ms.',
    );
  }

  void _rolarScrollablesAtivosParaRevelar() {
    final raiz = WidgetsBinding.instance.rootElement;
    if (raiz == null) return;
    final scrollables = <ScrollableState>[];
    void visitar(Element el) {
      final widget = el.widget;
      if (widget is Offstage && widget.offstage) return;
      if (widget is TickerMode && !widget.enabled) return;
      if (el is StatefulElement && el.state is ScrollableState) {
        scrollables.add(el.state as ScrollableState);
      }
      el.visitChildren(visitar);
    }

    visitar(raiz);
    for (final s in scrollables) {
      final pos = s.position;
      if (!pos.hasPixels || !pos.hasContentDimensions) continue;
      if (pos.axis == Axis.vertical && pos.pixels < pos.maxScrollExtent) {
        final proximo = (pos.pixels + 320.0).clamp(0.0, pos.maxScrollExtent);
        pos.jumpTo(proximo);
      }
    }
  }

  /// Indica se há atualmente um widget visível na árvore com `ValueKey<String>(valorKey)`.
  bool existeElementoVisivelPorKey(String valorKey) =>
      _encontrarElementoVisivelPorKey(valorKey) != null;

  /// Aguarda até que o elemento identificado por [valorKey] seja desmontado da árvore visível.
  Future<void> aguardarAusenciaPorKey(
    String valorKey, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final limite = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(limite)) {
      if (_encontrarElementoVisivelPorKey(valorKey) == null) {
        return;
      }
      await avancarQuadro();
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    throw StateError(
      'Elemento com Key("$valorKey") permaneceu visível após ${timeout.inMilliseconds}ms.',
    );
  }

  /// Garante visibilidade por rolagem e dispara um toque físico no centro do widget [valorKey].
  Future<void> tocarPorKey(
    String valorKey, {
    Duration esperaPosToque = const Duration(milliseconds: 380),
  }) async {
    var elemento = await aguardarElementoPorKey(valorKey);
    if (elemento.findAncestorWidgetOfExactType<SnackBar>() == null) {
      final messenger = ScaffoldMessenger.maybeOf(elemento);
      if (messenger != null) {
        messenger.removeCurrentSnackBar();
        await avancarQuadro();
        elemento = await aguardarElementoPorKey(valorKey);
      }
    }
    if (Scrollable.maybeOf(elemento) != null) {
      await Scrollable.ensureVisible(
        elemento,
        duration: Duration.zero,
        alignment: 0.25,
      );
      await avancarQuadro();
      await avancarQuadro();
      elemento = await aguardarElementoPorKey(valorKey);
    }

    final caixa = _encontrarRenderBox(elemento);
    if (caixa == null || !caixa.hasSize || caixa.size.isEmpty) {
      throw StateError(
        'RenderBox inválido ou sem dimensões para Key("$valorKey").',
      );
    }

    final centroGlobal = caixa.localToGlobal(caixa.size.center(Offset.zero));
    final pointerId = _proximoPonteiro++;
    GestureBinding.instance.handlePointerEvent(
      PointerAddedEvent(pointer: pointerId, position: centroGlobal),
    );
    GestureBinding.instance.handlePointerEvent(
      PointerDownEvent(pointer: pointerId, position: centroGlobal),
    );
    await avancarQuadro();
    GestureBinding.instance.handlePointerEvent(
      PointerUpEvent(pointer: pointerId, position: centroGlobal),
    );
    await bombarDurante(esperaPosToque);
  }

  /// Localiza o campo de texto [valorKey] e insere [texto] passando pelos `inputFormatters` do `EditableText`.
  Future<void> digitarPorKey(
    String valorKey,
    String texto, {
    Duration esperaPosDigitacao = const Duration(milliseconds: 120),
  }) async {
    var elemento = await aguardarElementoPorKey(valorKey);
    if (Scrollable.maybeOf(elemento) != null) {
      await Scrollable.ensureVisible(
        elemento,
        duration: Duration.zero,
        alignment: 0.35,
      );
      await avancarQuadro();
      elemento = await aguardarElementoPorKey(valorKey);
    }

    final editable = _encontrarEditableTextState(elemento);
    if (editable == null) {
      throw StateError(
        'Nenhum EditableTextState descendente encontrado para Key("$valorKey").',
      );
    }

    final valorAnterior = editable.currentTextEditingValue;
    var valorNovo = TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
    final formatadores = editable.widget.inputFormatters;
    if (formatadores != null) {
      for (final fmt in formatadores) {
        valorNovo = fmt.formatEditUpdate(valorAnterior, valorNovo);
      }
    }

    editable.userUpdateTextEditingValue(
      valorNovo,
      SelectionChangedCause.keyboard,
    );
    await bombarDurante(esperaPosDigitacao);
  }

  Element? _encontrarElementoVisivelPorKey(String valorKey) {
    final raiz = WidgetsBinding.instance.rootElement;
    if (raiz == null) return null;

    Element? encontrado;
    void visitar(Element el) {
      if (encontrado != null) return;
      final widget = el.widget;
      if (widget is Offstage && widget.offstage) {
        return;
      }
      if (widget is TickerMode && !widget.enabled) {
        return;
      }
      final key = widget.key;
      if (key is ValueKey<String> && key.value == valorKey) {
        final box = _encontrarRenderBox(el);
        if (box != null && box.hasSize && !box.size.isEmpty) {
          encontrado = el;
          return;
        }
      }
      el.visitChildren(visitar);
    }

    visitar(raiz);
    return encontrado;
  }

  RenderBox? _encontrarRenderBox(Element raiz) {
    final ro = raiz.renderObject;
    if (ro is RenderBox) return ro;

    RenderBox? encontrado;
    void visitar(Element el) {
      if (encontrado != null) return;
      if (el.renderObject is RenderBox) {
        encontrado = el.renderObject! as RenderBox;
        return;
      }
      el.visitChildren(visitar);
    }

    raiz.visitChildren(visitar);
    return encontrado;
  }

  EditableTextState? _encontrarEditableTextState(Element raiz) {
    EditableTextState? encontrado;
    void visitar(Element el) {
      if (encontrado != null) return;
      if (el is StatefulElement && el.state is EditableTextState) {
        encontrado = el.state as EditableTextState;
        return;
      }
      el.visitChildren(visitar);
    }

    visitar(raiz);
    return encontrado;
  }
}
