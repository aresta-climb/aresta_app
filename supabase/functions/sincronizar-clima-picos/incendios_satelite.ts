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

    for (const anelBruto of contornosExternos) {
      if (Math.abs(calcularAreaAssinada(anelBruto)) <= 0.00018) continue;
      const contornoSuave = simplificarAnelUniforme(
        suavizarChaikin(anelBruto, 2),
        36,
      );
      if (contornoSuave.length < 3) continue;

      let somaFrp = 0;
      let somaLat = 0;
      let somaLon = 0;
      let contagemFocos = 0;
      for (const f of grupo) {
        if (pontoEmPoligono(f.lon, f.lat, contornoSuave)) {
          contagemFocos++;
          somaFrp += f.frpMw;
          somaLat += f.lat * f.frpMw;
          somaLon += f.lon * f.frpMw;
        }
      }
      if (contagemFocos === 0 || somaFrp <= 0) continue;

      const latCentro = arredondar(somaLat / somaFrp, 4);
      const lonCentro = arredondar(somaLon / somaFrp, 4);
      if (pontoSobChuvaAtiva(lonCentro, latCentro, bolhasChuvaAtivas)) continue;

      const nucleosInternos: ParLonLat[][] = [];
      for (const nucBruto of contornosNucleos) {
        if (Math.abs(calcularAreaAssinada(nucBruto)) <= 0.00008) continue;
        const cNuc = calcularCentroideAnel(nucBruto);
        if (!pontoEmPoligono(cNuc[0], cNuc[1], contornoSuave)) continue;
        const nucSuave = simplificarAnelUniforme(
          suavizarChaikin(nucBruto, 2),
          24,
        );
        if (nucSuave.length >= 3) nucleosInternos.push(nucSuave);
      }

      candidatos.push({
        contornoSuave,
        nucleosInternos,
        latCentro,
        lonCentro,
        potenciaTotalMw: arredondar(somaFrp, 1),
        totalFocosInternos: contagemFocos,
      });
    }
  }

  if (candidatos.length === 0) return [];

  const condicoesAtuais =
    await consultarCondicoesAtuaisCentroidesIncendioOpenMeteo(
      candidatos.map((c) => ({ lat: c.latCentro, lon: c.lonCentro })),
    );

  const todasBolhasFogo: BolhaIncendioJson[] = [];
  let contadorFogo = 1;
  for (let idx = 0; idx < candidatos.length; idx++) {
    const cand = candidatos[idx];
    const cond = condicoesAtuais[idx] ?? {
      rumoGraus: 270,
      velKmh: 14,
      precipMmH: 0,
    };
    if (cond.precipMmH >= 0.15) continue;

    const bolhaFogo: BolhaIncendioJson = {
      id: `incendio_${contadorFogo++}`,
      lat: cand.latCentro,
      lon: cand.lonCentro,
      potencia_frp_mw: cand.potenciaTotalMw,
      total_focos: cand.totalFocosInternos,
      vento_rumo_graus: arredondar(cond.rumoGraus, 1),
      vento_kmh: arredondar(Math.max(5, cond.velKmh), 1),
      fonte_satelite: fontePrimaria,
      contorno_externo: cand.contornoSuave,
    };
    if (cand.nucleosInternos.length > 0) {
      bolhaFogo.nucleos_intensos = cand.nucleosInternos;
    }
    todasBolhasFogo.push(bolhaFogo);
  }

  return todasBolhasFogo;
}

function pontoSobChuvaAtiva(
  lon: number,
  lat: number,
  bolhasChuva: BolhaChuvaJson[],
): boolean {
  for (const b of bolhasChuva) {
    if (pontoEmPoligono(lon, lat, b.contorno_externo)) return true;
    for (const v of b.contorno_externo) {
      const dx = lon - v[0];
      const dy = lat - v[1];
      if (dx * dx + dy * dy <= 0.042 * 0.042) return true;
    }
  }
  return false;
}

async function buscarFocosNasaFirmsViirs(
  regioes: RegiaoSinotica[],
  chaveNasaFirms: string,
): Promise<FocoCalorSatelite[]> {
  const focos: FocoCalorSatelite[] = [];
  for (const reg of regioes) {
    const bbox = `${reg.minLon.toFixed(2)},${reg.minLat.toFixed(2)},${reg.maxLon.toFixed(2)},${reg.maxLat.toFixed(2)}`;
    const url = `${URL_NASA_FIRMS_AREA_CSV}/${encodeURIComponent(chaveNasaFirms)}/VIIRS_SNPP_NRT/${bbox}/1`;
    const resp = await fetch(url, {
      headers: { "User-Agent": "ArestaSupabaseClimaSync/2.0" },
    });
    if (!resp.ok) {
      throw new Error(`NASA FIRMS HTTP ${resp.status}`);
    }
    const csv = await resp.text();
    focos.push(
      ...extrairFocosDeCsv(csv, "latitude", "longitude", "frp", "NASA_FIRMS"),
    );
  }
  return focos;
}

async function buscarFocosInpeBdQueimadas(
  regioes: RegiaoSinotica[],
): Promise<FocoCalorSatelite[]> {
  const agora = new Date();
  const datasUtc = [agora];
  if (agora.getUTCHours() < 12) {
    datasUtc.push(new Date(agora.getTime() - 86400 * 1000));
  }
  const formatarDia = (d: Date): string =>
    `${d.getUTCFullYear()}${String(d.getUTCMonth() + 1).padStart(2, "0")}${String(d.getUTCDate()).padStart(2, "0")}`;

  const focos: FocoCalorSatelite[] = [];
  for (const d of datasUtc) {
    const url = `${URL_INPE_FOCOS_DIARIO_BR}/focos_diario_br_${formatarDia(d)}.csv`;
    const resp = await fetch(url, {
      headers: { "User-Agent": "ArestaSupabaseClimaSync/2.0" },
    });
    if (!resp.ok) continue;
    const csv = await resp.text();
    for (const f of extrairFocosDeCsv(
      csv,
      "lat",
      "lon",
      "frp",
      "INPE_NASA_VIIRS",
    )) {
      const dentro = regioes.some(
        (r) =>
          f.lat >= r.minLat &&
          f.lat <= r.maxLat &&
          f.lon >= r.minLon &&
          f.lon <= r.maxLon,
      );
      if (dentro) focos.push(f);
    }
  }
  return focos;
}

function extrairFocosDeCsv(
  csv: string,
  colLat: string,
  colLon: string,
  colFrp: string,
  fonte: string,
): FocoCalorSatelite[] {
  const linhas = csv.split(/\r?\n/);
  if (linhas.length < 2) return [];
  const cabecalho = linhas[0].split(",").map((c) => c.trim().toLowerCase());
  const iLat = cabecalho.indexOf(colLat);
  const iLon = cabecalho.indexOf(colLon);
  const iFrp = cabecalho.indexOf(colFrp);
  const iConf = cabecalho.indexOf("confidence");
  const iIndustrial = cabecalho.indexOf("id_area_industrial");
  const iPrecip = cabecalho.indexOf("precipitacao");
  const iRisco = cabecalho.indexOf("risco_fogo");
  if (iLat < 0 || iLon < 0) return [];

