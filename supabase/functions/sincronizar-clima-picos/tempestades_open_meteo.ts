// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import {
  agruparRegioesSinoticas,
  arredondar,
  calcularAreaAssinada,
  calcularCentroideAnel,
  extrairContornosMarchingSquares,
  pontoEmPoligono,
  simplificarAnelUniforme,
  suavizarChaikin,
} from "./geometria_contornos.ts";
import {
  amostrarCelulaRadarMmHora,
  carregarMetadadosRadarRainViewer,
  carregarMosaicoRadarRegiao,
} from "./radar_chuva_rainviewer.ts";
import {
  type BolhaChuvaJson,
  type EventoChuvaJson,
  LIMIAR_FRENTE_AO_VIVO_MM_H,
  LIMIAR_NUCLEO_EXTREMO_MM_H,
  LIMIAR_NUCLEO_FORTE_MM_H,
  type ParLonLat,
  type PicoCoordenada,
  URL_OPEN_METEO_FORECAST,
} from "./tipos_clima.ts";

interface AmostraGradeClima {
  mmHora: number;
  ventoWx: number;
  ventoWy: number;
}

/**
 * Consulta o histórico horário observado dos últimos 5 dias até o instante civil local atual
 * (`timezone=auto`) de cada pico, evitando virada prematura de data em UTC e descartando horas futuras.
 */
export async function coletarHistoricoChuvaPicosOpenMeteo(
  picos: PicoCoordenada[],
): Promise<Record<string, EventoChuvaJson[]>> {
  const tamanhoLote = 40;
  const chuvaPorPico: Record<string, EventoChuvaJson[]> = {};

  for (let ini = 0; ini < picos.length; ini += tamanhoLote) {
    const lote = picos.slice(ini, ini + tamanhoLote);
    const lats = lote.map((p) => p.latitude.toFixed(5)).join(",");
    const lons = lote.map((p) => p.longitude.toFixed(5)).join(",");
    const url = `${URL_OPEN_METEO_FORECAST}?latitude=${lats}&longitude=${lons}&hourly=precipitation&current=precipitation&past_days=5&forecast_days=1&timezone=auto`;

    const resp = await fetch(url, {
      headers: { "User-Agent": "ArestaSupabaseClimaSync/2.1" },
    });
    if (!resp.ok) {
      throw new Error(`Open-Meteo (histórico) retornou HTTP ${resp.status}`);
    }
    const json = await resp.json();
    const entradas = Array.isArray(json) ? json : [json];
    if (entradas.length !== lote.length) {
      throw new Error(
        `Contagem Open-Meteo inesperada (${entradas.length} != ${lote.length}).`,
      );
    }

    for (let k = 0; k < lote.length; k++) {
      const entrada = entradas[k];
      const horaAtualLocal = String(entrada?.current?.time ?? "");
      const horas: string[] = entrada?.hourly?.time ?? [];
      const precipitacoes: Array<number | null> =
        entrada?.hourly?.precipitation ?? [];

      const acumuladoPorDiaLocal = new Map<string, number>();
      for (let h = 0; h < horas.length; h++) {
        const carimboHora = horas[h];
        if (!carimboHora || carimboHora.length < 10) continue;
        // Soma estritamente horas já transcorridas no fuso civil local do pico (nunca previsão futura)
        if (horaAtualLocal.length >= 13 && carimboHora > horaAtualLocal) {
          continue;
        }
        const mm = Number(precipitacoes[h] ?? 0);
        if (!Number.isFinite(mm) || mm <= 0) continue;
        const diaLocal = carimboHora.slice(0, 10);
        acumuladoPorDiaLocal.set(
          diaLocal,
          (acumuladoPorDiaLocal.get(diaLocal) ?? 0) + mm,
        );
      }

      const eventosValidos: EventoChuvaJson[] = [];
      for (const [dataLocal, somaMm] of acumuladoPorDiaLocal.entries()) {
        if (somaMm >= 1.0) {
          eventosValidos.push({
            data: dataLocal,
            mm: Math.round(somaMm * 10) / 10,
          });
        }
      }

      if (eventosValidos.length > 0) {
        chuvaPorPico[lote[k].id] = eventosValidos;
      }
    }
  }

  return chuvaPorPico;
}

/**
 * Funde o composto global de radar em tempo real (`RainViewer z=6`, `~2,2 km/px`) com o campo
 * mesoescala de vento e precipitação do `Open-Meteo` sobre uma malha fina (`~0,14° ≈ 15 km`),
 * preservando tanto grandes frentes multi-celulares quanto pequenos bolsões de chuva nos estados.
 */
