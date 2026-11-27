// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/modelos/cadena.dart';
import '../../data/modelos/estatisticas_caderneta.dart';
import '../../data/modelos/interacao_via.dart';
import '../../data/modelos/perfil_escalador.dart';
import '../../idioma/tradutor_app.dart';
import '../../services/caderneta/catalogo_vias_caderneta.dart';
import '../../services/caderneta/repositorio_caderneta.dart';
import '../../services/comunidade/repositorio_interacoes_via.dart';
import '../../services/firebase/app_logger.dart';
import '../../services/repositorio_dataset.dart';
import 'registro_cadena_view_model.dart';

/// ViewModel da tela de Caderneta Esportiva do Escalador ([CadernetaPage]).
///
/// Gerencia a interação reativa com o [RepositorioCaderneta] e o [RepositorioInteracoesVia],
/// provendo os dados de identidade esportiva pública ([PerfilEscalador]), histórico de cadenas,
/// alertas criados/confirmados pelo usuário, métricas analíticas e textos prontos para a Dumb UI.
class PerfilViewModel extends ChangeNotifier {
  /// Repositório da caderneta esportiva utilizado para persistência e consultas.
  final RepositorioCaderneta repositorio;

  /// Repositório comunitário utilizado para listar e resolver alertas acompanhados na Caderneta.
  final RepositorioInteracoesVia repositorioInteracoes;

  /// Duração da janela de desfazer antes de persistir a resolução de um alerta.
  final Duration duracaoJanelaDesfazer;

  /// Função opcional para obter o grau textual oficial da via a partir de seu `escaladaUid`.
  final String? Function(String escaladaUid)? obterGrauDaVia;

  /// Função opcional para obter o nome legível da via a partir de seu `escaladaUid`.
  final String? Function(String escaladaUid)? obterNomeDaVia;

  final ValueChanged<Cadena>? _aoEditarCadena;
  final ValueChanged<Cadena>? _aoExcluirCadena;
  final ValueChanged<Cadena>? _aoTocarVia;
  final Listenable? _escutaMetadados;
  final CatalogoViasCaderneta? _catalogoViasProprio;
  final Map<String, ({String escaladaUid, Timer timer})>
  _resolucoesAlertasPendentes = {};

  bool _modoVias = true;
  bool _descartado = false;

  /// Construtor que aceita os repositórios injetados ou utiliza as instâncias padrão locais.
  PerfilViewModel({
    RepositorioCaderneta? repositorio,
    RepositorioInteracoesVia? repositorioInteracoes,
    this.duracaoJanelaDesfazer = const Duration(seconds: 4),
    this.obterGrauDaVia,
    this.obterNomeDaVia,
    ValueChanged<Cadena>? aoEditarCadena,
    ValueChanged<Cadena>? aoExcluirCadena,
    ValueChanged<Cadena>? aoTocarVia,
    Listenable? escutaMetadados,
    CatalogoViasCaderneta? catalogoViasProprio,
  }) : repositorio = repositorio ?? RepositorioCadernetaLocal.instancia,
       repositorioInteracoes =
           repositorioInteracoes ?? RepositorioInteracoesViaMemoria.instancia,
       _aoEditarCadena = aoEditarCadena,
       _aoExcluirCadena = aoExcluirCadena,
       _aoTocarVia = aoTocarVia,
       _escutaMetadados = escutaMetadados,
       _catalogoViasProprio = catalogoViasProprio {
    this.repositorio.cadenasNotifier.addListener(_aoAtualizarRepositorio);
    this.repositorio.perfilNotifier.addListener(_aoAtualizarRepositorio);
    this.repositorioInteracoes.alteracoesListenable.addListener(
      _aoAtualizarRepositorio,
    );
    _escutaMetadados?.addListener(_aoAtualizarRepositorio);
    ControladorIdiomaApp.instancia.notificadorIdioma.addListener(
      _aoAtualizarRepositorio,
    );
    unawaited(
      this.repositorioInteracoes.sincronizarMeusAlertasContribuidos().catchError(
        (Object e) {
          AppLogger.instance.logAviso(
            'Sincronização de alertas na Caderneta adiada: $e',
          );
        },
      ),
    );
  }

