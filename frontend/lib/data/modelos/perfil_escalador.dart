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
/// * [fotoUrl]: URL remota (`https://...`) ou Data URI (`data:image/jpeg;base64,...`) da foto de perfil.
/// * [accessToken]: Token JWT de sessão do Supabase Auth (quando autenticado).
class PerfilEscalador {
  /// Apelido esportivo padrão adotado quando o usuário não especificar um nome.
  static const String apelidoPadrao = 'Escalador Aresta';

  /// Identificador público estável em NanoID 14c Base62.
  final String autorIdPublico;

  /// Nome ou apelido de exibição esportivo do atleta (máximo 50 caracteres).
  final String autorNomePublico;

  /// UUID do usuário vinculado no serviço de autenticação (se logado).
  final String? userId;

  /// URL remota ou Data URI (`data:image/...;base64,...`) da foto de perfil do escalador.
  final String? fotoUrl;

  /// Token de acesso JWT ativo da sessão do Supabase Auth.
  final String? accessToken;

  /// Indica se este perfil está atualmente vinculado a uma conta autenticada.
  bool get estaAutenticado => userId != null && userId!.trim().isNotEmpty;

  /// Cria uma instância imutável de [PerfilEscalador], validando limites e campos.
  PerfilEscalador({
    required this.autorIdPublico,
    String autorNomePublico = apelidoPadrao,
    this.userId,
    String? fotoUrl,
    String? accessToken,
  }) : autorNomePublico = _sanitizarNome(autorNomePublico),
       fotoUrl = _sanitizarOpcional(fotoUrl),
       accessToken = _sanitizarOpcional(accessToken);

  /// Cria uma nova identidade de perfil gerando um [autorIdPublico] NanoID 14c automaticamente.
  factory PerfilEscalador.criarPadrao({
    String? autorNomePublico,
    String? userId,
    String? fotoUrl,
    String? accessToken,
  }) {
    return PerfilEscalador(
      autorIdPublico: gerarUid(),
      autorNomePublico: autorNomePublico ?? apelidoPadrao,
      userId: userId,
      fotoUrl: fotoUrl,
      accessToken: accessToken,
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

  static String? _sanitizarOpcional(String? valor) {
    if (valor == null) return null;
    final aparado = valor.trim();
    return aparado.isEmpty ? null : aparado;
  }

  /// Converte a instância em um mapa compatível com persistência local e banco de dados.
  Map<String, dynamic> toMap() {
    return {
      'autor_id_publico': autorIdPublico,
      'autor_nome_publico': autorNomePublico,
      'user_id': userId,
      'foto_url': fotoUrl,
      'access_token': accessToken,
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
      fotoUrl: (map['foto_url'] ?? map['avatar_url']) as String?,
      accessToken: map['access_token'] as String?,
    );
  }

  /// Serializa a instância em uma string JSON formatada.
  String toJson() => json.encode(toMap());

  /// Deserializa uma string JSON para uma instância de [PerfilEscalador].
  factory PerfilEscalador.fromJson(String source) =>
      PerfilEscalador.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Cria uma cópia da instância permitindo a substituição seletiva de campos.
  ///
  /// Quando [limparUserId] é `true`, remove o vínculo de autenticação (`userId: null` e `accessToken: null`),
  /// preservando o [autorIdPublico], [autorNomePublico] e [fotoUrl] locais.
  PerfilEscalador copyWith({
    String? autorIdPublico,
    String? autorNomePublico,
    String? userId,
    String? fotoUrl,
    String? accessToken,
    bool limparUserId = false,
    bool limparFotoUrl = false,
    bool limparAccessToken = false,
  }) {
    return PerfilEscalador(
      autorIdPublico: autorIdPublico ?? this.autorIdPublico,
      autorNomePublico: autorNomePublico ?? this.autorNomePublico,
      userId: limparUserId ? null : (userId ?? this.userId),
      fotoUrl: limparFotoUrl ? null : (fotoUrl ?? this.fotoUrl),
      accessToken: (limparUserId || limparAccessToken)
          ? null
          : (accessToken ?? this.accessToken),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PerfilEscalador &&
        other.autorIdPublico == autorIdPublico &&
        other.autorNomePublico == autorNomePublico &&
        other.userId == userId &&
        other.fotoUrl == fotoUrl &&
        other.accessToken == accessToken;
  }

  @override
  int get hashCode => Object.hash(
    autorIdPublico,
    autorNomePublico,
    userId,
    fotoUrl,
    accessToken,
  );

  @override
  String toString() {
    return 'PerfilEscalador(autorIdPublico: $autorIdPublico, autorNomePublico: $autorNomePublico, userId: $userId, fotoUrl: $fotoUrl)';
  }
}
