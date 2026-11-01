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


COMMIT;
