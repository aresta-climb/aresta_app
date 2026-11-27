// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import '../data/modelos/modelos_clima_pico.dart';
import '../data/modelos/modelos_rede_viaria_aresta.dart';
import '../data/modelos/modelos_relevo_topografico.dart';

/// Dados desserializados em zero-GC a partir do ativo binário `malha_globo_brasil.bin`.
typedef DadosMalhaBinariaDecodificados = ({
  String versaoMalhaViaria,
  List<PoligonoGeografico> continentes,
  List<Offset> brasil,
  List<PoligonoGeografico> estados,
  List<LocalidadeRegionalMapa> localidades,
  List<RodoviaRegionalMapa> rodovias,
});

/// Dados desserializados a partir do ativo binário `altimetria_picos_inicial.bin`.
typedef DadosAltimetriaBinariaDecodificados = ({
  Map<String, CotaAltimetricaPico> cotasPorPico,
  GradeElevacaoRegionalOffline? gradeRegional,
});

/// Codificador e decodificador binário compacto (`little-endian`, `Float32` / `Int16`) para
/// a malha geográfica, snapshots viários offline e grades altimétricas SRTM.
///
/// Substitui `jsonDecode` + `base64Decode` por leitura direta em `ByteData`, reduzindo
/// o tamanho em disco em ~4x e eliminando pausas de GC ao abrir ou interagir com o mapa.
abstract final class CodificadorMalhaBinaria {
  static const int magicMalhaGlobo = 0x424D5241; // 'ARMB' little-endian
  static const int magicSnapshotViario = 0x56535241; // 'ARSV' little-endian
  static const int magicAltimetria = 0x4C415241; // 'ARAL' little-endian
  static const int versaoFormato = 1;

  /// Codifica os vetores completos do globo e da malha viária para o formato binário `ARMB`.
  static Uint8List codificarMalhaGlobo({
    required String versaoMalhaViaria,
    required List<PoligonoGeografico> continentes,
    required List<Offset> brasil,
    required List<PoligonoGeografico> estados,
    required List<LocalidadeRegionalMapa> localidades,
    required List<RodoviaRegionalMapa> rodovias,
  }) {
    final w = _EscritorBinario()
      ..u32(magicMalhaGlobo)
      ..u16(versaoFormato)
      ..u16(0)
      ..texto(versaoMalhaViaria)
      ..u16(continentes.length);
    for (final c in continentes) {
      w
        ..texto(c.id)
        ..listaOffsets(c.verticesLonLat);
    }
    w
      ..listaOffsets(brasil)
      ..u16(estados.length);
    for (final uf in estados) {
      w
        ..texto(uf.id)
        ..listaOffsets(uf.verticesLonLat);
    }
    w.u16(localidades.length);
    for (final loc in localidades) {
      w
        ..texto(loc.nome)
        ..u8(loc.nivel.clamp(1, 3))
        ..f32(loc.longitude)
        ..f32(loc.latitude);
    }
    _escreverListaRodovias(w, rodovias);
    return w.finalizar();
  }

  /// Decodifica `malha_globo_brasil.bin` diretamente de bytes nativos sem alocar mapas JSON.
  static DadosMalhaBinariaDecodificados decodificarMalhaGlobo(Uint8List bytes) {
    final r = _LeitorBinario(bytes);
    if (r.u32() != magicMalhaGlobo || r.u16() != versaoFormato) {
      throw const FormatException('Cabeçalho inválido em malha_globo_brasil.bin.');
    }
    r.u16(); // reservado
    final versaoViaria = r.texto();

