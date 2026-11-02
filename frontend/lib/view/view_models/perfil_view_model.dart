// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import '../../data/modelos/cadena.dart';
import '../../data/modelos/perfil_escalador.dart';
import '../../services/caderneta/catalogo_vias_caderneta.dart';
import '../../services/caderneta/estatisticas_caderneta.dart';
import '../../services/caderneta/repositorio_caderneta.dart';
import '../../services/repositorio_dataset.dart';

/// ViewModel da tela de Caderneta Esportiva do Escalador ([CadernetaPage]).
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

  /// Fonte reativa opcional de metadados externos (ex.: catálogo SQLite hidratado).
  final Listenable? _escutaMetadados;

  /// Catálogo de vias instanciado e gerenciado internamente quando criado via [comCatalogo].
  final CatalogoViasCaderneta? _catalogoViasProprio;

  bool _modoVias = true;

  /// Construtor que aceita o repositório injetado ou utiliza a instância padrão local.
  PerfilViewModel({
    RepositorioCaderneta? repositorio,
    this.obterGrauDaVia,
    this.obterNomeDaVia,
    Listenable? escutaMetadados,
    CatalogoViasCaderneta? catalogoViasProprio,
  }) : repositorio = repositorio ?? RepositorioCadernetaLocal.instancia,
       _escutaMetadados = escutaMetadados,
       _catalogoViasProprio = catalogoViasProprio {
    this.repositorio.cadenasNotifier.addListener(_aoAtualizarRepositorio);
    this.repositorio.perfilNotifier.addListener(_aoAtualizarRepositorio);
    _escutaMetadados?.addListener(_aoAtualizarRepositorio);
  }

  /// Cria o ViewModel conectado automaticamente ao catálogo local ([CatalogoViasCaderneta]),
  /// assumindo a responsabilidade de descartar o catálogo em [dispose].
  factory PerfilViewModel.comCatalogo({
    RepositorioCaderneta? repositorio,
    DatasetRepository? datasetRepo,
  }) {
    final repo = repositorio ?? RepositorioCadernetaLocal.instancia;
    final catalogoVias = CatalogoViasCaderneta(
      repositorioCaderneta: repo,
      datasetRepo: datasetRepo ?? DatasetRepository.instance,
    );
    return PerfilViewModel(
      repositorio: repo,
      obterNomeDaVia: catalogoVias.obterNomeDaVia,
      obterGrauDaVia: catalogoVias.obterGrauDaVia,
      escutaMetadados: catalogoVias,
      catalogoViasProprio: catalogoVias,
    );
  }

  void _aoAtualizarRepositorio() {
    notifyListeners();
  }

  @override
  void dispose() {
    repositorio.cadenasNotifier.removeListener(_aoAtualizarRepositorio);
    repositorio.perfilNotifier.removeListener(_aoAtualizarRepositorio);
    _escutaMetadados?.removeListener(_aoAtualizarRepositorio);
    _catalogoViasProprio?.dispose();
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