  /// Cria o ViewModel conectado automaticamente ao catálogo local ([CatalogoViasCaderneta]),
  /// assumindo a responsabilidade de descartar o catálogo em [dispose].
  factory PerfilViewModel.comCatalogo({
    RepositorioCaderneta? repositorio,
    RepositorioInteracoesVia? repositorioInteracoes,
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
      repositorioInteracoes: repositorioInteracoes,
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
    if (!_descartado) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _descartado = true;
    final pendentes = _resolucoesAlertasPendentes.entries.toList(
      growable: false,
    );
    _resolucoesAlertasPendentes.clear();
    for (final p in pendentes) {
      p.value.timer.cancel();
      unawaited(
        repositorioInteracoes.confirmarAlerta(
          escaladaUid: p.value.escaladaUid,
          alertaUid: p.key,
          aindaEstaLa: false,
        ),
      );
    }
    repositorio.cadenasNotifier.removeListener(_aoAtualizarRepositorio);
    repositorio.perfilNotifier.removeListener(_aoAtualizarRepositorio);
    repositorioInteracoes.alteracoesListenable.removeListener(
      _aoAtualizarRepositorio,
    );
    _escutaMetadados?.removeListener(_aoAtualizarRepositorio);
    ControladorIdiomaApp.instancia.notificadorIdioma.removeListener(
      _aoAtualizarRepositorio,
    );
    _catalogoViasProprio?.dispose();
    super.dispose();
  }

  /// Retorna os metadados do perfil do escalador atual.
  PerfilEscalador get perfil => repositorio.obterPerfil();

  /// Retorna a lista de todas as ascensões registradas na caderneta.
  List<Cadena> get historicoCadenas => repositorio.cadenasNotifier.value;

  /// Retorna o título formatado da seção de histórico com a contagem atual de registros.
  String get tituloSecaoHistorico => tr(ChaveTexto.cadHistoricoContagem, {
    'n': '${historicoCadenas.length}',
  });

  /// Retorna os alertas criados (`CRIADO POR VOCÊ`) e confirmados (`CONFIRMADO (+1)`) pelo perfil atual.
  List<AlertaContribuidoCaderneta> get meusAlertas => repositorioInteracoes
      .obterMeusAlertasContribuidos()
      .map(
        (item) => _resolucoesAlertasPendentes.containsKey(item.alerta.uid)
            ? AlertaContribuidoCaderneta(
                alerta: item.alerta,
                papel: item.papel,
                ativo: false,
                ultimaInteracaoEm: item.ultimaInteracaoEm,
              )
            : item,
      )
      .toList(growable: false);

  /// Título formatado da seção de alertas na Caderneta.
  String get tituloSecaoMeusAlertas => tr(ChaveTexto.cadMeusAlertasContagem, {
    'n': '${meusAlertas.length}',
  });

  /// Marca otimisticamente [alerta] como resolvido na Caderneta e agenda o envio após [duracaoJanelaDesfazer].
  void iniciarResolucaoMeuAlertaComDesfazer(AlertaSegurancaVia alerta) {
    _resolucoesAlertasPendentes.remove(alerta.uid)?.timer.cancel();
    _resolucoesAlertasPendentes[alerta.uid] = (
      escaladaUid: alerta.escaladaUid,
      timer: Timer(duracaoJanelaDesfazer, () {
        _resolucoesAlertasPendentes.remove(alerta.uid);
        unawaited(
          repositorioInteracoes.confirmarAlerta(
            escaladaUid: alerta.escaladaUid,
            alertaUid: alerta.uid,
            aindaEstaLa: false,
          ),
        );
      }),
    );
    _aoAtualizarRepositorio();
  }

  /// Cancela a resolução pendente de [alertaUid], restaurando o estado ativo na Caderneta.
  void desfazerResolucaoMeuAlerta(String alertaUid) {
    final pendente = _resolucoesAlertasPendentes.remove(alertaUid);
    if (pendente != null) {
      pendente.timer.cancel();
      _aoAtualizarRepositorio();
    }
  }

  /// Edita a categoria e/ou o detalhe de um alerta ativo criado pelo próprio escalador na Caderneta.
  Future<bool> editarMeuAlerta(
    AlertaSegurancaVia alerta,
    CategoriaAlertaSeguranca novaCategoria, {
    String? detalhe,
  }) async {
    try {
      await repositorioInteracoes.editarAlerta(
        escaladaUid: alerta.escaladaUid,
        alertaUid: alerta.uid,
        novaCategoria: novaCategoria,
        detalhe: detalhe,
      );
      return true;
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Falha ao editar alerta ${alerta.uid} pela Caderneta',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Exclui permanentemente um alerta criado pelo próprio escalador na Caderneta.
  Future<bool> excluirMeuAlerta(AlertaSegurancaVia alerta) async {
    _resolucoesAlertasPendentes.remove(alerta.uid)?.timer.cancel();
    try {
      await repositorioInteracoes.excluirAlerta(
        escaladaUid: alerta.escaladaUid,
        alertaUid: alerta.uid,
      );
      return true;
    } catch (e, stackTrace) {
      AppLogger.instance.logError(
        'Falha ao excluir alerta ${alerta.uid} pela Caderneta',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

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
    return obterNomeDaVia?.call(uid) ?? '${tr(ChaveTexto.modVia)} ($uid)';
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
    final rotuloTentativas = cadena.tentativas == 1
        ? tr(ChaveTexto.estiloTentativaSingular)
        : tr(ChaveTexto.estiloTentativaPlural);
    return '$data • ${cadena.tipoEscalada.rotulo} • ${cadena.tentativas} $rotuloTentativas';
  }

  /// Formata as notas privadas da [cadena] entre aspas tipográficas ou retorna `null` quando vazia.
  String? formatarCitacaoNotas(Cadena cadena) {
    final texto = cadena.notasPrivadas.trim();
    if (texto.isEmpty) return null;
    return '“$texto”';
  }
}
