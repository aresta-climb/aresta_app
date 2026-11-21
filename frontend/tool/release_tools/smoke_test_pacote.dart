// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:archive/archive.dart';
import 'auditar_binario_loja.dart';
import 'servidor_smoke_ci.dart';

/// Resultado de execução de um subprocesso externo acionado pelo orquestrador.
class ResultadoProcessoCli {
  final int exitCode;
  final String stdout;
  final String stderr;

  const ResultadoProcessoCli(this.exitCode, this.stdout, this.stderr);
}

/// Assinatura injetável para execução de subprocessos CLI (`adb`, `java`, `xcrun`, `flutter`).
typedef ExecutorProcessoCli = Future<ResultadoProcessoCli> Function(
  String executavel,
  List<String> argumentos, {
  Map<String, String>? ambiente,
});

/// Orquestra a validação pós-build completa dos pacotes móveis do Aresta Climb em CI:
/// - Auditoria de pureza binária do pacote oficial (`.aab` / `.ipa`);
/// - Cold Start puro do `universal.apk` extraído do `.aab` oficial no Android Emulator;
/// - Verificação de assinatura e linkagem dinâmica (`codesign` e `otool -L`) do `.ipa` no macOS;
/// - Execução da jornada ponta a ponta autenticada contra [ServidorSmokeCi] em loopback.
class OrquestradorSmokePacote {
  final ExecutorProcessoCli _executorProcesso;
  final Duration tempoEsperaColdStart;
  final Duration timeoutJornada;

  OrquestradorSmokePacote({
    ExecutorProcessoCli? executorProcesso,
    this.tempoEsperaColdStart = const Duration(seconds: 6),
    this.timeoutJornada = const Duration(seconds: 150),
  }) : _executorProcesso = executorProcesso ?? _executarProcessoPadrao;

