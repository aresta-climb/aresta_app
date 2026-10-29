// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Resultado imutável da classificação de porte de memória RAM do dispositivo.
class PerfilDispositivo {
  /// Categoria do dispositivo: `'baixo'` (<= 3 GB), `'medio'` (4-6 GB), `'alto'` (>= 8 GB) ou `'desconhecido'`.
  final String tierDispositivo;

  /// Memória RAM total aproximada em gigabytes formatada como texto (ex: `'3'`, `'6'`, `'12'`, `'0'`).
  final String ramGb;

  /// Limite máximo em bytes recomendado para o `PaintingBinding.instance.imageCache`.
  final int limiteCacheImagensBytes;

  const PerfilDispositivo({
    required this.tierDispositivo,
    required this.ramGb,
    required this.limiteCacheImagensBytes,
  });
}

/// Classificador determinístico do porte de memória RAM física do dispositivo.
///
/// Utilizado na inicialização do aplicativo para dimensionar o teto adaptativo do cache
/// de bitmaps (`imageCache.maximumSizeBytes`) e enriquecer automaticamente traces do
/// Firebase Performance e eventos do Google Analytics 4 com as dimensões `tier_dispositivo` e `ram_gb`.
class ClassificadorDispositivo {
  ClassificadorDispositivo._construtorPrivado();

  /// Instância singleton global do classificador.
  static ClassificadorDispositivo instancia =
      ClassificadorDispositivo._construtorPrivado();

  /// Caminho padrão do arquivo de informações de memória do kernel Linux/Android.
  static String caminhoMeminfoPadrao = '/proc/meminfo';

  static const int _limiteBaixoBytes = 50 * 1024 * 1024;
  static const int _limiteMedioBytes = 100 * 1024 * 1024;
  static const int _limiteAltoBytes = 150 * 1024 * 1024;

  PerfilDispositivo _perfilAtual = const PerfilDispositivo(
    tierDispositivo: 'desconhecido',
    ramGb: '0',
    limiteCacheImagensBytes: _limiteMedioBytes,
  );

  /// Categoria atual do dispositivo (`'baixo'`, `'medio'`, `'alto'` ou `'desconhecido'`).
  String get tierDispositivo => _perfilAtual.tierDispositivo;

  /// Memória RAM em GB do dispositivo atual (`'0'` quando desconhecido).
  String get ramGb => _perfilAtual.ramGb;

  /// Teto em bytes recomendado para o `imageCache` do dispositivo atual.
  int get limiteCacheImagensBytes => _perfilAtual.limiteCacheImagensBytes;

  /// Reseta o estado do classificador para isolamento entre testes.
  @visibleForTesting
  static void resetarParaTestes({String? caminhoMeminfoPadrao}) {
    ClassificadorDispositivo.caminhoMeminfoPadrao =
        caminhoMeminfoPadrao ?? '/proc/meminfo';
    instancia = ClassificadorDispositivo._construtorPrivado();
  }

  /// Classifica o dispositivo a partir de [ramTotalMb] (quando informado) ou lendo
  /// [caminhoMeminfo] (padrão `/proc/meminfo`), atualizando o perfil ativo em memória.
  PerfilDispositivo classificar({int? ramTotalMb, String? caminhoMeminfo}) {
    final int? mbResolvido =
        ramTotalMb ?? _lerRamMbDeArquivo(caminhoMeminfo ?? caminhoMeminfoPadrao);

    if (mbResolvido == null || mbResolvido <= 0) {
      _perfilAtual = const PerfilDispositivo(
        tierDispositivo: 'desconhecido',
        ramGb: '0',
        limiteCacheImagensBytes: _limiteMedioBytes,
      );
      return _perfilAtual;
    }

    final int gbArredondado = math.max(1, (mbResolvido / 1024.0).round());
    final String tier;
    final int limiteBytes;

    if (mbResolvido <= 3584) {
      tier = 'baixo';
      limiteBytes = _limiteBaixoBytes;
    } else if (mbResolvido <= 6656) {
      tier = 'medio';
      limiteBytes = _limiteMedioBytes;
    } else {
      tier = 'alto';
      limiteBytes = _limiteAltoBytes;
    }

    _perfilAtual = PerfilDispositivo(
      tierDispositivo: tier,
      ramGb: gbArredondado.toString(),
      limiteCacheImagensBytes: limiteBytes,
    );
    return _perfilAtual;
  }

  static int? _lerRamMbDeArquivo(String caminho) {
    final arquivo = File(caminho);
    if (!arquivo.existsSync()) return null;
    final conteudo = arquivo.readAsStringSync();
    final match = RegExp(
      r'MemTotal:\s+(\d+)\s+kB',
      caseSensitive: false,
    ).firstMatch(conteudo);
    if (match == null) return null;
    final int kb = int.parse(match.group(1)!);
    return (kb / 1024.0).round();
  }
}
