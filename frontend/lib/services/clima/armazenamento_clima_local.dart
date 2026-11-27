// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../firebase/app_logger.dart';
import '../../data/modelos/modelos_clima_pico.dart';

/// Persistência local com rotação atômica de cópia única de segurança (`atual` + `seguranca`).
///
/// Garante que apenas duas versões coexistam no disco do dispositivo (descartando dados
/// antigos a cada atualização) e recupera automaticamente a cópia de segurança caso
/// o arquivo ativo sofra escrita incompleta ou corrupção.
class ArmazenamentoClimaLocal {
  static const String nomeArquivoAtual = 'clima_altimetria_atual.json';
  static const String nomeArquivoSeguranca = 'clima_altimetria_seguranca.json';

  final Future<String> Function() _provedorDiretorioBase;

  ArmazenamentoClimaLocal({
    Future<String> Function()? provedorDiretorioBase,
  }) : _provedorDiretorioBase =
            provedorDiretorioBase ?? _obterDiretorioDocumentosPadrao;

  static Future<String> _obterDiretorioDocumentosPadrao() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  /// Grava [snapshot] validando via arquivo `.tmp`, promovendo o `atual` anterior
  /// para `seguranca` (descartando cópias antigas) e atualizando `atual` atomicamente.
  Future<void> salvarSnapshot(SnapshotClimaAltimetria snapshot) async {
    final dirBase = await _provedorDiretorioBase();
    final diretorio = Directory(dirBase);
    if (!diretorio.existsSync()) {
      diretorio.createSync(recursive: true);
    }

    final caminhoAtual = '$dirBase/$nomeArquivoAtual';
    final caminhoSeguranca = '$dirBase/$nomeArquivoSeguranca';
    final caminhoTmp = '$caminhoAtual.tmp';

    final jsonTexto = jsonEncode(snapshot.paraMapa());
    final arquivoTmp = File(caminhoTmp);
    await arquivoTmp.writeAsString(jsonTexto, flush: true);

    final arquivoAtual = File(caminhoAtual);
    final atualValido = _tentarLerArquivo(arquivoAtual);
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

  /// Lê o snapshot `atual`, recorrendo e reparando a partir da única `copia_seguranca` se corrompido.
  Future<SnapshotClimaAltimetria?> lerSnapshot() async {
    final dirBase = await _provedorDiretorioBase();
    final arquivoAtual = File('$dirBase/$nomeArquivoAtual');
    final lidoAtual = _tentarLerArquivo(arquivoAtual);
    if (lidoAtual != null) {
      return lidoAtual;
    }

    final arquivoSeguranca = File('$dirBase/$nomeArquivoSeguranca');
    final lidoSeguranca = _tentarLerArquivo(arquivoSeguranca);
    if (lidoSeguranca != null) {
      AppLogger.instance.logAviso(
        '[ArmazenamentoClimaLocal] Arquivo atual ausente ou corrompido; restaurando cópia única de segurança.',
      );
      await arquivoSeguranca.copy(arquivoAtual.path);
      return lidoSeguranca;
    }

    return null;
  }

  /// Lê diretamente a cópia única de segurança armazenada em disco (quando existente).
  Future<SnapshotClimaAltimetria?> lerCopiaSeguranca() async {
    final dirBase = await _provedorDiretorioBase();
    return _tentarLerArquivo(File('$dirBase/$nomeArquivoSeguranca'));
  }

  static SnapshotClimaAltimetria? _tentarLerArquivo(File arquivo) {
    if (!arquivo.existsSync()) return null;
    try {
      final mapa = jsonDecode(arquivo.readAsStringSync());
      if (mapa is! Map<String, dynamic>) return null;
      return SnapshotClimaAltimetria.deMapa(mapa);
    } catch (_) {
      return null;
    }
  }
}
