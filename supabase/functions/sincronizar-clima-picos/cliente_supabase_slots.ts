// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import type { CotaAltimetricaDem } from "./tipos_clima.ts";

/** Lê o snapshot de altimetria já consolidado no Supabase (`atual`, com fallback para `copia_seguranca`). */
export async function lerAltimetriaExistenteSupabase(
  supabaseUrl: string,
  chaveServiceRole: string,
): Promise<Record<string, CotaAltimetricaDem>> {
  for (const slot of ["atual", "copia_seguranca"]) {
    const resp = await fetch(
      `${supabaseUrl}/rest/v1/snapshots_altimetria_picos?slot=eq.${slot}&select=altimetria_por_pico&limit=1`,
      {
        headers: {
          apikey: chaveServiceRole,
          Authorization: `Bearer ${chaveServiceRole}`,
          Accept: "application/json",
        },
      },
    );
    if (!resp.ok) continue;
    const linhas = await resp.json();
    if (
      Array.isArray(linhas) &&
      linhas.length > 0 &&
      linhas[0]?.altimetria_por_pico &&
      typeof linhas[0].altimetria_por_pico === "object"
    ) {
      return linhas[0].altimetria_por_pico as Record<
        string,
        CotaAltimetricaDem
      >;
    }
  }
  return {};
}

/** Lê o `versao_hash` atual da malha viária já salva no Supabase (`atual` ou `copia_seguranca`). */
export async function lerVersaoMalhaViariaSupabase(
  supabaseUrl: string,
  chaveServiceRole: string,
): Promise<string | null> {
  for (const slot of ["atual", "copia_seguranca"]) {
    const resp = await fetch(
      `${supabaseUrl}/rest/v1/snapshots_malha_viaria_picos?slot=eq.${slot}&select=versao_hash&limit=1`,
      {
        headers: {
          apikey: chaveServiceRole,
          Authorization: `Bearer ${chaveServiceRole}`,
          Accept: "application/json",
        },
      },
    );
    if (!resp.ok) continue;
    const linhas = await resp.json();
    if (
      Array.isArray(linhas) &&
      linhas.length > 0 &&
      typeof linhas[0]?.versao_hash === "string"
    ) {
      return linhas[0].versao_hash;
    }
  }
  return null;
}

/** Invoca uma RPC PostgREST transacional no Supabase para rotacionar os slots `atual` -> `copia_seguranca`. */
export async function chamarRpcSupabase(
  supabaseUrl: string,
  chaveServiceRole: string,
  nomeFuncao: string,
  parametros: Record<string, unknown>,
): Promise<void> {
  const resp = await fetch(`${supabaseUrl}/rest/v1/rpc/${nomeFuncao}`, {
    method: "POST",
    headers: {
      apikey: chaveServiceRole,
      Authorization: `Bearer ${chaveServiceRole}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(parametros),
  });
  if (!resp.ok) {
    const erroTxt = await resp.text();
    throw new Error(`RPC ${nomeFuncao} falhou (${resp.status}): ${erroTxt}`);
  }
}
