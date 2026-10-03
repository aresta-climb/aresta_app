## Why

Conquistadores e mantenedores de vias de escalada necessitam de uma forma rápida e contextualizada de auditar e registrar manutenções em proteções fixas (grampos, chapeletas e paradas) no aplicativo parceiro Fixalog diretamente a partir dos detalhes da via no Aresta Climb. Hoje não há integração entre os aplicativos nem opção de habilitar ferramentas voltadas para mantenedores nas configurações do app.

## What Changes

- **Nova configuração "Ferramentas para Mantenedores"**: Adicionado um card na tela de Configurações (`SettingsPage`) com um interruptor (Switch) desativado por padrão, persistido localmente via `shared_preferences`.
- **Gerenciador reativo de estado**: Criação de `ConfiguracaoMantenedorController` com `ValueNotifier<bool>` para propagar o estado da configuração instantaneamente sem reiniciar o app.
- **Utilitário de geração de Deep Link Fixalog**: Função para construir a URL padronizada em `https://fixalog.arestaclimb.com/<pico_id>/<setor_slug>/<via_slug>` (ou com `<grupo_slug>`), espelhando a hierarquia e slugificação do Aresta Climb.
- **Botão "Manutenir no Fixalog" na página da via**: Na tela de detalhes da escalada (`ViaPage`), no bloco de "Histórico & Conquista", exibe o botão quando a configuração estiver ativa, permitindo abrir o link via `url_launcher` (Universal/App Links com fallback web).
- **Tratamento de fallback e telemetria**: Registro de telemetria da ação de abertura e feedback amigável via `SnackBar` caso a URL não possa ser aberta.

## Capabilities

### New Capabilities
- `ferramentas-mantenedor-fixalog`: Adiciona a preferência de "Ferramentas para Mantenedores" nas configurações do app e o botão contextual "Manutenir no Fixalog" na página de detalhes de escaladas, com geração de deep link padronizado.

### Modified Capabilities
<!-- Nenhuma especificação existente teve seus requisitos alterados. -->

## Impact

- **Código Afetado**:
  - `frontend/lib/pages/settings.dart` e `frontend/lib/view_functions/settings_functions.dart` (novo card de configuração).
  - `frontend/lib/pages/via.dart` e `frontend/lib/view_functions/via_functions.dart` (botão no bloco Histórico & Conquista).
  - `frontend/lib/services/configuracao_mantenedor_controller.dart` (novo controlador singleton de configuração).
  - `frontend/lib/utils/fixalog_link_utils.dart` (gerador do link do Fixalog).
- **Dependências**: Reutiliza `shared_preferences`, `url_launcher` e `slug_utils` já existentes no projeto.
- **APIs/Contratos**: Não altera APIs remotas nem estruturas do Protobuf.
