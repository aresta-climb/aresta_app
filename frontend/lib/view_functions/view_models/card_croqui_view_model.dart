// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../aresta_api/proto/generated/croqui.pb.dart';
import '../../aresta_api/proto/generated/indice.pb.dart';
import '../../services/dataset/modelos/metadados_indice.dart';

/// ViewModel de item para exibição de cards de croquis na interface (Dumb UI).
///
/// Encapsula diretamente a mensagem Protobuf ([ResumoCroqui] ou [Croqui]) através de
/// getters sob demanda, formatando dados para apresentação visual de forma leve.
abstract class CardCroquiViewModel {
  /// Identificador único do pico/croqui.
  String get id;

  /// Título formatado em caixa alta para apresentação visual.
  String get titulo;

  /// Nome legível da localização (ex: 'SERRA DO CIPÓ').
  String get localizacao;

  /// Descrição textual resumida do pico/croqui.
  String get descricao;

  /// Resumo textual de setores e modalidades de escalada já formatado.
  String get textoEstatisticas;

  /// Caminho relativo da miniatura visual no armazenamento local ou CDN.
  String get caminhoMiniatura;

  /// Indica se os dados do croqui já foram baixados para acesso offline.
  bool get salvoOffline;

  /// Texto formatado de distância relativa do usuário (ex: '350m' ou '12.4km'), se disponível.
  String? get textoDistancia;

  /// Caminho opcional da imagem de capa local ou remota.
  String? get caminhoCapa;

  /// Hash SHA-256 opcional para validação de integridade e cache de imagem.
  String? get checksumSha256;

  /// Nome legível do pico (alias para [titulo]).
  String get nome => titulo;

  /// Retorna uma instância atualizada com o estado [salvoOffline].
  CardCroquiViewModel comSalvoOffline(bool salvoOffline);

  /// Suporte a indexação legada para retrocompatibilidade com testes e chamadores dinâmicos.
  dynamic operator [](String key) {
    switch (key) {
      case 'id':
        return id;
      case 'nome':
      case 'titulo':
        return titulo;
      case 'local':
      case 'localizacao':
        return localizacao;
      case 'descricao':
        return descricao;
      case 'isDownloaded':
      case 'salvoOffline':
        return salvoOffline;
      case 'stats':
        return textoEstatisticas;
      case 'thumbnailUrl':
        return caminhoMiniatura;
      case 'distance':
        return textoDistancia;
      case 'checksum':
        return checksumSha256;
      default:
        return null;
    }
  }

  const CardCroquiViewModel._();

  /// Cria um [CardCroquiViewModel] com valores primitivos explícitos (útil para testes unitários ou Dumb UI).
  const factory CardCroquiViewModel({
    required String id,
    required String titulo,
    String localizacao,
    String descricao,
    required String textoEstatisticas,
    required String caminhoMiniatura,
    bool salvoOffline,
    String? textoDistancia,
    String? caminhoCapa,
    String? checksumSha256,
  }) = _CardCroquiValores;

  /// Cria um [CardCroquiViewModel] diretamente sobre a mensagem Protobuf [ResumoCroqui].
  factory CardCroquiViewModel.deMetadados(
    ResumoCroqui metadados, {
    bool salvoOffline,
    String? textoDistancia,
    bool estatisticasDetalhadas,
  }) = _CardCroquiMetadados;

  /// Cria um [CardCroquiViewModel] diretamente sobre a mensagem Protobuf [Croqui] completo.
  factory CardCroquiViewModel.deCroqui(
    Croqui croqui, {
    String? textoDistancia,
  }) = _CardCroquiCroqui;

  /// Cria um [CardCroquiViewModel] com valores primitivos explícitos (útil para testes unitários).
  const factory CardCroquiViewModel.deValores({
    required String id,
    required String titulo,
    String localizacao,
    String descricao,
    required String textoEstatisticas,
    required String caminhoMiniatura,
    bool salvoOffline,
    String? textoDistancia,
    String? caminhoCapa,
    String? checksumSha256,
  }) = _CardCroquiValores;

  /// Cria um [CardCroquiViewModel] a partir de mapas legados ou mocks de teste.
  factory CardCroquiViewModel.deMapa(
    Map<String, dynamic> mapa, {
    bool salvoOffline,
  }) = _CardCroquiMapa;
}

/// Implementação leve que referencia diretamente a mensagem Protobuf [ResumoCroqui].
class _CardCroquiMetadados extends CardCroquiViewModel {
  final ResumoCroqui _metadados;

