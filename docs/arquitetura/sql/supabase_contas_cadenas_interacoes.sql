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

-- ============================================================================
-- 3. TABELA: public.cadenas (Backup Privado da Caderneta Esportiva)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.cadenas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    escalada_uid VARCHAR(14) NOT NULL
        CONSTRAINT chk_cadenas_escalada_uid_nanoid CHECK (escalada_uid ~ '^[0-9A-Za-z]{14}$'),
    data_ascensao DATE NOT NULL,
    -- 1: À Vista, 2: Flash, 3: Trabalhado, 4: Tentativa (alinhado com TipoAscensao)
    tipo_ascensao SMALLINT NOT NULL
        CONSTRAINT chk_cadenas_tipo_ascensao CHECK (tipo_ascensao BETWEEN 1 AND 4),
    -- 1: Guiado, 2: Top Rope, 3: Boulder, 4: Solo (alinhado com TipoEscalada)
    tipo_escalada SMALLINT NOT NULL
        CONSTRAINT chk_cadenas_tipo_escalada CHECK (tipo_escalada BETWEEN 1 AND 4),
    tentativas SMALLINT NOT NULL DEFAULT 1
        CONSTRAINT chk_cadenas_tentativas_positivas CHECK (tentativas >= 1),
    -- Código numérico do enum Protobuf (GrauVia / GrauBoulder)
    grau_sugerido SMALLINT,
    notas_privadas VARCHAR(200) NOT NULL DEFAULT '',
    criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.cadenas IS
    'Caderneta privada do escalador sincronizada via PowerSync (acesso exclusivo do titular).';

DROP TRIGGER IF EXISTS trg_cadenas_atualizado_em ON public.cadenas;
CREATE TRIGGER trg_cadenas_atualizado_em
    BEFORE UPDATE ON public.cadenas
    FOR EACH ROW
    EXECUTE FUNCTION public.atualizar_coluna_atualizado_em();

CREATE INDEX IF NOT EXISTS idx_cadenas_usuario ON public.cadenas(user_id);
CREATE INDEX IF NOT EXISTS idx_cadenas_escalada ON public.cadenas(escalada_uid);

-- Habilitação obrigatória de RLS em public.cadenas
ALTER TABLE public.cadenas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "cadenas_proprio_usuario" ON public.cadenas;
CREATE POLICY "cadenas_proprio_usuario" ON public.cadenas
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 4. TABELA: public.fila_interacoes (Buffer Transitório Comunitário & Alertas Waze)
-- ============================================================================
-- Esvaziada de hora em hora pelo Aresta Bot (service_role) para consolidação no
-- repositório Git aberto (aresta_db/interacoes/) sob licença ODbL.
-- Nenhum user_id privado ou dado pessoal (e-mail/telefone) é armazenado aqui.

