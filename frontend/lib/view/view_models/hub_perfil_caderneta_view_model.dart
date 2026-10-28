// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
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
  final VoidCallback? aoAbrirCaderneta;

  /// Callback para navegação até as configurações do aplicativo.
  final VoidCallback? aoAbrirConfiguracoes;

  /// Callback para abertura do diálogo de dados e privacidade.
  final VoidCallback? aoAbrirDadosPrivacidade;

  /// Callback para confirmação de encerramento de sessão / logout.
  final VoidCallback? aoConfirmarSaida;

  /// Callback para edição do perfil do escalador.
  final VoidCallback? aoEditarPerfil;

  /// Construtor com injeção de dependências e configuração de ouvintes reativos.
  HubPerfilCadernetaViewModel({
    required this.repositorio,
    this.funcaoAtleta = 'Escalador',
    int Function()? obterTotalPicos,
    int Function()? obterTotalVias,
    this.aoAbrirCaderneta,
    this.aoAbrirConfiguracoes,
    this.aoAbrirDadosPrivacidade,
    this.aoConfirmarSaida,
    this.aoEditarPerfil,
  })  : _obterTotalPicos = obterTotalPicos,
        _obterTotalVias = obterTotalVias {
    repositorio.cadenasNotifier.addListener(_notificarMudanca);
    repositorio.perfilNotifier.addListener(_notificarMudanca);
  }

  void _notificarMudanca() {
    notifyListeners();
  }

  @override
  void dispose() {
    repositorio.cadenasNotifier.removeListener(_notificarMudanca);
    repositorio.perfilNotifier.removeListener(_notificarMudanca);
    super.dispose();
  }

  /// Retorna os metadados do perfil do escalador.
  PerfilEscalador get perfil => repositorio.obterPerfil();

  /// Nome público esportivo do atleta.
  String get nomeAtleta => perfil.autorNomePublico;

  /// Identificador público único do autor (NanoID 14 caracteres).
  String get autorIdPublico => perfil.autorIdPublico;

  /// Lista imutável de ascensões esportivas registradas.
  List<Cadena> get cadenas => repositorio.cadenasNotifier.value;

  /// Total de ascensões bem-sucedidas (cadenas confirmadas).
  int get totalCadenas => cadenas.where((c) => c.isCadena).length;

  /// Total de tentativas / pegas registradas sem cadeia.
  int get totalTentativas =>
      cadenas.where((c) => c.tipoAscensao == TipoAscensao.tentativa).length;

  /// Total de picos distintos com registros ou valor provido pelo resolver.
  int get totalPicos {
    if (_obterTotalPicos != null) {
      return _obterTotalPicos();
    }
    return totalVias > 0 ? 1 : 0;
  }

  /// Total de vias distintas com registros ou valor provido pelo resolver.
  int get totalVias {
    if (_obterTotalVias != null) {
      return _obterTotalVias();
    }
    return cadenas.map((c) => c.escaladaUid).toSet().length;
  }

  /// Atualiza o nome público esportivo do atleta de forma persistente.
  Future<void> atualizarNome(String novoNome) async {
    final nomeTratado = novoNome.trim();
    if (nomeTratado.isEmpty || nomeTratado == nomeAtleta) {
      return;
    }
    final perfilAtualizado = perfil.copyWith(autorNomePublico: nomeTratado);
    await repositorio.salvarPerfil(perfilAtualizado);
  }

  /// Copia o [autorIdPublico] do atleta para a área de transferência do dispositivo.
  Future<void> copiarIdPublico() async {
    await Clipboard.setData(ClipboardData(text: autorIdPublico));
  }

  /// Aciona a abertura da tela detalhada de Caderneta.
  void abrirCaderneta() {
    aoAbrirCaderneta?.call();
  }

  /// Aciona a abertura da tela de configurações.
  void abrirConfiguracoes() {
    aoAbrirConfiguracoes?.call();
  }

  /// Aciona a visualização dos dados e privacidade.
  void abrirDadosPrivacidade() {
    aoAbrirDadosPrivacidade?.call();
  }

  /// Aciona o fluxo de saída / logout.
  void confirmarSaida() {
    aoConfirmarSaida?.call();
  }

  /// Aciona a edição dos dados do perfil.
  void editarPerfil() {
    aoEditarPerfil?.call();
  }
}
