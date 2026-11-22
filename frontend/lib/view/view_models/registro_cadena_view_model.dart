// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import '../../data/modelos/cadena.dart';
import '../../data/modelos/interacao_via.dart';
import '../../data/modelos/tipo_ascensao.dart';
import '../../data/modelos/tipo_escalada.dart';
import '../../services/caderneta/repositorio_caderneta.dart';
import '../../services/comunidade/repositorio_interacoes_via.dart';
import '../../utils/calculadora_delta_grau.dart';

/// Item imutável de apresentação de um chip de percepção de grau (`-2` a `+2`) para a Dumb UI.
@immutable
class OpcaoDeltaGrauApresentacao {
  /// Deslocamento numérico em relação ao grau oficial (`-2` a `+2`).
  final int delta;

  /// Rótulo formatado pronto para exibição no chip (ex.: `'Justo (7a)'`, `'+1 (7b)'`).
  final String rotulo;

  /// Indica se esta opção está atualmente selecionada pelo escalador.
  final bool selecionado;

  /// Cria uma instância constante de [OpcaoDeltaGrauApresentacao].
  const OpcaoDeltaGrauApresentacao({
    required this.delta,
    required this.rotulo,
    required this.selecionado,
  });
}

/// ViewModel que encapsula o estado e as regras de negócio do registro e edição de ascensões e cadenas,
/// unificando os dados privados da caderneta com a contribuição pública de grau (`-2..+2`) e dicas de beta.
class RegistroCadenaViewModel extends ChangeNotifier {
  /// Sequência canônica de deltas de grau exibida no formulário de contribuição pública.
  static const List<int> deltasDisponiveis = [-2, -1, 0, 1, 2];
  /// Limite máximo de caracteres permitido nas anotações técnicas privadas.
  static const int limiteNotasPrivadas = 200;

  /// Limite máximo de caracteres permitido no comentário público opcional (`VARCHAR(280)`).
  static const int limiteComentarioPublico =
      ComentarioComunidadeVia.limiteCaracteres;

  /// Identificador NanoID 14c estável da via associada.
  final String escaladaUid;

  /// Nome legível da escalada para exibição no cabeçalho do modal.
  final String nomeEscalada;

  /// Código numérico Protobuf do grau oficial da escalada, quando definido.
  final int? codigoGrauOficial;

  /// Indica se a escalada pertence à modalidade boulder.
  final bool ehBoulder;

  /// Indica se o bloco unificado de contribuição pública deve ser exibido no modal.
  final bool exibirContribuicaoPublica;

  /// Repositório da caderneta esportiva utilizado para persistência pessoal.
  final RepositorioCaderneta repositorio;

  /// Repositório comunitário utilizado para publicar voto de grau e comentário público.
  final RepositorioInteracoesVia repositorioInteracoes;

  /// Instância original da ascensão quando o formulário opera em modo de edição.
  final Cadena? cadenaOriginal;

  TipoAscensao _tipoAscensao;
  TipoEscalada _tipoEscalada;
  int _tentativas;
  DateTime _dataAscensao;
  String _notasPrivadas;
  int? _grauSugerido;
  int _deltaGrau = 0;
  String _comentarioPublico = '';

  /// Inicializa o ViewModel com valores padrão ou fornecidos pelo chamador.
  RegistroCadenaViewModel({
    required this.escaladaUid,
    required this.nomeEscalada,
    TipoEscalada tipoEscaladaPadrao = TipoEscalada.guiado,
    TipoAscensao tipoAscensaoPadrao = TipoAscensao.trabalhado,
    int tentativasIniciais = 1,
    DateTime? dataAscensaoInicial,
    String notasIniciais = '',
    int? grauSugerido,
    this.codigoGrauOficial,
    bool? ehBoulder,
    this.exibirContribuicaoPublica = false,
    this.cadenaOriginal,
    RepositorioCaderneta? repositorio,
    RepositorioInteracoesVia? repositorioInteracoes,
  }) : _tipoEscalada = tipoEscaladaPadrao,
       _tipoAscensao = tipoAscensaoPadrao,
       _tentativas = tentativasIniciais < 1 ? 1 : tentativasIniciais,
       _dataAscensao = dataAscensaoInicial ?? DateTime.now(),
       _notasPrivadas = notasIniciais.length > limiteNotasPrivadas
           ? notasIniciais.substring(0, limiteNotasPrivadas)
           : notasIniciais,
       _grauSugerido = grauSugerido ?? codigoGrauOficial,
       ehBoulder = ehBoulder ?? tipoEscaladaPadrao.isBoulder,
       repositorio = repositorio ?? RepositorioCadernetaLocal.instancia,
       repositorioInteracoes =
           repositorioInteracoes ?? RepositorioInteracoesViaMemoria.instancia;

