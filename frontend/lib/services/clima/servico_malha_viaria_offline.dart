// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../constants/constantes_rede.dart';
import '../../data/modelos/modelos_rede_viaria_aresta.dart';
import '../firebase/app_logger.dart';
import '../http/cliente_http_aresta.dart';

/// Persistência local offline-first da malha viária (`OpenStreetMap`) com rotação atômica
/// de dois slots (`atual` + `seguranca`), espelhando a estratégia dos recursos da NASA.
class ArmazenamentoMalhaViariaLocal {
  static const String nomeArquivoAtual = 'malha_viaria_picos_atual.json';
  static const String nomeArquivoSeguranca =
      'malha_viaria_picos_seguranca.json';

  final Future<String?> Function() _provedorDiretorioBase;

  ArmazenamentoMalhaViariaLocal({
    Future<String?> Function()? provedorDiretorioBase,
  }) : _provedorDiretorioBase =
            provedorDiretorioBase ?? _obterDiretorioDocumentosPadrao;

  static Future<String?> _obterDiretorioDocumentosPadrao() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    } on MissingPluginException {
      return null;
    }
  }

  /// Grava [snapshot] em background via arquivo `.tmp`, promovendo o `atual` anterior
  /// para `seguranca` e renomeando atomicamente sem bloquear o Isolate principal de UI.
  Future<void> salvarSnapshot(SnapshotMalhaViariaOffline snapshot) async {
    final dirBase = await _provedorDiretorioBase();
    if (dirBase == null) return;
    final diretorio = Directory(dirBase);
    if (!diretorio.existsSync()) {
      diretorio.createSync(recursive: true);
    }

    final caminhoAtual = '$dirBase/$nomeArquivoAtual';
    final caminhoSeguranca = '$dirBase/$nomeArquivoSeguranca';
    final caminhoTmp = '$caminhoAtual.tmp';

    final mapa = snapshot.paraMapa();
    final jsonTexto = await Isolate.run(() => jsonEncode(mapa));
    final arquivoTmp = File(caminhoTmp);
    await arquivoTmp.writeAsString(jsonTexto, flush: true);

    final arquivoAtual = File(caminhoAtual);
    final atualValido = await _tentarLerArquivo(arquivoAtual);
    if (atualValido != null) {
      await arquivoAtual.copy(caminhoSeguranca);
    } else {
      await arquivoTmp.copy(caminhoSeguranca);
    }

    if (arquivoAtual.existsSync()) {
      await arquivoAtual.delete();
    }
    await arquivoTmp.rename(caminhoAtual);
  }

  /// Lê o snapshot `atual`, restaurando automaticamente a partir de `seguranca` se corrompido.
  Future<SnapshotMalhaViariaOffline?> lerSnapshot() async {
    final dirBase = await _provedorDiretorioBase();
    if (dirBase == null) return null;
    final arquivoAtual = File('$dirBase/$nomeArquivoAtual');
    final lidoAtual = await _tentarLerArquivo(arquivoAtual);
    if (lidoAtual != null) {
      return lidoAtual;
    }

    final arquivoSeguranca = File('$dirBase/$nomeArquivoSeguranca');
    final lidoSeguranca = await _tentarLerArquivo(arquivoSeguranca);
    if (lidoSeguranca != null) {
      AppLogger.instance.logAviso(
        '[ArmazenamentoMalhaViariaLocal] Arquivo atual ausente ou corrompido; restaurando cópia única de segurança.',
      );
      await arquivoSeguranca.copy(arquivoAtual.path);
      return lidoSeguranca;
    }

