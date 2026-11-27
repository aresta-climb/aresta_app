# Tasks

## 1. Internacionalização (i18n)

- [x] 1.1 Adicionar as novas chaves `share*` em `frontend/lib/idioma/modelo_idioma_app.dart` e suas traduções em `dicionario_pt.dart`, `dicionario_en.dart`, `dicionario_es.dart`, `dicionario_de.dart` e `dicionario_nl.dart`, verificando com `flutter test test/idioma/`.

## 2. Modelo de Dados do Cartão

- [x] 2.1 Escrever os testes unitários em `frontend/test/data/modelos/dados_cartao_compartilhamento_test.dart` cobrindo Pico, Grupo, Setor, Escalada (com cascata de imagens, faixa de graus, contagens, modalidades e `SeloPessoalCompartilhamento` sem notas privadas) e implementar `frontend/lib/data/modelos/dados_cartao_compartilhamento.dart` verificando o passe dos testes.

## 3. Telemetria, Serviço de Compartilhamento e Fake Determinístico

- [x] 3.1 Adicionar o parâmetro `formato` (`'link'` / `'imagem_stories'`) em `TelemetryService.logCompartilharEntidade` (`frontend/lib/services/firebase/telemetria.dart`) e `MockTelemetryService`, validando em `frontend/test/services/firebase/telemetria_test.dart`.
- [x] 3.2 Criar `frontend/test/fakes/servico_compartilhamento_fake.dart` e seu teste espelhado `frontend/test/fakes/servico_compartilhamento_fake_test.dart` validando registros determinísticos de link, imagem PNG e clipboard além da simulação de erro.
- [x] 3.3 Evoluir `ServicoCompartilhamento` (`frontend/lib/services/compartilhamento/servico_compartilhamento.dart`) com `compartilharLinkPorDados`, `compartilharImagemStories` (cópia automática de URL para clipboard, envio PNG puro `image/png` e limpeza de diretório temporário) e `capturadorPadrao`, validando em `frontend/test/services/compartilhamento/servico_compartilhamento_test.dart`.
- [x] 3.4 Escrever os testes em `frontend/test/services/compartilhamento/capturador_imagem_cartao_test.dart` (usando `tester.runAsync` e caso Fail-Fast) e implementar `frontend/lib/services/compartilhamento/capturador_imagem_cartao.dart`, verificando o passe dos testes.

## 4. Cartão Editorial e Modal Unificado

- [x] 4.1 Escrever os testes de widget em `frontend/test/widgets/compartilhamento/cartao_compartilhamento_aresta_test.dart` (cobrindo as 4 entidades, pílula `LINHA #N`, selo de cadena/tentativa, assinatura discreta `arestaclimb.com` / `@arestaclimb`, ausência de QR Code e tema escuro) e implementar `frontend/lib/widgets/compartilhamento/cartao_compartilhamento_aresta.dart`.
- [x] 4.2 Escrever os testes de widget em `frontend/test/widgets/compartilhamento/modal_compartilhamento_entidade_test.dart` (preview ao vivo, ações Stories vs WhatsApp, toast orientativo, responsividade em `320x568` e ausência de `notasPrivadas`) e implementar `frontend/lib/widgets/compartilhamento/modal_compartilhamento_entidade.dart`.

## 5. Integração nas Páginas, Caderneta e Documentação

- [x] 5.1 Integrar o `ModalCompartilhamentoEntidade` em `pico.dart`, `grupo.dart`, `setor.dart`, `via.dart`, `via_view_model.dart` e `via_functions.dart` (incluindo botão rápido no selo de ascensão e ação `"Compartilhar"` no toast pós-registro da caderneta), atualizando `pico_test.dart`, `grupo_test.dart`, `setor_test.dart`, `via_test.dart` e `via_view_model_test.dart`.
- [x] 5.2 Atualizar `frontend/README.md` documentando os novos módulos e o fluxo unificado de compartilhamento para Stories e Link Rápido.

## 6. Verificação Integrada e Cobertura

- [x] 6.1 Executar `flutter analyze`, a suíte completa de testes afetados com `--coverage` (confirmando 100% de cobertura nos novos arquivos) e `openspec validate --specs`.

## Workflow follow-up

- Sincronizar a delta spec `compartilhamento-entidades` com `openspec/specs/compartilhamento-entidades/spec.md` e arquivar a mudança.
- Realizar `git commit` cirúrgico (isolando trabalho paralelo existente no workspace) e `git push`.
