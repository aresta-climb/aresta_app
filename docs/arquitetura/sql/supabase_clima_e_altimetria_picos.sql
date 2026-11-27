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

    IF p_bolhas_incendio IS NULL OR jsonb_typeof(p_bolhas_incendio) <> 'array' THEN
        RAISE EXCEPTION 'bolhas_incendio inválido: esperado array JSONB';
    END IF;

    IF p_chuva_por_pico IS NULL OR jsonb_typeof(p_chuva_por_pico) <> 'object' THEN
        RAISE EXCEPTION 'chuva_por_pico inválido: esperado objeto JSONB';
    END IF;

    -- 1. Atualiza a cópia única de segurança com o 'atual' vigente (descartando a cópia antiga)
    INSERT INTO public.estado_clima_picos (
        slot,
        gerado_em,
        bolhas_chuva,
        bolhas_incendio,
        chuva_por_pico,
        atualizado_em
    )
    SELECT
        'copia_seguranca',
        gerado_em,
        bolhas_chuva,
        bolhas_incendio,
        chuva_por_pico,
        now()
    FROM public.estado_clima_picos
    WHERE slot = 'atual'
    ON CONFLICT (slot) DO UPDATE SET
        gerado_em = EXCLUDED.gerado_em,
        bolhas_chuva = EXCLUDED.bolhas_chuva,
        bolhas_incendio = EXCLUDED.bolhas_incendio,
        chuva_por_pico = EXCLUDED.chuva_por_pico,
        atualizado_em = now();

    -- 2. Grava os dados recém-validados em 'atual'
    INSERT INTO public.estado_clima_picos (
        slot,
        gerado_em,
        bolhas_chuva,
        bolhas_incendio,
        chuva_por_pico,
        atualizado_em
    )
    VALUES (
        'atual',
        p_gerado_em,
        p_bolhas_chuva,
        p_bolhas_incendio,
        p_chuva_por_pico,
        now()
    )
    ON CONFLICT (slot) DO UPDATE SET
        gerado_em = EXCLUDED.gerado_em,
        bolhas_chuva = EXCLUDED.bolhas_chuva,
        bolhas_incendio = EXCLUDED.bolhas_incendio,
        chuva_por_pico = EXCLUDED.chuva_por_pico,
        atualizado_em = now();

    -- Se ainda não existia 'copia_seguranca' (primeira execução histórica), espelha 'atual'
    INSERT INTO public.estado_clima_picos (
        slot,
        gerado_em,
        bolhas_chuva,
        bolhas_incendio,
        chuva_por_pico,
        atualizado_em
    )
    VALUES (
        'copia_seguranca',
        p_gerado_em,
        p_bolhas_chuva,
        p_bolhas_incendio,
        p_chuva_por_pico,
        now()
    )
    ON CONFLICT (slot) DO NOTHING;
END;
$$;

CREATE OR REPLACE FUNCTION public.rotacionar_snapshot_altimetria_picos(
    p_gerado_em TIMESTAMPTZ,
    p_altimetria_por_pico JSONB
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF p_altimetria_por_pico IS NULL
       OR jsonb_typeof(p_altimetria_por_pico) <> 'object'
       OR p_altimetria_por_pico = '{}'::jsonb THEN
        RAISE EXCEPTION 'altimetria_por_pico inválido ou vazio: rotação abortada para preservar cópia de segurança';
    END IF;

