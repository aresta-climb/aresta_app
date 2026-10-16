// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import '../../data/modelos/cadena.dart';
import '../../data/modelos/perfil_escalador.dart';
import '../../services/caderneta/estatisticas_caderneta.dart';
import '../../services/caderneta/repositorio_caderneta.dart';

/// ViewModel da tela de Perfil do Escalador ([PerfilPage]).
///
/// Gerencia a interação reativa com o [RepositorioCaderneta], provendo os dados de identidade
/// esportiva pública ([PerfilEscalador]), histórico de cadenas, métricas analíticas e a pirâmide
/// de graus com suporte a alternância dinâmica entre modalidades (Vias e Boulders).
class PerfilViewModel extends ChangeNotifier {
  /// Repositório da caderneta esportiva utilizado para persistência e consultas.
  final RepositorioCaderneta repositorio;

  /// Função opcional para obter o grau textual oficial da via a partir de seu `escaladaUid`.
  final String? Function(String escaladaUid)? obterGrauDaVia;

  /// Função opcional para obter o nome legível da via a partir de seu `escaladaUid`.
  final String? Function(String escaladaUid)? obterNomeDaVia;

  bool _modoVias = true;

  /// Construtor que aceita o repositório injetado ou utiliza a instância padrão local.
  PerfilViewModel({
    RepositorioCaderneta? repositorio,
    this.obterGrauDaVia,
    this.obterNomeDaVia,
  }) : repositorio = repositorio ?? RepositorioCadernetaLocal.instancia {
    this.repositorio.cadenasNotifier.addListener(_aoAtualizarRepositorio);
    this.repositorio.perfilNotifier.addListener(_aoAtualizarRepositorio);
  }

  void _aoAtualizarRepositorio() {
    notifyListeners();
  }

  @override
  void dispose() {
    repositorio.cadenasNotifier.removeListener(_aoAtualizarRepositorio);
    repositorio.perfilNotifier.removeListener(_aoAtualizarRepositorio);
    super.dispose();
  }

  /// Retorna os metadados do perfil do escalador atual.
  PerfilEscalador get perfil => repositorio.obterPerfil();

  /// Retorna a lista de todas as ascensões registradas na caderneta.
  List<Cadena> get historicoCadenas => repositorio.cadenasNotifier.value;

  /// Retorna as estatísticas agregadas atualizadas.
  EstatisticasCaderneta get estatisticas =>
      repositorio.calcularEstatisticas(obterGrauDaVia: obterGrauDaVia);

  /// Indica se a visualização da pirâmide está ativa para vias (true) ou boulders (false).
  bool get modoVias => _modoVias;

  /// Retorna os dados da pirâmide de graduação conforme a modalidade selecionada.
  Map<String, int> get piramideAtiva =>
      _modoVias ? estatisticas.piramideVias : estatisticas.piramideBoulders;

  /// Alterna a modalidade exibida na pirâmide entre Vias (`true`) e Boulders (`false`).
  void alternarModoModalidade(bool apenasVias) {
    if (_modoVias != apenasVias) {
      _modoVias = apenasVias;
      notifyListeners();
    }
  }

  /// Atualiza o apelido público esportivo do atleta no repositório.
  Future<void> atualizarNome(String novoNome) async {
    final perfilAtualizado = perfil.copyWith(autorNomePublico: novoNome);
    await repositorio.salvarPerfil(perfilAtualizado);
  }

  /// Remove permanentemente uma ascensão da caderneta.
  Future<void> excluirCadena(String id) async {
    await repositorio.excluirCadena(id);
  }

  /// Obtém o nome amigável da escalada pelo seu [uid], provendo fallback quando não localizado.
  String obterNomeEscalada(String uid) {
    return obterNomeDaVia?.call(uid) ?? 'Via ($uid)';
  }

  /// Obtém a graduação formatada da escalada pelo seu [uid].
  String? obterGrauEscalada(String uid) {
    return obterGrauDaVia?.call(uid);
  }

  /// Formata a data de uma ascensão em padrão textual legível brasileiro (DD/MM/AAAA).
  String formatarDataAscensao(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }
}
