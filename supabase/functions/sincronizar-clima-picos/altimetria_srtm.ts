// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import {
  type CotaAltimetricaDem,
  DIMENSAO_GRADE_DEM,
  type PicoCoordenada,
  RAIO_GRADE_DEM_GRAUS,
  URL_BASE_TERRARIUM,
  ZOOM_TERRARIUM,
} from "./tipos_clima.ts";

/**
 * Amostra a altimetria real de `30m` (`NASA SRTM` via AWS Open Data Terrarium `z=12`)
 * para os picos informados, extraindo base, cume e malha DEM `13x13`.
 */
export async function extrairCotasSrtm30m(
  picos: PicoCoordenada[],
): Promise<Record<string, CotaAltimetricaDem>> {
  const cacheTiles = new Map<string, Float64Array>();

  async function amostrarElevacao(lat: number, lon: number): Promise<number> {
    const escalaMundo = 256 * (1 << ZOOM_TERRARIUM);
    const pxGlobal = ((lon + 180) / 360) * escalaMundo;
    const latRad = (lat * Math.PI) / 180;
    const pyGlobal =
      ((1 - Math.log(Math.tan(latRad) + 1 / Math.cos(latRad)) / Math.PI) *
        0.5) *
      escalaMundo;

    const maxTile = (1 << ZOOM_TERRARIUM) - 1;
    const tx = Math.max(0, Math.min(maxTile, Math.floor(pxGlobal / 256)));
    const ty = Math.max(0, Math.min(maxTile, Math.floor(pyGlobal / 256)));
    const chave = `${ZOOM_TERRARIUM}/${tx}/${ty}`;

    let gradeTile = cacheTiles.get(chave);
    if (!gradeTile) {
      const resp = await fetch(`${URL_BASE_TERRARIUM}/${chave}.png`);
      if (!resp.ok) {
        throw new Error(`Falha HTTP ${resp.status} no tile SRTM ${chave}`);
      }
      const pngBytes = new Uint8Array(await resp.arrayBuffer());
      gradeTile = await decodificarPngTerrarium256(pngBytes);
      cacheTiles.set(chave, gradeTile);
    }

    const lx = Math.max(0, Math.min(255, pxGlobal - tx * 256));
    const ly = Math.max(0, Math.min(255, pyGlobal - ty * 256));
    const x0 = Math.floor(lx);
    const y0 = Math.floor(ly);
    const x1 = Math.min(255, x0 + 1);
    const y1 = Math.min(255, y0 + 1);
    const fx = lx - x0;
    const fy = ly - y0;

    const e00 = gradeTile[y0 * 256 + x0];
    const e10 = gradeTile[y0 * 256 + x1];
    const e01 = gradeTile[y1 * 256 + x0];
    const e11 = gradeTile[y1 * 256 + x1];
    const topo = e00 + (e10 - e00) * fx;
    const base = e01 + (e11 - e01) * fx;
    return topo + (base - topo) * fy;
  }

  const resultado: Record<string, CotaAltimetricaDem> = {};
  for (const p of picos) {
    const grade: number[] = [];
    for (let j = 0; j < DIMENSAO_GRADE_DEM; j++) {
      const v = -1 + (2 * j) / (DIMENSAO_GRADE_DEM - 1);
      const lat = p.latitude + v * RAIO_GRADE_DEM_GRAUS;
      for (let i = 0; i < DIMENSAO_GRADE_DEM; i++) {
        const u = -1 + (2 * i) / (DIMENSAO_GRADE_DEM - 1);
        const lon = p.longitude + u * RAIO_GRADE_DEM_GRAUS;
        grade.push(Math.round(await amostrarElevacao(lat, lon)));
      }
    }

    let minBase = 99999;
    let maxMacico = -99999;
    for (let sj = -8; sj <= 8; sj++) {
      const dLat = sj * 0.0014;
      for (let si = -8; si <= 8; si++) {
        const dLon = si * 0.0014;
        const dist = Math.hypot(dLat, dLon);
        if (dist > 0.0115) continue;
        const v = Math.round(
          await amostrarElevacao(p.latitude + dLat, p.longitude + dLon),
        );
        if (v < minBase) minBase = v;
        if (dist <= 0.0055 && v > maxMacico) maxMacico = v;
      }
    }

