// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';

import 'componentes_marcador_globo.dart';
import 'controlador_camera_globo.dart';
import 'malha_relevo_lod.dart';

export 'componentes_marcador_globo.dart';

/// Projetor declarativo das camadas espaciais sobrepostas ao globo/mapa:
/// localidades reais do IBGE sem colisão, ponto GPS do usuário, clusters por UF (`LOD 0`),
/// bolhas compactas Aresta e pílula expandida do pico selecionado.
abstract final class CamadaMarcadoresGloboExplorar {
  /// Constrói todas as camadas de widgets posicionados (`Positioned`) sobre o canvas do planeta.
  static List<Widget> construirCamadas({
    required BuildContext context,
    required Size tamanho,
    required ControladorCameraGlobo controlador,
    required RedeViariaArestaGlobo? redeViaria,
    required List<MarcadorPicoGlobo> picos,
    required List<PicoRelevoReferencia> referenciasRelevo,
    required String? picoSelecionadoId,
    required ({double latitude, double longitude})? localizacaoUsuario,
    required double recuoSuperiorControles,
    double progressoLuzViaria = 1.0,
    required void Function(MarcadorPicoGlobo pico, {double? lodExplicito})
        aoSelecionarPico,
  }) {
    return <Widget>[
      ..._construirRotulosLocalidadesProximas(
        tamanho: tamanho,
        controlador: controlador,
        redeViaria: redeViaria,
        picos: picos,
        referencias: referenciasRelevo,
        picoSelecionadoId: picoSelecionadoId,
        recuoSuperiorControles: recuoSuperiorControles,
        progressoLuzViaria: progressoLuzViaria,
      ),
      ..._construirMarcadorLocalizacaoUsuario(
        tamanho: tamanho,
        controlador: controlador,
        localizacaoUsuario: localizacaoUsuario,
        referencias: referenciasRelevo,
        recuoSuperiorControles: recuoSuperiorControles,
      ),
      ..._construirMarcadoresLod(
        tamanho: tamanho,
        controlador: controlador,
        picos: picos,
        referencias: referenciasRelevo,
        picoSelecionadoId: picoSelecionadoId,
        recuoSuperiorControles: recuoSuperiorControles,
        aoSelecionarPico: aoSelecionarPico,
      ),
    ];
  }

