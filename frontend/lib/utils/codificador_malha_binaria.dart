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

    final nCont = r.u16();
    final continentes = List<PoligonoGeografico>.generate(
      nCont,
      (_) => PoligonoGeografico(id: r.texto(), verticesLonLat: r.listaOffsets()),
      growable: false,
    );
    final brasil = r.listaOffsets();
    final nUf = r.u16();
    final estados = List<PoligonoGeografico>.generate(
      nUf,
      (_) => PoligonoGeografico(id: r.texto(), verticesLonLat: r.listaOffsets()),
      growable: false,
    );
    final nLoc = r.u16();
    final localidades = List<LocalidadeRegionalMapa>.generate(
      nLoc,
      (_) {
        final nome = r.texto();
        final nivel = r.u8().clamp(1, 3);
        final lon = r.f32();
        final lat = r.f32();
        return LocalidadeRegionalMapa(
          nome: nome,
          ehCidade: nivel == 1,
          nivel: nivel,
          longitude: lon,
          latitude: lat,
        );
      },
      growable: false,
    );
    final rodovias = _lerListaRodovias(r);
    return (
      versaoMalhaViaria: versaoViaria,
      continentes: continentes,
      brasil: brasil,
      estados: estados,
      localidades: localidades,
      rodovias: rodovias,
    );
  }

  /// Codifica um [SnapshotMalhaViariaOffline] em formato binário `ARSV` para cache local em disco.
  static Uint8List codificarSnapshotViario(SnapshotMalhaViariaOffline snapshot) {
    final w = _EscritorBinario()
      ..u32(magicSnapshotViario)
      ..u16(versaoFormato)
      ..u16(0)
      ..i64(snapshot.geradoEm.toUtc().millisecondsSinceEpoch)
      ..texto(snapshot.versaoHash);
    _escreverListaRodovias(w, snapshot.rodovias);
    return w.finalizar();
  }

  /// Decodifica um [SnapshotMalhaViariaOffline] a partir de bytes binários `ARSV`.
  static SnapshotMalhaViariaOffline decodificarSnapshotViario(Uint8List bytes) {
    final r = _LeitorBinario(bytes);
    if (r.u32() != magicSnapshotViario || r.u16() != versaoFormato) {
      throw const FormatException('Cabeçalho inválido no snapshot viário binário.');
    }
    r.u16();
    final ms = r.i64();
    final versao = r.texto();
    final rodovias = _lerListaRodovias(r);
    if (versao.isEmpty || rodovias.isEmpty) {
      throw const FormatException('Snapshot viário binário vazio.');
    }
    return SnapshotMalhaViariaOffline(
      geradoEm: DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
      versaoHash: versao,
      rodovias: rodovias,
    );
  }

  /// Codifica as cotas DEM 30m por pico e a grade regional SRTM para `altimetria_picos_inicial.bin`.
  static Uint8List codificarAltimetriaInicial({
    required Map<String, CotaAltimetricaPico> cotasPorPico,
    GradeElevacaoRegionalOffline? gradeRegional,
  }) {
    final w = _EscritorBinario()
      ..u32(magicAltimetria)
      ..u16(versaoFormato)
      ..u8(gradeRegional != null ? 1 : 0)
      ..u8(0)
      ..u16(cotasPorPico.length);

    for (final entry in cotasPorPico.entries) {
      final c = entry.value;
      w
        ..texto(entry.key)
        ..i16(c.altitudeBaseMetros)
        ..i16(c.altitudePicoMetros)
        ..i16(c.altitudePontoMetros ?? -32768)
        ..u16(c.dimensaoGradeDem)
        ..f32(c.raioGradeDemGraus)
        ..u16(c.gradeDemMetros.length);
      for (final z in c.gradeDemMetros) {
        w.i16(z);
      }
    }

    if (gradeRegional != null) {
      w
        ..f32(gradeRegional.latMin)
        ..f32(gradeRegional.lonMin)
        ..f32(gradeRegional.passoGraus)
        ..u16(gradeRegional.linhas)
        ..u16(gradeRegional.colunas);
      for (var i = 0; i < gradeRegional.cotasMetros.length; i++) {
        w.i16(gradeRegional.cotasMetros[i]);
      }
    }
    return w.finalizar();
  }

  /// Decodifica `altimetria_picos_inicial.bin` diretamente em `Int16List` / objetos imutáveis.
  static DadosAltimetriaBinariaDecodificados decodificarAltimetriaInicial(
    Uint8List bytes,
  ) {
    final r = _LeitorBinario(bytes);
    if (r.u32() != magicAltimetria || r.u16() != versaoFormato) {
      throw const FormatException('Cabeçalho inválido em altimetria_picos_inicial.bin.');
    }
    final temGrade = r.u8() == 1;
    r.u8();
    final nPicos = r.u16();
    final cotasPorPico = <String, CotaAltimetricaPico>{};
    for (var i = 0; i < nPicos; i++) {
      final id = r.texto();
      final baseM = r.i16();
      final picoM = r.i16();
      final pontoBruto = r.i16();
      final dim = r.u16();
      final raio = r.f32();
      final nAmostras = r.u16();
      final amostras = List<int>.generate(nAmostras, (_) => r.i16(), growable: false);
      cotasPorPico[id] = CotaAltimetricaPico(
        altitudeBaseMetros: baseM,
        altitudePicoMetros: picoM,
        altitudePontoMetros: pontoBruto == -32768 ? null : pontoBruto,
        dimensaoGradeDem: dim,
        raioGradeDemGraus: raio,
        gradeDemMetros: amostras,
      );
    }

    GradeElevacaoRegionalOffline? grade;
    if (temGrade) {
      final latMin = r.f32();
      final lonMin = r.f32();
      final passo = r.f32();
      final linhas = r.u16();
      final colunas = r.u16();
      final total = linhas * colunas;
      final cotas = Int16List(total);
      for (var i = 0; i < total; i++) {
        cotas[i] = r.i16();
      }
      grade = GradeElevacaoRegionalOffline(
        latMin: latMin,
        lonMin: lonMin,
        passoGraus: passo,
        linhas: linhas,
        colunas: colunas,
        cotasMetros: cotas,
      );
    }
    return (cotasPorPico: cotasPorPico, gradeRegional: grade);
  }

