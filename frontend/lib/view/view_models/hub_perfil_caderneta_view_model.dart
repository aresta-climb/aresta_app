// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../data/modelos/cadena.dart';
import '../../data/modelos/perfil_escalador.dart';
import '../../data/modelos/tipo_ascensao.dart';
import '../../services/autenticacao/servico_autenticacao.dart';
import '../../services/caderneta/catalogo_vias_caderneta.dart';
import '../../services/caderneta/repositorio_caderneta.dart';
import '../../services/midia/seletor_foto_perfil.dart';
import '../../services/repositorio_dataset.dart';

/// Modelo de apresentação para a tela de Hub do Perfil do Escalador e Caderneta.
///
/// Centraliza o estado reativo de identidade esportiva, o cálculo de métricas rápidas
/// (cadenas, tentativas, picos e vias) e os comandos de negócio do perfil
/// (edição de nome, troca de foto, cópia do ID público e encerramento de sessão).
class HubPerfilCadernetaViewModel extends ChangeNotifier {
  /// Repositório de persistência e consulta da caderneta.
  final RepositorioCaderneta repositorio;

  /// Serviço de autenticação e sincronização remota com o Supabase.
  final ServicoAutenticacao _servicoAutenticacao;

  /// Seletor nativo de foto de perfil.
  final SeletorFotoPerfil _seletorFotoPerfil;

  /// Rótulo esportivo do escalador (ex.: "Escalador" ou "Escaladora").
  final String funcaoAtleta;

  /// Função customizada opcional para apuração do total de picos.
  final int Function()? _obterTotalPicos;

  /// Função customizada opcional para apuração do total de vias.
  final int Function()? _obterTotalVias;

  /// Fonte reativa opcional de metadados externos (ex.: catálogo SQLite hidratado).
  final Listenable? _escutaMetadados;

  /// Catálogo de vias instanciado e gerenciado internamente quando criado via [comCatalogo].
  final CatalogoViasCaderneta? _catalogoViasProprio;

  /// Construtor com injeção de dependências e configuração de ouvintes reativos.
  HubPerfilCadernetaViewModel({
    required this.repositorio,
    ServicoAutenticacao? servicoAutenticacao,
    SeletorFotoPerfil? seletorFotoPerfil,
    this.funcaoAtleta = 'Escalador',
    int Function()? obterTotalPicos,
    int Function()? obterTotalVias,
    Listenable? escutaMetadados,
    CatalogoViasCaderneta? catalogoViasProprio,
  }) : _servicoAutenticacao =
           servicoAutenticacao ??
           ServicoAutenticacaoLocal(repositorio: repositorio),
       _seletorFotoPerfil =
           seletorFotoPerfil ?? SeletorFotoPerfilNativo.instancia,
       _obterTotalPicos = obterTotalPicos,
       _obterTotalVias = obterTotalVias,
       _escutaMetadados = escutaMetadados,
       _catalogoViasProprio = catalogoViasProprio {
    repositorio.cadenasNotifier.addListener(_notificarMudanca);
    repositorio.perfilNotifier.addListener(_notificarMudanca);
    _escutaMetadados?.addListener(_notificarMudanca);
  }

  /// Cria o ViewModel conectado automaticamente ao catálogo local ([CatalogoViasCaderneta]),
  /// assumindo a responsabilidade de descartar o catálogo em [dispose].
  factory HubPerfilCadernetaViewModel.comCatalogo({
    RepositorioCaderneta? repositorio,
    ServicoAutenticacao? servicoAutenticacao,
    SeletorFotoPerfil? seletorFotoPerfil,
    DatasetRepository? datasetRepo,
    String funcaoAtleta = 'Escalador',
  }) {
    final repo = repositorio ?? RepositorioCadernetaLocal.instancia;
    final catalogoVias = CatalogoViasCaderneta(
      repositorioCaderneta: repo,
      datasetRepo: datasetRepo ?? DatasetRepository.instance,
    );
    return HubPerfilCadernetaViewModel(
      repositorio: repo,
      servicoAutenticacao: servicoAutenticacao,
      seletorFotoPerfil: seletorFotoPerfil,
      funcaoAtleta: funcaoAtleta,
      obterTotalPicos: catalogoVias.obterTotalPicosDistintos,
      escutaMetadados: catalogoVias,
      catalogoViasProprio: catalogoVias,
    );
  }

