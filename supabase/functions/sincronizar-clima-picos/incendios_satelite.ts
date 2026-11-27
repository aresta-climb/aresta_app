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

