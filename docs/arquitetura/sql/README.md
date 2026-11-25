# Banco de Dados Supabase e PowerSync — Aresta Climb

Este diretório contém os arquivos de banco de dados para contas de escaladores, fotos de perfil (`avatars`), backup de caderneta (`cadenas`) e fila de interações e alertas (`fila_interacoes`), conforme `docs/arquitetura/mds/arquitetura_unificada_contas_cadenas_uids.md`.

---

## 1. Arquivos

| Arquivo | Finalidade |
| :--- | :--- |
| `supabase_contas_cadenas_interacoes.sql` | Script DDL e RLS idempotente para execução no **SQL Editor** do Supabase (`perfis`, `cadenas`, `fila_interacoes`, bucket `avatars`, função `excluir_minha_conta` e publicação `powersync`). |
| `powersync_sync_rules.yaml` | Regras de sincronização (`bucket_usuario`) para configuração no PowerSync. |

---

## 2. Implantação no Supabase

1. Abra **Supabase Dashboard** $\rightarrow$ **SQL Editor** $\rightarrow$ **New Query**.
2. Cole o conteúdo de `supabase_contas_cadenas_interacoes.sql` e clique em **Run**.
   * O script é idempotente: remove políticas e constraints antigas antes de recriá-las, migra códigos renomeados e remove duplicatas.
3. Em **Authentication** $\rightarrow$ **URL Configuration**, adicione em **Redirect URLs**:
   * `aresta://app.arestaclimb.com/auth-callback`
4. Em **Authentication** $\rightarrow$ **Providers**, habilite os métodos sem senha:
   * **Email** (envio de código OTP de 6 dígitos).
   * **Google** (*Client ID* e *Client Secret* OAuth 2.0 com callback `https://<project-ref>.supabase.co/auth/v1/callback`).
   * **Apple** (para login no iOS).
5. *(Se utilizar PowerSync)* Copie `powersync_sync_rules.yaml` para **Sync Rules** no painel PowerSync apontando para a publicação `powersync`.

---

## 3. Modelo de Segurança (RLS e Storage)

* **`public.perfis` (Somente Autenticado):**
  * Armazena `user_id`, `autor_id_publico` (NanoID 14c), `autor_nome_publico` e `avatar_url`.
  * O trigger `trg_auth_users_criar_perfil` cria a linha ao registrar o usuário em `auth.users`, preservando `autor_id_publico`, `autor_nome_publico` e foto informados em `raw_user_meta_data`.
  * Política RLS: `auth.uid() = user_id` (`SELECT`, `INSERT`, `UPDATE`).
* **Bucket `avatars` (`storage.buckets` / `storage.objects`):**
  * Leitura pública (`avatars/<user_id>/avatar.webp`) e escrita (`INSERT`, `UPDATE`, `DELETE`) restrita à pasta `auth.uid()::text`.
* **`public.cadenas` (Acesso Privado por Usuário):**
  * Sem permissão para `anon`. Apenas o titular (`auth.uid() = user_id`) lê, insere/atualiza (`POST ?on_conflict=id`) ou remove suas ascensões e `notas_privadas`.
* **`public.excluir_minha_conta()` (LGPD e Apple 5.1.1(v)):**
  * Função `SECURITY DEFINER` executável por `authenticated` (`POST /rest/v1/rpc/excluir_minha_conta`). Remove os arquivos em `avatars/<auth.uid()>/` e apaga o registro em `auth.users`, cascateando `public.perfis` e `public.cadenas`.
* **`public.fila_interacoes` (Leitura Pública e Escrita Autenticada):**
  * **Leitura (`TO anon, authenticated`):** Qualquer cliente consulta alertas ativos, votos de grau e comentários pendentes.
  * **Escrita (`TO authenticated`):** `VOTO_GRAU`, `COMENTARIO`, `ALERTA_SEGURANCA` (`FAUNA`, `ROCHA_AGARRA_INSTAVEL`, `PROTECAO_PRECARIA`, `EXPOSICAO_E4_MAIS`) e `CONFIRMACAO_ALERTA` exigem sessão autenticada cujo `autor_id_publico` exista para `auth.uid()` em `public.perfis`. Reexecutar o script remove políticas e constraints antigas, migra `ABELHAS_INSETOS` $\rightarrow$ `FAUNA` e `RISCO_EXPOSICAO` $\rightarrow$ `EXPOSICAO_E4_MAIS`, e apaga registros `VIA_MOLHADA`.
  * **Limite de 1 Confirmação Positiva por Perfil:** O índice único parcial `idx_fila_confirmacao_positiva_unica_por_autor` e o trigger `trg_fila_validar_contribuicao_unica_alerta` impedem auto-confirmação pelo autor do alerta e mais de um `+1` pelo mesmo perfil no mesmo alerta.
  * **Sem Edição ou Exclusão pelo Cliente:** `anon` e `authenticated` não possuem `UPDATE` nem `DELETE` na fila; apenas `service_role` processa e limpa os lotes.
