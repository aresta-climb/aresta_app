// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../constants/constantes_rede.dart';
import '../../utils/codificador_malha_binaria.dart';
import '../firebase/app_logger.dart';
import '../http/cliente_http_aresta.dart';
import 'armazenamento_clima_local.dart';
import 'calculadora_umidade_pico.dart';
import '../../data/modelos/modelos_clima_pico.dart';

/// Fronteira abstrata de rede para busca dos snapshots públicos de clima e altimetria.
abstract interface class FonteRemotaClimaAltimetria {
  /// Obtém o snapshot remoto de chuva regional (`estado_clima_picos`, ~3 KB) e,
  /// somente quando [incluirAltimetria] for verdadeiro, consulta `snapshots_altimetria_picos`
  /// (recorrendo ao slot `copia_seguranca` quando necessário).
  Future<SnapshotClimaAltimetria> buscarSnapshotRemoto({
    bool incluirAltimetria = false,
  });
}

/// Cliente PostgREST que lê `public.estado_clima_picos` e `public.snapshots_altimetria_picos`
/// no Supabase com suporte transparente aos slots `atual` e `copia_seguranca`.
class ClienteClimaAltimetriaSupabase implements FonteRemotaClimaAltimetria {
  final String urlBaseSupabase;
  final String chaveAnonima;
  final ClienteHttpAresta _clienteHttp;
  final Duration timeoutRequisicao;

  ClienteClimaAltimetriaSupabase({
    String? urlBaseSupabase,
    String? chaveAnonima,
    ClienteHttpAresta? clienteHttp,
    this.timeoutRequisicao = const Duration(seconds: 4),
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
  Future<SnapshotClimaAltimetria> buscarSnapshotRemoto({
    bool incluirAltimetria = false,
  }) async {
    final linhaClima = await _consultarComFallbackSlot('estado_clima_picos');
    final linhaAlt = incluirAltimetria
        ? await _consultarComFallbackSlot('snapshots_altimetria_picos')
        : null;

    return SnapshotClimaAltimetria.deMapa(<String, dynamic>{
      'gerado_em': linhaClima['gerado_em'] ?? linhaAlt?['gerado_em'],
      'bolhas_chuva': linhaClima['bolhas_chuva'] ?? const <dynamic>[],
      'bolhas_incendio': linhaClima['bolhas_incendio'] ?? const <dynamic>[],
      'chuva_por_pico':
          linhaClima['chuva_por_pico'] ?? const <String, dynamic>{},
      'altimetria_por_pico':
          linhaAlt?['altimetria_por_pico'] ?? const <String, dynamic>{},
    });
  }

  Future<Map<String, dynamic>> _consultarComFallbackSlot(String tabela) async {
    final atual = await _consultarSlot(tabela, 'atual');
    if (atual != null) return atual;

    final seguranca = await _consultarSlot(tabela, 'copia_seguranca');
    if (seguranca != null) {
      AppLogger.instance.logAviso(
        '[ClienteClimaAltimetriaSupabase] Slot atual vazio em $tabela; utilizando slot copia_seguranca.',
      );
      return seguranca;
    }

    throw HttpException('Nenhum registro encontrado em $tabela (atual/copia_seguranca).');
  }

  Future<Map<String, dynamic>?> _consultarSlot(String tabela, String slot) async {
    final uri = Uri.parse('$urlBaseSupabase/rest/v1/$tabela?slot=eq.$slot&limit=1');
    final resp = await _clienteHttp.get(uri, headers: _cabecalhos).timeout(timeoutRequisicao);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw HttpException(
        'Erro HTTP ${resp.statusCode} ao consultar $tabela ($slot).',
        uri: uri,
      );
    }
    final lista = jsonDecode(resp.body);
    if (lista is List && lista.isNotEmpty && lista.first is Map) {
      return Map<String, dynamic>.from(lista.first as Map);
    }
    return null;
  }
}

/// Serviço reativo que coordena a semente offline de altimetria, o cache rotativo local
/// e a avaliação instantânea da curva de secagem de 5 dias para a aba `Explorar` e `PicoDetailsPage`.
class ServicoClimaAltimetria extends ChangeNotifier {
  static const Duration ttlSincronizacao = Duration(minutes: 30);
  static const String caminhoAssetSementeAltimetria =
      'assets/dados/altimetria_picos_inicial.bin';

