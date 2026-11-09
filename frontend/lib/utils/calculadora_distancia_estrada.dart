// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

/// Representa um nó compartilhado da malha viária do OpenStreetMap (`catalogo_nos_estrada`)
/// contendo as distâncias rodoviárias pré-computadas em metros até os croquis que o alcançam.
///
/// Reutilizar o mesmo nó entre múltiplos croquis vizinhos evita duplicação espacial na
/// árvore de busca 2D e permite avaliar todos os picos locais em uma única consulta.
class NoEstrada {
  /// Identificador único do nó no OpenStreetMap (`no_osm_id`).
  final int noOsmId;

  /// Latitude do nó em graus decimais (`latitude_e7 / 1e7`).
  final double latitude;

  /// Longitude do nó em graus decimais (`longitude_e7 / 1e7`).
  final double longitude;

  /// Mapa associando o identificador do croqui (`croqui_uid` ou `id_slug`) à distância
  /// rodoviária em metros deste nó até o estacionamento principal do croqui.
  final Map<String, int> distanciasPorCroquiMetros;

  /// Cria um nó rodoviário imutável com suas distâncias pré-computadas por croqui.
  const NoEstrada({
    required this.noOsmId,
    required this.latitude,
    required this.longitude,
    required this.distanciasPorCroquiMetros,
  });
}

/// Representa um portal de borda (`na_borda = 1`) na fronteira da malha de 180 km
/// de um croqui.
///
/// Quando o usuário está a mais de 180 km de um pico (fora da malha local do croqui),
/// os portais de borda permitem calcular a aproximação de longa distância até o ponto
/// de entrada rodoviário mais favorável da região, preservando o contorno real da serra
/// nos últimos 180 km até o estacionamento.
class PortalBordaPico {
  /// Identificador único do nó no OpenStreetMap (`no_osm_id`).
  final int noOsmId;

  /// Latitude do portal de borda em graus decimais.
  final double latitude;

  /// Longitude do portal de borda em graus decimais.
  final double longitude;

  /// Distância rodoviária pré-computada em metros deste portal até o estacionamento do pico.
  final int distanciaEstradaAtePicoMetros;

  /// Cria um portal de borda imutável de um croqui.
  const PortalBordaPico({
    required this.noOsmId,
    required this.latitude,
    required this.longitude,
    required this.distanciaEstradaAtePicoMetros,
  });
}

class _NoKd {
  final NoEstrada no;
  final _NoKd? esquerda;
  final _NoKd? direita;

  const _NoKd({
    required this.no,
    this.esquerda,
    this.direita,
  });
}

class _CandidatoVizinho {
  final NoEstrada no;
  final double distanciaMetros;

  const _CandidatoVizinho({
    required this.no,
    required this.distanciaMetros,
  });
}

/// Árvore espacial 2D (KD-Tree) construída em memória sobre os nós da malha rodoviária
/// para busca em tempo logarítmico $O(\log N)$ dos nós mais próximos da posição do usuário.
///
/// Alterna o eixo de particionamento entre latitude (níveis pares) e longitude (níveis ímpares)
/// para balancear a subdivisão espacial e podar subárvores distantes sem inspecionar toda a malha.
class ArvoreKdNosEstrada {
  /// Cota inferior conservadora de metros por grau de latitude na superfície terrestre,
  /// garantindo que a poda geométrica nunca descarte um nó potencialmente mais próximo.
  static const double _metrosPorGrauLatitude = 110540.0;

  /// Cota de metros por grau de longitude no equador antes da projeção pelo cosseno da latitude.
  static const double _metrosPorGrauLongitudeEquador = 111320.0;

  final _NoKd? _raiz;
  final int _tamanho;

  /// Constrói uma KD-Tree 2D balanceada a partir da coleção de nós rodoviários.
  ArvoreKdNosEstrada(List<NoEstrada> nos)
      : _tamanho = nos.length,
        _raiz = _construirSubarvore(nos, 0);

  const ArvoreKdNosEstrada._vazia()
      : _raiz = null,
        _tamanho = 0;

  /// Indica se a árvore não possui nenhum nó indexado.
  bool get estaVazia => _raiz == null;

  /// Quantidade total de nós rodoviários indexados na árvore.
  int get tamanho => _tamanho;

