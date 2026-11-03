// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import '../../data/modelos/cadena.dart';
import '../../data/modelos/perfil_escalador.dart';
import '../../services/caderneta/catalogo_vias_caderneta.dart';
import '../../services/caderneta/estatisticas_caderneta.dart';
import '../../services/caderneta/repositorio_caderneta.dart';
import '../../services/repositorio_dataset.dart';
import 'registro_cadena_view_model.dart';

/// ViewModel da tela de Caderneta Esportiva do Escalador ([CadernetaPage]).
///
/// Gerencia a interação reativa com o [RepositorioCaderneta], provendo os dados de identidade
/// esportiva pública ([PerfilEscalador]), histórico de cadenas, métricas analíticas, textos
/// formatados prontos para exibição na Dumb UI e callbacks de intenção de navegação/ação.
class PerfilViewModel extends ChangeNotifier {
  /// Repositório da caderneta esportiva utilizado para persistência e consultas.
  final RepositorioCaderneta repositorio;

  /// Função opcional para obter o grau textual oficial da via a partir de seu `escaladaUid`.
  final String? Function(String escaladaUid)? obterGrauDaVia;

  /// Função opcional para obter o nome legível da via a partir de seu `escaladaUid`.
  final String? Function(String escaladaUid)? obterNomeDaVia;

  /// Callback opcional invocado quando o usuário solicita editar uma ascensão.
  final ValueChanged<Cadena>? _aoEditarCadena;

  /// Callback opcional invocado quando o usuário solicita excluir uma ascensão.
  final ValueChanged<Cadena>? _aoExcluirCadena;

  /// Callback opcional invocado quando o usuário toca em uma ascensão para abrir sua via.
  final ValueChanged<Cadena>? _aoTocarVia;

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
    ValueChanged<Cadena>? aoEditarCadena,
    ValueChanged<Cadena>? aoExcluirCadena,
    ValueChanged<Cadena>? aoTocarVia,
    Listenable? escutaMetadados,
    CatalogoViasCaderneta? catalogoViasProprio,
  }) : repositorio = repositorio ?? RepositorioCadernetaLocal.instancia,
       _aoEditarCadena = aoEditarCadena,
       _aoExcluirCadena = aoExcluirCadena,
       _aoTocarVia = aoTocarVia,
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
    ValueChanged<Cadena>? aoEditarCadena,
    ValueChanged<Cadena>? aoExcluirCadena,
    ValueChanged<Cadena>? aoTocarVia,
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
      aoEditarCadena: aoEditarCadena,
      aoExcluirCadena: aoExcluirCadena,
      aoTocarVia: aoTocarVia,
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

  /// Retorna o título formatado da seção de histórico com a contagem atual de registros.
  String get tituloSecaoHistorico =>
      'Histórico de Ascensões (${historicoCadenas.length})';

  /// Retorna as estatísticas agregadas atualizadas.
  EstatisticasCaderneta get estatisticas =>
      repositorio.calcularEstatisticas(obterGrauDaVia: obterGrauDaVia);

  /// Indica se a visualização da pirâmide está ativa para vias (true) ou boulders (false).
  bool get modoVias => _modoVias;

  /// Retorna os dados da pirâmide de graduação conforme a modalidade selecionada.
  Map<String, int> get piramideAtiva =>
      _modoVias ? estatisticas.piramideVias : estatisticas.piramideBoulders;

  /// Indica se um callback customizado de edição foi injetado neste ViewModel.
  bool get possuiCallbackEditar => _aoEditarCadena != null;

  /// Indica se um callback customizado de exclusão foi injetado neste ViewModel.
  bool get possuiCallbackExcluir => _aoExcluirCadena != null;

  /// Indica se um callback customizado de navegação para a via foi injetado neste ViewModel.
  bool get possuiCallbackTocarVia => _aoTocarVia != null;

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

  /// Aciona a intenção de editar a [cadena] através do callback injetado.
  void editarCadena(Cadena cadena) {
    _aoEditarCadena?.call(cadena);
  }

  /// Aciona a intenção de solicitar exclusão da [cadena] através do callback injetado.
  void solicitarExclusaoCadena(Cadena cadena) {
    _aoExcluirCadena?.call(cadena);
  }

  /// Aciona a intenção de abrir a página da via associada à [cadena] através do callback injetado.
  void tocarVia(Cadena cadena) {
    _aoTocarVia?.call(cadena);
  }

  /// Constrói um [RegistroCadenaViewModel] pré-configurado para editar a [cadena] informada.
  RegistroCadenaViewModel criarViewModelEdicao(Cadena cadena) {
    return RegistroCadenaViewModel.paraEdicao(
      cadena: cadena,
      nomeEscalada: obterNomeEscalada(cadena.escaladaUid),
      repositorio: repositorio,
    );
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

  /// Formata a linha de metadados secundários de uma [cadena] (data, modalidade e tentativas)
  /// com concordância nominal pronta para exibição na Dumb UI.
  String formatarSubtituloAscensao(Cadena cadena) {
    final data = formatarDataAscensao(cadena.dataAscensao);
    final rotuloTentativas = cadena.tentativas == 1 ? 'tentativa' : 'tentativas';
    return '$data • ${cadena.tipoEscalada.rotulo} • ${cadena.tentativas} $rotuloTentativas';
  }

  /// Formata as notas privadas da [cadena] entre aspas tipográficas ou retorna `null` quando vazia.
  String? formatarCitacaoNotas(Cadena cadena) {
    final texto = cadena.notasPrivadas.trim();
    if (texto.isEmpty) return null;
    return '“$texto”';
  }
}
