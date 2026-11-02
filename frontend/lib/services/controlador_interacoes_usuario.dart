// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'configuracao_recursos.dart';

/// Gerencia a preferência local do usuário sobre a exibição de recursos
/// interativos de Perfil e Caderneta Esportiva na interface do aplicativo.
///
/// Permite que escaladores interessados exclusivamente na consulta técnica de
/// croquis ocultem os botões de perfil e registro de cadenas em tempo de
/// execução sem apagar seus dados locais nem bloquear alertas de segurança.
class ControladorInteracoesUsuario {
  /// Chave de persistência local da preferência no [SharedPreferences].
  static const String chavePreferenciaInteracoes =
      'aresta_interacoes_caderneta_ativas_v1';

  static ControladorInteracoesUsuario? _instanciaCompartilhada;

  /// Retorna ou instancia o controlador singleton compartilhado na aplicação.
  static ControladorInteracoesUsuario get instancia =>
      _instanciaCompartilhada ??= ControladorInteracoesUsuario();

  /// Permite substituir a instância singleton para isolamento em testes.
  @visibleForTesting
  static set instancia(ControladorInteracoesUsuario? valor) {
    _instanciaCompartilhada = valor;
  }

  /// Restaura a instância singleton compartilhada para o estado limpo entre testes.
  @visibleForTesting
  static void redefinirParaTestes() {
    _instanciaCompartilhada = null;
  }

  SharedPreferences? _preferencias;
  final ValueNotifier<bool> _interacoesAtivasNotifier =
      ValueNotifier<bool>(true);

  /// Cria uma instância do controlador, aceitando opcionalmente [SharedPreferences].
  ControladorInteracoesUsuario({SharedPreferences? preferencias})
    : _preferencias = preferencias;

  /// Notificador reativo que emite mudanças sempre que o usuário alterna a preferência.
  ValueListenable<bool> get interacoesAtivasNotifier =>
      _interacoesAtivasNotifier;

  /// Indica se o usuário optou por manter os recursos de perfil e caderneta visíveis.
  bool get interacoesAtivas => _interacoesAtivasNotifier.value;

  /// Indica se o recurso de Perfil e Caderneta está habilitado na compilação atual.
  bool get recursoHabilitadoNoAmbiente => ConfiguracaoRecursos.perfilHabilitado;

  /// Indica se os elementos opcionais de Perfil e Caderneta devem ser exibidos na UI,
  /// combinando a liberação do recurso na compilação ([recursoHabilitadoNoAmbiente])
  /// com a preferência ativa do usuário ([interacoesAtivas]).
  bool get exibirElementosInterativos =>
      recursoHabilitadoNoAmbiente && _interacoesAtivasNotifier.value;

  /// Carrega a preferência previamente salva no dispositivo, mantendo `true` por padrão.
  Future<void> inicializar() async {
    _preferencias ??= await SharedPreferences.getInstance();
    _interacoesAtivasNotifier.value =
        _preferencias!.getBool(chavePreferenciaInteracoes) ?? true;
  }

  /// Atualiza e persiste a preferência do usuário, notificando ouvintes reativamente.
  Future<void> definirInteracoesAtivas(bool ativo) async {
    _preferencias ??= await SharedPreferences.getInstance();
    _interacoesAtivasNotifier.value = ativo;
    await _preferencias!.setBool(chavePreferenciaInteracoes, ativo);
  }
}
