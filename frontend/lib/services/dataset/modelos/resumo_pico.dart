// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import '../../../aresta_api/proto/generated/croqui.pb.dart';
import 'estatisticas_pico.dart';

/// Representa de forma fortemente tipada o resumo de um pico/crag do catálogo.
///
/// Substitui o uso inseguro de `Map<String, dynamic>` ao longo de toda a aplicação,
/// garantindo tipagem forte, autocompletação e validações de integridade em tempo de compilação.
class ResumoPico {
  /// Identificador único do pico (ex: 'pedra_bela').
  final String id;

  /// Nome amigável do pico de escalada.
  final String nome;

  /// Localização textual resumida (ex: cidade, estado ou país).
  final String local;

  /// Descrição ou apresentação geral da área de escalada.
  final String descricao;

  /// URL de download ou sincronização remota do pacote de croqui.
  final String url;

  /// Checksum SHA-256 do arquivo binário para validação de integridade.
  final String checksum;

  /// URL da imagem miniatura pré-computada para carregamento remoto ágil.
  final String thumbnailUrl;

  /// Indica se o pico já está completamente baixado no armazenamento local.
  final bool isDownloaded;

  /// Tamanho total em bytes do pacote do pico.
  final int? tamanhoBytes;

  /// Tamanho pré-formatado legível para exibição humana (ex: '2.5 MB').
  final String tamanhoFormatado;

  /// Carimbo de data/hora da última atualização em formato ISO-8601.
  final String? dataUpdate;

  /// Latitude geográfica da localização do pico.
  final double? latitude;

  /// Longitude geográfica da localização do pico.
  final double? longitude;

  /// Estatísticas pré-computadas de vias e setores.
  final EstatisticasPico? estatisticas;

  /// Caminho local no sistema de arquivos para a imagem de capa principal.
  final String? capaPath;

  /// Instância completa do Croqui binário carregado em memória, se disponível.
  final Croqui? croqui;

  /// Instância de Pico de detalhe associado, se carregado.
  final Pico? pico;

  /// Distância calculada em quilômetros em relação à coordenada atual do usuário.
  final double? distanciaKm;

  const ResumoPico({
    required this.id,
    required this.nome,
    required this.local,
    this.descricao = '',
    this.url = '',
    this.checksum = '',
    this.thumbnailUrl = '',
    this.isDownloaded = false,
    this.tamanhoBytes,
    this.tamanhoFormatado = 'Offline',
    this.dataUpdate,
    this.latitude,
    this.longitude,
    this.estatisticas,
    this.capaPath,
    this.croqui,
    this.pico,
    this.distanciaKm,
  });

  /// Cria uma nova instância com campos alterados seletivamente.
  ResumoPico copyWith({
    String? id,
    String? nome,
    String? local,
    String? descricao,
    String? url,
    String? checksum,
    String? thumbnailUrl,
    bool? isDownloaded,
    int? tamanhoBytes,
    String? tamanhoFormatado,
    String? dataUpdate,
    double? latitude,
    double? longitude,
    EstatisticasPico? estatisticas,
    String? capaPath,
    Croqui? croqui,
    Pico? pico,
    double? distanciaKm,
  }) {
    return ResumoPico(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      local: local ?? this.local,
      descricao: descricao ?? this.descricao,
      url: url ?? this.url,
      checksum: checksum ?? this.checksum,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      tamanhoBytes: tamanhoBytes ?? this.tamanhoBytes,
      tamanhoFormatado: tamanhoFormatado ?? this.tamanhoFormatado,
      dataUpdate: dataUpdate ?? this.dataUpdate,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      estatisticas: estatisticas ?? this.estatisticas,
      capaPath: capaPath ?? this.capaPath,
      croqui: croqui ?? this.croqui,
      pico: pico ?? this.pico,
      distanciaKm: distanciaKm ?? this.distanciaKm,
    );
  }

