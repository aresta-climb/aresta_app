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
  lerVersaoMalhaViariaSupabase,
} from "./cliente_supabase_slots.ts";
import { buscarPicosDoIndiceProtobuf } from "./decodificador_indice_protobuf.ts";
import { coletarIncendiosFlorestaisContornos } from "./incendios_satelite.ts";
import {
  calcularHashCatalogoViario,
  coletarMalhaViariaHierarquicaOsm,
} from "./malha_viaria_osm.ts";
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

    let altimetriaRotacionada = false;
    if (picosSemAltimetria.length > 0) {
      const novasCotas = await extrairCotasSrtm30m(picosSemAltimetria);
      const consolidadoAltimetria: Record<string, CotaAltimetricaDem> = {
        ...altimetriaExistente,
        ...novasCotas,
      };
      await chamarRpcSupabase(
        supabaseUrl,
        chaveServiceRole,
        "rotacionar_snapshot_altimetria_picos",
        {
          p_gerado_em: geradoEm,
          p_altimetria_por_pico: consolidadoAltimetria,
        },
      );
      altimetriaRotacionada = true;
    }

    // 1b. Malha viária hierárquica OSM incremental (só regera quando o conjunto de picos muda)
    let malhaViariaRotacionada = false;
    const hashViarioAlvo = calcularHashCatalogoViario(picos);
    const hashViarioAtual = await lerVersaoMalhaViariaSupabase(
      supabaseUrl,
      chaveServiceRole,
    );
    if (hashViarioAtual !== hashViarioAlvo) {
      try {
        const rodoviasOsm = await coletarMalhaViariaHierarquicaOsm(picos);
        if (rodoviasOsm.length > 0) {
          await chamarRpcSupabase(
            supabaseUrl,
            chaveServiceRole,
            "rotacionar_snapshot_malha_viaria_picos",
            {
              p_gerado_em: geradoEm,
              p_versao_hash: hashViarioAlvo,
              p_rodovias: rodoviasOsm,
            },
          );
          malhaViariaRotacionada = true;
        }
      } catch (erroOsm) {
        console.warn(
          `[sincronizar-clima-picos] Malha viária mantida no slot anterior: ${erroOsm}`,
        );
      }
    }

    // 2. Curva hídrica de 5 dias + tempestades ao vivo + incêndios florestais filtrados contra chuva ativa
    const chaveNasaFirms = (Deno.env.get("NASA_FIRMS_MAP_KEY") ?? "").trim();
    const [chuvaPorPicoBruta, bolhasChuva] = await Promise.all([
      coletarHistoricoChuvaPicosOpenMeteo(picos),
      coletarTempestadesAoVivoContornosOpenMeteo(picos),
    ]);
    const bolhasIncendio = await coletarIncendiosFlorestaisContornos(
      picos,
      chaveNasaFirms,
      bolhasChuva,
    );

    const chuvaPorPico = associarPicosAsTempestadesAtivas(
      picos,
      chuvaPorPicoBruta,
      bolhasChuva,
    );

    await chamarRpcSupabase(
      supabaseUrl,
      chaveServiceRole,
      "rotacionar_estado_clima_picos",
      {
        p_gerado_em: geradoEm,
        p_bolhas_chuva: bolhasChuva,
        p_chuva_por_pico: chuvaPorPico,
        p_bolhas_incendio: bolhasIncendio,
      },
    );

    return respostaJson({
      sucesso: true,
      gerado_em: geradoEm,
      total_picos: picos.length,
      novos_picos_altimetria: picosSemAltimetria.length,
      altimetria_rotacionada: altimetriaRotacionada,
      malha_viaria_rotacionada: malhaViariaRotacionada,
      bolhas_ativas: bolhasChuva.length,
      bolhas_incendio_ativas: bolhasIncendio.length,
      picos_com_chuva_recente: Object.keys(chuvaPorPico).length,
    });
  } catch (erro) {
    const mensagem = erro instanceof Error ? erro.message : String(erro);
    console.error(
      `[sincronizar-clima-picos] Falha abortada com segurança: ${mensagem}`,
    );
    return respostaJson(
      {
        sucesso: false,
        erro: mensagem,
        detalhe:
          "Rotação abortada para preservar intactos os slots atual e copia_seguranca.",
      },
      502,
    );
  }
});

function respostaJson(corpo: unknown, status = 200): Response {
  return new Response(JSON.stringify(corpo), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });
}