  @override
  final bool salvoOffline;

  @override
  final String? textoDistancia;

  final bool estatisticasDetalhadas;

  _CardCroquiMetadados(
    this._metadados, {
    this.salvoOffline = false,
    this.textoDistancia,
    this.estatisticasDetalhadas = false,
  }) : super._();

  @override
  String get id => _metadados.id;

  @override
  String get titulo =>
      _metadados.nome.trim().isEmpty ? 'SEM NOME' : _metadados.nome.trim().toUpperCase();

  @override
  String get localizacao => _metadados.localizacaoFormatada.toUpperCase();

  @override
  String get descricao => _metadados.descricao;

  @override
  String get caminhoMiniatura => 'thumbnails/${_metadados.id}.webp';

  @override
  String? get caminhoCapa => null;

  @override
  String? get checksumSha256 =>
      _metadados.hasChecksumSha256Thumbnail() ? _metadados.checksumSha256Thumbnail : null;

  @override
  String get textoEstatisticas {
    if (!_metadados.hasPrecomputados()) return '0 setores • 0 escaladas';
    final p = _metadados.precomputados;
    final base = '${p.totalSetores} setores • ${p.totalEscaladas} escaladas';
    if (!estatisticasDetalhadas) return base;

    final List<String> modalidades = [];
    if (p.totalBoulders > 0) modalidades.add('${p.totalBoulders} boulders');
    if (p.totalEsportivas > 0) modalidades.add('${p.totalEsportivas} esportivas');
    if (p.totalMoveis > 0) modalidades.add('${p.totalMoveis} móveis');
    if (p.totalMultiplasEnfiadas > 0) {
      modalidades.add('${p.totalMultiplasEnfiadas} múltiplas enfiadas');
    }
    if (p.totalHighlines > 0) modalidades.add('${p.totalHighlines} highlines');
    if (modalidades.isNotEmpty) {
      return '$base (${modalidades.join(', ')})';
    }
    return base;
  }

  @override
  CardCroquiViewModel comSalvoOffline(bool novoSalvoOffline) {
    if (salvoOffline == novoSalvoOffline) return this;
    return _CardCroquiMetadados(
      _metadados,
      salvoOffline: novoSalvoOffline,
      textoDistancia: textoDistancia,
      estatisticasDetalhadas: estatisticasDetalhadas,
    );
  }
}

/// Implementação leve que referencia diretamente a mensagem Protobuf [Croqui].
class _CardCroquiCroqui extends CardCroquiViewModel {
  final Croqui _croqui;

  @override
  final String? textoDistancia;

  _CardCroquiCroqui(this._croqui, {this.textoDistancia}) : super._();

  @override
  String get id => _croqui.id;

  @override
  String get titulo {
    final nomeFonte = _croqui.nome.trim().isNotEmpty
        ? _croqui.nome.trim()
        : (_croqui.picos.isNotEmpty ? _croqui.picos.first.nome.trim() : '');
    return nomeFonte.isEmpty ? 'SEM NOME' : nomeFonte.toUpperCase();
  }

  @override
  String get localizacao {
    final localFonte = _croqui.picos.isNotEmpty && _croqui.picos.first.estado.trim().isNotEmpty
        ? _croqui.picos.first.estado.trim()
        : '';
    return localFonte.isEmpty ? 'LOCAL DESCONHECIDO' : localFonte.toUpperCase();
  }

  @override
  String get descricao => _croqui.descricao;

  @override
  String get caminhoMiniatura => 'thumbnails/${_croqui.id}.webp';

  @override
  bool get salvoOffline => true;

  @override
  String? get caminhoCapa => null;

  @override
  String? get checksumSha256 => null;

  @override
  String get textoEstatisticas {
    if (_croqui.picos.isNotEmpty && _croqui.picos.first.hasPrecomputados()) {
      final stats = _croqui.picos.first.precomputados;
      return '${stats.totalSetores} setores • ${stats.totalEscaladas} escaladas';
    }
    return '0 setores • 0 escaladas';
  }

  @override
  CardCroquiViewModel comSalvoOffline(bool novoSalvoOffline) => this;
}

/// Implementação para valores primitivos explícitos (testes e flexibilidade).
class _CardCroquiValores extends CardCroquiViewModel {
  @override
  final String id;
  @override
  final String titulo;
  @override
  final String localizacao;
  @override
  final String descricao;
  @override
  final String textoEstatisticas;
  @override
  final String caminhoMiniatura;
  @override
  final bool salvoOffline;
  @override
  final String? textoDistancia;
  @override
  final String? caminhoCapa;
  @override
  final String? checksumSha256;

