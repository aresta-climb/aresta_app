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

