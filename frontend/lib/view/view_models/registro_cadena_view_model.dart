// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import '../../data/modelos/cadena.dart';
import '../../data/modelos/tipo_ascensao.dart';
import '../../data/modelos/tipo_escalada.dart';
import '../../services/caderneta/repositorio_caderneta.dart';

/// ViewModel que encapsula o estado e as regras de negócio do registro de ascensões e cadenas.
///
/// Responsável por gerenciar a seleção de estilo esportivo ([TipoAscensao]), modalidade ([TipoEscalada]),
/// contagem de tentativas, data da ascensão e notas técnicas privadas, viabilizando uma interface visual
/// estritamente declarativa e desacoplada (Dumb UI / Humble View).
class RegistroCadenaViewModel extends ChangeNotifier {
  /// Limite máximo de caracteres permitido nas anotações técnicas privadas.
  static const int limiteNotasPrivadas = 200;

  /// Identificador NanoID 14c estável da via associada.
  final String escaladaUid;

  /// Nome legível da escalada para exibição no cabeçalho do modal.
  final String nomeEscalada;

  /// Grau sugerido oficial ou pré-calculado da escalada.
  final int? grauSugerido;

  /// Repositório da caderneta esportiva utilizado para persistência.
  final RepositorioCaderneta repositorio;

  TipoAscensao _tipoAscensao;
  TipoEscalada _tipoEscalada;
  int _tentativas;
  DateTime _dataAscensao;
  String _notasPrivadas;

  /// Inicializa o ViewModel com valores padrão ou fornecidos pelo chamador.
  RegistroCadenaViewModel({
    required this.escaladaUid,
    required this.nomeEscalada,
    TipoEscalada tipoEscaladaPadrao = TipoEscalada.guiado,
    TipoAscensao tipoAscensaoPadrao = TipoAscensao.trabalhado,
    int tentativasIniciais = 1,
    DateTime? dataAscensaoInicial,
    String notasIniciais = '',
    this.grauSugerido,
    RepositorioCaderneta? repositorio,
  })  : _tipoEscalada = tipoEscaladaPadrao,
        _tipoAscensao = tipoAscensaoPadrao,
        _tentativas = tentativasIniciais < 1 ? 1 : tentativasIniciais,
        _dataAscensao = dataAscensaoInicial ?? DateTime.now(),
        _notasPrivadas = notasIniciais.length > limiteNotasPrivadas
            ? notasIniciais.substring(0, limiteNotasPrivadas)
            : notasIniciais,
        repositorio = repositorio ?? RepositorioCadernetaLocal.instancia;

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

  /// Indica se a quantidade de tentativas pode ser decrementada (deve ser maior que 1).
  bool get podeDecrementarTentativas => _tentativas > 1;

  /// Indica se as anotações privadas atingiram a capacidade limite máxima.
  bool get atingiuLimiteNotas => _notasPrivadas.length >= limiteNotasPrivadas;

  /// Indicador formatado do uso de caracteres (ex: '45/200').
  String get contadorNotasTexto =>
      '${_notasPrivadas.length}/$limiteNotasPrivadas';

  /// Retorna a data da ascensão formatada em padrão brasileiro (DD/MM/AAAA).
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

  /// Salva a ascensão na caderneta através do [repositorio] e retorna a instância criada.
  Future<Cadena> salvar() async {
    final cadena = Cadena.criar(
      escaladaUid: escaladaUid,
      dataAscensao: _dataAscensao,
      tipoAscensao: _tipoAscensao,
      tipoEscalada: _tipoEscalada,
      tentativas: _tentativas,
      grauSugerido: grauSugerido,
      notasPrivadas: _notasPrivadas.trim(),
    );

    await repositorio.salvarCadena(cadena);
    return cadena;
  }
}
