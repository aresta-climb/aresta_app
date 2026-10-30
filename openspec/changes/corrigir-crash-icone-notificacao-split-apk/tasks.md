# Tasks

## 1. Biblioteca de Fake Determinístico e Remoção do `largeIcon` em `GerenciadorNotificacaoDownload`

- [ ] 1.1 Criar o Fake determinístico `frontend/test/fakes/plugin_notificacoes_locais_fake.dart` e seu teste espelhado `frontend/test/fakes/plugin_notificacoes_locais_fake_test.dart`, verificando que passam em `flutter test test/fakes/plugin_notificacoes_locais_fake_test.dart` com 100% de cobertura.
- [ ] 1.2 Seguindo TDD (Red-Green-Refactor) e a Regra do Escoteiro (`AGENTS.md`), refatorar `frontend/test/services/notificacoes/gerenciador_notificacao_download_test.dart` para usar `PluginNotificacoesLocaisFake` (sem `mocktail`) e exigir que `largeIcon` seja `null` em `atualizarProgresso`, `notificarConclusao` e `notificarFalha`, verificando que o teste falha (*Red*).
- [ ] 1.3 Remover `iconeBitmapRaster = 'ic_launcher_foreground'` e `largeIcon: const DrawableResourceAndroidBitmap(iconeBitmapRaster)` de `frontend/lib/services/notificacoes/gerenciador_notificacao_download.dart` (mantendo `icon: iconePequeno` e `startForegroundService`), verificando que `flutter test --coverage test/services/notificacoes/gerenciador_notificacao_download_test.dart` passa com 100% de cobertura (*Green*).
- [ ] 1.4 Atualizar a documentação em `frontend/lib/services/README.md` se aplicável para refletir o uso exclusivo do ícone principal `@mipmap/ic_launcher` nas notificações de download.

## 2. Reativação do Resource Shrinking no Build de Release Android

- [ ] 2.1 Reativar `isShrinkResources = true` no bloco `buildTypes.release` de `frontend/android/app/build.gradle.kts` e verificar que `flutter analyze` executa sem alertas ou erros.
