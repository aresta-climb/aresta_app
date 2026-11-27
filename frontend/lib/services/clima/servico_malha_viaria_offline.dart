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

    return null;
  }

  /// Lê diretamente a cópia única de segurança em disco quando existente.
  Future<SnapshotMalhaViariaOffline?> lerCopiaSeguranca() async {
    final dirBase = await _provedorDiretorioBase();
    if (dirBase == null) return null;
    return _tentarLerArquivo(File('$dirBase/$nomeArquivoSeguranca'));
  }

  static Future<SnapshotMalhaViariaOffline?> _tentarLerArquivo(
    File arquivo,
  ) async {
    if (!arquivo.existsSync()) return null;
    try {
      final bruto = await arquivo.readAsString();
      return await Isolate.run(() {
        final decodificado = jsonDecode(bruto);
        if (decodificado is! Map<String, dynamic>) return null;
        return SnapshotMalhaViariaOffline.deMapa(decodificado);
      });
    } catch (_) {
      return null;
    }
  }
}

/// Fronteira remota para sincronização incremental de `public.snapshots_malha_viaria_picos`.
abstract interface class FonteRemotaMalhaViaria {
  /// Consulta apenas o cabeçalho leve (`versao_hash`) para evitar download desnecessário em campo.
  Future<String?> consultarVersaoRemota();

  /// Baixa o snapshot completo de rodovias pavimentadas com fallback para `copia_seguranca`.
  Future<SnapshotMalhaViariaOffline> buscarSnapshotRemoto();
}

/// Cliente PostgREST que lê `public.snapshots_malha_viaria_picos` (`atual` -> `copia_seguranca`).
class ClienteMalhaViariaSupabase implements FonteRemotaMalhaViaria {
  static const String nomeTabela = 'snapshots_malha_viaria_picos';

  final String urlBaseSupabase;
  final String chaveAnonima;
  final ClienteHttpAresta _clienteHttp;
  final Duration timeoutRequisicao;

  ClienteMalhaViariaSupabase({
    String? urlBaseSupabase,
    String? chaveAnonima,
    ClienteHttpAresta? clienteHttp,
    this.timeoutRequisicao = const Duration(seconds: 6),
  })  : urlBaseSupabase =
            (urlBaseSupabase ?? NetworkConstants.kDefaultSupabaseUrl)
                .replaceAll(RegExp(r'/+$'), ''),
        chaveAnonima = chaveAnonima ?? NetworkConstants.kDefaultSupabaseAnonKey,
        _clienteHttp = clienteHttp ?? ClienteHttpAresta.instancia;

  Map<String, String> get _cabecalhos {
    final headers = <String, String>{
      'apikey': chaveAnonima,
      'Accept': 'application/json',
    };
    if (chaveAnonima.startsWith('eyJ')) {
      headers['Authorization'] = 'Bearer $chaveAnonima';
    }
    return headers;
  }

  @override
  Future<String?> consultarVersaoRemota() async {
    final meta = await _consultarComFallbackSlot(colunas: 'slot,versao_hash');
    final versao = (meta['versao_hash'] as String?)?.trim() ?? '';
    return versao.isEmpty ? null : versao;
  }

  @override
  Future<SnapshotMalhaViariaOffline> buscarSnapshotRemoto() async {
    final textoBruto = await _consultarTextoComFallbackSlot(
      colunas: 'gerado_em,versao_hash,rodovias',
    );
    return Isolate.run(() {
      final lista = jsonDecode(textoBruto) as List<dynamic>;
      final primeiro = Map<String, dynamic>.from(lista.first as Map);
      return SnapshotMalhaViariaOffline.deMapa(primeiro);
    });
  }

  Future<Map<String, dynamic>> _consultarComFallbackSlot({
    required String colunas,
  }) async {
    final texto = await _consultarTextoComFallbackSlot(colunas: colunas);
    final lista = jsonDecode(texto) as List<dynamic>;
    return Map<String, dynamic>.from(lista.first as Map);
  }

  Future<String> _consultarTextoComFallbackSlot({
    required String colunas,
  }) async {
    final atual = await _consultarSlotTexto('atual', colunas: colunas);
    if (atual != null) return atual;

    final seguranca = await _consultarSlotTexto(
      'copia_seguranca',
      colunas: colunas,
    );
    if (seguranca != null) {
      AppLogger.instance.logAviso(
        '[ClienteMalhaViariaSupabase] Slot atual vazio; utilizando slot copia_seguranca.',
      );
      return seguranca;
    }

    throw const HttpException(
      'Nenhum registro válido em snapshots_malha_viaria_picos (atual/copia_seguranca).',
    );
  }

