// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import {
  type RegiaoSinotica,
  URL_RAINVIEWER_MAPAS,
  ZOOM_RADAR_RAINVIEWER,
} from "./tipos_clima.ts";

/** Metadados do mosaico global de radar meteorológico em tempo real (`RainViewer`). */
export interface MetadadosRadarAoVivo {
  host: string;
  caminhoQuadroAtual: string;
}

/** Mosaico regional decodificado de refletividade de precipitação (`mm/h`) em tiles `256x256`. */
export interface MosaicoRadarRegiao {
  zoom: number;
  tilesMmHora: Map<string, Float32Array>;
}

/**
 * Consulta o catálogo público `weather-maps.json` do RainViewer para obter o quadro mais recente
 * do composto global de radares meteorológicos + satélite infravermelho (atualizado a cada 10 min).
 */
export async function carregarMetadadosRadarRainViewer(): Promise<
  MetadadosRadarAoVivo | null
> {
  try {
    const resp = await fetch(URL_RAINVIEWER_MAPAS, {
      headers: { "User-Agent": "ArestaSupabaseClimaSync/2.1" },
    });
    if (!resp.ok) return null;
    const json = await resp.json();
    const host = String(json?.host ?? "").replace(/\/+$/, "");
    const quadrosPassados = Array.isArray(json?.radar?.past)
      ? json.radar.past
      : [];
    if (!host || quadrosPassados.length === 0) return null;
    const ultimo = quadrosPassados[quadrosPassados.length - 1];
    const caminho = String(ultimo?.path ?? "");
    if (!caminho) return null;
    return { host, caminhoQuadroAtual: caminho };
  } catch (erro) {
    console.warn(
      `[sincronizar-clima-picos] Catálogo RainViewer indisponível (${erro}); prosseguindo com malha mesoescala Open-Meteo.`,
    );
    return null;
  }
}

/** Baixa e decodifica em paralelo os tiles PNG `z=6` (`~2,2 km/px`) que cobrem `regiao`. */
export async function carregarMosaicoRadarRegiao(
  meta: MetadadosRadarAoVivo,
  regiao: RegiaoSinotica,
  cacheCompartilhado: Map<string, Float32Array>,
): Promise<MosaicoRadarRegiao | null> {
  const z = ZOOM_RADAR_RAINVIEWER;
  const maxTile = (1 << z) - 1;
  const txMin = Math.max(0, Math.min(maxTile, lonParaTileX(regiao.minLon, z)));
  const txMax = Math.max(0, Math.min(maxTile, lonParaTileX(regiao.maxLon, z)));
  const tyMin = Math.max(0, Math.min(maxTile, latParaTileY(regiao.maxLat, z)));
  const tyMax = Math.max(0, Math.min(maxTile, latParaTileY(regiao.minLat, z)));

  const chavesPendentes: Array<{ chave: string; tx: number; ty: number }> = [];
  for (let ty = tyMin; ty <= tyMax; ty++) {
    for (let tx = txMin; tx <= txMax; tx++) {
      const chave = `${z}/${tx}/${ty}`;
      if (!cacheCompartilhado.has(chave)) {
        chavesPendentes.push({ chave, tx, ty });
      }
    }
  }

  await Promise.all(
    chavesPendentes.map(async ({ chave, tx, ty }) => {
      try {
        const url = `${meta.host}${meta.caminhoQuadroAtual}/256/${z}/${tx}/${ty}/2/1_0.png`;
        const resp = await fetch(url, {
          headers: { "User-Agent": "ArestaSupabaseClimaSync/2.1" },
        });
        if (!resp.ok) return;
        const bytes = new Uint8Array(await resp.arrayBuffer());
        const gradeMm = await decodificarPngRadarParaMmHora(bytes);
        cacheCompartilhado.set(chave, gradeMm);
      } catch (_) {
        // Falha pontual em um tile isolado não interrompe o mosaico regional
      }
    }),
  );