  void _notificarMudanca() {
    notifyListeners();
  }

  @override
  void dispose() {
    repositorio.cadenasNotifier.removeListener(_notificarMudanca);
    repositorio.perfilNotifier.removeListener(_notificarMudanca);
    _escutaMetadados?.removeListener(_notificarMudanca);
    _catalogoViasProprio?.dispose();
    super.dispose();
  }

  /// Retorna os metadados do perfil do escalador.
  PerfilEscalador get perfil => repositorio.obterPerfil();

  /// Indica se o perfil atual está vinculado a uma conta autenticada.
  bool get estaAutenticado => perfil.estaAutenticado;

  /// Nome público esportivo do atleta.
  String get nomeAtleta => perfil.autorNomePublico;

  /// URL ou Data URI da foto de perfil do escalador.
  String? get fotoUrl => perfil.fotoUrl;

  /// Identificador público único do autor (NanoID 14 caracteres).
  String get autorIdPublico => perfil.autorIdPublico;

  /// Lista imutável de ascensões esportivas registradas.
  List<Cadena> get cadenas => repositorio.cadenasNotifier.value;

  /// Total de ascensões bem-sucedidas (cadenas confirmadas).
  int get totalCadenas => cadenas.where((c) => c.isCadena).length;

  /// Total de tentativas / pegas registradas sem cadeia.
  int get totalTentativas =>
      cadenas.where((c) => c.tipoAscensao == TipoAscensao.tentativa).length;

  /// Total de picos distintos com registros no catálogo.
  int get totalPicos {
    if (_obterTotalPicos != null) {
      return _obterTotalPicos();
    }
    return totalVias > 0 ? 1 : 0;
  }

  /// Total de vias distintas com registros na caderneta.
  int get totalVias {
    if (_obterTotalVias != null) {
      return _obterTotalVias();
    }
    return cadenas.map((c) => c.escaladaUid).toSet().length;
  }

  /// Atualiza o nome público esportivo do atleta de forma persistente e sincroniza com o Supabase.
  Future<void> atualizarNome(String novoNome) async {
    final nomeTratado = novoNome.trim();
    if (nomeTratado.isEmpty || nomeTratado == nomeAtleta) {
      return;
    }
    await _servicoAutenticacao.atualizarPerfilRemoto(novoNome: nomeTratado);
  }

  /// Atualiza a foto de perfil do atleta de forma persistente e sincroniza com o Supabase.
  Future<void> atualizarFotoPerfil(String novaFotoUrl) async {
    final fotoTratada = novaFotoUrl.trim();
    if (fotoTratada.isEmpty || fotoTratada == fotoUrl) {
      return;
    }
    await _servicoAutenticacao.atualizarPerfilRemoto(novaFotoUrl: fotoTratada);
  }

  /// Abre a galeria do dispositivo para selecionar uma nova foto e atualiza o perfil no Supabase.
  ///
  /// Retorna `true` quando uma nova foto foi selecionada e salva.
  Future<bool> selecionarEAtualizarFoto() async {
    final dataUri = await _seletorFotoPerfil.selecionarFotoComoDataUri();
    if (dataUri == null || dataUri.isEmpty) {
      return false;
    }
    await atualizarFotoPerfil(dataUri);
    return true;
  }

  /// Seleciona uma nova foto na galeria, persiste no perfil e retorna a [fotoUrl] resultante (ou `null` se cancelado).
  Future<String?> selecionarEObterNovaFoto() async {
    final alterou = await selecionarEAtualizarFoto();
    return alterou ? fotoUrl : null;
  }

  /// Copia o [autorIdPublico] do atleta para a área de transferência do dispositivo.
  Future<void> copiarIdPublico() async {
    await Clipboard.setData(ClipboardData(text: autorIdPublico));
  }

  /// Encerra a sessão autenticada do escalador, preservando o ID público e as cadenas locais.
  Future<void> encerrarSessao() async {
    await _servicoAutenticacao.encerrarSessao();
  }
}
