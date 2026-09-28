// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../aresta_api/proto/generated/indice.pb.dart';
import '../../services/dataset/modelos/metadados_indice.dart';
import 'card_croqui_view_model.dart';

/// ViewModel de item para marcadores e dados geográficos no mapa global (Dumb UI).
///
/// Encapsula a mensagem Protobuf [ResumoCroqui] através de getters diretos,
/// calculando coordenadas decimais sob demanda para exibição em mapas.
abstract class MapaPicoViewModel {
  /// Identificador único do pico.
  String get id;

  /// Nome legível do pico.
  String get nome;

  /// Latitude em graus decimais.
  double? get latitude;

  /// Longitude em graus decimais.
  double? get longitude;

  /// Indica se os dados do croqui já estão baixados localmente.
  bool get estaBaixado;

  /// Total de setores catalogados.
  int get totalSetores;

  /// Total de vias/escaladas catalogadas.
  int get totalEscaladas;

  /// Caminho relativo da miniatura.
  String get caminhoMiniatura;

  /// Nome formatado da localização geográfica.
  String get localizacao;

  /// Descrição resumida do local.
  String get descricao;

  /// URL de download remoto do arquivo binário.
  String get urlDownload;

  /// Checksum SHA-256 do arquivo binário.
  String get checksumSha256;

  const MapaPicoViewModel._();

  /// Constrói um [MapaPicoViewModel] com valores primitivos explícitos (testes e flexibilidade).
  const factory MapaPicoViewModel({
    required String id,
    required String nome,
    double? latitude,
    double? longitude,
    bool estaBaixado,
    int totalSetores,
    int totalEscaladas,
    String caminhoMiniatura,
    String localizacao,
    String descricao,
    String urlDownload,
    String checksumSha256,
  }) = _MapaPicoValores;

  /// Indica se o pico possui coordenadas geográficas válidas para plotagem de marcador no mapa.
  bool get temCoordenadasValidas =>
      latitude != null &&
      longitude != null &&
      (latitude! != 0.0 || longitude! != 0.0);

  /// Converte o [MapaPicoViewModel] para [CardCroquiViewModel] para exibição no card de croqui.
  CardCroquiViewModel paraCardCroquiViewModel();

  /// Constrói um [MapaPicoViewModel] diretamente sobre a mensagem Protobuf [ResumoCroqui].
  factory MapaPicoViewModel.deMetadados({
    required ResumoCroqui metadados,
    bool estaBaixado,
    String baseUrl,
  }) = _MapaPicoMetadados;

  /// Constrói um [MapaPicoViewModel] com valores primitivos explícitos (testes e flexibilidade).
  const factory MapaPicoViewModel.deValores({
    required String id,
    required String nome,
    double? latitude,
    double? longitude,
    bool estaBaixado,
    int totalSetores,
    int totalEscaladas,
    String caminhoMiniatura,
    String localizacao,
    String descricao,
    String urlDownload,
    String checksumSha256,
  }) = _MapaPicoValores;

  /// Constrói um [MapaPicoViewModel] a partir de mapas legados ou mocks.
  factory MapaPicoViewModel.deMapa(
    Map<String, dynamic> mapa, {
    bool estaBaixado,
  }) = _MapaPicoMapa;
}

/// Implementação leve diretamente sobre a mensagem Protobuf [ResumoCroqui].
class _MapaPicoMetadados extends MapaPicoViewModel {
  final ResumoCroqui _metadados;

  @override
  final bool estaBaixado;

  final String _baseUrl;

  _MapaPicoMetadados({
    required ResumoCroqui metadados,
    this.estaBaixado = false,
    String baseUrl = '',
  })  : _metadados = metadados,
        _baseUrl = baseUrl,
        super._();

  @override
  String get id => _metadados.id;

  @override
  String get nome => _metadados.nome.isEmpty ? 'Pico' : _metadados.nome;

  @override
  double? get latitude => _metadados.hasLocalizacao()
      ? _metadados.localizacao.latitude / 10000000.0
      : null;

