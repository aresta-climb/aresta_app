// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'tipo_ascensao.dart';
import 'tipo_escalada.dart';

/// Representa o registro individual de uma realização esportiva (cadena) ou tentativa.
///
/// Espelha o esquema da tabela `cadenas` e atende às diretrizes de arquitetura:
/// * Identificador próprio único [id] em padrão UUID v4 (16 bytes binários no Postgres/PowerSync).
/// * Chave unívoca direta [escaladaUid] (NanoID 14c) associando a ascensão à via.
/// * [notasPrivadas] estritamente pessoais limitadas ao máximo de 200 caracteres.
class Cadena {
  /// Identificador universal único do registro (UUID v4).
  final String id;

  /// Identificador do usuário no serviço de autenticação (opcional em modo offline puro).
  final String? userId;

  /// NanoID universal de 14 caracteres Base62 que identifica a via de escalada.
  final String escaladaUid;

  /// Data da realização da ascensão ou tentativa.
  final DateTime dataAscensao;

  /// Estilo esportivo de ascensão (À Vista, Flash, Trabalhado ou Tentativa).
  final TipoAscensao tipoAscensao;

  /// Modalidade da escalada (Guiado, Top Rope, Boulder ou Solo).
  final TipoEscalada tipoEscalada;

  /// Quantidade de pegas / tentativas despendidas (valor mínimo 1).
  final int tentativas;

  /// Sugestão opcional de graduação conforme enum de graduação do Protobuf.
  final int? grauSugerido;

  /// Anotações técnicas de uso exclusivo do escalador (máximo 200 caracteres).
  final String notasPrivadas;

  /// Carimbo de data e hora de inclusão do registro.
  final DateTime criadoEm;

  /// Cria uma instância imutável de [Cadena], garantindo validações de domínio.
  Cadena({
    required this.id,
    this.userId,
    required this.escaladaUid,
    required this.dataAscensao,
    this.tipoAscensao = TipoAscensao.trabalhado,
    this.tipoEscalada = TipoEscalada.guiado,
    int tentativas = 1,
    this.grauSugerido,
    String notasPrivadas = '',
    DateTime? criadoEm,
  })  : tentativas = tentativas < 1 ? 1 : tentativas,
        notasPrivadas = notasPrivadas.length > 200
            ? notasPrivadas.substring(0, 200)
            : notasPrivadas,
        criadoEm = criadoEm ?? DateTime.now();

  /// Cria uma nova [Cadena] com geração automática de UUID v4 e data de criação.
  factory Cadena.criar({
    String? userId,
    required String escaladaUid,
    required DateTime dataAscensao,
    TipoAscensao tipoAscensao = TipoAscensao.trabalhado,
    TipoEscalada tipoEscalada = TipoEscalada.guiado,
    int tentativas = 1,
    int? grauSugerido,
    String notasPrivadas = '',
  }) {
    return Cadena(
      id: const Uuid().v4(),
      userId: userId,
      escaladaUid: escaladaUid,
      dataAscensao: dataAscensao,
      tipoAscensao: tipoAscensao,
      tipoEscalada: tipoEscalada,
      tentativas: tentativas,
      grauSugerido: grauSugerido,
      notasPrivadas: notasPrivadas,
      criadoEm: DateTime.now(),
    );
  }

  /// Indica se a ascensão qualifica-se como cadena esportiva efetivada.
  bool get isCadena => tipoAscensao.isCadena;

  /// Retorna o peso numérico para fins de desempate e destaque visual.
  int get prioridadeVisual => tipoAscensao.prioridadeVisual;

  /// Converte a instância em um mapa compatível com persistência local e banco de dados.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'escalada_uid': escaladaUid,
      'data_ascensao': dataAscensao.toIso8601String(),
      'tipo_ascensao': tipoAscensao.codigo,
      'tipo_escalada': tipoEscalada.codigo,
      'tentativas': tentativas,
      'grau_sugerido': grauSugerido,
      'notas_privadas': notasPrivadas,
      'criado_em': criadoEm.toIso8601String(),
    };
  }

  /// Reconstrói uma instância a partir de um [Map].
  factory Cadena.fromMap(Map<String, dynamic> map) {
    return Cadena(
      id: map['id'] as String? ?? const Uuid().v4(),
      userId: map['user_id'] as String?,
      escaladaUid: map['escalada_uid'] as String? ?? '',
      dataAscensao: map['data_ascensao'] != null
          ? DateTime.parse(map['data_ascensao'] as String)
          : DateTime.now(),
      tipoAscensao: TipoAscensao.fromCodigo(map['tipo_ascensao'] as int?),
      tipoEscalada: TipoEscalada.fromCodigo(map['tipo_escalada'] as int?),
      tentativas: (map['tentativas'] as int?) ?? 1,
      grauSugerido: map['grau_sugerido'] as int?,
      notasPrivadas: (map['notas_privadas'] as String?) ?? '',
      criadoEm: map['criado_em'] != null
          ? DateTime.parse(map['criado_em'] as String)
          : null,
    );
  }

  /// Serializa a instância em uma string JSON formatada.
  String toJson() => json.encode(toMap());

  /// Deserializa uma string JSON para uma instância de [Cadena].
  factory Cadena.fromJson(String source) =>
      Cadena.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Cria uma cópia da instância permitindo a substituição seletiva de campos.
  Cadena copyWith({
    String? id,
    String? userId,
    String? escaladaUid,
    DateTime? dataAscensao,
    TipoAscensao? tipoAscensao,
    TipoEscalada? tipoEscalada,
    int? tentativas,
    int? grauSugerido,
    String? notasPrivadas,
    DateTime? criadoEm,
  }) {
    return Cadena(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      escaladaUid: escaladaUid ?? this.escaladaUid,
      dataAscensao: dataAscensao ?? this.dataAscensao,
      tipoAscensao: tipoAscensao ?? this.tipoAscensao,
      tipoEscalada: tipoEscalada ?? this.tipoEscalada,
      tentativas: tentativas ?? this.tentativas,
      grauSugerido: grauSugerido ?? this.grauSugerido,
      notasPrivadas: notasPrivadas ?? this.notasPrivadas,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cadena &&
        other.id == id &&
        other.userId == userId &&
        other.escaladaUid == escaladaUid &&
        other.dataAscensao == dataAscensao &&
        other.tipoAscensao == tipoAscensao &&
        other.tipoEscalada == tipoEscalada &&
        other.tentativas == tentativas &&
        other.grauSugerido == grauSugerido &&
        other.notasPrivadas == notasPrivadas &&
        other.criadoEm == criadoEm;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      escaladaUid,
      dataAscensao,
      tipoAscensao,
      tipoEscalada,
      tentativas,
      grauSugerido,
      notasPrivadas,
      criadoEm,
    );
  }

  @override
  String toString() {
    return 'Cadena(id: $id, escaladaUid: $escaladaUid, tipoAscensao: ${tipoAscensao.rotulo}, data: $dataAscensao)';
  }
}