export async function coletarTempestadesAoVivoContornosOpenMeteo(
  picos: PicoCoordenada[],
): Promise<BolhaChuvaJson[]> {
  const regioes = agruparRegioesSinoticas(picos);
  const metadadosRadar = await carregarMetadadosRadarRainViewer();
  const cacheTilesRadar = new Map<string, Float32Array>();
  const candidatosGlobais: Array<{
    bolha: Omit<BolhaChuvaJson, "id">;
    relevancia: number;
  }> = [];

  for (const regiao of regioes) {
    const spanLat = regiao.maxLat - regiao.minLat;
    const spanLon = regiao.maxLon - regiao.minLon;

    // 1. Malha mesoescala Open-Meteo (até 22x22 = 484 pontos em lotes paralelos) para vento real 10m + chuva NWP
    const rowsMeteo = Math.max(10, Math.min(22, Math.round(spanLat / 0.55) + 1));
    const colsMeteo = Math.max(10, Math.min(22, Math.round(spanLon / 0.55) + 1));
    const passoLatMeteo = spanLat / (rowsMeteo - 1);
    const passoLonMeteo = spanLon / (colsMeteo - 1);

    const pontosMeteo: Array<{
      r: number;
      c: number;
      lat: number;
      lon: number;
    }> = [];
    for (let r = 0; r < rowsMeteo; r++) {
      const lat = regiao.minLat + r * passoLatMeteo;
      for (let c = 0; c < colsMeteo; c++) {
        pontosMeteo.push({
          r,
          c,
          lat,
          lon: regiao.minLon + c * passoLonMeteo,
        });
      }
    }

    const gradeMeteo: AmostraGradeClima[][] = Array.from(
      { length: rowsMeteo },
      () =>
        Array.from({ length: colsMeteo }, () => ({
          mmHora: 0,
          ventoWx: 0,
          ventoWy: 0,
        })),
    );

    const tamanhoLote = 90;
    const lotesMeteo: Array<typeof pontosMeteo> = [];
    for (let ini = 0; ini < pontosMeteo.length; ini += tamanhoLote) {
      lotesMeteo.push(pontosMeteo.slice(ini, ini + tamanhoLote));
    }

    const mosaicoRadarPromessa = metadadosRadar
      ? carregarMosaicoRadarRegiao(metadadosRadar, regiao, cacheTilesRadar)
      : Promise.resolve(null);

    const [, mosaicoRadar] = await Promise.all([
      executarEmConcorrenciaLimitada(lotesMeteo, 3, async (lote) => {
        const latsStr = lote.map((p) => p.lat.toFixed(3)).join(",");
        const lonsStr = lote.map((p) => p.lon.toFixed(3)).join(",");
        const url = `${URL_OPEN_METEO_FORECAST}?latitude=${latsStr}&longitude=${lonsStr}&current=precipitation,rain,showers,wind_speed_10m,wind_direction_10m&timezone=UTC`;

        const resp = await fetch(url, {
          headers: { "User-Agent": "ArestaSupabaseClimaSync/2.1" },
        });
        if (!resp.ok) {
          throw new Error(
            `Open-Meteo (malha ao vivo) retornou HTTP ${resp.status}`,
          );
        }
        const json = await resp.json();
        const entradas = Array.isArray(json) ? json : [json];
        if (entradas.length !== lote.length) {
          throw new Error(
            `Contagem da malha Open-Meteo inesperada (${entradas.length} != ${lote.length}).`,
          );
        }

        for (let k = 0; k < lote.length; k++) {
          const cur = entradas[k]?.current ?? {};
          const precip = Number(cur.precipitation ?? 0);
          const chuva = Number(cur.rain ?? 0) + Number(cur.showers ?? 0);
          const taxaMmH = Math.max(
            0,
            Number.isFinite(precip) ? precip : 0,
            Number.isFinite(chuva) ? chuva : 0,
          );
          const velKmh = Math.max(0, Number(cur.wind_speed_10m ?? 12));
          const dirDe = Number(cur.wind_direction_10m ?? 225);
          const rumoParaRad = (((dirDe + 180) % 360) * Math.PI) / 180;

          const pt = lote[k];
          gradeMeteo[pt.r][pt.c] = {
            mmHora: taxaMmH,
            ventoWx: Math.sin(rumoParaRad) * velKmh,
            ventoWy: Math.cos(rumoParaRad) * velKmh,
          };
        }
      }),
      mosaicoRadarPromessa,
    ]);

    // 2. Malha fina (~0,14° ≈ 15 km) para capturar todos os bolsões locais e recortes reais da frente
    const rowsInt = Math.max(24, Math.min(88, Math.round(spanLat / 0.14) + 1));
    const colsInt = Math.max(24, Math.min(88, Math.round(spanLon / 0.14) + 1));
    const passoLat = spanLat / (rowsInt - 1);
    const passoLon = spanLon / (colsInt - 1);

    const R = rowsInt + 2;
    const C = colsInt + 2;
    const latsGrade: number[] = [];
    const lonsGrade: number[] = [];
    for (let r = 0; r < R; r++) latsGrade.push(regiao.minLat + (r - 1) * passoLat);
    for (let c = 0; c < C; c++) lonsGrade.push(regiao.minLon + (c - 1) * passoLon);

    const campoFino: AmostraGradeClima[][] = Array.from({ length: R }, () =>
      Array.from({ length: C }, () => ({ mmHora: 0, ventoWx: 0, ventoWy: 0 })),
    );

    for (let r = 1; r <= rowsInt; r++) {
      const lat = latsGrade[r];
      for (let c = 1; c <= colsInt; c++) {
        const lon = lonsGrade[c];
        const interp = interpolarGradeMeteo(
          gradeMeteo,
          regiao.minLat,
          regiao.minLon,
          passoLatMeteo,
          passoLonMeteo,
          lat,
          lon,
        );
        const radarMmH = mosaicoRadar
          ? amostrarCelulaRadarMmHora(
              mosaicoRadar,
              lat,
              lon,
              passoLat * 0.5,
              passoLon * 0.5,
            )
          : 0;
        const mmCombinado = mosaicoRadar
          ? Math.max(radarMmH, interp.mmHora * 0.82)
          : interp.mmHora;
        campoFino[r][c] = {
          mmHora: mmCombinado,
          ventoWx: interp.ventoWx,
          ventoWy: interp.ventoWy,
        };
      }
    }