  @override
  double? get longitude => _metadados.hasLocalizacao()
      ? _metadados.localizacao.longitude / 10000000.0
      : null;

  @override
  int get totalSetores =>
      _metadados.hasPrecomputados() ? _metadados.precomputados.totalSetores : 0;

  @override
  int get totalEscaladas =>
      _metadados.hasPrecomputados() ? _metadados.precomputados.totalEscaladas : 0;

  @override
  String get caminhoMiniatura => 'thumbnails/${_metadados.id}.webp';

  @override
  String get localizacao => _metadados.localizacaoFormatada;

  @override
  String get descricao => _metadados.descricao;

  @override
  String get urlDownload => _baseUrl.isNotEmpty
      ? '$_baseUrl/${_metadados.caminhoRelativo}?v=${_metadados.checksumSha256Croqui}'
      : _metadados.caminhoRelativo;

  @override
  String get checksumSha256 => _metadados.checksumSha256Croqui;

  @override
  CardCroquiViewModel paraCardCroquiViewModel() {
    return CardCroquiViewModel.deMetadados(
      _metadados,
      salvoOffline: estaBaixado,
    );
  }
}

/// Implementação para valores explícitos.
class _MapaPicoValores extends MapaPicoViewModel {
  @override
  final String id;
  @override
  final String nome;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  final bool estaBaixado;
  @override
  final int totalSetores;
  @override
  final int totalEscaladas;
  @override
  final String caminhoMiniatura;
  @override
  final String localizacao;
  @override
  final String descricao;
  @override
  final String urlDownload;
  @override
  final String checksumSha256;

  const _MapaPicoValores({
    required this.id,
    required this.nome,
    this.latitude,
    this.longitude,
    this.estaBaixado = false,
    this.totalSetores = 0,
    this.totalEscaladas = 0,
    this.caminhoMiniatura = '',
    this.localizacao = '',
    this.descricao = '',
    this.urlDownload = '',
    this.checksumSha256 = '',
  }) : super._();

  @override
  CardCroquiViewModel paraCardCroquiViewModel() {
    return CardCroquiViewModel.deValores(
      id: id,
      titulo: nome.toUpperCase(),
      localizacao: localizacao.toUpperCase(),
      descricao: descricao,
      textoEstatisticas: '$totalSetores setores • $totalEscaladas vias',
      caminhoMiniatura: caminhoMiniatura.isNotEmpty ? caminhoMiniatura : 'thumbnails/$id.webp',
      salvoOffline: estaBaixado,
      checksumSha256: checksumSha256.isNotEmpty ? checksumSha256 : null,
    );
  }
}

/// Implementação para mapas legados.
class _MapaPicoMapa extends MapaPicoViewModel {
  final Map<String, dynamic> _mapa;

  @override
  final bool estaBaixado;

  _MapaPicoMapa(this._mapa, {bool estaBaixado = false})
      : estaBaixado = estaBaixado || (_mapa['isDownloaded'] == true),
        super._();

  @override
  String get id => _mapa['id']?.toString() ?? '';

  @override
  String get nome => _mapa['nome']?.toString() ?? 'Pico';

  @override
  double? get latitude => (_mapa['latitude'] as num?)?.toDouble();

  @override
  double? get longitude => (_mapa['longitude'] as num?)?.toDouble();

  @override
  int get totalSetores => (_mapa['totalSetores'] as num?)?.toInt() ?? 0;

  @override
  int get totalEscaladas => (_mapa['totalEscaladas'] as num?)?.toInt() ?? 0;

  @override
  String get localizacao => _mapa['local']?.toString() ?? '';

  @override
  String get caminhoMiniatura => _mapa['thumbnailUrl']?.toString() ?? '';

  @override
  String get descricao => _mapa['descricao']?.toString() ?? '';

  @override
  String get urlDownload => _mapa['urlDownload']?.toString() ?? '';

  @override
  String get checksumSha256 => _mapa['checksum']?.toString() ?? '';

  @override
  CardCroquiViewModel paraCardCroquiViewModel() {
    return CardCroquiViewModel.deMapa(_mapa, salvoOffline: estaBaixado);
  }
}