  static ServicoClimaAltimetria? _instanciaCompartilhada;

  /// Instância compartilhada entre `Explorar` e `PicoDetailsPage` para leitura imediata em memória.
  static ServicoClimaAltimetria get instancia =>
      _instanciaCompartilhada ??= ServicoClimaAltimetria();

  /// Restaura a instância compartilhada entre testes.
  @visibleForTesting
  static void redefinirParaTestes() {
    _instanciaCompartilhada?.dispose();
    _instanciaCompartilhada = null;
  }

  final ArmazenamentoClimaLocal _armazenamento;
  final FonteRemotaClimaAltimetria _fonteRemota;
  final DateTime Function() _relogioUtc;
  final DateTime Function() _relogioLocal;
  final AssetBundle _assetBundle;

  final Map<String, CotaAltimetricaPico> _altimetriaPorPico = {};
  final Map<String, List<EventoChuvaPico>> _chuvaPorPico = {};
  List<BolhaChuvaRegional> _bolhasBrutas = const [];
  List<BolhaIncendioRegional> _incendiosBrutos = const [];
  DateTime? _geradoEmClimaUtc;
  DateTime? _ultimaSincronizacaoUtc;
  Future<bool>? _sincronizacaoEmAndamento;
  bool _inicializado = false;
  bool _descartado = false;

  ServicoClimaAltimetria({
    ArmazenamentoClimaLocal? armazenamento,
    FonteRemotaClimaAltimetria? fonteRemota,
    DateTime Function()? relogioUtc,
    DateTime Function()? relogioLocal,
    AssetBundle? assetBundle,
  })  : _armazenamento = armazenamento ?? ArmazenamentoClimaLocal(),
        _fonteRemota = fonteRemota ?? ClienteClimaAltimetriaSupabase(),
        _relogioUtc = relogioUtc ?? (() => DateTime.now().toUtc()),
        _relogioLocal = relogioLocal ?? (relogioUtc ?? DateTime.now),
        _assetBundle = assetBundle ?? rootBundle;

  /// Verdadeiro após carregar a semente embutida e o cache em disco.
  bool get inicializado => _inicializado;

  /// Verdadeiro quando já há um snapshot meteorológico carregado do disco ou da rede.
  bool get temSnapshotClima => _geradoEmClimaUtc != null;

  /// Carrega a altimetria estática embarcada no APK/IPA e hidrata o cache local em disco.
  Future<void> inicializar() async {
    if (_inicializado || _descartado) return;
    await _carregarSementeAltimetriaAsset();
    if (_descartado) return;

    final cacheDisco = await _armazenamento.lerSnapshot();
    if (_descartado) return;
    if (cacheDisco != null) {
      _aplicarSnapshotEmMemoria(cacheDisco);
    }
    _inicializado = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }

