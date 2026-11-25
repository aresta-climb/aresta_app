# Testes Arquiteturais (`test/architecture/`)

Este diretório contém testes estáticos sobre o código-fonte de `lib/` e configurações nativas para verificar regras de isolamento e estrutura.

## Arquivos

### 1. `isolamento_logs_arquitetura_test.dart`
Proíbe chamadas a `print()` ou `debugPrint()` em `lib/` fora de `lib/services/firebase/app_logger.dart`. Todo registro deve passar por `AppLogger.instance`.

### 2. `firebase_isolation_test.dart`
Proíbe importações de pacotes `firebase_*` fora de `lib/services/firebase/`.

### 3. `path_drawing_isolation_test.dart`
Restringe a importação de `package:path_drawing/` exclusivamente a `lib/utils/construtor_caminho_trajeto.dart`.

### 4. `android_manifest_test.dart`
Verifica permissões, intent-filters e declarações exigidas em `AndroidManifest.xml`.

### 5. `isolamento_cliente_http_test.dart`
Garante que apenas `lib/services/http/cliente_http_aresta.dart` importe `package:http/...` ou instancie clientes HTTP em `lib/`, proibindo `ClienteHttpAresta.paraTestes` e chamadas `.close()` no código de produção.

### 6. `isolamento_smoke_ci_test.dart`
Verifica que `lib/main.dart` e o restante do código de produção não importem `lib/services/smoke_ci/`.

### 7. `isolamento_mvvm_modulos_test.dart`
Verifica nos módulos migrados:
- Ausência de importações de `services/` em páginas e widgets declarativos (`login`, `caderneta`, `hub_perfil_caderneta`, `via`, `widgets/autenticacao`, `widgets/caderneta`, `widgets/navegacao`, `widgets/perfil`, `widgets/via` e funções visuais associadas).
- Ausência de dependências de `services/`, `view/`, `widgets/` ou `pages/` em `lib/data/modelos/`.
- Espelhamento 1:1 de arquivos `_test.dart` e limite de até 650 linhas por arquivo.