  /// Cria um [RegistroCadenaViewModel] pré-populado para edição de uma [cadena] existente.
  factory RegistroCadenaViewModel.paraEdicao({
    required Cadena cadena,
    required String nomeEscalada,
    RepositorioCaderneta? repositorio,
    RepositorioInteracoesVia? repositorioInteracoes,
  }) {
    return RegistroCadenaViewModel(
      escaladaUid: cadena.escaladaUid,
      nomeEscalada: nomeEscalada,
      tipoEscaladaPadrao: cadena.tipoEscalada,
      tipoAscensaoPadrao: cadena.tipoAscensao,
      tentativasIniciais: cadena.tentativas,
      dataAscensaoInicial: cadena.dataAscensao,
      notasIniciais: cadena.notasPrivadas,
      grauSugerido: cadena.grauSugerido,
      cadenaOriginal: cadena,
      repositorio: repositorio,
      repositorioInteracoes: repositorioInteracoes,
    );
  }

  /// Indica se o ViewModel está editando um registro existente na caderneta.
  bool get editando => cadenaOriginal != null;

  /// Indica se o escalador está autenticado para publicar votos e dicas públicas.
  bool get estaAutenticadoParaComunidade =>
      repositorio.obterPerfil().estaAutenticado;

  /// Título contextual exibido no cabeçalho do modal.
  String get tituloModal => editando ? 'Editar Ascensão' : 'Registrar Ascensão';

  /// Rótulo contextual exibido no botão principal de salvamento.
  String get rotuloBotaoSalvar {
    if (editando) return 'Salvar Alterações';
    if (exibirContribuicaoPublica && estaAutenticadoParaComunidade) {
      return 'Salvar Cadena & Contribuir';
    }
    return 'Salvar na Caderneta';
  }

  /// Estilo esportivo de ascensão atualmente selecionado.
  TipoAscensao get tipoAscensao => _tipoAscensao;

  /// Modalidade da escalada (guiado, boulder, etc.).
  TipoEscalada get tipoEscalada => _tipoEscalada;

  /// Quantidade de tentativas / pegas despendidas (mínimo 1).
  int get tentativas => _tentativas;

  /// Data em que a ascensão ocorreu.
  DateTime get dataAscensao => _dataAscensao;

  /// Texto das anotações privadas do escalador.
  String get notasPrivadas => _notasPrivadas;

  /// Código numérico Protobuf do grau sugerido resultante.
  int? get grauSugerido => _grauSugerido;

  /// Deslocamento selecionado em relação ao grau oficial (`-2` a `+2`, padrão `0`).
  int get deltaGrau => _deltaGrau;

  /// Opções pré-formatadas dos chips de percepção de grau (`-2..+2`) prontas para a Dumb UI.
  List<OpcaoDeltaGrauApresentacao> get opcoesDeltaGrau {
    return deltasDisponiveis
        .map(
          (delta) => OpcaoDeltaGrauApresentacao(
            delta: delta,
            rotulo: rotuloOpcaoDeltaGrau(
              delta,
              codigoOficial: codigoGrauOficial,
              ehBoulder: ehBoulder,
            ),
            selecionado: delta == _deltaGrau,
          ),
        )
        .toList(growable: false);
  }

  /// Texto opcional de dica/beta pública para o guia comunitário.
  String get comentarioPublico => _comentarioPublico;

  /// Indica se a quantidade de tentativas pode ser decrementada (deve ser maior que 1).
  bool get podeDecrementarTentativas => _tentativas > 1;

  /// Indica se as anotações privadas atingiram a capacidade limite máxima.
  bool get atingiuLimiteNotas => _notasPrivadas.length >= limiteNotasPrivadas;

  /// Indicador formatado do uso de caracteres nas notas privadas (ex: `'45/200'`).
  String get contadorNotasTexto =>
      '${_notasPrivadas.length}/$limiteNotasPrivadas';

  /// Indica se o comentário público atingiu o limite máximo de 280 caracteres.
  bool get atingiuLimiteComentarioPublico =>
      _comentarioPublico.length >= limiteComentarioPublico;

