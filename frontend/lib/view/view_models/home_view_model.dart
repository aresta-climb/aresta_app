// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../aresta_api/proto/generated/indice.pb.dart';
import 'pico_proximo_view_model.dart';
import '../../services/controlador_interacoes_usuario.dart';
import '../../services/repositorio_dataset.dart';
import '../../services/http/sync_service.dart';
import '../../services/http/servico_download_segundo_plano.dart';
import '../../services/dataset/modelos/metadados_indice.dart';
import '../function_library/biblioteca_funcoes_comuns.dart';
import '../function_library/funcoes_home.dart';

/// Modelo de apresentação e gerenciador de estado para a tela [HomePage] (MVVM).
///
/// Encapsula o cálculo geodésico de picos próximos ao usuário, monitoramento de downloads,
/// sincronização manual e acionamento de navegação para detalhes do croqui, mantendo a interface (Dumb UI)
/// completamente livre de referências diretas a repositórios e serviços de rede.
class HomeViewModel extends ChangeNotifier {
  /// Repositório central de dados de escalada.
  final DatasetRepository datasetRepo;

  /// Serviço de sincronização e download de arquivos binários.
  final SyncService syncService;

  final ControladorInteracoesUsuario _controladorInteracoes;

  /// Callback opcional invocado sempre que a coordenada geográfica do usuário é atualizada.
  final void Function(double lat, double lon)? aoAtualizarLocalizacao;

  /// Callback opcional invocado quando o usuário aciona o card "VER MAIS ->" no carrossel.
  final VoidCallback? aoVerMaisProximos;

  double? _userLat;
  double? _userLon;
  List<PicoProximoViewModel>? _cachePicosProximos;

  HomeViewModel({
    required this.datasetRepo,
    required this.syncService,
    ControladorInteracoesUsuario? controladorInteracoes,
    this.aoAtualizarLocalizacao,
    this.aoVerMaisProximos,
  }) : _controladorInteracoes =
           controladorInteracoes ?? ControladorInteracoesUsuario.instancia {
    datasetRepo.activeDataset.addListener(_aoAtualizarDataset);
    datasetRepo.homeResetTrigger.addListener(_aoAtualizarDataset);
    datasetRepo.calculadoraDistanciaEstrada.addListener(_aoAtualizarDataset);
  }

  void _aoAtualizarDataset() {
    _cachePicosProximos = null;
    notifyListeners();
  }

  @override
  void dispose() {
    datasetRepo.activeDataset.removeListener(_aoAtualizarDataset);
    datasetRepo.homeResetTrigger.removeListener(_aoAtualizarDataset);
    datasetRepo.calculadoraDistanciaEstrada.removeListener(_aoAtualizarDataset);
    super.dispose();
  }

  /// Indica se os dados do catálogo ainda estão sendo inicializados.
  bool get carregando => datasetRepo.activeDataset.value == null;

  /// Latitude atual do usuário, se já resolvida.
  double? get latitudeUsuario => _userLat;

  /// Longitude atual do usuário, se já resolvida.
  double? get longitudeUsuario => _userLon;

  /// Monitoramento reativo do progresso percentual dos picos atualmente em download.
  ValueListenable<Map<String, double>> get downloadingCrags =>
      syncService.downloadingCrags;

  /// Notificador reativo que sinaliza mudanças na visibilidade de elementos de perfil/caderneta.
  ValueListenable<bool> get interacoesUsuarioAtivasListenable =>
      _controladorInteracoes.interacoesAtivasNotifier;

  /// Indica se o atalho para o Perfil do Escalador deve ser exibido na barra superior da Home.
  bool get exibirBotaoPerfil =>
      _controladorInteracoes.exibirElementosInterativos;

  /// Atualiza a coordenada geográfica do usuário para cálculo de distâncias.
  void atualizarLocalizacaoUsuario(double lat, double lon) {
    _userLat = lat;
    _userLon = lon;
    _cachePicosProximos = null;
    aoAtualizarLocalizacao?.call(lat, lon);
    notifyListeners();
  }

  /// Aciona o callback de transição para explorar mais picos próximos.
  void acionarVerMaisProximos() {
    aoVerMaisProximos?.call();
  }

  /// Verifica se um pico específico já foi baixado para o armazenamento local.
  bool estaBaixado(String picoId) {
    final dataset = datasetRepo.activeDataset.value;
    if (dataset == null) return false;
    return dataset.croquisBaixados.any((c) => c.id == picoId) ||
        dataset.picosBaixados.any((p) => p.id == picoId);
  }

  List<MetadadosIndice> get _picosDisponiveis {
    final dataset = datasetRepo.activeDataset.value;
    if (dataset == null) return const [];
    return dataset.metadadosDisponiveis;
  }

  /// Indica se o catálogo possui mais picos disponíveis além dos 6 exibidos no carrossel.
  bool get temMaisPicosParaExplorar => _picosDisponiveis.length > 6;

  /// Retorna os picos mais próximos ao usuário formatados como [PicoProximoViewModel].
  List<PicoProximoViewModel> get picosProximos {
    final availablePicos = _picosDisponiveis;
    if (availablePicos.isEmpty) return const [];

    if (_userLat == null || _userLon == null) {
      return const [];
    }

    final emCache = _cachePicosProximos;
    if (emCache != null) {
      return emCache;
    }

    final proximos = calcularPicosMaisProximos(
      userLat: _userLat!,
      userLon: _userLon!,
      picosDisponiveis: availablePicos,
      calculadoraDistancia: datasetRepo.calculadoraDistanciaEstrada.value,
    );

    final resultado = proximos.map((item) {
      final pico = item.pico as MetadadosIndice;
      return PicoProximoViewModel.deMetadados(
        metadados: pico,
        distanciaKm: item.distanciaKm,
        estaBaixado: estaBaixado(pico.id),
      );
    }).toList();
    _cachePicosProximos = resultado;
    return resultado;
  }

  /// Dispara a sincronização manual dos dados com o servidor remoto.
  Future<void> sincronizarManual(BuildContext context) async {
    await handleManualSync(context, datasetRepo, syncService);
  }

  /// Aciona o download dos dados de um pico específico em segundo plano.
  Future<bool> baixarPico(String picoId) async {
    final indice = datasetRepo.indiceData.value;
    if (indice != null) {
      final resumos = indice.croquis.where((r) => r.id == picoId).toList();
      if (resumos.isNotEmpty) {
        final servicoDownload = ServicoDownloadSegundoPlano(syncService: syncService);
        return await servicoDownload.executarDownload(resumos.first);
      }
    }
    final resumoFallback = ResumoCroqui()
      ..id = picoId
      ..nome = picoId;
    return await syncService.downloadCrag(resumoFallback);
  }

  /// Abre a tela de detalhes de um pico a partir do seu identificador único.
  Future<void> abrirPico(BuildContext context, String picoId) async {
    if (datasetRepo.activeDataset.value == null) return;
    await handlePicoSelection(context, datasetRepo, picoId, source: 'home');
  }
}
