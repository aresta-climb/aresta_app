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

  if (cacheCompartilhado.size === 0) return null;
  return { zoom: z, tilesMmHora: cacheCompartilhado };
}

/**
 * Amostra a intensidade representativa de chuva (`mm/h`) dentro de uma célula geográfica,
 * preservando pequenos bolsões convectivos locais (`5–25 km`) via max-pooling ponderado `3x3`.
 */
export function amostrarCelulaRadarMmHora(
  mosaico: MosaicoRadarRegiao,
  latCentro: number,
  lonCentro: number,
  meioPassoLat: number,
  meioPassoLon: number,
): number {
  let pico = 0;
  let somaAtivos = 0;
  let qtdAtivos = 0;

  for (let sy = -1; sy <= 1; sy++) {
    const lat = Math.max(-85, Math.min(85, latCentro + sy * meioPassoLat * 0.68));
    for (let sx = -1; sx <= 1; sx++) {
      const lon = lonCentro + sx * meioPassoLon * 0.68;
      const val = lerPixelRadarMmHora(mosaico, lat, lon);
      if (val > pico) pico = val;
      if (val >= 0.12) {
        somaAtivos += val;
        qtdAtivos++;
      }
    }
  }

  if (qtdAtivos === 0) return 0;
  const mediaAtivos = somaAtivos / qtdAtivos;
  return pico * 0.65 + mediaAtivos * 0.35;
}

function lerPixelRadarMmHora(
  mosaico: MosaicoRadarRegiao,
  lat: number,
  lon: number,
): number {
  const escalaMundo = 256 * (1 << mosaico.zoom);
  const pxGlobal = ((lon + 180) / 360) * escalaMundo;
  const latRad = (lat * Math.PI) / 180;
  const pyGlobal =
    ((1 - Math.log(Math.tan(latRad) + 1 / Math.cos(latRad)) / Math.PI) * 0.5) *
    escalaMundo;

  const maxTile = (1 << mosaico.zoom) - 1;
  const tx = Math.max(0, Math.min(maxTile, Math.floor(pxGlobal / 256)));
  const ty = Math.max(0, Math.min(maxTile, Math.floor(pyGlobal / 256)));
  const tile = mosaico.tilesMmHora.get(`${mosaico.zoom}/${tx}/${ty}`);
  if (!tile) return 0;

  const lx = Math.max(0, Math.min(255, Math.floor(pxGlobal - tx * 256)));
  const ly = Math.max(0, Math.min(255, Math.floor(pyGlobal - ty * 256)));
  return tile[ly * 256 + lx];
}

function lonParaTileX(lon: number, zoom: number): number {
  return Math.floor(((lon + 180) / 360) * (1 << zoom));
}

function latParaTileY(lat: number, zoom: number): number {
  const rad = (Math.max(-85, Math.min(85, lat)) * Math.PI) / 180;
  return Math.floor(
    ((1 - Math.log(Math.tan(rad) + 1 / Math.cos(rad)) / Math.PI) * 0.5) *
      (1 << zoom),
  );
}

/**
 * Decodifica PNG `256x256` (RGBA `6`, RGB `2` ou paleta indexada `3` com `PLTE`/`tRNS`)
 * convertendo a escala cromática Universal Blue (`color=2`) em `mm/h`.
 */
export async function decodificarPngRadarParaMmHora(
  bytesPng: Uint8Array,
): Promise<Float32Array> {
  const resultadoVazio = new Float32Array(256 * 256);
  if (
    bytesPng.length < 33 ||
    bytesPng[0] !== 0x89 ||
    bytesPng[1] !== 0x50 ||
    bytesPng[2] !== 0x4e ||
    bytesPng[3] !== 0x47
  ) {
    return resultadoVazio;
  }

  const view = new DataView(
    bytesPng.buffer,
    bytesPng.byteOffset,
    bytesPng.byteLength,
  );
  let offset = 8;
  let largura = 0;
  let altura = 0;
  let bits = 8;
  let tipoCor = 6;
  let paletaRgb: Uint8Array | null = null;
  let paletaAlfa: Uint8Array | null = null;
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
      bits = bytesPng[dadosIni + 8];
      tipoCor = bytesPng[dadosIni + 9];
    } else if (tipo === "PLTE") {
      paletaRgb = bytesPng.subarray(dadosIni, dadosIni + tam);
    } else if (tipo === "tRNS") {
      paletaAlfa = bytesPng.subarray(dadosIni, dadosIni + tam);
    } else if (tipo === "IDAT") {
      const fatia = bytesPng.subarray(dadosIni, dadosIni + tam);
      pedacosIdat.push(fatia);
      totalIdat += fatia.length;
    } else if (tipo === "IEND") {
      break;
    }
    offset = dadosIni + tam + 4;
  }

  if (largura !== 256 || altura !== 256 || totalIdat === 0) {
    return resultadoVazio;
  }

  const idatUnido = new Uint8Array(totalIdat);
  let cursor = 0;
  for (const p of pedacosIdat) {
    idatUnido.set(p, cursor);
    cursor += p.length;
  }

  const descomprimido = new Uint8Array(
    await new Response(
      new Blob([idatUnido])
        .stream()
        .pipeThrough(new DecompressionStream("deflate")),
    ).arrayBuffer(),
  );

  const canaisPorPixel =
    tipoCor === 6 ? 4 : tipoCor === 2 ? 3 : tipoCor === 4 ? 2 : 1;
  const bitsPorPixel = canaisPorPixel * bits;
  const bppFiltro = Math.max(1, Math.ceil(bitsPorPixel / 8));
  const stride = Math.ceil((largura * bitsPorPixel) / 8);
  const linhaAtual = new Uint8Array(stride);
  const linhaAnterior = new Uint8Array(stride);
  const gradeMm = new Float32Array(largura * altura);

  const paeth = (a: number, b: number, c: number): number => {
    const p = a + b - c;
    const pa = Math.abs(p - a);
    const pb = Math.abs(p - b);
    const pc = Math.abs(p - c);
    if (pa <= pb && pa <= pc) return a;
    if (pb <= pc) return b;
    return c;
  };

