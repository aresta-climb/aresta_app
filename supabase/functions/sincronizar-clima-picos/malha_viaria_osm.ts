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

const METROPOLES_CENTROS: [number, number, number][] = [
  [-19.9191, -43.9386, 0.17], // Belo Horizonte
  [-22.9068, -43.1729, 0.20], // Rio de Janeiro
  [-23.5505, -46.6333, 0.25], // São Paulo
  [-20.3155, -40.3128, 0.12], // Vitória
  [-18.9186, -48.2772, 0.10], // Uberlândia
];

function dentroMetropole(lat: number, lon: number, fator = 1.0): boolean {
  return METROPOLES_CENTROS.some(
    ([mlat, mlon, r]) => Math.hypot(lon - mlon, lat - mlat) <= r * fator,
  );
}

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
  return `osm-v3-essencial-${picos.length}-${h.toString(16)}`;
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

async function consultarOverpass(
  query: string,
): Promise<Record<string, unknown>[]> {
  const corpo = new URLSearchParams({ data: query }).toString();
  for (const url of ENDPOINTS_OVERPASS) {
    const resp = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "User-Agent": "ArestaClimbSupabaseSync/2.1",
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

/** Extrai exclusivamente artérias rodoviárias principais nas cidades e acessos pavimentados rurais aos picos. */
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

  const caixasSecundariasRurais = picos
    .filter((p) => !dentroMetropole(p.latitude, p.longitude, 1.15))
    .map(
      (p) =>
        `way["highway"~"^(secondary|tertiary)$"]["surface"!~"^(unpaved|dirt|gravel|ground|sand|earth)$"](${(p.latitude - 0.085).toFixed(4)},${(p.longitude - 0.085).toFixed(4)},${(p.latitude + 0.085).toFixed(4)},${(p.longitude + 0.085).toFixed(4)});`,
    )
    .join("\n");

  const query = `
    [out:json][timeout:75];
    (
      way["highway"~"^(motorway|trunk|primary)$"](${minLat.toFixed(3)},${minLon.toFixed(3)},${maxLat.toFixed(3)},${maxLon.toFixed(3)});
      ${caixasSecundariasRurais}
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
    const nivel: 1 | 2 | 3 =
      hw === "motorway" || hw === "trunk" ? 1 : hw === "primary" ? 2 : 3;
    const codigo = normalizarCodigoRodovia(tags.ref ?? "");
    const bruto: [number, number][] = el.geometry.map(
      (pt: { lon: number; lat: number }) => [Number(pt.lon), Number(pt.lat)],
    );
    const [meioLon, meioLat] = bruto[Math.floor(bruto.length / 2)];
    if (nivel === 3 && dentroMetropole(meioLat, meioLon, 1.05) && !codigo) {
      continue;
    }
    if (nivel === 2 && !codigo) continue;
    if (nivel === 1 && dentroMetropole(meioLat, meioLon, 1.0) && !codigo) {
      const nome = (tags.name ?? "").toLowerCase();
      const arteriasPrincipais = [
        "cristiano machado",
        "antônio carlos",
        "antonio carlos",
        "amazonas",
        "via expressa",
        "anel rodovi",
        "contorno",
      ];
      if (!arteriasPrincipais.some((chave) => nome.includes(chave))) {
        continue;
      }
    }

    const eps = nivel === 1 ? 0.00085 : nivel === 2 ? 0.00070 : 0.00055;
    const simp = simplificarRdp(bruto, eps);
    if (simp.length >= 2) {
      saida.push({
        classe:
          nivel === 1 ? "principal" : nivel === 2 ? "primaria" : "secundaria",
        nivel,
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
