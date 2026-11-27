-- SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
-- SPDX-License-Identifier: MPL-2.0
--
-- Infraestrutura de Clima Regional (RainTracker) e Altimetria Externa (NASA SRTM 30m / NASADEM)
-- Arquitetura de Rotação Atômica com 1 Cópia de Segurança ('atual' + 'copia_seguranca')
-- Referência: docs/arquitetura/mds/arquitetura_unificada_explorar_globo_lods_e_clima.md

BEGIN;

-- ============================================================================
-- 1. TABELAS DE SNAPSHOTS COM ESTRITAMENTE 2 SLOTS ('atual' e 'copia_seguranca')
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.estado_clima_picos (
    slot TEXT PRIMARY KEY,
    gerado_em TIMESTAMPTZ NOT NULL,
    bolhas_chuva JSONB NOT NULL DEFAULT '[]'::jsonb,
    bolhas_incendio JSONB NOT NULL DEFAULT '[]'::jsonb,
    chuva_por_pico JSONB NOT NULL DEFAULT '{}'::jsonb,
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_estado_clima_slot_valido
        CHECK (slot IN ('atual', 'copia_seguranca')),
    CONSTRAINT chk_estado_clima_bolhas_array
        CHECK (jsonb_typeof(bolhas_chuva) = 'array'),
    CONSTRAINT chk_estado_clima_incendios_array
        CHECK (jsonb_typeof(bolhas_incendio) = 'array'),
    CONSTRAINT chk_estado_clima_picos_objeto
        CHECK (jsonb_typeof(chuva_por_pico) = 'object')
);

ALTER TABLE public.estado_clima_picos
    ADD COLUMN IF NOT EXISTS bolhas_incendio JSONB NOT NULL DEFAULT '[]'::jsonb;

CREATE TABLE IF NOT EXISTS public.snapshots_altimetria_picos (
    slot TEXT PRIMARY KEY,
    gerado_em TIMESTAMPTZ NOT NULL,
    altimetria_por_pico JSONB NOT NULL DEFAULT '{}'::jsonb,
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_altimetria_slot_valido
        CHECK (slot IN ('atual', 'copia_seguranca')),
    CONSTRAINT chk_altimetria_picos_objeto
        CHECK (jsonb_typeof(altimetria_por_pico) = 'object')
);

-- ============================================================================
-- 2. SEGURANÇA DE LINHA (RLS) — LEITURA PÚBLICA, ESCRITA RESTRITA AO SERVIDOR
-- ============================================================================

ALTER TABLE public.estado_clima_picos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.snapshots_altimetria_picos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS leitura_publica_estado_clima_picos ON public.estado_clima_picos;
CREATE POLICY leitura_publica_estado_clima_picos
    ON public.estado_clima_picos
    FOR SELECT
    TO anon, authenticated
    USING (true);

DROP POLICY IF EXISTS leitura_publica_snapshots_altimetria_picos ON public.snapshots_altimetria_picos;
CREATE POLICY leitura_publica_snapshots_altimetria_picos
    ON public.snapshots_altimetria_picos
    FOR SELECT
    TO anon, authenticated
    USING (true);

REVOKE INSERT, UPDATE, DELETE ON public.estado_clima_picos FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.snapshots_altimetria_picos FROM anon, authenticated;
GRANT SELECT ON public.estado_clima_picos TO anon, authenticated;
GRANT SELECT ON public.snapshots_altimetria_picos TO anon, authenticated;

-- ============================================================================
-- 3. FUNÇÕES TRANSACIONAIS DE ROTAÇÃO ATÔMICA (ATUAL -> COPIA_SEGURANCA)
-- Toda nova carga íntegra promove o 'atual' vigente para 'copia_seguranca'
-- (descartando versões mais antigas) antes de gravar o novo 'atual'.
-- ============================================================================

DROP FUNCTION IF EXISTS public.rotacionar_estado_clima_picos(TIMESTAMPTZ, JSONB, JSONB);

CREATE OR REPLACE FUNCTION public.rotacionar_estado_clima_picos(
    p_gerado_em TIMESTAMPTZ,
    p_bolhas_chuva JSONB,
    p_chuva_por_pico JSONB,
    p_bolhas_incendio JSONB DEFAULT '[]'::jsonb
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF p_bolhas_chuva IS NULL OR jsonb_typeof(p_bolhas_chuva) <> 'array' THEN
        RAISE EXCEPTION 'bolhas_chuva inválido: esperado array JSONB';
    END IF;

