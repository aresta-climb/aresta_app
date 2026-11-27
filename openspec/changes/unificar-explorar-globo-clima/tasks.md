## 1. Infraestrutura SQL/Supabase e Sementes Offline de Geometria e Altimetria

- [x] 1.1 Criar o script SQL idempotente `docs/arquitetura/sql/supabase_clima_e_altimetria_picos.sql` definindo `public.estado_clima_picos` e `public.snapshots_altimetria_picos` com slots `'atual'` e `'copia_seguranca'`, funções transacionais de rotação atômica (que atualizam a cópia de segurança e descartam dados antigos), políticas RLS de leitura pública e agendamento `pg_cron` (3h)
- [x] 1.2 Criar utilitário offline `frontend/tool/gerar_malha_geografica_offline.dart` (com teste espelhado) com rotação de 1 cópia de segurança (`.seguranca.json`) caso IBGE ou NASA estejam offline, gerando `frontend/assets/geometria/malha_globo_brasil.json` (`< 400 KB`) e `frontend/assets/dados/altimetria_picos_inicial.json` (NASA SRTM 30m / NASADEM), registrando-os no `pubspec.yaml`

## 2. Domínio de Clima (RainTracker), Altimetria e Fakes Determinísticos (TDD)

- [x] 2.1 Escrever testes comportamentais em `frontend/test/services/clima/calculadora_umidade_pico_test.dart` cobrindo a curva de 5 dias (`2d -> 2d -> 1d -> Seco`), múltiplos eventos de chuva, encolhimento de bolhas e ausência de alerta em picos secos, e implementar `frontend/lib/services/clima/calculadora_umidade_pico.dart`
- [x] 2.2 Escrever testes para o armazenamento local com rotação de cópia única de segurança (`atual` + `copia_seguranca`, descarte do antigo e recuperação automática em corrupção) em `frontend/test/services/clima/armazenamento_clima_local_test.dart` (usando `Directory.systemTemp` real) e implementar `frontend/lib/services/clima/armazenamento_clima_local.dart`
- [x] 2.3 Criar a biblioteca `test-only` `frontend/test/fakes/cliente_clima_altimetria_fake.dart` com seu respectivo teste espelhado `frontend/test/fakes/cliente_clima_altimetria_fake_test.dart` validando contrato, TTL e simulação determinística de falhas de rede
- [x] 2.4 Escrever testes de integração HTTP local (`HttpServer.bind(InternetAddress.loopbackIPv4, 0)`) em `frontend/test/services/clima/servico_clima_altimetria_test.dart` e implementar `frontend/lib/services/clima/servico_clima_altimetria.dart` usando `ClienteHttpAresta`

## 3. Agregação Offline de Graus no Catálogo e Evolução do `BrowseViewModel` (TDD)

- [x] 3.1 Escrever testes em `frontend/test/services/catalogo/perfis_grau_catalogo_test.dart` validando a extração rápida de faixas de grau de Vias (`1º–12a`) e Boulder (`V0–V15`) por `croqui_uid`/`id_slug` a partir de um `catalogo.db` SQLite real temporário, e implementar a consulta em `frontend/lib/services/catalogo/repositorio_catalogo.dart`
- [x] 3.2 Atualizar e expandir `frontend/test/view/view_models/explorar_view_model_test.dart` (Red-Green-Refactor) para cobrir filtragem combinada por faixa de grau (`Via` e `Boulder`), multi-seleção de modalidades (`Esportiva`, `Boulder`, `Móvel / Trad`, `Paredão`, `Highline`), raio de distância, apenas offline, estado de umidade contextual, altitude por pico e seleção sincronizada mapa-lista, implementando em `frontend/lib/view/view_models/explorar_view_model.dart` e `card_croqui_view_model.dart`

## 4. Motor Gráfico de Globo e Relevo em 4 LODs (`< 4ms`/frame) (TDD)

- [x] 4.1 Escrever testes unitários da matemática de projeção contínua (`3D` esférica/inclinada e `2D` plana), culling de horizonte, transição de 4 LODs, arco de voo parabólico (`Fly-To`) e prevenção de colisão de rótulos em `frontend/test/widgets/explorar/controlador_camera_globo_test.dart`, e implementar `frontend/lib/widgets/explorar/controlador_camera_globo.dart`
- [x] 4.2 Escrever testes para o carregador/decodificador da malha geográfica e gerador procedural determinístico de relevo local (`LOD 2` e `LOD 3`) em `frontend/test/widgets/explorar/malha_relevo_lod_test.dart`, e implementar `frontend/lib/widgets/explorar/malha_relevo_lod.dart`
- [x] 4.3 Escrever `testWidgets` em `frontend/test/widgets/explorar/superficie_globo_explorar_test.dart` validando gestos de rotação com inércia, zoom entre os 4 LODs, renderização das bolhas de chuva, alternância `3D/2D`, onda sonar no toque de pino e centro óptico acoplado à gaveta, e implementar `frontend/lib/widgets/explorar/superficie_globo_explorar.dart`

## 5. Barra de Busca com Seletor de Grau, Modal de Filtros e Gaveta Sincronizada (TDD)

- [x] 5.1 Escrever `testWidgets` em `frontend/test/widgets/explorar/barra_busca_filtros_explorar_test.dart` cobrindo busca textual, popover rápido do botão `Grau`, chips ativos removíveis e abertura do modal completo `Filtros e Ordenação` (com tag `Paredão`), e implementar `frontend/lib/widgets/explorar/barra_busca_filtros_explorar.dart`
- [x] 5.2 Escrever `testWidgets` em `frontend/test/widgets/explorar/gaveta_deslizante_explorar_test.dart` validando as 3 posições de encaixe (`Mapa`, `Dividir`, `Lista`), auto-scroll animado ao selecionar pino no mapa, destaque temporário no card e exibição estritamente contextual do alerta de chuva + altitude, e implementar `frontend/lib/widgets/explorar/gaveta_deslizante_explorar.dart`
- [x] 5.3 Atualizar `frontend/test/pages/explorar_test.dart` e integrar a nova experiência unificada em `frontend/lib/pages/explorar.dart` e `frontend/lib/view/function_library/funcoes_explorar.dart`

## 6. Remoção Limpa de `MapaGlobalPage` e Verificação Final 100%

- [x] 6.1 Remover `MapaGlobalPage`, `MapaGlobalViewModel`, `MapaGlobalNode`, `AppNav.toMapaGlobal`, helpers exclusivos e respectivos arquivos de teste obsoletos, atualizando `construtor_view_arvore.dart` e testes de navegação afetados
- [x] 6.2 Atualizar os arquivos `README.md` impactados (`frontend/lib/pages/README.md`, `frontend/lib/services/README.md`, `frontend/lib/navigation/README.md`, `docs/arquitetura/sql/README.md`) com linguagem simples, objetiva e em português
- [x] 6.3 Executar `flutter analyze` (zero avisos) e `flutter test --coverage` validando 100% de cobertura comportamental em todos os arquivos criados e modificados