  Future<void> _carregarSementeAltimetriaAsset() async {
    try {
      final bd = await _assetBundle.load(caminhoAssetSementeAltimetria);
      final bytes = bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);
      final decodificado =
          CodificadorMalhaBinaria.decodificarAltimetriaInicial(bytes);
      _altimetriaPorPico.addAll(decodificado.cotasPorPico);
    } catch (e, st) {
      AppLogger.instance.logError(
        '[ServicoClimaAltimetria] Falha ao carregar semente inicial de altimetria',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Sincroniza `estado_clima_picos` (~3 KB) caso o TTL de 3 horas tenha expirado ou [forcar] seja
  /// verdadeiro, consultando `snapshots_altimetria_picos` apenas se surgir algum pico em
  /// [idsPicosCatalogo] ainda ausente da base altimétrica local.
  Future<bool> sincronizarSeNecessario({
    bool forcar = false,
    Iterable<String> idsPicosCatalogo = const [],
  }) {
    final emVoo = _sincronizacaoEmAndamento;
    if (emVoo != null) return emVoo;
    final futuro = _executarSincronizacao(
      forcar: forcar,
      idsPicosCatalogo: idsPicosCatalogo,
    );
    _sincronizacaoEmAndamento = futuro;
    return futuro.whenComplete(() => _sincronizacaoEmAndamento = null);
  }

  Future<bool> _executarSincronizacao({
    required bool forcar,
    required Iterable<String> idsPicosCatalogo,
  }) async {
    final agora = _relogioUtc();
    final precisaAltimetria = _altimetriaPorPico.isEmpty ||
        idsPicosCatalogo.any(
          (id) => id.isNotEmpty && !_altimetriaPorPico.containsKey(id),
        );
    if (!forcar &&
        !precisaAltimetria &&
        _ultimaSincronizacaoUtc != null &&
        agora.difference(_ultimaSincronizacaoUtc!) < ttlSincronizacao) {
      return false;
    }

    try {
      if (_descartado) return false;
      final remoto = await _fonteRemota.buscarSnapshotRemoto(
        incluirAltimetria: forcar || precisaAltimetria,
      );
      if (_descartado) return false;
      final altMesclada = <String, CotaAltimetricaPico>{
        ..._altimetriaPorPico,
      };
      for (final entry in remoto.altimetriaPorPico.entries) {
        altMesclada[entry.key] = entry.value.preservandoGradeSeAusente(
          _altimetriaPorPico[entry.key],
        );
      }
      final consolidado = SnapshotClimaAltimetria(
        geradoEm: remoto.geradoEm,
        bolhasChuva: remoto.bolhasChuva,
        bolhasIncendio: remoto.bolhasIncendio,
        chuvaPorPico: remoto.chuvaPorPico,
        altimetriaPorPico: altMesclada,
      );

      await _armazenamento.salvarSnapshot(consolidado);
      if (_descartado) return false;
      _aplicarSnapshotEmMemoria(consolidado);
      _ultimaSincronizacaoUtc = agora;
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.instance.logAviso(
        '[ServicoClimaAltimetria] Sincronização remota indisponível; mantendo cache local ($e).',
      );
      return false;
    }
  }

  void _aplicarSnapshotEmMemoria(SnapshotClimaAltimetria snap) {
    _altimetriaPorPico.addAll(snap.altimetriaPorPico);
    _chuvaPorPico
      ..clear()
      ..addAll(snap.chuvaPorPico);
    _bolhasBrutas = snap.bolhasChuva;
    _incendiosBrutos = snap.bolhasIncendio;
    _geradoEmClimaUtc = snap.geradoEm;
  }

  /// Retorna a altitude máxima do maciço em metros (ou `null` quando desconhecida).
  int? obterAltitudePico(String idSlug) =>
      _altimetriaPorPico[idSlug]?.altitudePicoMetros;

  /// Retorna a cota completa (`base` e `pico`) para escalonamento do relevo 3D no `LOD 3`.
  CotaAltimetricaPico? obterCotaAltimetrica(String idSlug) =>
      _altimetriaPorPico[idSlug];

  /// Calcula em `O(1)` o estado vigente de umidade de [idSlug] na data civil local do dispositivo.
  EstadoUmidadePico obterUmidadePico(String idSlug) {
    final eventos = _chuvaPorPico[idSlug];
    if (eventos == null || eventos.isEmpty) {
      return const EstadoUmidadePico.seco();
    }
    return CalculadoraUmidadePico.avaliarHistoricoPico(
      eventos: eventos,
      dataReferencia: _relogioLocal(),
    );
  }

  /// Lista de tempestades ao vivo vigentes para pintura animada nos `LODs 0–3`.
  List<BolhaAtivaRenderizavel> get bolhasAtivas {
    final gerado = _geradoEmClimaUtc;
    if (gerado == null || _bolhasBrutas.isEmpty) return const [];
    return CalculadoraUmidadePico.filtrarBolhasAtivas(
      bolhas: _bolhasBrutas,
      geradoEm: gerado,
      dataReferencia: _relogioUtc(),
    );
  }

  /// Lista de zonas de incêndio florestal vigentes (NASA FIRMS / INPE VIIRS-MODIS) nas últimas 24h.
  List<BolhaIncendioAtivaRenderizavel> get bolhasIncendioAtivas {
    final gerado = _geradoEmClimaUtc;
    if (gerado == null || _incendiosBrutos.isEmpty) return const [];
    return CalculadoraUmidadePico.filtrarIncendiosAtivos(
      incendios: _incendiosBrutos,
      geradoEm: gerado,
      dataReferencia: _relogioUtc(),
    );
  }
}
