// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/modelos/modelos_clima_pico.dart';
import '../../idioma/tradutor_app.dart';
import '../../widgets/card_pico.dart';
import '../../widgets/explorar/componentes_marcador_globo.dart';
import '../view_models/card_croqui_view_model.dart';

export '../../widgets/card_pico.dart';

/// Extrai a sigla da Unidade Federativa (`UF`, ex.: `'MG'`, `'RJ'`) a partir do slug/caminho
/// padronizado do catálogo (`br_mg_...`) ou aproxima pela coordenada geográfica.
String extrairSiglaUfPico({
  required String id,
  required String caminhoRelativo,
  required double latitude,
  required double longitude,
}) {
  final padraoBr = RegExp(r'(?:^|/|_)br_([a-zA-Z]{2})(?:_|/)');
  final mId = padraoBr.firstMatch(id);
  if (mId != null) return mId.group(1)!.toUpperCase();

  final mCam = padraoBr.firstMatch(caminhoRelativo);
  if (mCam != null) return mCam.group(1)!.toUpperCase();

  if (latitude >= -23.4 &&
      latitude <= -20.7 &&
      longitude >= -44.9 &&
      longitude <= -40.9) {
    return 'RJ';
  }
  if (latitude >= -21.4 &&
      latitude <= -17.8 &&
      longitude >= -41.9 &&
      longitude <= -39.6) {
    return 'ES';
  }
  if (latitude >= -25.3 &&
      latitude <= -19.7 &&
      longitude >= -53.1 &&
      longitude <= -44.1) {
    return 'SP';
  }
  if (latitude >= -22.9 &&
      latitude <= -14.2 &&
      longitude >= -51.1 &&
      longitude <= -39.8) {
    return 'MG';
  }
  if (latitude < -25.3) return 'RS';
  if (latitude > -14.2) return 'BA';
  return 'BR';
}

/// Constrói um [MarcadorPicoGlobo] imutável a partir dos dados geográficos, cota DEM e estado de umidade.
MarcadorPicoGlobo construirMarcadorGloboPico({
  required String id,
  required String nome,
  required String caminhoRelativo,
  required double latitude,
  required double longitude,
  required CotaAltimetricaPico? cota,
  required EstadoUmidadePico umidade,
}) {
  final picoAlt = cota?.altitudePicoMetros ?? 920;
  final baseAlt = cota?.altitudeBaseMetros ?? math.max(0, picoAlt - 280);
  return MarcadorPicoGlobo(
    id: id,
    nome: nome.isEmpty ? tr(ChaveTexto.comumPico) : nome,
    uf: extrairSiglaUfPico(
      id: id,
      caminhoRelativo: caminhoRelativo,
      latitude: latitude,
      longitude: longitude,
    ),
    latitude: latitude,
    longitude: longitude,
    altitudeBaseMetros: baseAlt,
    altitudePicoMetros: picoAlt,
    dimensaoGradeDem: cota?.dimensaoGradeDem ?? 0,
    raioGradeDemGraus: cota?.raioGradeDemGraus ?? 0.024,
    gradeDemMetros: cota?.gradeDemMetros ?? const [],
    umidade: umidade,
  );
}

/// Normaliza um alvo de download (`CardCroquiViewModel`, `Map` ou identificador textual) em `(id, nome)`.
({String id, String nome}) resolverAlvoDownloadExplorar(Object? crag) {
  final padraoPico = tr(ChaveTexto.comumPico);
  if (crag is CardCroquiViewModel) {
    return (
      id: crag.id,
      nome: crag.titulo.isEmpty ? padraoPico : crag.titulo,
    );
  }
  if (crag is Map) {
    return (
      id: crag['id']?.toString() ?? '',
      nome: crag['nome']?.toString() ?? padraoPico,
    );
  }
  return (id: crag?.toString() ?? '', nome: padraoPico);
}

/// Constrói um item de cartão de pico isolado normalizando entradas de metadados ou mapas.
Widget buildCragListItem(
  dynamic crag,
  ValueListenable<Map<String, double>> downloadingCrags,
  VoidCallback onDownload, {
  VoidCallback? onOpen,
  bool isDownloaded = false,
}) {
  final CardCroquiViewModel item = crag is CardCroquiViewModel
      ? crag
      : mapearMetadadosParaCard(crag, salvoOffline: isDownloaded);
  final dados = item.salvoOffline == isDownloaded
      ? item
      : item.comSalvoOffline(isDownloaded);
  return CragCard(
    dados: dados,
    downloadingCrags: downloadingCrags,
    onDownload: onDownload,
    onOpen: onOpen,
  );
}

/// Calcula a opacidade contínua (`0.0 .. 1.0`) do fundo da barra superior conforme a gaveta sobe para modo Lista.
double calcularOpacidadeFundoBarraTopo({
  required double alturaGavetaPx,
  required double alturaTelaPx,
}) {
  return ((alturaGavetaPx / math.max(1.0, alturaTelaPx) - 0.72) / 0.16)
      .clamp(0.0, 1.0);
}

/// Calcula o nível mínimo de zoom ao centralizar na coordenada GPS do usuário.
double calcularLodFocoLocalizacaoUsuario(double lodAtual) =>
    math.max(1.58, lodAtual);

/// Calcula o centro óptico e o LOD ideal no modo dividido para enquadrar simultaneamente
/// a localização GPS do usuário e o pico selecionado na barra de busca, mantendo as rodovias visíveis.
({double destinoLat, double destinoLon, double destinoLod})
    calcularEnquadramentoRotaUsuarioPico({
  required double usuarioLat,
  required double usuarioLon,
  required double picoLat,
  required double picoLon,
}) {
  final centroLat = (usuarioLat + picoLat) * 0.5;
  final centroLon = (usuarioLon + picoLon) * 0.5;
  final cosLat = math.cos(centroLat * math.pi / 180.0);
  final spanEfetivoGraus = math.max(
    (usuarioLat - picoLat).abs() * 1.65,
    (usuarioLon - picoLon).abs() * cosLat * 1.45,
  );
  final lodCalculado =
      2.48 - 0.36 * (math.log(math.max(0.18, spanEfetivoGraus)) / math.ln2);
  return (
    destinoLat: centroLat,
    destinoLon: centroLon,
    destinoLod: lodCalculado.clamp(1.74, 2.52),
  );
}
