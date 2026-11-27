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
  type BolhaChuvaJson,
  type BolhaIncendioJson,
  LIMIAR_NUCLEO_EXTREMO_INCENDIO_FRP,
  LIMIAR_NUCLEO_INTENSO_INCENDIO_FRP,
  LIMIAR_PERIMETRO_INCENDIO_FRP,
  type ParLonLat,
  type PicoCoordenada,
  type RegiaoSinotica,
  URL_INPE_FOCOS_DIARIO_BR,
  URL_NASA_FIRMS_AREA_CSV,
  URL_OPEN_METEO_FORECAST,
} from "./tipos_clima.ts";

interface FocoCalorSatelite {
  lat: number;
  lon: number;
  frpMw: number;
  fonte: string;
}

/**
 * Coleta focos termais orbitais (`NASA FIRMS VIIRS 375m` -> `INPE BDQueimadas`),
 * filtra anomalias industriais e zonas chuvosas, agrupa clusters genuínos de incêndio
 * e extrai perímetros suavizados orientados pelo vento de `10m`.
 */
export async function coletarIncendiosFlorestaisContornos(
  picos: PicoCoordenada[],
  chaveNasaFirms: string,
  bolhasChuvaAtivas: BolhaChuvaJson[],
): Promise<BolhaIncendioJson[]> {
  const regioes = agruparRegioesSinoticas(picos);
  let focosBrutos: FocoCalorSatelite[] = [];
  let fontePrimaria = "NASA_FIRMS_VIIRS_375M";

  if (chaveNasaFirms.length > 0) {
    try {
      focosBrutos = await buscarFocosNasaFirmsViirs(regioes, chaveNasaFirms);
    } catch (erroNasa) {
      console.warn(
        `[sincronizar-clima-picos] NASA FIRMS indisponível (${erroNasa}); alternando para INPE BDQueimadas (sensores NASA MODIS/VIIRS).`,
      );
      focosBrutos = [];
    }
  }

  if (focosBrutos.length === 0) {
    fontePrimaria = "INPE_BDQUEIMADAS_NASA_VIIRS_MODIS";
    focosBrutos = await buscarFocosInpeBdQueimadas(regioes);
  }

  const focos = focosBrutos.filter(
    (f) => !pontoSobChuvaAtiva(f.lon, f.lat, bolhasChuvaAtivas),
  );
  if (focos.length === 0) return [];

  const visitados = new Uint8Array(focos.length);
  const clustersValidos: FocoCalorSatelite[][] = [];
  const raioCluster2 = 0.085 * 0.085;

  for (let i = 0; i < focos.length; i++) {
    if (visitados[i]) continue;
    visitados[i] = 1;
    const fila = [focos[i]];
    const grupo: FocoCalorSatelite[] = [];
    let somaFrpGrupo = 0;

    while (fila.length > 0) {
      const atual = fila.pop()!;
      grupo.push(atual);
      somaFrpGrupo += atual.frpMw;
      for (let j = 0; j < focos.length; j++) {
        if (visitados[j]) continue;
        const dLat = focos[j].lat - atual.lat;
        const dLon = focos[j].lon - atual.lon;
        if (dLat * dLat + dLon * dLon <= raioCluster2) {
          visitados[j] = 1;
          fila.push(focos[j]);
        }
      }
    }

    if (grupo.length >= 2 || somaFrpGrupo >= 10.0) {
      clustersValidos.push(grupo);
    }
  }

  if (clustersValidos.length === 0) return [];

  const candidatos: Array<{
    contornoSuave: ParLonLat[];
    nucleosInternos: ParLonLat[][];
    latCentro: number;
    lonCentro: number;
    potenciaTotalMw: number;
    totalFocosInternos: number;
  }> = [];

  const margemGraus = 0.075;
  const passoLocal = 0.02;
  const sigma2 = 0.022 * 0.022;

  for (const grupo of clustersValidos) {
    let minLat = Infinity;
    let maxLat = -Infinity;
    let minLon = Infinity;
    let maxLon = -Infinity;
    for (const f of grupo) {
      if (f.lat < minLat) minLat = f.lat;
      if (f.lat > maxLat) maxLat = f.lat;
      if (f.lon < minLon) minLon = f.lon;
      if (f.lon > maxLon) maxLon = f.lon;
    }
    minLat -= margemGraus;
    maxLat += margemGraus;
    minLon -= margemGraus;
    maxLon += margemGraus;

    const rowsInt = Math.max(
      10,
      Math.min(42, Math.ceil((maxLat - minLat) / passoLocal) + 1),
    );
    const colsInt = Math.max(
      10,
      Math.min(42, Math.ceil((maxLon - minLon) / passoLocal) + 1),
    );
    const pLat = (maxLat - minLat) / (rowsInt - 1);
    const pLon = (maxLon - minLon) / (colsInt - 1);

    const R = rowsInt + 2;
    const C = colsInt + 2;
    const latsGrade: number[] = [];
    const lonsGrade: number[] = [];
    for (let r = 0; r < R; r++) latsGrade.push(minLat + (r - 1) * pLat);
    for (let c = 0; c < C; c++) lonsGrade.push(minLon + (c - 1) * pLon);

    const campoFrp: number[][] = Array.from({ length: R }, () =>
      new Array<number>(C).fill(0),
    );

    for (const foco of grupo) {
      for (let r = 1; r <= rowsInt; r++) {
        const dLat2 = (latsGrade[r] - foco.lat) ** 2;
        if (dLat2 > sigma2 * 6.0) continue;
        for (let c = 1; c <= colsInt; c++) {
          if (pontoSobChuvaAtiva(lonsGrade[c], latsGrade[r], bolhasChuvaAtivas)) {
            continue;
          }
          const dLon2 = (lonsGrade[c] - foco.lon) ** 2;
          const expo = (dLat2 + dLon2) / (2 * sigma2);
          if (expo > 4.5) continue;
          campoFrp[r][c] += foco.frpMw * Math.exp(-expo);
        }
      }
    }

    const contornosExternos = extrairContornosMarchingSquares(
      campoFrp,
      latsGrade,
      lonsGrade,
      LIMIAR_PERIMETRO_INCENDIO_FRP,
    );
    const contornosNucleos = [
      ...extrairContornosMarchingSquares(
        campoFrp,
        latsGrade,
        lonsGrade,
        LIMIAR_NUCLEO_INTENSO_INCENDIO_FRP,
      ),
      ...extrairContornosMarchingSquares(
        campoFrp,
        latsGrade,
        lonsGrade,
        LIMIAR_NUCLEO_EXTREMO_INCENDIO_FRP,
      ),
    ];

