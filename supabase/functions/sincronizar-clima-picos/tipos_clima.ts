// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/** Endpoints públicos e parâmetros físicos do pipeline servidor-a-servidor de clima e altimetria. */
export const URL_PADRAO_INDICE_BINARYPB =
  "https://serving.arestaclimb.com/v4/indice.binarypb";
export const URL_BASE_TERRARIUM =
  "https://s3.amazonaws.com/elevation-tiles-prod/terrarium";
export const URL_OPEN_METEO_FORECAST = "https://api.open-meteo.com/v1/forecast";
export const URL_RAINVIEWER_MAPAS =
  "https://api.rainviewer.com/public/weather-maps.json";
export const URL_NASA_FIRMS_AREA_CSV =
  "https://firms.modaps.eosdis.nasa.gov/api/area/csv";
export const URL_INPE_FOCOS_DIARIO_BR =
  "https://dataserver-coids.inpe.br/queimadas/queimadas/focos/csv/diario/Brasil";

export const DIMENSAO_GRADE_DEM = 13;
export const RAIO_GRADE_DEM_GRAUS = 0.024;
export const ZOOM_TERRARIUM = 12;
export const ZOOM_RADAR_RAINVIEWER = 6;

export const LIMIAR_FRENTE_AO_VIVO_MM_H = 0.15;
export const LIMIAR_NUCLEO_FORTE_MM_H = 1.8;
export const LIMIAR_NUCLEO_EXTREMO_MM_H = 5.5;
export const LIMIAR_PERIMETRO_INCENDIO_FRP = 6.0;
export const LIMIAR_NUCLEO_INTENSO_INCENDIO_FRP = 20.0;
export const LIMIAR_NUCLEO_EXTREMO_INCENDIO_FRP = 48.0;

/** Coordenada geográfica oficial de um pico extraída de `indice.binarypb`. */
export interface PicoCoordenada {
  id: string;
  latitude: number;
  longitude: number;
}

/** Envelope retangular agrupando picos próximos para amostragem sinótica em lote. */
export interface RegiaoSinotica {
  minLat: number;
  maxLat: number;
  minLon: number;
  maxLon: number;
}

/** Cota altimétrica e grade DEM `13x13` de `30m` persistidas em `snapshots_altimetria_picos`. */
export interface CotaAltimetricaDem {
  altitude_ponto_m: number;
  altitude_base_m: number;
  altitude_pico_m: number;
  dimensao_grade: number;
  raio_grade_graus: number;
  grade_dem_m: number[];
}

/** Evento diário de precipitação acumulada usado pela curva de secagem de 5 dias nos cards. */
export interface EventoChuvaJson {
  data: string;
  mm: number;
  bolha_id?: string;
}

/** Par `[longitude, latitude]` em graus decimais (`WGS84`). */
export type ParLonLat = [number, number];

/** Pegada pretérita de deslocamento de um sistema de tempestade. */
export interface RastroPassadoJson {
  horas_atras: number;
  contorno: ParLonLat[];
}

/** Frente regional de tempestade ao vivo com isoietas e vetor de vento a `10m`. */
export interface BolhaChuvaJson {
  id: string;
  lat: number;
  lon: number;
  intensidade_mm_h: number;
  vento_rumo_graus: number;
  vento_kmh: number;
  contorno_externo: ParLonLat[];
  nucleos_intensos?: ParLonLat[][];
  rastros_passados?: RastroPassadoJson[];
}

/** Perímetro regional de incêndio florestal ativo detectado por satélite (`VIIRS`/`MODIS`). */
export interface BolhaIncendioJson {
  id: string;
  lat: number;
  lon: number;
  potencia_frp_mw: number;
  total_focos: number;
  vento_rumo_graus: number;
  vento_kmh: number;
  fonte_satelite: string;
  contorno_externo: ParLonLat[];
  nucleos_intensos?: ParLonLat[][];
}