  static _NoKd? _construirSubarvore(List<NoEstrada> lista, int profundidade) {
    if (lista.isEmpty) {
      return null;
    }
    final usarLatitude = profundidade.isEven;
    final ordenada = List<NoEstrada>.of(lista)
      ..sort(
        (a, b) => usarLatitude
            ? a.latitude.compareTo(b.latitude)
            : a.longitude.compareTo(b.longitude),
      );
    final indiceMediana = ordenada.length ~/ 2;
    return _NoKd(
      no: ordenada[indiceMediana],
      esquerda: _construirSubarvore(
        ordenada.sublist(0, indiceMediana),
        profundidade + 1,
      ),
      direita: _construirSubarvore(
        ordenada.sublist(indiceMediana + 1),
        profundidade + 1,
      ),
    );
  }

  /// Busca até [limite] nós mais próximos da coordenada ([latitude], [longitude])
  /// que estejam dentro de [raioMaximoMetros], ordenados da menor para a maior distância.
  List<NoEstrada> buscarMaisProximos({
    required double latitude,
    required double longitude,
    int limite = 3,
    double raioMaximoMetros = 15000.0,
  }) {
    final melhores = <_CandidatoVizinho>[];
    _buscarRecursivo(
      atual: _raiz,
      latitude: latitude,
      longitude: longitude,
      profundidade: 0,
      limite: limite,
      raioMaximoMetros: raioMaximoMetros,
      melhores: melhores,
    );
    return melhores.map((c) => c.no).toList(growable: false);
  }

  void _buscarRecursivo({
    required _NoKd? atual,
    required double latitude,
    required double longitude,
    required int profundidade,
    required int limite,
    required double raioMaximoMetros,
    required List<_CandidatoVizinho> melhores,
  }) {
    if (atual == null) {
      return;
    }

    final distanciaAteNo = Geolocator.distanceBetween(
      latitude,
      longitude,
      atual.no.latitude,
      atual.no.longitude,
    );

    if (distanciaAteNo <= raioMaximoMetros) {
      melhores.add(
        _CandidatoVizinho(
          no: atual.no,
          distanciaMetros: distanciaAteNo,
        ),
      );
      melhores.sort((a, b) => a.distanciaMetros.compareTo(b.distanciaMetros));
      if (melhores.length > limite) {
        melhores.removeLast();
      }
    }

    final usarLatitude = profundidade.isEven;
    final diferencaGraus = usarLatitude
        ? (latitude - atual.no.latitude)
        : (longitude - atual.no.longitude);

    final ramoPrincipal = diferencaGraus < 0 ? atual.esquerda : atual.direita;
    final ramoOposto = diferencaGraus < 0 ? atual.direita : atual.esquerda;

    _buscarRecursivo(
      atual: ramoPrincipal,
      latitude: latitude,
      longitude: longitude,
      profundidade: profundidade + 1,
      limite: limite,
      raioMaximoMetros: raioMaximoMetros,
      melhores: melhores,
    );

    final cotaInferiorPlanoMetros = usarLatitude
        ? diferencaGraus.abs() * _metrosPorGrauLatitude
        : diferencaGraus.abs() *
            _metrosPorGrauLongitudeEquador *
            math.cos(latitude * math.pi / 180.0).abs();

    final limiarPoda = melhores.length < limite
        ? raioMaximoMetros
        : melhores.last.distanciaMetros;

    if (cotaInferiorPlanoMetros <= limiarPoda) {
      _buscarRecursivo(
        atual: ramoOposto,
        latitude: latitude,
        longitude: longitude,
        profundidade: profundidade + 1,
        limite: limite,
        raioMaximoMetros: raioMaximoMetros,
        melhores: melhores,
      );
    }
  }
}

/// Calculadora offline de distância rodoviária estimada entre a posição do usuário e os croquis.
///
/// Combina a busca logarítmica dos $k = 3$ nós mais próximos na [ArvoreKdNosEstrada] (para
/// picos a até 180 km), a avaliação de portais de borda (`na_borda = 1`) para picos
/// distantes ($> 180\text{ km}$) e o fallback geodésico para croquis sem malha pré-computada.
class CalculadoraDistanciaEstrada {
  /// Fator médio de tortuosidade rodoviária aplicado a trechos estimados em linha reta
  /// (conexão inicial do usuário até a malha ou aproximação inter-regional até portais de borda).
  static const double fatorTortuosidade = 1.25;

  /// Raio máximo em metros (15 km) para capturar nós da malha rodoviária ao redor do usuário.
  static const double raioCapturaMalhaMetros = 15000.0;

  /// Quantidade de nós vizinhos avaliados ao redor do usuário para evitar escolher um nó
  /// na direção contrária ao fluxo da rodovia.
  static const int quantidadeVizinhos = 3;

  final ArvoreKdNosEstrada _arvoreNos;
  final Map<String, List<PortalBordaPico>> _portaisPorCroqui;