  /// Suporte a indexação por chave para compatibilidade temporária durante a transição.
  dynamic operator [](String key) {
    switch (key) {
      case 'id':
        return id;
      case 'nome':
        return nome;
      case 'local':
        return local;
      case 'descricao':
        return descricao;
      case 'url':
        return url;
      case 'checksum':
        return checksum;
      case 'thumbnailUrl':
        return thumbnailUrl;
      case 'isDownloaded':
        return isDownloaded;
      case 'tamanhoBytes':
        return tamanhoBytes;
      case 'tamanhoFormatado':
        return tamanhoFormatado;
      case 'dataUpdate':
        return dataUpdate;
      case 'latitude':
        return latitude;
      case 'longitude':
        return longitude;
      case 'estatisticas':
        return estatisticas?.paraMapa();
      case 'capaPath':
        return capaPath;
      case 'data':
        return (pico != null && croqui != null)
            ? {'pico': pico, 'croqui': croqui}
            : null;
      case 'distance':
        return distanciaKm;
      default:
        return null;
    }
  }

  /// Verifica a existência de chaves mapeadas.
  bool containsKey(String key) {
    return this[key] != null;
  }

  /// Converte para representação em mapa genérico.
  Map<String, dynamic> paraMapa() {
    return {
      'id': id,
      'nome': nome,
      'local': local,
      'descricao': descricao,
      'url': url,
      'checksum': checksum,
      'thumbnailUrl': thumbnailUrl,
      'isDownloaded': isDownloaded,
      'tamanhoBytes': tamanhoBytes,
      'tamanhoFormatado': tamanhoFormatado,
      if (dataUpdate != null) 'dataUpdate': dataUpdate,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (estatisticas != null) 'estatisticas': estatisticas!.paraMapa(),
      if (capaPath != null) 'capaPath': capaPath,
      if (distanciaKm != null) 'distance': distanciaKm,
    };
  }

  /// Instancia o [ResumoPico] a partir de um mapa de dados legado.
  factory ResumoPico.deMapa(Map<String, dynamic> mapa) {
    Croqui? croqui;
    Pico? pico;
    final dynamic data = mapa['data'];
    if (data is Map) {
      if (data['croqui'] is Croqui) croqui = data['croqui'] as Croqui;
      if (data['pico'] is Pico) pico = data['pico'] as Pico;
    }

    EstatisticasPico? estatisticas;
    if (mapa['estatisticas'] is Map<String, dynamic>) {
      estatisticas =
          EstatisticasPico.deMapa(mapa['estatisticas'] as Map<String, dynamic>);
    }

    return ResumoPico(
      id: mapa['id']?.toString() ?? '',
      nome: mapa['nome']?.toString() ?? '',
      local: mapa['local']?.toString() ?? '',
      descricao: mapa['descricao']?.toString() ?? '',
      url: mapa['url']?.toString() ?? '',
      checksum: mapa['checksum']?.toString() ?? '',
      thumbnailUrl: mapa['thumbnailUrl']?.toString() ?? '',
      isDownloaded: mapa['isDownloaded'] == true,
      tamanhoBytes: (mapa['tamanhoBytes'] as num?)?.toInt(),
      tamanhoFormatado: mapa['tamanhoFormatado']?.toString() ?? 'Offline',
      dataUpdate: mapa['dataUpdate']?.toString(),
      latitude: (mapa['latitude'] as num?)?.toDouble(),
      longitude: (mapa['longitude'] as num?)?.toDouble(),
      estatisticas: estatisticas,
      capaPath: mapa['capaPath']?.toString(),
      croqui: croqui,
      pico: pico,
      distanciaKm: (mapa['distance'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResumoPico &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nome == other.nome &&
          local == other.local &&
          url == other.url &&
          isDownloaded == other.isDownloaded &&
          tamanhoBytes == other.tamanhoBytes &&
          distanciaKm == other.distanciaKm;

  @override
  int get hashCode => Object.hash(
        id,
        nome,
        local,
        url,
        isDownloaded,
        tamanhoBytes,
        distanciaKm,
      );

  @override
  String toString() => 'ResumoPico(id: $id, nome: $nome, local: $local)';
}