  static List<Widget> _construirMarcadorLocalizacaoUsuario({
    required Size tamanho,
    required ControladorCameraGlobo controlador,
    required ({double latitude, double longitude})? localizacaoUsuario,
    required List<PicoRelevoReferencia> referencias,
    required double recuoSuperiorControles,
  }) {
    final loc = localizacaoUsuario;
    if (loc == null) return const [];
    final pt = controlador.projetarCoordenada(
      latitude: loc.latitude,
      longitude: loc.longitude,
      elevacaoMetros: 0.0,
      tamanhoTela: tamanho,
    );
    final limiteInferior = tamanho.height - controlador.alturaGavetaPx + 8.0;
    final limiteSuperior = recuoSuperiorControles + 8.0;
    if (!pt.visivel ||
        pt.x < 10 ||
        pt.x > tamanho.width - 10 ||
        pt.y < limiteSuperior ||
        pt.y > limiteInferior) {
      return const [];
    }

    return [
      Positioned(
        left: pt.x - 11,
        top: pt.y - 11,
        child: IgnorePointer(
          child: Container(
            key: const Key('marcador_localizacao_usuario'),
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x3838BDF8),
              border: Border.all(color: const Color(0x5538BDF8)),
            ),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0284C7),
                border: Border.all(color: Colors.white, width: 2.0),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  static List<Widget> _construirMarcadoresLod({
    required Size tamanho,
    required ControladorCameraGlobo controlador,
    required List<MarcadorPicoGlobo> picos,
    required List<PicoRelevoReferencia> referencias,
    required String? picoSelecionadoId,
    required double recuoSuperiorControles,
    required void Function(MarcadorPicoGlobo pico, {double? lodExplicito})
        aoSelecionarPico,
  }) {
    final limiteInferior = tamanho.height - controlador.alturaGavetaPx + 8.0;
    final limiteSuperior = recuoSuperiorControles + 12.0;

    if (controlador.altitudeCameraKm >= 1800.0) {
      return _construirClustersPorUf(
        tamanho: tamanho,
        controlador: controlador,
        picos: picos,
        limiteSuperior: limiteSuperior,
        limiteInferior: limiteInferior,
        aoSelecionarPico: aoSelecionarPico,
      );
    }

    final visiveis = <({MarcadorPicoGlobo pico, PontoProjetadoTela pt})>[];
    for (final p in picos) {
      final pt = controlador.projetarCoordenada(
        latitude: p.latitude,
        longitude: p.longitude,
        elevacaoMetros: 0.0,
        tamanhoTela: tamanho,
      );
      if (pt.visivel &&
          pt.x > 16 &&
          pt.x < tamanho.width - 16 &&
          pt.y > limiteSuperior &&
          pt.y < limiteInferior) {
        visiveis.add((pico: p, pt: pt));
      }
    }

    visiveis.sort((a, b) {
      final prioA = a.pico.id == picoSelecionadoId ? 1 : 0;
      final prioB = b.pico.id == picoSelecionadoId ? 1 : 0;
      return prioA.compareTo(prioB);
    });

    final widgets = <Widget>[];
    for (final item in visiveis) {
      final p = item.pico;
      final pt = item.pt;
      if (p.id != picoSelecionadoId) {
        widgets.add(
          BolhaCompactaPicoGlobo(
            pico: p,
            ponto: pt,
            aoTocar: () => aoSelecionarPico(p),
          ),
        );
      } else {
        widgets.add(
          PilulaExpandidaPicoGlobo(
            pico: p,
            ponto: pt,
            tamanhoTela: tamanho,
            lodAtual: controlador.lod,
            aoTocar: () => aoSelecionarPico(p),
          ),
        );
      }
    }
    return widgets;
  }

  static List<Widget> _construirClustersPorUf({
    required Size tamanho,
    required ControladorCameraGlobo controlador,
    required List<MarcadorPicoGlobo> picos,
    required double limiteSuperior,
    required double limiteInferior,
    required void Function(MarcadorPicoGlobo pico, {double? lodExplicito})
        aoSelecionarPico,
  }) {
    final clusters = ControladorCameraGlobo.agruparPorEstado(
      picos.map(
        (p) => (id: p.id, uf: p.uf, lat: p.latitude, lon: p.longitude),
      ),
    );

    final projetados = <({ClusterEstadoGlobo cluster, Offset pos})>[];
    for (final cluster in clusters) {
      final pt = controlador.projetarCoordenada(
        latitude: cluster.latitudeMedia,
        longitude: cluster.longitudeMedia,
        elevacaoMetros: 0,
        tamanhoTela: tamanho,
      );
      if (!pt.visivel ||
          pt.x < 20 ||
          pt.x > tamanho.width - 20 ||
          pt.y < limiteSuperior ||
          pt.y > limiteInferior) {
        continue;
      }
      projetados.add((cluster: cluster, pos: Offset(pt.x, pt.y)));
    }

    final posicoesSemColisao = _separarPosicoesClusters(
      projetados.map((p) => p.pos).toList(),
      larguraMinima: 56.0,
      alturaMinima: 28.0,
    );

    final widgets = <Widget>[];
    for (var i = 0; i < projetados.length; i++) {
      final cluster = projetados[i].cluster;
      final pos = posicoesSemColisao[i];
      widgets.add(
        Positioned(
          left: (pos.dx - 28).clamp(8.0, tamanho.width - 64.0),
          top: (pos.dy - 12).clamp(limiteSuperior, limiteInferior - 24.0),
          child: GestureDetector(
            key: Key('cluster_uf_${cluster.uf}'),
            onTap: () {
              final alvo = picos.firstWhere(
                (p) => p.id == cluster.primeiroPicoId,
              );
              aoSelecionarPico(alvo, lodExplicito: 1.18);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xE60B111A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x55BAE6FD)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const IconeMarcaAresta(
                    largura: 12.0,
                    cor: Color(0xFFE27D60),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${cluster.uf} ${cluster.quantidade}',
                    style: const TextStyle(
                      color: Color(0xFFF4F3ED),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  static List<Widget> _construirRotulosLocalidadesProximas({
    required Size tamanho,
    required ControladorCameraGlobo controlador,
    required RedeViariaArestaGlobo? redeViaria,
    required List<MarcadorPicoGlobo> picos,
    required List<PicoRelevoReferencia> referencias,
    required String? picoSelecionadoId,
    required double recuoSuperiorControles,
    required double progressoLuzViaria,
  }) {
    if (controlador.lod < 1.68 ||
        redeViaria == null ||
        redeViaria.cidadesClassificadas.isEmpty) {
      return const [];
    }

    final rede = redeViaria;
    final limiteInferior = tamanho.height - controlador.alturaGavetaPx - 12.0;
    final limiteSuperior = recuoSuperiorControles + 22.0;
    final nivelMaximoVisivel = controlador.lod >= 3.25
        ? 3
        : (controlador.lod >= 2.35 ? 2 : 1);

    final candidatos = <({
      String id,
      CidadeClassificadaMapa cidade,
      Offset pos,
    })>[];

    for (var i = 0; i < rede.cidadesClassificadas.length; i++) {
      final cidade = rede.cidadesClassificadas[i];
      final loc = cidade.localidade;
      if (loc.nivel > nivelMaximoVisivel) continue;
      if ((loc.latitude - controlador.latitudeCentral).abs() > 2.5 ||
          (loc.longitude - controlador.longitudeCentral).abs() > 2.9) {
        continue;
      }

      final pt = controlador.projetarCoordenada(
        latitude: loc.latitude,
        longitude: loc.longitude,
        elevacaoMetros: 0.0,
        tamanhoTela: tamanho,
      );
      if (!pt.visivel ||
          pt.x < 40 ||
          pt.x > tamanho.width - 40 ||
          pt.y < limiteSuperior ||
          pt.y > limiteInferior) {
        continue;
      }
      candidatos.add((id: 'loc_$i', cidade: cidade, pos: Offset(pt.x, pt.y)));
    }

    if (candidatos.isEmpty) return const [];
    candidatos.sort((a, b) {
      final relA = a.cidade.ehRelevanteAresta ? 0 : 1;
      final relB = b.cidade.ehRelevanteAresta ? 0 : 1;
      if (relA != relB) return relA.compareTo(relB);
      return a.cidade.localidade.nivel.compareTo(b.cidade.localidade.nivel);
    });

    final entradasColisao = <({
      String id,
      String nome,
      Offset posicao,
      bool prioritario,
    })>[];
    for (final p in picos) {
      final ptPico = controlador.projetarCoordenada(
        latitude: p.latitude,
        longitude: p.longitude,
        elevacaoMetros: 0.0,
        tamanhoTela: tamanho,
      );
      if (ptPico.visivel &&
          ptPico.x > 0 &&
          ptPico.x < tamanho.width &&
          ptPico.y > 0 &&
          ptPico.y < tamanho.height) {
        final ehSel = p.id == picoSelecionadoId;
        entradasColisao.add((
          id: 'ancora_pico_${p.id}',
          nome: ehSel ? p.nome : '',
          posicao: Offset(ptPico.x, ehSel ? ptPico.y - 32.0 : ptPico.y),
          prioritario: true,
        ));
      }
    }
    for (final c in candidatos) {
      entradasColisao.add((
        id: c.id,
        nome: c.cidade.localidade.nome,
        posicao: c.pos,
        prioritario: false,
      ));
    }

    final aprovados = ControladorCameraGlobo.selecionarIdsSemColisaoRotulos(
      entradasColisao,
      alturaCaixa: 30.0,
    );

    final opacidade =
        ControladorCameraGlobo.smoothstep(1.68, 2.15, controlador.lod);
    final widgets = <Widget>[];
    for (final c in candidatos) {
      if (!aprovados.contains(c.id)) continue;
      if (widgets.length >= 8) break;
      final loc = c.cidade.localidade;
      final ehPolo = loc.nivel == 1;
      final acesaAresta = c.cidade.ehRelevanteAresta &&
          progressoLuzViaria >= c.cidade.tempoAtivacao;

      widgets.add(
        Positioned(
          left: (c.pos.dx - 70).clamp(6.0, tamanho.width - 146.0),
          top: c.pos.dy - 9,
          width: 140,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacidade,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    key: Key(
                      acesaAresta
                          ? 'cidade_aresta_${loc.nome}'
                          : 'cidade_referencia_${loc.nome}',
                    ),
                    width: acesaAresta ? 6.0 : (ehPolo ? 5.0 : 4.0),
                    height: acesaAresta ? 6.0 : (ehPolo ? 5.0 : 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: acesaAresta
                          ? const Color(0xFFFFE3B8)
                          : const Color(0xFFF8FAFC),
                      border: Border.all(
                        color: acesaAresta
                            ? const Color(0xFFE27D60)
                            : const Color(0xDD0F172A),
                        width: acesaAresta ? 1.4 : 1.0,
                      ),
                      boxShadow: acesaAresta
                          ? const [
                              BoxShadow(
                                color: Color(0xAAFF9248),
                                blurRadius: 5,
                                spreadRadius: 0.6,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 4.5),
                  Flexible(
                    child: Text(
                      loc.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: acesaAresta
                            ? const Color(0xFFFFF7ED)
                            : (ehPolo
                                ? const Color(0xE8F1F5F9)
                                : const Color(0xCC94A3B8)),
                        fontSize: ehPolo ? 10.4 : 9.4,
                        letterSpacing: ehPolo ? 0.25 : 0.1,
                        fontWeight: acesaAresta || ehPolo
                            ? FontWeight.w700
                            : FontWeight.w500,
                        shadows: acesaAresta
                            ? const [
                                Shadow(color: Color(0xEE090D14), blurRadius: 5),
                                Shadow(color: Color(0x66E27D60), blurRadius: 8),
                              ]
                            : const [
                                Shadow(color: Color(0xEE090D14), blurRadius: 5),
                              ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  static List<Offset> _separarPosicoesClusters(
    List<Offset> originais, {
    required double larguraMinima,
    required double alturaMinima,
  }) {
    final resultado = List<Offset>.of(originais);
    for (var iter = 0; iter < 3; iter++) {
      for (var i = 0; i < resultado.length; i++) {
        for (var j = i + 1; j < resultado.length; j++) {
          final dx = resultado[j].dx - resultado[i].dx;
          final dy = resultado[j].dy - resultado[i].dy;
          if (dx.abs() < larguraMinima && dy.abs() < alturaMinima) {
            final empurraoY = (alturaMinima - dy.abs()) * 0.52 + 1.0;
            final sinalY = dy >= 0 ? 1.0 : -1.0;
            resultado[i] = resultado[i].translate(0, -sinalY * empurraoY);
            resultado[j] = resultado[j].translate(0, sinalY * empurraoY);
          }
        }
      }
    }
    return resultado;
  }
}
