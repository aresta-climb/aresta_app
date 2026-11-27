// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import type {
  ParLonLat,
  PicoCoordenada,
  RegiaoSinotica,
} from "./tipos_clima.ts";

/** Agrupa picos próximos em caixas regionais expandidas para amostragem sinótica eficiente. */
export function agruparRegioesSinoticas(
  picos: PicoCoordenada[],
): RegiaoSinotica[] {
  const visitado = new Uint8Array(picos.length);
  const regioes: RegiaoSinotica[] = [];
  const limiarUniaoGraus = 11.0;
  const margemGraus = 5.2;

  for (let i = 0; i < picos.length; i++) {
    if (visitado[i]) continue;
    visitado[i] = 1;
    const fila = [i];
    let minLat = picos[i].latitude;
    let maxLat = picos[i].latitude;
    let minLon = picos[i].longitude;
    let maxLon = picos[i].longitude;

    while (fila.length > 0) {
      const atual = fila.pop()!;
      const pA = picos[atual];
      if (pA.latitude < minLat) minLat = pA.latitude;
      if (pA.latitude > maxLat) maxLat = pA.latitude;
      if (pA.longitude < minLon) minLon = pA.longitude;
      if (pA.longitude > maxLon) maxLon = pA.longitude;

      for (let j = 0; j < picos.length; j++) {
        if (visitado[j]) continue;
        const dist = Math.hypot(
          picos[j].latitude - pA.latitude,
          picos[j].longitude - pA.longitude,
        );
        if (dist <= limiarUniaoGraus) {
          visitado[j] = 1;
          fila.push(j);
        }
      }
    }

    regioes.push({
      minLat: Math.max(-85, minLat - margemGraus),
      maxLat: Math.min(85, maxLat + margemGraus),
      minLon: Math.max(-179.5, minLon - margemGraus),
      maxLon: Math.min(179.5, maxLon + margemGraus),
    });
  }

  return regioes;
}

/** Extrai anéis poligonais fechados de isolinha por Marching Squares sobre uma grade escalar 2D. */
export function extrairContornosMarchingSquares(
  campo: number[][],
  lats: number[],
  lons: number[],
  limiar: number,
): ParLonLat[][] {
  const R = campo.length;
  const C = campo[0].length;
  const arestasPorOrigem = new Map<
    string,
    Array<{ ini: ParLonLat; fim: ParLonLat; usada: boolean }>
  >();

  const chavePt = (p: ParLonLat): string =>
    `${Math.round(p[0] * 10000)}:${Math.round(p[1] * 10000)}`;

  const interp = (a: number, b: number, va: number, vb: number): number => {
    const dv = vb - va;
    if (Math.abs(dv) < 1e-9) return (a + b) * 0.5;
    const t = Math.max(0, Math.min(1, (limiar - va) / dv));
    return a + (b - a) * t;
  };

  const registrarSegmento = (ini: ParLonLat, fim: ParLonLat): void => {
    const kIni = chavePt(ini);
    if (kIni === chavePt(fim)) return;
    let lista = arestasPorOrigem.get(kIni);
    if (!lista) {
      lista = [];
      arestasPorOrigem.set(kIni, lista);
    }
    lista.push({ ini, fim, usada: false });
  };