  const _CardCroquiValores({
    required this.id,
    required this.titulo,
    this.localizacao = '',
    this.descricao = '',
    required this.textoEstatisticas,
    required this.caminhoMiniatura,
    this.salvoOffline = false,
    this.textoDistancia,
    this.caminhoCapa,
    this.checksumSha256,
  }) : super._();

  @override
  CardCroquiViewModel comSalvoOffline(bool novoSalvoOffline) {
    if (salvoOffline == novoSalvoOffline) return this;
    return CardCroquiViewModel.deValores(
      id: id,
      titulo: titulo,
      localizacao: localizacao,
      descricao: descricao,
      textoEstatisticas: textoEstatisticas,
      caminhoMiniatura: caminhoMiniatura,
      salvoOffline: novoSalvoOffline,
      textoDistancia: textoDistancia,
      caminhoCapa: caminhoCapa,
      checksumSha256: checksumSha256,
    );
  }
}

/// Implementação para mapas legados em testes.
class _CardCroquiMapa extends CardCroquiViewModel {
  final Map<String, dynamic> _mapa;

  @override
  final bool salvoOffline;

  _CardCroquiMapa(this._mapa, {bool salvoOffline = false})
      : salvoOffline = salvoOffline ||
            (_mapa['isDownloaded'] == true) ||
            (_mapa['salvoOffline'] == true),
        super._();

  @override
  CardCroquiViewModel comSalvoOffline(bool novoSalvoOffline) {
    if (salvoOffline == novoSalvoOffline) return this;
    return _CardCroquiMapa(_mapa, salvoOffline: novoSalvoOffline);
  }

  @override
  String get id => _mapa['id']?.toString() ?? '';

  @override
  String get titulo => (_mapa['nome']?.toString() ?? 'Pico').toUpperCase();

  @override
  String get localizacao => (_mapa['local']?.toString() ?? '').toUpperCase();

  @override
  String get descricao => _mapa['descricao']?.toString() ?? '';

  @override
  String get textoEstatisticas =>
      _mapa['stats']?.toString() ?? '0 setores • 0 escaladas';

  @override
  String get caminhoMiniatura =>
      _mapa['thumbnailUrl']?.toString() ?? 'thumbnails/$id.webp';

  @override
  String? get textoDistancia => _mapa['distance']?.toString();

  @override
  String? get caminhoCapa => _mapa['capaPath']?.toString();

  @override
  String? get checksumSha256 => _mapa['checksum']?.toString();
}

/// Função de compatibilidade que instancia [CardCroquiViewModel] a partir de metadados flexíveis.
CardCroquiViewModel mapearMetadadosParaCard(
  dynamic metadados, {
  bool salvoOffline = false,
  String? textoDistancia,
  bool estatisticasDetalhadas = false,
}) {
  if (metadados is CardCroquiViewModel) return metadados;
  if (metadados is ResumoCroqui) {
    return CardCroquiViewModel.deMetadados(
      metadados,
      salvoOffline: salvoOffline,
      textoDistancia: textoDistancia,
      estatisticasDetalhadas: estatisticasDetalhadas,
    );
  }
  if (metadados is Croqui) {
    return CardCroquiViewModel.deCroqui(
      metadados,
      textoDistancia: textoDistancia,
    );
  }
  if (metadados is Map) {
    return CardCroquiViewModel.deMapa(
      Map<String, dynamic>.from(metadados),
      salvoOffline: salvoOffline,
    );
  }
  try {
    return (metadados as dynamic).paraCardCroquiViewModel() as CardCroquiViewModel;
  } catch (_) {}
  try {
    return (metadados as dynamic).paraCardCroquiDTO() as CardCroquiViewModel;
  } catch (_) {}
  return CardCroquiViewModel.deValores(
    id: metadados.toString(),
    titulo: metadados.toString(),
    textoEstatisticas: '',
    caminhoMiniatura: '',
    salvoOffline: salvoOffline,
    textoDistancia: textoDistancia,
  );
}

/// Função de compatibilidade que instancia [CardCroquiViewModel.deCroqui].
CardCroquiViewModel mapearCroquiParaCard(
  Croqui croqui, {
  String? textoDistancia,
}) {
  return CardCroquiViewModel.deCroqui(
    croqui,
    textoDistancia: textoDistancia,
  );
}
