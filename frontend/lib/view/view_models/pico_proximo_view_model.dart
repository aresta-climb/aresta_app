// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../aresta_api/proto/generated/indice.pb.dart';
import '../../services/dataset/modelos/metadados_indice.dart';
import '../../utils/calculadora_distancia_estrada.dart';
import '../function_library/funcoes_home.dart';
import 'card_croqui_view_model.dart';

/// ViewModel de item que representa um pico próximo ao usuário para carrosséis ou listas (Dumb UI).
///
/// Encapsula a mensagem Protobuf [ResumoCroqui] através de getters diretos,
/// calculando e formatando o tempo (sem trânsito) ou a distância sob demanda para a camada de apresentação.
abstract class PicoProximoViewModel {
  /// Identificador único do pico.
  String get id;

  /// Nome legível do pico de escalada.
  String get nome;

  /// Nome formatado da localização geográfica ou estado.
  String get localizacao;

  /// Distância calculada em quilômetros em relação ao usuário.
  double? get distanciaKm;

  /// Duração estimada em minutos (sem trânsito) quando dentro da malha local, ou `null` quando fora.
  int? get duracaoMinutos;

  /// Caminho relativo ou URL da miniatura visual.
  String get caminhoMiniatura;

  /// Indica se os dados do croqui já se encontram armazenados localmente.
  bool get estaBaixado;

  /// Total pré-computado de setores.
  int get totalSetores;

  /// Total pré-computado de vias/escaladas.
  int get totalEscaladas;

  /// Checksum SHA-256 opcional para validação de integridade.
  String? get checksumSha256;

  const PicoProximoViewModel._();

  /// Cria um [PicoProximoViewModel] com valores explícitos (testes e mocks).
  const factory PicoProximoViewModel({
    required String id,
    required String nome,
    required String localizacao,
    double? distanciaKm,
    int? duracaoMinutos,
    required String caminhoMiniatura,
    bool estaBaixado,
    int totalSetores,
    int totalEscaladas,
    String? checksumSha256,
  }) = _PicoProximoValores;

  /// Retorna a proximidade formatada para leitura humana (ex: `'~40 min'`, `'450 m'` ou `'12.3 km'`).
  String get distanciaFormatada {
    if (duracaoMinutos != null) {
      return EstimativaViagemPico(
        distanciaMetros: (distanciaKm ?? 0) * 1000.0,
        duracaoMinutos: duracaoMinutos,
      ).formatarTempoArredondado();
    }
    return formatarDistanciaKm(distanciaKm);
  }

  /// Retorna o texto do tooltip explicativo quando há estimativa de tempo sem trânsito, ou `null` caso contrário.
  String? get tooltipDistancia {
    if (duracaoMinutos == null || distanciaKm == null) {
      return null;
    }
    return EstimativaViagemPico(
      distanciaMetros: distanciaKm! * 1000.0,
      duracaoMinutos: duracaoMinutos,
    ).formatarTooltip();
  }

  /// Converte o [PicoProximoViewModel] para o [CardCroquiViewModel] para exibição no [CragCard].
  CardCroquiViewModel paraCardCroquiViewModel();

  /// Constrói um [PicoProximoViewModel] diretamente sobre a mensagem Protobuf [ResumoCroqui].
  factory PicoProximoViewModel.deMetadados({
    required ResumoCroqui metadados,
    double? distanciaKm,
    int? duracaoMinutos,
    bool estaBaixado,
  }) = _PicoProximoMetadados;

  /// Constrói um [PicoProximoViewModel] com valores explícitos (testes e mocks).
  const factory PicoProximoViewModel.deValores({
    required String id,
    required String nome,
    required String localizacao,
    double? distanciaKm,
    int? duracaoMinutos,
    required String caminhoMiniatura,
    bool estaBaixado,
    int totalSetores,
    int totalEscaladas,
    String? checksumSha256,
  }) = _PicoProximoValores;
}

/// Implementação leve que referencia diretamente a mensagem Protobuf [ResumoCroqui].
class _PicoProximoMetadados extends PicoProximoViewModel {
  final ResumoCroqui _metadados;

  @override
  final double? distanciaKm;

  @override
  final int? duracaoMinutos;

  @override
  final bool estaBaixado;

  _PicoProximoMetadados({
    required ResumoCroqui metadados,
    this.distanciaKm,
    this.duracaoMinutos,
    this.estaBaixado = false,
  })  : _metadados = metadados,
        super._();

  @override
  String get id => _metadados.id;

  @override
  String get nome => _metadados.nome.isEmpty ? 'Pico' : _metadados.nome;

  @override
  String get localizacao => _metadados.localizacaoFormatada;

  @override
  String get caminhoMiniatura => 'thumbnails/${_metadados.id}.webp';

  @override
  int get totalSetores =>
      _metadados.hasPrecomputados() ? _metadados.precomputados.totalSetores : 0;

  @override
  int get totalEscaladas =>
      _metadados.hasPrecomputados() ? _metadados.precomputados.totalEscaladas : 0;

  @override
  String? get checksumSha256 => _metadados.hasChecksumSha256Thumbnail()
      ? _metadados.checksumSha256Thumbnail
      : null;

  @override
  CardCroquiViewModel paraCardCroquiViewModel() {
    return CardCroquiViewModel.deMetadados(
      _metadados,
      salvoOffline: estaBaixado,
      textoDistancia: distanciaFormatada.isNotEmpty ? distanciaFormatada : null,
      tooltipDistancia: tooltipDistancia,
    );
  }
}

/// Implementação com valores primitivos para testes e mocks.
class _PicoProximoValores extends PicoProximoViewModel {
  @override
  final String id;
  @override
  final String nome;
  @override
  final String localizacao;
  @override
  final double? distanciaKm;
  @override
  final int? duracaoMinutos;
  @override
  final String caminhoMiniatura;
  @override
  final bool estaBaixado;
  @override
  final int totalSetores;
  @override
  final int totalEscaladas;
  @override
  final String? checksumSha256;

  const _PicoProximoValores({
    required this.id,
    required this.nome,
    required this.localizacao,
    this.distanciaKm,
    this.duracaoMinutos,
    required this.caminhoMiniatura,
    this.estaBaixado = false,
    this.totalSetores = 0,
    this.totalEscaladas = 0,
    this.checksumSha256,
  }) : super._();

  @override
  CardCroquiViewModel paraCardCroquiViewModel() {
    return CardCroquiViewModel.deValores(
      id: id,
      titulo: nome.toUpperCase(),
      localizacao: localizacao.toUpperCase(),
      caminhoMiniatura: caminhoMiniatura,
      salvoOffline: estaBaixado,
      textoDistancia: distanciaFormatada.isNotEmpty ? distanciaFormatada : null,
      tooltipDistancia: tooltipDistancia,
      textoEstatisticas: '$totalSetores setores • $totalEscaladas vias',
      checksumSha256: checksumSha256,
    );
  }
}
