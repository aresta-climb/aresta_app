// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import type { PicoCoordenada } from "./tipos_clima.ts";

export interface RodoviaHierarquicaOsm {
  classe: "principal";
  nivel: 1;
  codigo: string;
  poligono: [number, number][];
}

const ENDPOINTS_OVERPASS = [
  "https://overpass-api.de/api/interpreter",
  "https://lz4.overpass-api.de/api/interpreter",
];

const REGEX_RODOVIA_FEDERAL_BR = /\bBR-\s*(\d{2,3})\b/i;

/** Calcula hash determinístico leve do catálogo de picos para atualização incremental das rodovias BR-xxx. */
export function calcularHashCatalogoViario(picos: PicoCoordenada[]): string {
  const ordenado = [...picos]
    .sort((a, b) => a.id.localeCompare(b.id))
    .map((p) => `${p.id}:${p.latitude.toFixed(3)},${p.longitude.toFixed(3)}`)
    .join("|");
  let h = 2166136261;
  for (let i = 0; i < ordenado.length; i++) {
    h ^= ordenado.charCodeAt(i);
    h = Math.imul(h, 16777619) >>> 0;
  }
  return `osm-br-v5-${picos.length}-${h.toString(16)}`;
}

function extrairCodigoRodoviaBr(tags: Record<string, string>): string {
  const texto = [
    tags.ref ?? "",
    tags.int_ref ?? "",
    tags.nat_ref ?? "",
    tags.official_ref ?? "",
    tags.name ?? "",
  ].join(" ; ");
  const m = REGEX_RODOVIA_FEDERAL_BR.exec(texto);
  if (!m) return "";
  return `BR-${m[1].padStart(3, "0")}`;
}

function simplificarRdp(
  pts: [number, number][],
  eps: number,
): [number, number][] {
  if (pts.length <= 2) return pts;
  const [ax, ay] = pts[0];
  const [bx, by] = pts[pts.length - 1];
  const dx = bx - ax;
  const dy = by - ay;
  const norm2 = dx * dx + dy * dy;
  let maxDist2 = -1;
  let idxMax = 0;

  for (let i = 1; i < pts.length - 1; i++) {
    const [px, py] = pts[i];
    let t = norm2 > 1e-12 ? ((px - ax) * dx + (py - ay) * dy) / norm2 : 0;
    t = Math.max(0, Math.min(1, t));
    const projX = ax + t * dx;
    const projY = ay + t * dy;
    const d2 = (px - projX) ** 2 + (py - projY) ** 2;
    if (d2 > maxDist2) {
      maxDist2 = d2;
      idxMax = i;
    }
  }

  if (maxDist2 > eps * eps) {
    const esq = simplificarRdp(pts.slice(0, idxMax + 1), eps);
    const dir = simplificarRdp(pts.slice(idxMax), eps);
    return [...esq.slice(0, -1), ...dir];
  }
  return [pts[0], pts[pts.length - 1]];
}

async function consultarOverpass(
  query: string,
): Promise<Record<string, unknown>[]> {
  const corpo = new URLSearchParams({ data: query }).toString();
  for (const url of ENDPOINTS_OVERPASS) {
    const resp = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "User-Agent": "ArestaClimbSupabaseSync/2.2",
      },
      body: corpo,
    });
    if (resp.ok) {
      const json = await resp.json();
      return Array.isArray(json?.elements) ? json.elements : [];
    }
  }
  throw new Error("Falha ao consultar endpoints Overpass para rodovias BR.");
}

/** Extrai exclusivamente as rodovias federais principais (`BR-xxx`) na região de escalada. */
export async function coletarMalhaViariaHierarquicaOsm(
  picos: PicoCoordenada[],
): Promise<RodoviaHierarquicaOsm[]> {
  let minLat = -20.5,
    maxLat = -14.85,
    minLon = -44.6,
    maxLon = -43.2;
  for (const p of picos) {
    minLat = Math.min(minLat, p.latitude - 0.6);
    maxLat = Math.max(maxLat, p.latitude + 0.6);
    minLon = Math.min(minLon, p.longitude - 0.6);
    maxLon = Math.max(maxLon, p.longitude + 0.6);
  }

  const caixa = `${minLat.toFixed(3)},${minLon.toFixed(3)},${maxLat.toFixed(3)},${maxLon.toFixed(3)}`;
  const query = `
    [out:json][timeout:60];
    (
      way["highway"~"^(motorway|trunk|primary)$"]["ref"~"BR-"](${caixa});
      way["highway"~"^(motorway|trunk|primary)$"]["nat_ref"~"BR-"](${caixa});
    );
    out geom;
  `;

  const elementos = await consultarOverpass(query);
  const saida: RodoviaHierarquicaOsm[] = [];

  for (const el of elementos) {
    if (
      el.type !== "way" ||
      !Array.isArray(el.geometry) ||
      el.geometry.length < 2
    ) {
      continue;
    }
    const tags = (el.tags ?? {}) as Record<string, string>;
    const hw = tags.highway ?? "";
    if (hw.endsWith("_link")) continue;
    const codigo = extrairCodigoRodoviaBr(tags);
    if (!codigo) continue;

    const bruto: [number, number][] = el.geometry.map(
      (pt: { lon: number; lat: number }) => [Number(pt.lon), Number(pt.lat)],
    );
    const simp = simplificarRdp(bruto, 0.00080);
    if (simp.length >= 2) {
      saida.push({
        classe: "principal",
        nivel: 1,
        codigo,
        poligono: simp.map(([x, y]) => [
          Number(x.toFixed(5)),
          Number(y.toFixed(5)),
        ]),
      });
    }
  }
  return saida;
}