  /// Cria uma calculadora alimentada pelos [nos] da malha rodoviária e pelos [portaisPorCroqui].
  CalculadoraDistanciaEstrada({
    required List<NoEstrada> nos,
    Map<String, List<PortalBordaPico>> portaisPorCroqui =
        const <String, List<PortalBordaPico>>{},
  })  : _arvoreNos = ArvoreKdNosEstrada(nos),
        _portaisPorCroqui = portaisPorCroqui;

  /// Cria uma calculadora sem malha rodoviária carregada, operando em fallback geodésico direto.
  const CalculadoraDistanciaEstrada.vazia()
      : _arvoreNos = const ArvoreKdNosEstrada._vazia(),
        _portaisPorCroqui = const <String, List<PortalBordaPico>>{};

  /// Indica se há malha rodoviária carregada em memória.
  bool get possuiMalha =>
      !_arvoreNos.estaVazia || _portaisPorCroqui.isNotEmpty;

  /// Busca uma única vez os até [quantidadeVizinhos] nós rodoviários mais próximos do usuário
  /// dentro de [raioCapturaMalhaMetros] para reutilização no cálculo de múltiplos picos.
  List<NoEstrada> buscarNosProximos({
    required double latitudeUsuario,
    required double longitudeUsuario,
  }) {
    return _arvoreNos.buscarMaisProximos(
      latitude: latitudeUsuario,
      longitude: longitudeUsuario,
      limite: quantidadeVizinhos,
      raioMaximoMetros: raioCapturaMalhaMetros,
    );
  }

  /// Calcula a distância rodoviária estimada em metros entre o usuário e o croqui.
  ///
  /// - Se a calculadora estiver vazia ([possuiMalha] == `false`), retorna a distância geodésica direta.
  /// - Se algum dos nós vizinhos do usuário contiver [identificadorCroqui], retorna a menor soma
  ///   `dist_geodesica(U, K) * 1.25 + dist_estrada(K -> P)`.
  /// - Caso contrário, se o croqui possuir portais de borda (`na_borda = 1`), retorna a menor soma
  ///   `dist_geodesica(U, B) * 1.25 + dist_estrada(B -> P)`.
  /// - Como último recurso para croquis ainda sem malha compilada, retorna `dist_geodesica(U, P) * 1.25`.
  double calcularDistanciaMetros({
    required double latitudeUsuario,
    required double longitudeUsuario,
    required String identificadorCroqui,
    required double latitudePico,
    required double longitudePico,
    List<NoEstrada>? nosProximosPrecalculados,
  }) {
    if (!possuiMalha) {
      return Geolocator.distanceBetween(
        latitudeUsuario,
        longitudeUsuario,
        latitudePico,
        longitudePico,
      );
    }

    final nosProximos = nosProximosPrecalculados ??
        buscarNosProximos(
          latitudeUsuario: latitudeUsuario,
          longitudeUsuario: longitudeUsuario,
        );

    double? menorDistanciaMalha;
    for (final no in nosProximos) {
      final distanciaEstradaAtePico =
          no.distanciasPorCroquiMetros[identificadorCroqui];
      if (distanciaEstradaAtePico != null) {
        final distanciaAteNo = Geolocator.distanceBetween(
          latitudeUsuario,
          longitudeUsuario,
          no.latitude,
          no.longitude,
        );
        final distanciaTotal =
            distanciaAteNo * fatorTortuosidade + distanciaEstradaAtePico;
        if (menorDistanciaMalha == null ||
            distanciaTotal < menorDistanciaMalha) {
          menorDistanciaMalha = distanciaTotal;
        }
      }
    }

    if (menorDistanciaMalha != null) {
      return menorDistanciaMalha;
    }

    final portais = _portaisPorCroqui[identificadorCroqui];
    if (portais != null && portais.isNotEmpty) {
      double menorDistanciaPortal = double.infinity;
      for (final portal in portais) {
        final distanciaAtePortal = Geolocator.distanceBetween(
          latitudeUsuario,
          longitudeUsuario,
          portal.latitude,
          portal.longitude,
        );
        final distanciaTotal = distanciaAtePortal * fatorTortuosidade +
            portal.distanciaEstradaAtePicoMetros;
        if (distanciaTotal < menorDistanciaPortal) {
          menorDistanciaPortal = distanciaTotal;
        }
      }
      return menorDistanciaPortal;
    }

    return Geolocator.distanceBetween(
          latitudeUsuario,
          longitudeUsuario,
          latitudePico,
          longitudePico,
        ) *
        fatorTortuosidade;
  }
}
