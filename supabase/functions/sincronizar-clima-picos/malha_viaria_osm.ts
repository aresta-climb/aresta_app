// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import type { PicoCoordenada } from "./tipos_clima.ts";

export interface RodoviaHierarquicaOsm {
  classe: "principal" | "primaria" | "secundaria";
  nivel: 1 | 2 | 3;
  codigo: string;
  poligono: [number, number][];
}

const ENDPOINTS_OVERPASS = [
  "https://overpass-api.de/api/interpreter",
  "https://lz4.overpass-api.de/api/interpreter",
];

/** Calcula hash determinístico leve do catálogo de picos para atualização incremental da malha viária. */
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
  return `osm-h-${picos.length}-${h.toString(16)}`;
}

function normalizarCodigoRodovia(bruto: string): string {
  if (!bruto) return "";
  const parte = bruto.split(";")[0].trim().toUpperCase().replace(/\s+/g, "-");
  return /^[A-Z]{2,3}-\d{2,3}$/.test(parte) ? parte : "";
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

async function consultarOverpass(query: string): Promise<Record<string, unknown>[]> {
  const corpo = new URLSearchParams({ data: query }).toString();
  for (const url of ENDPOINTS_OVERPASS) {
    const resp = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "User-Agent": "ArestaClimbSupabaseSync/2.0",
      },
      body: corpo,
    });
    if (resp.ok) {
      const json = await resp.json();
      return Array.isArray(json?.elements) ? json.elements : [];
    }
  }
  throw new Error("Falha ao consultar endpoints Overpass para malha viária.");
}

