// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import type { PicoCoordenada } from "./tipos_clima.ts";

/**
 * Baixa `indice.binarypb` do servidor de catálogo Aresta e extrai todos os picos
 * com coordenadas geográficas válidas sem depender de bibliotecas externas de Protobuf.
 */
export async function buscarPicosDoIndiceProtobuf(
  urlIndice: string,
): Promise<PicoCoordenada[]> {
  const resp = await fetch(urlIndice, {
    headers: { "User-Agent": "ArestaSupabaseClimaSync/2.0" },
  });
  if (!resp.ok) {
    throw new Error(`Falha HTTP ${resp.status} ao baixar ${urlIndice}`);
  }
  const bytes = new Uint8Array(await resp.arrayBuffer());
  return decodificarIndiceBinaryPb(bytes);
}

/** Decodifica o binário Protobuf `Indice` lendo `id` (tag 1) e `Localizacao` ZigZag (tag 10) de cada resumo. */
export function decodificarIndiceBinaryPb(buf: Uint8Array): PicoCoordenada[] {
  const decodificadorTexto = new TextDecoder();
  const picos: PicoCoordenada[] = [];
  let pos = 0;

  while (pos < buf.length) {
    const tag = lerVarint(buf, pos);
    pos = tag.proximo;
    const campo = Number(tag.valor >> 3n);
    const wire = Number(tag.valor & 7n);

    if (campo === 2 && wire === 2) {
      const tamResumo = lerVarint(buf, pos);
      pos = tamResumo.proximo;
      const fimResumo = pos + Number(tamResumo.valor);
      let id = "";
      let lat = 0;
      let lon = 0;
      let temLoc = false;

      while (pos < fimResumo) {
        const subTag = lerVarint(buf, pos);
        pos = subTag.proximo;
        const subCampo = Number(subTag.valor >> 3n);
        const subWire = Number(subTag.valor & 7n);

        if (subCampo === 1 && subWire === 2) {
          const tamStr = lerVarint(buf, pos);
          pos = tamStr.proximo;
          const nBytes = Number(tamStr.valor);
          id = decodificadorTexto.decode(buf.subarray(pos, pos + nBytes));
          pos += nBytes;
        } else if (subCampo === 10 && subWire === 2) {
          const tamLoc = lerVarint(buf, pos);
          pos = tamLoc.proximo;
          const fimLoc = pos + Number(tamLoc.valor);
          while (pos < fimLoc) {
            const locTag = lerVarint(buf, pos);
            pos = locTag.proximo;
            const locCampo = Number(locTag.valor >> 3n);
            const locWire = Number(locTag.valor & 7n);
            if (locCampo === 1 && locWire === 0) {
              const v = lerVarint(buf, pos);
              pos = v.proximo;
              lat = decodificarZigZag32(v.valor) / 1e7;
              temLoc = true;
            } else if (locCampo === 2 && locWire === 0) {
              const v = lerVarint(buf, pos);
              pos = v.proximo;
              lon = decodificarZigZag32(v.valor) / 1e7;
              temLoc = true;
            } else {
              pos = pularCampoProtobuf(buf, pos, locWire);
            }
