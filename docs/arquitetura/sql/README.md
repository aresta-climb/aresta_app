# Configuração do Banco de Dados Supabase e PowerSync — Aresta Climb

Este diretório contém os artefatos executáveis de banco de dados para habilitar **Contas Opcionais de Escaladores**, **Backup Privado da Caderneta Esportiva** e **Interações Comunitárias / Alertas de Segurança estilo Waze** em conformidade com a [Arquitetura Unificada v3.0](../mds/arquitetura_unificada_contas_cadenas_uids.md).

---

## 1. Arquivos

| Arquivo | Finalidade |
| :--- | :--- |
| `supabase_contas_cadenas_interacoes.sql` | Script DDL + RLS idempotente para execução direta no **SQL Editor** do Supabase (`perfis`, `cadenas`, `fila_interacoes`, gatilho `auth.users` e publicação `powersync`). |
| `powersync_sync_rules.yaml` | Regras de bucket individual (`bucket_usuario`) para colar no painel do PowerSync Cloud / Self-Hosted. |

---

## 2. Passo a Passo de Implantação no Supabase

1. Acesse o painel do projeto no **Supabase Dashboard** $\rightarrow$ **SQL Editor** $\rightarrow$ **New Query**.
2. Copie todo o conteúdo de `supabase_contas_cadenas_interacoes.sql`, cole no editor e clique em **Run**.
   * *Nota:* O script é **100% idempotente** — pode ser reexecutado com segurança sem duplicar políticas, gatilhos ou índices.
3. Em **Authentication** $\rightarrow$ **Providers**, habilite os provedores desejados para criação opcional de conta:
   * **Email** (Magic Link / OTP ou senha) para login universal sem fricção.
   * **Google** / **Apple** (quando configurados para Android e iOS).
4. *(Quando conectar o PowerSync)* Copie o conteúdo de `powersync_sync_rules.yaml` para a aba **Sync Rules** do painel PowerSync apontando para a publicação lógica `powersync` criada pelo script SQL.

---

## 3. Resumo do Modelo de Segurança (RLS)

* **`public.perfis` (Somente Autenticado):**
  * Cada conta em `auth.users` recebe automaticamente sua linha em `public.perfis` via trigger `trg_auth_users_criar_perfil`.
  * Se o escalador já usava o app offline antes de criar conta, o `autor_id_publico` (NanoID 14c) e o `autor_nome_publico` locais enviados em `raw_user_meta_data` são preservados automaticamente na criação da conta.
  * Política RLS: `auth.uid() = user_id`.
* **`public.cadenas` (Backup Estritamente Privado):**
  * Nenhuma leitura pública é permitida (`REVOKE ALL FROM anon`). Apenas o próprio atleta (`auth.uid() = user_id`) lê, insere, edita ou exclui suas ascensões e `notas_privadas`.
* **`public.fila_interacoes` (Duas Camadas de Permissão):**
  * **Votos de Grau (`VOTO_GRAU`) e Comentários (`COMENTARIO`):** Exigem usuário autenticado (`TO authenticated`) cujo `autor_id_publico` pertença ao seu registro em `public.perfis`.
  * **Alertas de Segurança estilo Waze (`ALERTA_SEGURANCA`) e Confirmações *"Ainda está lá?"* (`CONFIRMACAO_ALERTA`):** Liberados também para usuários sem conta (`TO anon, authenticated`) identificados pelo NanoID 14c local do aparelho, garantindo que nenhum escalador enfrente barreira de login para reportar ou confirmar riscos de vida na rocha (abelhas/marimbondos, bloco solto, grampo precário, via molhada ou exposição).
  * **Imutabilidade pelo Cliente:** Usuários `anon` e `authenticated` não possuem permissão de `UPDATE` ou `DELETE` na fila; somente o *Aresta Bot* (`service_role`) consome e expurga os lotes consolidados no Git (`aresta_db`).