  static Future<ResultadoProcessoCli> _executarProcessoPadrao(
    String executavel,
    List<String> argumentos, {
    Map<String, String>? ambiente,
  }) async {
    final res = await Process.run(
      executavel,
      argumentos,
      environment: ambiente,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    return ResultadoProcessoCli(
      res.exitCode,
      res.stdout?.toString() ?? '',
      res.stderr?.toString() ?? '',
    );
  }

  static String _gerarTokenEfemero() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<ResultadoProcessoCli> _exigirSucesso(
    String executavel,
    List<String> argumentos, {
    Map<String, String>? ambiente,
  }) async {
    final res = await _executorProcesso(
      executavel,
      argumentos,
      ambiente: ambiente,
    );
    if (res.exitCode != 0) {
      throw StateError(
        'Comando falhou (${res.exitCode}): $executavel ${argumentos.join(' ')}\n'
        'STDOUT: ${res.stdout}\nSTDERR: ${res.stderr}',
      );
    }
    return res;
  }

  /// Executa auditoria + Cold Start do `.aab` oficial + jornada completa do APK de smoke no Android.
  Future<void> executarAndroid({
    required File arquivoAab,
    required File arquivoApkSmoke,
    required File bundletoolJar,
    required String pacote,
    Directory? diretorioSimbolos,
    File? arquivoSaidaEvidencia,
  }) async {
    stdout.writeln('==> [Android 1/3] Auditando pureza binária do AAB oficial...');
    final auditoria = AuditorBinarioLoja.auditarAab(arquivoAab);
    if (!auditoria.aprovado) {
      throw StateError(
        'Auditoria do AAB oficial reprovada:\n${auditoria.erros.join('\n')}',
      );
    }

    final tempDir = await Directory.systemTemp.createTemp('smoke_android_ci_');
    try {
      stdout.writeln('==> [Android 2/3] Validando Cold Start puro do universal.apk da loja...');
      final debugKsPath = '${tempDir.path}/smoke_debug.keystore';
      await _exigirSucesso('keytool', <String>[
        '-genkeypair',
        '-keystore',
        debugKsPath,
        '-storepass',
        'android',
        '-alias',
        'androiddebugkey',
        '-keypass',
        'android',
        '-keyalg',
        'RSA',
        '-keysize',
        '2048',
        '-validity',
        '1',
        '-dname',
        'CN=Smoke CI,O=Aresta,C=BR',
      ]);

      final apksPath = '${tempDir.path}/loja_universal.apks';
      await _exigirSucesso('java', <String>[
        '-jar',
        bundletoolJar.path,
        'build-apks',
        '--bundle=${arquivoAab.path}',
        '--output=$apksPath',
        '--mode=universal',
        '--ks=$debugKsPath',
        '--ks-pass=pass:android',
        '--ks-key-alias=androiddebugkey',
        '--key-pass=pass:android',
      ]);

      final apksBytes = File(apksPath).readAsBytesSync();
      final apksZip = ZipDecoder().decodeBytes(apksBytes);
      final universalEntry = apksZip.firstWhere(
        (e) => e.name.endsWith('universal.apk'),
        orElse: () => throw StateError('universal.apk não encontrado em $apksPath'),
      );
      final universalApk = File('${tempDir.path}/universal.apk');
      universalApk.writeAsBytesSync(universalEntry.content as List<int>);

      await _executorProcesso('adb', <String>['uninstall', pacote]);
      await _exigirSucesso('adb', <String>['install', '-r', universalApk.path]);
      await _executorProcesso('adb', <String>['logcat', '-c']);
      await _exigirSucesso('adb', <String>[
        'shell',
        'am',
        'start',
        '-W',
        '-n',
        '$pacote/com.example.frontend.MainActivity',
      ]);

      await Future<void>.delayed(tempoEsperaColdStart);
      final pidRes = await _executorProcesso('adb', <String>['shell', 'pidof', pacote]);
      final logcatColdStart = await _executorProcesso('adb', <String>[
        'logcat',
        '-d',
        '-s',
        'AndroidRuntime:E',
        'flutter:E',
      ]);
      await _executorProcesso('adb', <String>['uninstall', pacote]);

      if (pidRes.exitCode != 0 || pidRes.stdout.trim().isEmpty) {
        throw StateError(
          'Cold Start do AAB oficial falhou: processo $pacote encerrou prematuramente.\n'
          'Logcat:\n${logcatColdStart.stdout}',
        );
      }
      if (logcatColdStart.stdout.contains('FATAL EXCEPTION') &&
          logcatColdStart.stdout.contains(pacote)) {
        throw StateError(
          'Cold Start do AAB oficial apresentou FATAL EXCEPTION:\n${logcatColdStart.stdout}',
        );
      }

      stdout.writeln(
        '==> [Android 3/3] Executando jornada ponta a ponta no APK de smoke (--release --obfuscate)...',
      );
      final token = _gerarTokenEfemero();
      final servidor = await ServidorSmokeCi.iniciar(tokenEsperado: token);
      try {
        await _exigirSucesso('adb', <String>['install', '-r', arquivoApkSmoke.path]);
        await _executorProcesso('adb', <String>['logcat', '-c']);

        final futuroRelatorio = servidor.aguardarRelatorio(timeout: timeoutJornada);
        await _exigirSucesso('adb', <String>[
          'shell',
          'am',
          'start',
          '-W',
          '-n',
          '$pacote/com.example.frontend.MainActivity',
          '--es',
          'smoke_server',
          servidor.uriEmuladorAndroid.toString(),
          '--es',
          'smoke_token',
          token,
        ]);

        Map<String, dynamic> relatorio;
        try {
          relatorio = await futuroRelatorio;
        } catch (e) {
          final dumpLogcat = await _executorProcesso('adb', <String>['logcat', '-d']);
          throw StateError(
            'Timeout/falha aguardando relatório do smoke Android: $e\n'
            'Últimas linhas do logcat:\n${_ultimasLinhas(dumpLogcat.stdout, 120)}',
          );
        }

        if (relatorio['sucesso'] != true) {
          final textoErros = (relatorio['erros'] as List<dynamic>? ?? const <dynamic>[])
              .join('\n---\n');
          final desofuscado = await _tentarSimbolizar(textoErros, diretorioSimbolos);
          throw StateError(
            'Jornada de smoke Android reprovada!\nEtapas concluídas: ${relatorio['etapas']}\n'
            'Erros:\n$desofuscado',
          );
        }

        if (arquivoSaidaEvidencia != null) {
          await arquivoSaidaEvidencia.parent.create(recursive: true);
          await arquivoSaidaEvidencia.writeAsString(
            const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
              'plataforma': 'android',
              'pacote': pacote,
              'auditoriaAabAprovada': true,
              'coldStartLojaAprovado': true,
              'jornadaSmoke': relatorio,
            }),
          );
        }
        stdout.writeln('==> [Android OK] Jornada concluída: ${relatorio['etapas']}');
      } finally {
        await _executorProcesso('adb', <String>['uninstall', pacote]);
        await servidor.encerrar();
      }
    } finally {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  /// Executa auditoria do `.ipa` oficial (`codesign` + `otool`) e jornada completa no iOS Simulator.
  Future<void> executarIos({
    required File arquivoIpa,
    required Directory diretorioAppSimulador,
    required String pacote,
    Directory? diretorioSimbolos,
    File? arquivoSaidaEvidencia,
  }) async {
    stdout.writeln('==> [iOS 1/2] Auditando pureza binária, codesign e linkagem do IPA oficial...');
    final auditoria = AuditorBinarioLoja.auditarIpa(arquivoIpa);
    if (!auditoria.aprovado) {
      throw StateError(
        'Auditoria do IPA oficial reprovada:\n${auditoria.erros.join('\n')}',
      );
    }

    final tempDir = await Directory.systemTemp.createTemp('smoke_ios_ci_');
    try {
      await _exigirSucesso('unzip', <String>['-q', arquivoIpa.path, '-d', tempDir.path]);
      final appExtraido = '${tempDir.path}/Payload/Runner.app';
      await _exigirSucesso('codesign', <String>['--verify', '--verbose=2', appExtraido]);
      await _exigirSucesso('otool', <String>['-L', '$appExtraido/Runner']);

      stdout.writeln('==> [iOS 2/2] Executando jornada ponta a ponta no iOS Simulator...');
      final token = _gerarTokenEfemero();
      final servidor = await ServidorSmokeCi.iniciar(tokenEsperado: token);
      try {
        await _executorProcesso('xcrun', <String>['simctl', 'terminate', 'booted', pacote]);
        await _executorProcesso('xcrun', <String>['simctl', 'uninstall', 'booted', pacote]);
        await _exigirSucesso('xcrun', <String>[
          'simctl',
          'install',
          'booted',
          diretorioAppSimulador.path,
        ]);

        final futuroRelatorio = servidor.aguardarRelatorio(timeout: timeoutJornada);
        await _exigirSucesso(
          'xcrun',
          <String>['simctl', 'launch', 'booted', pacote],
          ambiente: <String, String>{
            ...Platform.environment,
            'SIMCTL_CHILD_ARESTA_SMOKE_SERVER': servidor.uriLocalHost.toString(),
            'SIMCTL_CHILD_ARESTA_SMOKE_TOKEN': token,
          },
        );

        Map<String, dynamic> relatorio;
        try {
          relatorio = await futuroRelatorio;
        } catch (e) {
          final logsSim = await _executorProcesso('xcrun', <String>[
            'simctl',
            'spawn',
            'booted',
            'log',
            'show',
            '--last',
            '2m',
            '--predicate',
            'process == "Runner"',
          ]);
          throw StateError(
            'Timeout/falha aguardando relatório do smoke iOS: $e\n'
            'Logs do Simulator:\n${_ultimasLinhas(logsSim.stdout, 120)}',
          );
        }

        if (relatorio['sucesso'] != true) {
          final textoErros = (relatorio['erros'] as List<dynamic>? ?? const <dynamic>[])
              .join('\n---\n');
          final desofuscado = await _tentarSimbolizar(textoErros, diretorioSimbolos);
          throw StateError(
            'Jornada de smoke iOS reprovada!\nEtapas concluídas: ${relatorio['etapas']}\n'
            'Erros:\n$desofuscado',
          );
        }

        if (arquivoSaidaEvidencia != null) {
          await arquivoSaidaEvidencia.parent.create(recursive: true);
          await arquivoSaidaEvidencia.writeAsString(
            const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
              'plataforma': 'ios',
              'pacote': pacote,
              'auditoriaIpaAprovada': true,
              'jornadaSmoke': relatorio,
            }),
          );
        }
        stdout.writeln('==> [iOS OK] Jornada concluída: ${relatorio['etapas']}');
      } finally {
        await _executorProcesso('xcrun', <String>['simctl', 'terminate', 'booted', pacote]);
        await servidor.encerrar();
      }
    } finally {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  Future<String> _tentarSimbolizar(String stackBruto, Directory? dirSimbolos) async {
    if (dirSimbolos == null || !dirSimbolos.existsSync() || stackBruto.trim().isEmpty) {
      return stackBruto;
    }
    final arqEntrada = File(
      '${Directory.systemTemp.path}/stack_smoke_${DateTime.now().millisecondsSinceEpoch}.txt',
    );
    try {
      await arqEntrada.writeAsString(stackBruto);
      final simbolos = dirSimbolos
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.symbols'))
          .toList();
      if (simbolos.isEmpty) return stackBruto;
      final res = await _executorProcesso('flutter', <String>[
        'symbolize',
        '-i',
        arqEntrada.path,
        '-d',
        simbolos.first.path,
      ]);
      return res.exitCode == 0 && res.stdout.trim().isNotEmpty ? res.stdout : stackBruto;
    } finally {
      if (arqEntrada.existsSync()) {
        arqEntrada.deleteSync();
      }
    }
  }

  static String _ultimasLinhas(String texto, int maxLinhas) {
    final linhas = texto.split('\n');
    if (linhas.length <= maxLinhas) return texto;
    return linhas.sublist(linhas.length - maxLinhas).join('\n');
  }
}

Future<void> main(List<String> args) async {
  String? plataforma;
  String? aab;
  String? apkSmoke;
  String? bundletoolJar;
  String? ipa;
  String? appSimulador;
  String pacote = 'app.escalada.croquis';
  String? simbolos;
  String? saidaRelatorio;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--plataforma' && i + 1 < args.length) {
      plataforma = args[++i];
    } else if (arg == '--aab' && i + 1 < args.length) {
      aab = args[++i];
    } else if (arg == '--apk-smoke' && i + 1 < args.length) {
      apkSmoke = args[++i];
    } else if (arg == '--bundletool-jar' && i + 1 < args.length) {
      bundletoolJar = args[++i];
    } else if (arg == '--ipa' && i + 1 < args.length) {
      ipa = args[++i];
    } else if (arg == '--app-simulador' && i + 1 < args.length) {
      appSimulador = args[++i];
    } else if (arg == '--pacote' && i + 1 < args.length) {
      pacote = args[++i];
    } else if (arg == '--simbolos' && i + 1 < args.length) {
      simbolos = args[++i];
    } else if (arg == '--saida-relatorio' && i + 1 < args.length) {
      saidaRelatorio = args[++i];
    }
  }

  final orq = OrquestradorSmokePacote();
  final dirSimbolos = simbolos != null ? Directory(simbolos) : null;
  final arqSaida = saidaRelatorio != null ? File(saidaRelatorio) : null;

  if (plataforma == 'android') {
    if (aab == null || apkSmoke == null || bundletoolJar == null) {
      stderr.writeln(
        'Parâmetros obrigatórios para android: --aab, --apk-smoke, --bundletool-jar',
      );
      exit(2);
    }
    await orq.executarAndroid(
      arquivoAab: File(aab),
      arquivoApkSmoke: File(apkSmoke),
      bundletoolJar: File(bundletoolJar),
      pacote: pacote,
      diretorioSimbolos: dirSimbolos,
      arquivoSaidaEvidencia: arqSaida,
    );
  } else if (plataforma == 'ios') {
    if (ipa == null || appSimulador == null) {
      stderr.writeln('Parâmetros obrigatórios para ios: --ipa, --app-simulador');
      exit(2);
    }
    await orq.executarIos(
      arquivoIpa: File(ipa),
      diretorioAppSimulador: Directory(appSimulador),
      pacote: pacote,
      diretorioSimbolos: dirSimbolos,
      arquivoSaidaEvidencia: arqSaida,
    );
  } else {
    stderr.writeln('Informe --plataforma android ou --plataforma ios');
    exit(2);
  }
}