  Future<String?> _consultarSlotTexto(
    String slot, {
    required String colunas,
  }) async {
    final uri = Uri.parse(
      '$urlBaseSupabase/rest/v1/$nomeTabela?select=$colunas&slot=eq.$slot&limit=1',
    );
    final resp =
        await _clienteHttp.get(uri, headers: _cabecalhos).timeout(timeoutRequisicao);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw HttpException(
        'Erro HTTP ${resp.statusCode} ao consultar $nomeTabela ($slot).',
        uri: uri,
      );
    }
    final decodificado = jsonDecode(resp.body);
    if (decodificado is List &&
        decodificado.isNotEmpty &&
        decodificado.first is Map) {
      return resp.body;
    }
    return null;
  }
}

/// Serviço offline-first que mantém a cópia local da malha viária para setores remotos sem sinal
/// e sincroniza incrementalmente com o Supabase quando o escalador retorna a área conectada.
class ServicoMalhaViariaOffline extends ChangeNotifier {
  static const Duration ttlVerificacao = Duration(hours: 6);

  static ServicoMalhaViariaOffline? _instanciaCompartilhada;

  /// Instância compartilhada usada por [CenaGloboExplorarViewModel].
  static ServicoMalhaViariaOffline get instancia =>
      _instanciaCompartilhada ??= ServicoMalhaViariaOffline();

  /// Restaura a instância global entre testes isolados.
  @visibleForTesting
  static void redefinirParaTestes() {
    _instanciaCompartilhada?.dispose();
    _instanciaCompartilhada = null;
  }

  final ArmazenamentoMalhaViariaLocal _armazenamento;
  final FonteRemotaMalhaViaria _fonteRemota;
  final DateTime Function() _relogioUtc;

  SnapshotMalhaViariaOffline? _snapshotAtivo;
  DateTime? _ultimaVerificacaoUtc;
  Future<bool>? _sincronizacaoEmVoo;
  bool _inicializado = false;
  bool _descartado = false;

  ServicoMalhaViariaOffline({
    ArmazenamentoMalhaViariaLocal? armazenamento,
    FonteRemotaMalhaViaria? fonteRemota,
    DateTime Function()? relogioUtc,
  })  : _armazenamento = armazenamento ?? ArmazenamentoMalhaViariaLocal(),
        _fonteRemota = fonteRemota ?? ClienteMalhaViariaSupabase(),
        _relogioUtc = relogioUtc ?? (() => DateTime.now().toUtc());

  /// Verdadeiro após verificar a cópia local em disco.
  bool get inicializado => _inicializado;

  /// Último snapshot offline persistido em disco (ou `null` quando a semente do APK é a vigente).
  SnapshotMalhaViariaOffline? get snapshotAtivo => _snapshotAtivo;

  /// Versão hash atualmente persistida no cache local em disco.
  String? get versaoAtiva => _snapshotAtivo?.versaoHash;

  /// Hidrata imediatamente a cópia local em disco sem exigir rede.
  Future<void> inicializar() async {
    if (_inicializado || _descartado) return;
    final cacheDisco = await _armazenamento.lerSnapshot();
    if (_descartado) return;
    _snapshotAtivo = cacheDisco;
    _inicializado = true;
    if (cacheDisco != null) {
      notifyListeners();
    }
  }

  /// Verifica se o Supabase possui uma `versao_hash` mais recente que [versaoSementeEmbarcada]
  /// ou o cache local, baixando e rotacionando a cópia offline quando houver cobertura de rede.
  Future<bool> sincronizarSeDisponivel({
    bool forcar = false,
    String? versaoSementeEmbarcada,
  }) {
    final emVoo = _sincronizacaoEmVoo;
    if (emVoo != null) return emVoo;
    final futuro = _executarSincronizacao(
      forcar: forcar,
      versaoSementeEmbarcada: versaoSementeEmbarcada,
    );
    _sincronizacaoEmVoo = futuro;
    return futuro.whenComplete(() => _sincronizacaoEmVoo = null);
  }

  Future<bool> _executarSincronizacao({
    required bool forcar,
    required String? versaoSementeEmbarcada,
  }) async {
    final agora = _relogioUtc();
    if (!forcar &&
        _ultimaVerificacaoUtc != null &&
        agora.difference(_ultimaVerificacaoUtc!) < ttlVerificacao) {
      return false;
    }

    try {
      if (_descartado) return false;
      final versaoRemota = await _fonteRemota.consultarVersaoRemota();
      if (_descartado) return false;

      final versaoLocal = _snapshotAtivo?.versaoHash ?? versaoSementeEmbarcada;
      if (versaoRemota == null ||
          (!forcar && versaoLocal != null && versaoRemota == versaoLocal)) {
        _ultimaVerificacaoUtc = agora;
        return false;
      }

      final novoSnapshot = await _fonteRemota.buscarSnapshotRemoto();
      if (_descartado) return false;
      await _armazenamento.salvarSnapshot(novoSnapshot);
      if (_descartado) return false;

      _snapshotAtivo = novoSnapshot;
      _ultimaVerificacaoUtc = agora;
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.instance.logAviso(
        '[ServicoMalhaViariaOffline] Sem conexão ou área remota; mantendo cópia offline local ($e).',
      );
      return false;
    }
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}
