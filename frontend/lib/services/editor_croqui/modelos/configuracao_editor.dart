// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Representa o estado persistido das configurações do Editor de Croquis.
///
/// Substitui o uso de `Map<String, dynamic>` na leitura e escrita do arquivo YAML
/// de configuração do editor local.
class ConfiguracaoEditor {
  /// URL remota ou local do servidor do editor de croquis conectado.
  final String? editorUrl;

  /// Indica se a aplicação está em modo experimental conectada a um editor.
  final bool isExperimental;

  /// Indica se os recursos de desenvolvedor estão ativos na interface.
  final bool isDevMode;

  /// Carimbo ISO-8601 do horário de expiração da sessão experimental temporária.
  final String? expiryTime;

  const ConfiguracaoEditor({
    this.editorUrl,
    this.isExperimental = false,
    this.isDevMode = false,
    this.expiryTime,
  });

  /// Instância padrão vazia.
  static const vazia = ConfiguracaoEditor();

  /// Cria uma cópia com campos atualizados seletivamente.
  ConfiguracaoEditor copyWith({
    String? editorUrl,
    bool? isExperimental,
    bool? isDevMode,
    String? expiryTime,
    bool clearEditorUrl = false,
  }) {
    return ConfiguracaoEditor(
      editorUrl: clearEditorUrl ? null : (editorUrl ?? this.editorUrl),
      isExperimental: isExperimental ?? this.isExperimental,
      isDevMode: isDevMode ?? this.isDevMode,
      expiryTime: expiryTime ?? this.expiryTime,
    );
  }

  /// Converte para mapa para serialização em formato YAML/JSON.
  Map<String, dynamic> paraMapa() {
    return {
      if (editorUrl != null) 'editorUrl': editorUrl,
      'isExperimental': isExperimental,
      'isDevMode': isDevMode,
      if (expiryTime != null) 'expiryTime': expiryTime,
    };
  }

  /// Instancia o modelo a partir de um mapa de dados desserializado.
  factory ConfiguracaoEditor.deMapa(Map<dynamic, dynamic> mapa) {
    return ConfiguracaoEditor(
      editorUrl: mapa['editorUrl']?.toString(),
      isExperimental: mapa['isExperimental'] == true,
      isDevMode: mapa['isDevMode'] == true,
      expiryTime: mapa['expiryTime']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfiguracaoEditor &&
          runtimeType == other.runtimeType &&
          editorUrl == other.editorUrl &&
          isExperimental == other.isExperimental &&
          isDevMode == other.isDevMode &&
          expiryTime == other.expiryTime;

  @override
  int get hashCode => Object.hash(
        editorUrl,
        isExperimental,
        isDevMode,
        expiryTime,
      );

  @override
  String toString() =>
      'ConfiguracaoEditor(editorUrl: $editorUrl, isExperimental: $isExperimental, isDevMode: $isDevMode)';
}
