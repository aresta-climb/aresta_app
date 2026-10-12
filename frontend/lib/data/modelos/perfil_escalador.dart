// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import '../../utils/gerador_uid.dart';

/// Representa a identidade esportiva pública do escalador no ecossistema Aresta.
///
/// Espelha o esquema da tabela `perfis`:
/// * [autorIdPublico]: Identificador público universal (NanoID 14c Base62) do atleta.
/// * [autorNomePublico]: Apelido ou nome esportivo público (máximo 50 caracteres).
/// * [userId]: Identificador UUID de autenticação do usuário (opcional em modo offline puro).
class PerfilEscalador {
  /// Apelido esportivo padrão adotado quando o usuário não especificar um nome.
  static const String apelidoPadrao = 'Escalador Aresta';

  /// Identificador público estável em NanoID 14c Base62.
  final String autorIdPublico;

  /// Nome ou apelido de exibição esportivo do atleta (máximo 50 caracteres).
  final String autorNomePublico;

  /// UUID do usuário vinculado no serviço de autenticação (se logado).
  final String? userId;

  /// Cria uma instância imutável de [PerfilEscalador], validando limites e campos.
  PerfilEscalador({
    required this.autorIdPublico,
    String autorNomePublico = apelidoPadrao,
    this.userId,
  }) : autorNomePublico = _sanitizarNome(autorNomePublico);

  /// Cria uma nova identidade de perfil gerando um [autorIdPublico] NanoID 14c automaticamente.
  factory PerfilEscalador.criarPadrao({
    String? autorNomePublico,
    String? userId,
  }) {
    return PerfilEscalador(
      autorIdPublico: gerarUid(),
      autorNomePublico: autorNomePublico ?? apelidoPadrao,
      userId: userId,
    );
  }

  /// Sanitiza o nome do atleta, garantindo fallback e limite de 50 caracteres.
  static String _sanitizarNome(String nome) {
    final aparado = nome.trim();
    if (aparado.isEmpty) {
      return apelidoPadrao;
    }
    return aparado.length > 50 ? aparado.substring(0, 50) : aparado;
  }

  /// Converte a instância em um mapa compatível com persistência local e banco de dados.
  Map<String, dynamic> toMap() {
    return {
      'autor_id_publico': autorIdPublico,
      'autor_nome_publico': autorNomePublico,
      'user_id': userId,
    };
  }

  /// Reconstrói uma instância a partir de um [Map].
  factory PerfilEscalador.fromMap(Map<String, dynamic> map) {
    final idRecebido = map['autor_id_publico'] as String?;
    final idValido = validarUid(idRecebido) ? idRecebido! : gerarUid();
    return PerfilEscalador(
      autorIdPublico: idValido,
      autorNomePublico:
          map['autor_nome_publico'] as String? ?? apelidoPadrao,
      userId: map['user_id'] as String?,
    );
  }

  /// Serializa a instância em uma string JSON formatada.
  String toJson() => json.encode(toMap());

  /// Deserializa uma string JSON para uma instância de [PerfilEscalador].
  factory PerfilEscalador.fromJson(String source) =>
      PerfilEscalador.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Cria uma cópia da instância permitindo a substituição seletiva de campos.
  PerfilEscalador copyWith({
    String? autorIdPublico,
    String? autorNomePublico,
    String? userId,
  }) {
    return PerfilEscalador(
      autorIdPublico: autorIdPublico ?? this.autorIdPublico,
      autorNomePublico: autorNomePublico ?? this.autorNomePublico,
      userId: userId ?? this.userId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PerfilEscalador &&
        other.autorIdPublico == autorIdPublico &&
        other.autorNomePublico == autorNomePublico &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(autorIdPublico, autorNomePublico, userId);

  @override
  String toString() {
    return 'PerfilEscalador(autorIdPublico: $autorIdPublico, autorNomePublico: $autorNomePublico, userId: $userId)';
  }
}