CREATE TABLE IF NOT EXISTS public.fila_interacoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    autor_id_publico VARCHAR(14) NOT NULL
        CONSTRAINT chk_fila_autor_id_nanoid CHECK (autor_id_publico ~ '^[0-9A-Za-z]{14}$'),
    autor_nome_publico VARCHAR(50) NOT NULL DEFAULT 'Anônimo'
        CONSTRAINT chk_fila_autor_nome_nao_vazio CHECK (char_length(btrim(autor_nome_publico)) > 0),
    escalada_uid VARCHAR(14) NOT NULL
        CONSTRAINT chk_fila_escalada_uid_nanoid CHECK (escalada_uid ~ '^[0-9A-Za-z]{14}$'),
    tipo TEXT NOT NULL
        CONSTRAINT chk_fila_tipo_valido CHECK (
            tipo IN ('VOTO_GRAU', 'COMENTARIO', 'ALERTA_SEGURANCA', 'CONFIRMACAO_ALERTA')
        ),
    -- Presets estilo Waze para avisos rápidos de segurança na via/setor
    categoria_alerta TEXT
        CONSTRAINT chk_fila_categoria_alerta CHECK (
            categoria_alerta IS NULL OR categoria_alerta IN (
                'ABELHAS_INSETOS',
                'ROCHA_AGARRA_INSTAVEL',
                'PROTECAO_PRECARIA',
                'VIA_MOLHADA',
                'RISCO_EXPOSICAO'
            )
        ),
    -- NanoID 14c do alerta ativo sendo confirmado ou encerrado ("Ainda está lá?")
    alerta_alvo_uid VARCHAR(14)
        CONSTRAINT chk_fila_alerta_alvo_nanoid CHECK (
            alerta_alvo_uid IS NULL OR alerta_alvo_uid ~ '^[0-9A-Za-z]{14}$'
        ),
    -- true = "Sim, ainda está lá", false = "Não, problema resolvido"
    alerta_ativo BOOLEAN,
    grau_sugerido SMALLINT,
    delta_grau SMALLINT
        CONSTRAINT chk_fila_delta_grau CHECK (delta_grau IS NULL OR delta_grau BETWEEN -2 AND 2),
    texto_comentario VARCHAR(280),
    status TEXT NOT NULL DEFAULT 'PENDENTE'
        CONSTRAINT chk_fila_status CHECK (status IN ('PENDENTE', 'PROCESSADO')),
    criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Validação estrutural dos campos obrigatórios por tipo de interação
    CONSTRAINT chk_fila_interacoes_payload_por_tipo CHECK (
        (
            tipo = 'VOTO_GRAU'
            AND (grau_sugerido IS NOT NULL OR delta_grau IS NOT NULL)
        )
        OR (
            tipo = 'COMENTARIO'
            AND texto_comentario IS NOT NULL
            AND char_length(btrim(texto_comentario)) BETWEEN 1 AND 280
        )
        OR (
            tipo = 'ALERTA_SEGURANCA'
            AND categoria_alerta IS NOT NULL
            AND (texto_comentario IS NULL OR char_length(texto_comentario) <= 100)
        )
        OR (
            tipo = 'CONFIRMACAO_ALERTA'
            AND alerta_alvo_uid IS NOT NULL
            AND alerta_ativo IS NOT NULL
        )
    )
);

COMMENT ON TABLE public.fila_interacoes IS
    'Buffer transitório de votos de grau, comentários e alertas de segurança estilo Waze.';

CREATE INDEX IF NOT EXISTS idx_fila_pendentes
    ON public.fila_interacoes(status, criado_em)
    WHERE status = 'PENDENTE';

CREATE INDEX IF NOT EXISTS idx_fila_escalada_pendentes
    ON public.fila_interacoes(escalada_uid)
    WHERE status = 'PENDENTE';

-- Habilitação obrigatória de RLS em public.fila_interacoes
ALTER TABLE public.fila_interacoes ENABLE ROW LEVEL SECURITY;

-- Política 1: Transparência total de leitura das interações pendentes na fila
DROP POLICY IF EXISTS "fila_interacoes_leitura" ON public.fila_interacoes;
DROP POLICY IF EXISTS "fila_interacoes_leitura_publica" ON public.fila_interacoes;
CREATE POLICY "fila_interacoes_leitura_publica" ON public.fila_interacoes
    FOR SELECT
    TO anon, authenticated
    USING (true);

-- Política 2: Escaladores autenticados podem enviar qualquer tipo de interação
-- vinculada ao seu próprio autor_id_publico registrado em public.perfis.
DROP POLICY IF EXISTS "fila_interacoes_insercao" ON public.fila_interacoes;
DROP POLICY IF EXISTS "fila_interacoes_insercao_autenticada" ON public.fila_interacoes;
CREATE POLICY "fila_interacoes_insercao_autenticada" ON public.fila_interacoes
    FOR INSERT
    TO authenticated
    WITH CHECK (
        status = 'PENDENTE'
        AND EXISTS (
            SELECT 1 FROM public.perfis p
            WHERE p.user_id = auth.uid()
              AND p.autor_id_publico = fila_interacoes.autor_id_publico
        )
    );

-- Política 3: Qualquer usuário do aplicativo (inclusive anônimo / sem conta) pode
-- reportar alertas de risco iminente na rocha e responder "Ainda está lá?" usando
-- o autor_id_publico local do aparelho, sem barreira de login.
DROP POLICY IF EXISTS "fila_interacoes_seguranca_anonima" ON public.fila_interacoes;
CREATE POLICY "fila_interacoes_seguranca_anonima" ON public.fila_interacoes
    FOR INSERT
    TO anon, authenticated
    WITH CHECK (
        status = 'PENDENTE'
        AND tipo IN ('ALERTA_SEGURANCA', 'CONFIRMACAO_ALERTA')
    );


COMMIT;
