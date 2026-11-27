// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0
//
// Supabase Edge Function: sincronizar-clima-picos
//
// Orquestrador declarativo do pipeline servidor-a-servidor de clima, incêndios e altimetria:
// 1. Lê as coordenadas oficiais de `indice.binarypb` (`decodificador_indice_protobuf.ts`).
// 2. Amostra incrementalmente a altimetria real de 30m (`altimetria_srtm.ts`) apenas para picos novos.
// 3. Coleta precipitação diária de 5 dias + frentes de tempestade ao vivo (`tempestades_open_meteo.ts`)
//    e perímetros orbitais de incêndios florestais (`incendios_satelite.ts`).
// 4. Rotaciona atomicamente os slots `atual` -> `copia_seguranca` via RPCs PostgREST (`cliente_supabase_slots.ts`).

import { extrairCotasSrtm30m } from "./altimetria_srtm.ts";
import {
  chamarRpcSupabase,
  lerAltimetriaExistenteSupabase,
} from "./cliente_supabase_slots.ts";
import { buscarPicosDoIndiceProtobuf } from "./decodificador_indice_protobuf.ts";
import { coletarIncendiosFlorestaisContornos } from "./incendios_satelite.ts";
import {
  associarPicosAsTempestadesAtivas,
  coletarHistoricoChuvaPicosOpenMeteo,
  coletarTempestadesAoVivoContornosOpenMeteo,
} from "./tempestades_open_meteo.ts";
import {
  type CotaAltimetricaDem,
  URL_PADRAO_INDICE_BINARYPB,
} from "./tipos_clima.ts";

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return respostaJson({ erro: "Método não permitido. Use POST." }, 405);
  }

  const supabaseUrl = (Deno.env.get("SUPABASE_URL") ?? "").replace(/\/+$/, "");
  const chaveServiceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const segredoCron = Deno.env.get("CRON_SECRET") ?? "";

  if (!supabaseUrl || !chaveServiceRole) {
    return respostaJson(
      { erro: "Variáveis SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY ausentes." },
      500,
    );
  }

  const cabecalhoAuth = req.headers.get("authorization") ?? "";
  const tokenRecebido = cabecalhoAuth.replace(/^Bearer\s+/i, "").trim();
  const autorizado =
    tokenRecebido === chaveServiceRole ||
    (segredoCron.length > 0 && tokenRecebido === segredoCron);

  if (!autorizado) {
    return respostaJson({ erro: "Não autorizado." }, 401);
  }

  try {
    const urlIndice =
      Deno.env.get("ARESTA_SERVING_INDICE_URL") ?? URL_PADRAO_INDICE_BINARYPB;
    const picos = await buscarPicosDoIndiceProtobuf(urlIndice);
    if (picos.length === 0) {
      throw new Error(
        `Nenhum pico com coordenadas válidas encontrado em ${urlIndice}.`,
      );
    }

    const geradoEm = new Date().toISOString();

    // 1. Altimetria incremental (só baixa tiles SRTM 30m quando surgir pico novo no índice)
    const altimetriaExistente = await lerAltimetriaExistenteSupabase(
      supabaseUrl,
      chaveServiceRole,
    );
    const picosSemAltimetria = picos.filter((p) => {
      const atual = altimetriaExistente[p.id];
      return (
        !atual ||
        !Array.isArray(atual.grade_dem_m) ||
        atual.grade_dem_m.length === 0
      );
    });

