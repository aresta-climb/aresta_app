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

    const cotaPino = Math.round(await amostrarElevacao(p.latitude, p.longitude));
    if (cotaPino > maxMacico) maxMacico = cotaPino;
    if (cotaPino < minBase) minBase = cotaPino;

    resultado[p.id] = {
      altitude_ponto_m: cotaPino,
      altitude_base_m: minBase,
      altitude_pico_m: Math.max(minBase, maxMacico),
      dimensao_grade: DIMENSAO_GRADE_DEM,
      raio_grade_graus: RAIO_GRADE_DEM_GRAUS,
      grade_dem_m: grade,
    };
  }

  return resultado;
}

/** Decodifica um tile PNG Terrarium `256x256` nativo via `DecompressionStream("deflate")` em cotas métricas. */
export async function decodificarPngTerrarium256(
  bytesPng: Uint8Array,
): Promise<Float64Array> {
  if (
    bytesPng.length < 33 ||
    bytesPng[0] !== 0x89 ||
    bytesPng[1] !== 0x50 ||
    bytesPng[2] !== 0x4e ||
    bytesPng[3] !== 0x47
  ) {
    throw new Error("Assinatura PNG inválida em tile Terrarium.");
  }

  const view = new DataView(
    bytesPng.buffer,
    bytesPng.byteOffset,
    bytesPng.byteLength,
  );
  let offset = 8;
  let largura = 0;
  let altura = 0;
  let tipoCor = 0;
  const pedacosIdat: Uint8Array[] = [];
  let totalIdat = 0;

  while (offset + 8 <= bytesPng.length) {
    const tam = view.getUint32(offset, false);
    const tipo = String.fromCharCode(
      bytesPng[offset + 4],
      bytesPng[offset + 5],
      bytesPng[offset + 6],
      bytesPng[offset + 7],
    );
    const dadosIni = offset + 8;
    if (dadosIni + tam + 4 > bytesPng.length) break;

    if (tipo === "IHDR") {
      largura = view.getUint32(dadosIni, false);
      altura = view.getUint32(dadosIni + 4, false);
      const bits = bytesPng[dadosIni + 8];
      tipoCor = bytesPng[dadosIni + 9];
      if (bits !== 8 || (tipoCor !== 2 && tipoCor !== 6)) {
        throw new Error(
          `PNG Terrarium não suportado (bits=${bits}, cor=${tipoCor})`,
        );
      }
    } else if (tipo === "IDAT") {
      const fatia = bytesPng.subarray(dadosIni, dadosIni + tam);
      pedacosIdat.push(fatia);
      totalIdat += fatia.length;
    } else if (tipo === "IEND") {
      break;
    }
    offset = dadosIni + tam + 4;
  }

  if (largura !== 256 || altura !== 256) {
    throw new Error(`Dimensão inesperada de tile (${largura}x${altura})`);
  }

  const idatUnido = new Uint8Array(totalIdat);
  let cursorIdat = 0;
  for (const p of pedacosIdat) {
    idatUnido.set(p, cursorIdat);
    cursorIdat += p.length;
  }

  const streamDescompressao = new Blob([idatUnido])
    .stream()
    .pipeThrough(new DecompressionStream("deflate"));
  const descomprimido = new Uint8Array(
    await new Response(streamDescompressao).arrayBuffer(),
  );

  const bpp = tipoCor === 6 ? 4 : 3;
  const stride = largura * bpp;
  const linhaAtual = new Uint8Array(stride);
  const linhaAnterior = new Uint8Array(stride);
  const elevacoes = new Float64Array(largura * altura);

  const paeth = (a: number, b: number, c: number): number => {
    const p = a + b - c;
    const pa = Math.abs(p - a);
    const pb = Math.abs(p - b);
    const pc = Math.abs(p - c);
    if (pa <= pb && pa <= pc) return a;
    if (pb <= pc) return b;
    return c;
  };

  let src = 0;
  for (let y = 0; y < altura; y++) {
    const filtro = descomprimido[src++];
    for (let i = 0; i < stride; i++) {
      const bruto = descomprimido[src++];
      const esq = i >= bpp ? linhaAtual[i - bpp] : 0;
      const cima = linhaAnterior[i];
      const diag = i >= bpp ? linhaAnterior[i - bpp] : 0;
      let rec = bruto;
      if (filtro === 1) rec = (bruto + esq) & 0xff;
      else if (filtro === 2) rec = (bruto + cima) & 0xff;
      else if (filtro === 3) rec = (bruto + ((esq + cima) >> 1)) & 0xff;
      else if (filtro === 4) rec = (bruto + paeth(esq, cima, diag)) & 0xff;
      linhaAtual[i] = rec;
    }
    for (let x = 0; x < largura; x++) {
      const idx = x * bpp;
      elevacoes[y * largura + x] =
        linhaAtual[idx] * 256 +
        linhaAtual[idx + 1] +
        linhaAtual[idx + 2] / 256 -
        32768;
    }
    linhaAnterior.set(linhaAtual);
  }

  return elevacoes;
}
