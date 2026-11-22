# Configuração do Banco de Dados Supabase e PowerSync — Aresta Climb

Este diretório contém os artefatos executáveis de banco de dados para habilitar **Contas Opcionais de Escaladores**, **Armazenamento de Foto de Perfil (`avatars`)**, **Backup Privado da Caderneta Esportiva** e **Interações Comunitárias / Alertas de Segurança estilo Waze** em conformidade com a [Arquitetura Unificada v3.0](../mds/arquitetura_unificada_contas_cadenas_uids.md).

---

## 1. Arquivos

| Arquivo | Finalidade |
| :--- | :--- |
| `supabase_contas_cadenas_interacoes.sql` | Script DDL + RLS idempotente para execução direta no **SQL Editor** do Supabase (`perfis`, `cadenas`, `fila_interacoes`, bucket `avatars` no Supabase Storage, gatilho `auth.users` e publicação `powersync`). |
| `powersync_sync_rules.yaml` | Regras de bucket individual (`bucket_usuario`) para colar no painel do PowerSync Cloud / Self-Hosted. |

---

## 2. Passo a Passo de Implantação no Supabase

1. Acesse o painel do projeto no **Supabase Dashboard** $\rightarrow$ **SQL Editor** $\rightarrow$ **New Query**.
2. Copie todo o conteúdo de `supabase_contas_cadenas_interacoes.sql`, cole no editor e clique em **Run**.
   * *Nota:* O script é idempotente — pode ser reexecutado com segurança sem duplicar políticas, colunas, gatilhos ou índices.
3. Em **Authentication** $\rightarrow$ **URL Configuration**, adicione o deep link de callback do aplicativo em **Redirect URLs**:
   * `aresta://app.arestaclimb.com/auth-callback`
4. Em **Authentication** $\rightarrow$ **Providers**, habilite os provedores desejados para criação opcional de conta:
   * **Email** (e-mail e senha).
   * **Google** (configurando o *Client ID* e o *Client Secret* OAuth 2.0 Web com callback `https://<project-ref>.supabase.co/auth/v1/callback`).
5. *(Quando conectar o PowerSync)* Copie o conteúdo de `powersync_sync_rules.yaml` para a aba **Sync Rules** do painel PowerSync apontando para a publicação lógica `powersync` criada pelo script SQL.

---

## 3. Resumo do Modelo de Segurança (RLS e Storage)

* **`public.perfis` (Somente Autenticado):**
  * Armazena `user_id`, `autor_id_publico` (NanoID 14c), `autor_nome_publico` e `avatar_url`.
  * Cada conta em `auth.users` recebe automaticamente sua linha em `public.perfis` via trigger `trg_auth_users_criar_perfil`.
  * Se o escalador já usava o app offline antes de criar conta, o `autor_id_publico` (NanoID 14c), o `autor_nome_publico` e a foto (`avatar_url` / `picture` / `foto_url`) enviados em `raw_user_meta_data` são preservados automaticamente na criação da conta.
  * Política RLS: `auth.uid() = user_id` (`SELECT`, `INSERT`, `UPDATE`).
* **Bucket `avatars` no Supabase Storage (`storage.buckets` / `storage.objects`):**
  * Bucket público para leitura de avatares (`avatars/<user_id>/avatar.webp`), com políticas RLS que restringem `INSERT`, `UPDATE` e `DELETE` exclusivamente à pasta do próprio usuário autenticado (`(storage.foldername(name))[1] = auth.uid()::text`).
* **`public.cadenas` (Backup Estritamente Privado via PostgREST):**
  * Nenhuma leitura pública é permitida (`REVOKE ALL FROM anon`). Apenas o próprio atleta (`auth.uid() = user_id`) lê, insere/atualiza (`POST ?on_conflict=id`) ou exclui (`DELETE`) suas ascensões e `notas_privadas`, sincronizadas pelo aplicativo com fila local offline.
* **`public.excluir_minha_conta()` (Exclusão Irreversível de Conta — LGPD & Apple 5.1.1(v)):**
  * Função `SECURITY DEFINER` invocada via `POST /rest/v1/rpc/excluir_minha_conta` exclusivamente por usuários `authenticated`. Remove os arquivos em `avatars/<auth.uid()>/` e exclui a linha em `auth.users`, cascateando `public.perfis` e `public.cadenas` sem expor ou afetar contribuições comunitárias desidentificadas.
* **`public.fila_interacoes` (Leitura Pública Universal + Escrita Vinculada ao Perfil):**
  * **Leitura Pública (`TO anon, authenticated`):** Qualquer escalador (com ou sem conta) visualiza todos os alertas de segurança ativos nas vias e no mapa interativo, bem como o consenso de grau e os betas da comunidade.
  * **Escrita Autenticada por Perfil (`TO authenticated`):** `VOTO_GRAU`, `COMENTARIO`, `ALERTA_SEGURANCA` e `CONFIRMACAO_ALERTA` exigem usuário autenticado cujo `autor_id_publico` pertença ao seu registro em `public.perfis` (`REVOKE ALL FROM anon; GRANT SELECT TO anon;`). Reexecutar o script SQL remove automaticamente políticas legadas (`DROP POLICY IF EXISTS "fila_interacoes_seguranca_anonima"`) e higieniza duplicatas antigas.
  * **Prevenção de Spam / `+1` Duplicado:** O índice único parcial `idx_fila_confirmacao_positiva_unica_por_autor` e o gatilho `trg_fila_validar_contribuicao_unica_alerta` garantem no máximo **1 confirmação positiva (*"Ainda está lá?"*) por perfil em cada alerta** (impedindo também auto-confirmação pelo criador do alerta).
  * **Imutabilidade pelo Cliente:** Usuários `anon` e `authenticated` não possuem permissão de `UPDATE` ou `DELETE` na fila; somente o *Aresta Bot* (`service_role`) consome e expurga os lotes consolidados no Git (`aresta_db`).
