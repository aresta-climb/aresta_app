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

