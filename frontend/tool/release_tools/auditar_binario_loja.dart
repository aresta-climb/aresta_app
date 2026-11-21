// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';

/// Resultado estruturado da auditoria de pureza e integridade de um binário de loja.
class ResultadoAuditoriaBinario {
  /// Indica se o pacote passou em todas as verificações de pureza e integridade.
  final bool aprovado;

  /// Lista de violações encontradas (vazia quando [aprovado] é `true`).
  final List<String> erros;

  const ResultadoAuditoriaBinario({
    required this.aprovado,
    required this.erros,
  });
}

/// Audita pacotes oficiais `.aab` e `.ipa` do Aresta Climb garantindo ausência física
/// de código/rotas de smoke test e presença das bibliotecas nativas essenciais.
class AuditorBinarioLoja {
  /// Marcadores estritamente proibidos nos artefatos oficiais de produção.
  static const List<String> marcadoresProibidos = <String>[
    '/__smoke__/',
    'app.escalada.croquis/smoke_ci',
    'ARESTA_SMOKE_SERVER',
    'main_smoke_ci',
  ];

  /// Inspeciona um Android App Bundle (`.aab`) oficial de release.
  static ResultadoAuditoriaBinario auditarAab(File arquivoAab) {
    final erros = <String>[];
    if (!arquivoAab.existsSync()) {
      return ResultadoAuditoriaBinario(
        aprovado: false,
        erros: <String>['Arquivo AAB não encontrado: ${arquivoAab.path}'],
      );
    }

    final archive = ZipDecoder().decodeBytes(arquivoAab.readAsBytesSync());
    final entradas = <String, ArchiveFile>{
      for (final f in archive) f.name: f,
    };

    final dexArquivos = entradas.keys
        .where((n) => n.startsWith('base/dex/') && n.endsWith('.dex'))
        .toList();
    if (dexArquivos.isEmpty) {
      erros.add('Nenhum bytecode base/dex/*.dex encontrado no AAB.');
    }

    for (final obrigatorio in const <String>[
      'base/lib/arm64-v8a/libapp.so',
      'base/lib/arm64-v8a/libflutter.so',
    ]) {
      final item = entradas[obrigatorio];
      if (item == null || item.size <= 0) {
        erros.add('Biblioteca nativa obrigatória ausente no AAB: $obrigatorio');
      }
    }

    final inspecionarPureza = entradas.keys.where(
      (n) =>
          (n.startsWith('base/dex/') && n.endsWith('.dex')) ||
          n.endsWith('/libapp.so'),
    );
    for (final nome in inspecionarPureza) {
      final bytes = entradas[nome]!.content as List<int>;
      for (final marcador in marcadoresProibidos) {
        if (_contemSubsequenciaBytes(bytes, ascii.encode(marcador))) {
          erros.add(
            'VIOLAÇÃO DE PUREZA: marcador proibido "$marcador" encontrado em $nome.',
          );
        }
      }
    }

    return ResultadoAuditoriaBinario(aprovado: erros.isEmpty, erros: erros);
  }

  /// Inspeciona um pacote iOS (`.ipa`) oficial de release.
  static ResultadoAuditoriaBinario auditarIpa(File arquivoIpa) {
    final erros = <String>[];
    if (!arquivoIpa.existsSync()) {
      return ResultadoAuditoriaBinario(
        aprovado: false,
        erros: <String>['Arquivo IPA não encontrado: ${arquivoIpa.path}'],
      );
    }

    final archive = ZipDecoder().decodeBytes(arquivoIpa.readAsBytesSync());
    final entradas = <String, ArchiveFile>{
      for (final f in archive) f.name: f,
    };

    for (final obrigatorio in const <String>[
      'Payload/Runner.app/Runner',
      'Payload/Runner.app/Frameworks/App.framework/App',
      'Payload/Runner.app/Frameworks/Flutter.framework/Flutter',
      'Payload/Runner.app/Info.plist',
    ]) {
      final item = entradas[obrigatorio];
      if (item == null || item.size <= 0) {
        erros.add('Artefato obrigatório ausente no IPA: $obrigatorio');
      }
    }

    final infoPlist = entradas['Payload/Runner.app/Info.plist'];
    if (infoPlist != null) {
      final plistBytes = infoPlist.content as List<int>;
      if (!_contemSubsequenciaBytes(
        plistBytes,
        ascii.encode('ITSAppUsesNonExemptEncryption'),
      )) {
        erros.add(
          'Chave obrigatória ITSAppUsesNonExemptEncryption ausente em Payload/Runner.app/Info.plist.',
        );
      }
    }

    for (final nome in const <String>[
      'Payload/Runner.app/Runner',
      'Payload/Runner.app/Frameworks/App.framework/App',
    ]) {
      final item = entradas[nome];
      if (item == null) continue;
      final bytes = item.content as List<int>;
      for (final marcador in marcadoresProibidos) {
        if (_contemSubsequenciaBytes(bytes, ascii.encode(marcador))) {
          erros.add(
            'VIOLAÇÃO DE PUREZA: marcador proibido "$marcador" encontrado em $nome.',
          );
        }
      }
    }

    return ResultadoAuditoriaBinario(aprovado: erros.isEmpty, erros: erros);
  }

  static bool _contemSubsequenciaBytes(List<int> feno, List<int> agulha) {
    if (agulha.isEmpty || feno.length < agulha.length) {
      return false;
    }
    final primeiro = agulha[0];
    final limite = feno.length - agulha.length;
    for (var i = 0; i <= limite; i++) {
      if (feno[i] != primeiro) continue;
      var bateu = true;
      for (var j = 1; j < agulha.length; j++) {
        if (feno[i + j] != agulha[j]) {
          bateu = false;
          break;
        }
      }
      if (bateu) return true;
    }
    return false;
  }
}

/// Executa a auditoria via argumentos de linha de comando e retorna o código de saída (`0`, `1` ou `2`).
int executarCliAuditoria(List<String> args) {
  String? caminhoAab;
  String? caminhoIpa;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--aab' && i + 1 < args.length) {
      caminhoAab = args[++i];
    } else if (args[i] == '--ipa' && i + 1 < args.length) {
      caminhoIpa = args[++i];
    }
  }

  if (caminhoAab == null && caminhoIpa == null) {
    stderr.writeln(
      'Uso: auditar_binario_loja.dart [--aab <arquivo.aab>] [--ipa <arquivo.ipa>]',
    );
    return 2;
  }

  var tudoOk = true;
  if (caminhoAab != null) {
    final res = AuditorBinarioLoja.auditarAab(File(caminhoAab));
    if (!res.aprovado) {
      for (final e in res.erros) {
        stderr.writeln('[ERRO AAB] $e');
      }
      tudoOk = false;
    } else {
      stdout.writeln(
        '[OK AAB] Pureza binária e bibliotecas nativas validadas: $caminhoAab',
      );
    }
  }

  if (caminhoIpa != null) {
    final res = AuditorBinarioLoja.auditarIpa(File(caminhoIpa));
    if (!res.aprovado) {
      for (final e in res.erros) {
        stderr.writeln('[ERRO IPA] $e');
      }
      tudoOk = false;
    } else {
      stdout.writeln(
        '[OK IPA] Pureza binária, Frameworks e Info.plist validados: $caminhoIpa',
      );
    }
  }

  return tudoOk ? 0 : 1;
}

void main(List<String> args) {
  final rc = executarCliAuditoria(args);
  if (rc != 0) {
    exit(rc);
  }
}
