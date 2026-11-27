// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../idioma/tradutor_app.dart';

/// Define as modalidades esportivas de realização de uma ascensão de escalada.
///
/// Segue fielmente a modelagem da tabela `cadenas` e as convenções esportivas:
/// * [aVista]: Primeira ascensão sem nenhuma informação, visualização de movimentos ou quedas prévias.
/// * [flash]: Primeira ascensão com beta/informação prévia, mas sem quedas.
/// * [trabalhado]: Ascensão bem-sucedida da base ao topo após uma ou mais tentativas prévias (Redpoint).
/// * [tentativa]: Pega ou tentativa em que a via não foi completada sem quedas/repousos na corda.
enum TipoAscensao {
  /// Primeira ascensão sem informação prévia ou queda (código 1).
  aVista(1),

  /// Primeira ascensão com informação prévia sem queda (código 2).
  flash(2),

  /// Ascensão completada com sucesso após tentativas prévias (código 3).
  trabalhado(3),

  /// Tentativa em que a via não foi encadenada (código 4).
  tentativa(4);

  /// Código numérico compacto persistido no banco de dados / PowerSync.
  final int codigo;

  const TipoAscensao(this.codigo);

  /// Rótulo localizado para apresentação na interface.
  String get rotulo => switch (this) {
    TipoAscensao.aVista => tr(ChaveTexto.estiloAVista),
    TipoAscensao.flash => tr(ChaveTexto.estiloFlash),
    TipoAscensao.trabalhado => tr(ChaveTexto.estiloTrabalhado),
    TipoAscensao.tentativa => tr(ChaveTexto.estiloTentativa),
  };

  /// Indica se a ascensão é considerada uma cadena completada com sucesso.
  bool get isCadena => this != TipoAscensao.tentativa;

  /// Retorna o peso numérico para destaque visual e desempate esportivo.
  ///
  /// A escala de prioridade esportiva segue:
  /// * Flash: 3 (maior mérito visual/destaque)
  /// * À Vista: 2
  /// * Trabalhado: 1
  /// * Tentativa: 0
  int get prioridadeVisual {
    switch (this) {
      case TipoAscensao.flash:
        return 3;
      case TipoAscensao.aVista:
        return 2;
      case TipoAscensao.trabalhado:
        return 1;
      case TipoAscensao.tentativa:
        return 0;
    }
  }

  /// Converte um código numérico de banco de dados para [TipoAscensao].
  ///
  /// Caso o código seja nulo ou desconhecido, retorna [TipoAscensao.trabalhado]
  /// como padrão esportivo seguro.
  static TipoAscensao fromCodigo(int? codigo) {
    switch (codigo) {
      case 1:
        return TipoAscensao.aVista;
      case 2:
        return TipoAscensao.flash;
      case 3:
        return TipoAscensao.trabalhado;
      case 4:
        return TipoAscensao.tentativa;
      default:
        return TipoAscensao.trabalhado;
    }
  }

  /// Converte um identificador textual para [TipoAscensao].
  ///
  /// Caso a string seja nula ou desconhecida, retorna [TipoAscensao.trabalhado].
  static TipoAscensao fromString(String? nome) {
    if (nome == null) return TipoAscensao.trabalhado;
    for (final tipo in TipoAscensao.values) {
      if (tipo.name == nome) {
        return tipo;
      }
    }
    return TipoAscensao.trabalhado;
  }
}
