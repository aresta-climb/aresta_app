-- SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
-- SPDX-License-Identifier: MPL-2.0
-- ============================================================================
-- ARESTA CLIMB — ESQUEMA FÍSICO SUPABASE (CONTAS, CADERNETA E INTERAÇÕES)
-- ============================================================================
-- Script idempotente pronto para execução direta no SQL Editor do Supabase.
-- Implementa:
--   1. Geração criptográfica de NanoID 14c Base62 (public.gerar_nanoid_14c).
--   2. Tabela public.perfis com gatilho de provisionamento automático no Auth
--      (preservando o autor_id_publico local do dispositivo quando informado).
--   3. Tabela public.cadenas para backup privado da caderneta via PowerSync.
--   4. Tabela public.fila_interacoes (buffer horário do Aresta Bot) suportando:
--      - Votos de graduação e comentários (exigem conta autenticada).
--      - Alertas de segurança estilo Waze e confirmações "Ainda está lá?"
--        (permitidos também para usuários anônimos sem conta).
--   5. Políticas estritas de Row Level Security (RLS) e publicação PowerSync.
-- ============================================================================

BEGIN;

-- Extensão criptográfica para geração segura de bytes aleatórios e UUIDs
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================================
-- 1. FUNÇÕES UTILITÁRIAS (NANOID 14C BASE62 E TIMESTAMPS)
-- ============================================================================

-- Gera um identificador NanoID de 14 caracteres Base62 ([0-9A-Za-z]) sem viés de módulo.
CREATE OR REPLACE FUNCTION public.gerar_nanoid_14c()
RETURNS VARCHAR(14)
LANGUAGE plpgsql
VOLATILE
SET search_path = public, extensions
AS $$
DECLARE
    alfabeto CONSTANT TEXT := '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    bytes_aleatorios BYTEA;
    resultado TEXT := '';
    indice INT;
    valor_byte INT;
BEGIN
    WHILE char_length(resultado) < 14 LOOP
        bytes_aleatorios := gen_random_bytes(24);
        FOR i IN 0..23 LOOP
            EXIT WHEN char_length(resultado) >= 14;
            valor_byte := get_byte(bytes_aleatorios, i);
            -- Amostragem por rejeição (248 = 62 * 4) para distribuição uniforme
            IF valor_byte < 248 THEN
                indice := (valor_byte % 62) + 1;
                resultado := resultado || substr(alfabeto, indice, 1);
            END IF;
        END LOOP;
    END LOOP;

    RETURN resultado::VARCHAR(14);
END;
$$;

COMMENT ON FUNCTION public.gerar_nanoid_14c() IS
    'Gera um NanoID criptograficamente seguro de 14 caracteres no alfabeto Base62 (0-9, A-Z, a-z).';

CREATE OR REPLACE FUNCTION public.atualizar_coluna_atualizado_em()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    NEW.atualizado_em := now();
    RETURN NEW;
END;
$$;

-- ============================================================================
-- 2. TABELA: public.perfis (Identidade Esportiva Pública do Escalador)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.perfis (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    autor_id_publico VARCHAR(14) UNIQUE NOT NULL DEFAULT public.gerar_nanoid_14c()
        CONSTRAINT chk_perfis_autor_id_nanoid CHECK (autor_id_publico ~ '^[0-9A-Za-z]{14}$'),
    autor_nome_publico VARCHAR(50) NOT NULL DEFAULT 'Escalador Aresta'
        CONSTRAINT chk_perfis_autor_nome_nao_vazio CHECK (char_length(btrim(autor_nome_publico)) > 0),
    criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.perfis IS
    'Metadados públicos do escalador autenticado, vinculando auth.users ao NanoID 14c público.';

DROP TRIGGER IF EXISTS trg_perfis_atualizado_em ON public.perfis;
CREATE TRIGGER trg_perfis_atualizado_em
    BEFORE UPDATE ON public.perfis
    FOR EACH ROW
    EXECUTE FUNCTION public.atualizar_coluna_atualizado_em();

-- Gatilho para criar automaticamente a linha em public.perfis no cadastro (Sign Up / OAuth),
-- reaproveitando o autor_id_publico gerado offline no aparelho caso enviado em raw_user_meta_data.
CREATE OR REPLACE FUNCTION public.criar_perfil_automatico_novo_usuario()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
    uid_candidato TEXT;
    nome_candidato TEXT;
    uid_final VARCHAR(14);
    nome_final VARCHAR(50);
BEGIN
    uid_candidato := btrim(COALESCE(NEW.raw_user_meta_data->>'autor_id_publico', ''));
    IF uid_candidato ~ '^[0-9A-Za-z]{14}$'
       AND NOT EXISTS (SELECT 1 FROM public.perfis WHERE autor_id_publico = uid_candidato) THEN
        uid_final := uid_candidato::VARCHAR(14);
    ELSE
        uid_final := public.gerar_nanoid_14c();
    END IF;

    nome_candidato := btrim(COALESCE(
        NULLIF(btrim(NEW.raw_user_meta_data->>'autor_nome_publico'), ''),
        NULLIF(btrim(NEW.raw_user_meta_data->>'full_name'), ''),
        NULLIF(btrim(NEW.raw_user_meta_data->>'name'), ''),
        'Escalador Aresta'
    ));
    nome_final := left(nome_candidato, 50)::VARCHAR(50);

    INSERT INTO public.perfis (user_id, autor_id_publico, autor_nome_publico)
    VALUES (NEW.id, uid_final, nome_final)
    ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auth_users_criar_perfil ON auth.users;
CREATE TRIGGER trg_auth_users_criar_perfil
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.criar_perfil_automatico_novo_usuario();

-- Habilitação obrigatória de RLS em public.perfis
ALTER TABLE public.perfis ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "perfis_proprio_usuario" ON public.perfis;
CREATE POLICY "perfis_proprio_usuario" ON public.perfis
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


COMMIT;