  /// Indicador formatado do uso de caracteres no comentário público (ex: `'18/280'`).
  String get contadorComentarioPublicoTexto =>
      '${_comentarioPublico.length}/$limiteComentarioPublico';

  /// Retorna a data da ascensão formatada em padrão brasileiro (`DD/MM/AAAA`).
  String get dataAscensaoFormatada {
    final dia = _dataAscensao.day.toString().padLeft(2, '0');
    final mes = _dataAscensao.month.toString().padLeft(2, '0');
    return '$dia/$mes/${_dataAscensao.year}';
  }

  /// Incrementa o contador de tentativas em 1 unidade.
  void incrementarTentativas() {
    _tentativas++;
    notifyListeners();
  }

  /// Decrementa o contador de tentativas se for estritamente superior a 1.
  void decrementarTentativas() {
    if (_tentativas > 1) {
      _tentativas--;
      notifyListeners();
    }
  }

  /// Altera o estilo esportivo de ascensão selecionado.
  void definirTipoAscensao(TipoAscensao novoTipo) {
    if (_tipoAscensao != novoTipo) {
      _tipoAscensao = novoTipo;
      notifyListeners();
    }
  }

  /// Altera a modalidade da escalada.
  void definirTipoEscalada(TipoEscalada novoTipo) {
    if (_tipoEscalada != novoTipo) {
      _tipoEscalada = novoTipo;
      notifyListeners();
    }
  }

  /// Atualiza a data da ascensão.
  void definirDataAscensao(DateTime novaData) {
    _dataAscensao = novaData;
    notifyListeners();
  }

  /// Atualiza as notas técnicas privadas, respeitando o limite máximo estabelecido.
  void definirNotasPrivadas(String novasNotas) {
    final notasTratadas = novasNotas.length > limiteNotasPrivadas
        ? novasNotas.substring(0, limiteNotasPrivadas)
        : novasNotas;
    if (_notasPrivadas != notasTratadas) {
      _notasPrivadas = notasTratadas;
      notifyListeners();
    }
  }

  /// Atualiza a percepção de grau (`-2` a `+2`) recalculando [grauSugerido] quando há grau oficial.
  void definirDeltaGrau(int novoDelta) {
    final limitado = novoDelta < -2 ? -2 : (novoDelta > 2 ? 2 : novoDelta);
    if (_deltaGrau == limitado) return;
    _deltaGrau = limitado;
    if (codigoGrauOficial != null) {
      _grauSugerido = deslocarCodigoGrau(
        codigoGrauOficial,
        _deltaGrau,
        ehBoulder: ehBoulder,
      );
    }
    notifyListeners();
  }

  /// Atualiza o comentário público opcional, respeitando o limite de 280 caracteres.
  void definirComentarioPublico(String novoTexto) {
    final tratado = novoTexto.length > limiteComentarioPublico
        ? novoTexto.substring(0, limiteComentarioPublico)
        : novoTexto;
    if (_comentarioPublico != tratado) {
      _comentarioPublico = tratado;
      notifyListeners();
    }
  }

  /// Salva a ascensão na caderneta pessoal e, quando aplicável, publica a contribuição comunitária.
  Future<Cadena> salvar() async {
    final original = cadenaOriginal;
    final cadena = original != null
        ? original.copyWith(
            dataAscensao: _dataAscensao,
            tipoAscensao: _tipoAscensao,
            tipoEscalada: _tipoEscalada,
            tentativas: _tentativas,
            grauSugerido: _grauSugerido,
            notasPrivadas: _notasPrivadas.trim(),
          )
        : Cadena.criar(
            escaladaUid: escaladaUid,
            dataAscensao: _dataAscensao,
            tipoAscensao: _tipoAscensao,
            tipoEscalada: _tipoEscalada,
            tentativas: _tentativas,
            grauSugerido: _grauSugerido,
            notasPrivadas: _notasPrivadas.trim(),
          );

    await repositorio.salvarCadena(cadena);

    if (!editando &&
        exibirContribuicaoPublica &&
        estaAutenticadoParaComunidade &&
        escaladaUid.trim().isNotEmpty) {
      await repositorioInteracoes.registrarAvaliacaoAscensao(
        escaladaUid: escaladaUid,
        deltaGrau: _deltaGrau,
        codigoGrauOficial: codigoGrauOficial,
        grauSugerido: _grauSugerido,
        ehBoulder: ehBoulder,
        estiloAscensao: _tipoAscensao,
        comentarioPublico: _comentarioPublico,
      );
    }

    return cadena;
  }
}
