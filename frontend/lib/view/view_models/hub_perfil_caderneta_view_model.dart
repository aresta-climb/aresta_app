// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/modelos/cadena.dart';
import '../../data/modelos/perfil_escalador.dart';
import '../../data/modelos/tipo_ascensao.dart';
import '../../services/caderneta/repositorio_caderneta.dart';

/// Modelo de apresentação para a tela de Hub do Perfil do Escalador e Caderneta.
///
/// Centraliza a orquestração reativa dos metadados de identidade esportiva,
/// cálculo de métricas rápidas (cadenas, tentativas, picos e vias) e o
/// roteamento de ações modulares (caderneta, configurações, dados e saída).
class HubPerfilCadernetaViewModel extends ChangeNotifier {
  /// Repositório de persistência e consulta da caderneta.
  final RepositorioCaderneta repositorio;

  /// Rótulo esportivo do escalador (ex.: "Escalador" ou "Escaladora").
  final String funcaoAtleta;

  /// Função customizada opcional para apuração do total de picos.
  final int Function()? _obterTotalPicos;

  /// Função customizada opcional para apuração do total de vias.
  final int Function()? _obterTotalVias;

  /// Callback para navegação até a página detalhada da caderneta.
  final void Function(BuildContext context)? aoAbrirCaderneta;

  /// Callback para navegação até as configurações do aplicativo.
  final void Function(BuildContext context)? aoAbrirConfiguracoes;

  /// Callback para abertura do diálogo de dados e privacidade.
  final void Function(BuildContext context)? aoAbrirDadosPrivacidade;

  /// Callback para confirmação de encerramento de sessão / logout.
  final void Function(BuildContext context)? aoConfirmarSaida;

  /// Callback para edição do perfil do escalador.
  final void Function(BuildContext context)? aoEditarPerfil;

  /// Construtor com injeção de dependências e configuração de ouvintes reativos.
  HubPerfilCadernetaViewModel({

}
