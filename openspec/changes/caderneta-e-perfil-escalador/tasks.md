# Tasks

## 1. Modelos de Domínio e Enums Esportivos (TDD)

- [x] 1.1 [RED] Escrever testes unitários em `frontend/test/data/modelos/tipo_ascensao_test.dart` e `frontend/test/data/modelos/tipo_escalada_test.dart` cobrindo valores, rótulos, `isCadena`, `prioridadeVisual` e serialização
- [x] 1.2 [GREEN] Implementar os enums `TipoAscensao` e `TipoEscalada` em `frontend/lib/data/modelos/tipo_ascensao.dart` e `frontend/lib/data/modelos/tipo_escalada.dart`
- [x] 1.3 [RED] Escrever testes unitários em `frontend/test/data/modelos/cadena_test.dart` validando UUID v4, associação direta com `escaladaUid` (NanoID 14c), validação e corte de `notasPrivadas` (máx. 200 chars), tentativas (mínimo 1), serialização `toMap`/`fromMap`, `toJson`/`fromJson` e `copyWith`
- [x] 1.4 [GREEN] Implementar a entidade imutável `Cadena` em `frontend/lib/data/modelos/cadena.dart`
- [x] 1.5 [RED] Escrever testes unitários em `frontend/test/data/modelos/perfil_escalador_test.dart` validando `autorIdPublico` (NanoID 14c Base62), apelido padrão/customizado e serialização
- [x] 1.6 [GREEN] Implementar a entidade imutável `PerfilEscalador` em `frontend/lib/data/modelos/perfil_escalador.dart`
- [x] 1.7 [REFACTOR] Documentar todos os modelos com docstrings (`///`) abrangentes em português e verificar 100% de cobertura nos testes de domínio

## 2. Repositório Reativo e Agregação de Estatísticas (TDD)

- [x] 2.1 [RED] Escrever testes unitários em `frontend/test/services/caderneta/estatisticas_caderneta_test.dart` validando cálculos de totais, contagem por estilo, agrupamento de pirâmide de graduação de vias e boulders, e identificação dos maiores graus
- [x] 2.2 [GREEN] Implementar a classe de valor `EstatisticasCaderneta` em `frontend/lib/services/caderneta/estatisticas_caderneta.dart`
- [x] 2.3 [RED] Escrever testes unitários em `frontend/test/services/caderneta/repositorio_caderneta_test.dart` cobrindo armazenamento local atômico, reatividade com `ValueListenable`, operações CRUD (`salvarCadena`, `excluirCadena`), filtro por `escaladaUid` e algoritmo de `obterMelhorAscensao`
- [x] 2.4 [GREEN] Implementar `RepositorioCaderneta` e sua implementação concreta `RepositorioCadernetaLocal` em `frontend/lib/services/caderneta/repositorio_caderneta.dart`
- [x] 2.5 [REFACTOR] Documentar a camada de serviços com docstrings explicando o padrão offline-first e compatibilidade com futura sincronização PowerSync

## 3. Modal de Registro de Cadena e Badging na Via (TDD)

- [x] 3.1 [RED] Escrever testes de widget em `frontend/test/widgets/caderneta/modal_registro_cadena_test.dart` cobrindo apresentação de chips de estilo, contador de tentativas, seletor de data, contador de limite de 200 caracteres para notas privadas e callback de salvamento
- [x] 3.2 [GREEN] Implementar o widget `ModalRegistroCadena` em `frontend/lib/widgets/caderneta/modal_registro_cadena.dart`
- [x] 3.3 [RED] Escrever testes de widget em `frontend/test/pages/via_test.dart` e de unidade em `frontend/test/view/function_library/via_functions_test.dart` cobrindo exibição do selo visual da melhor cadena alcançada e abertura do modal de registro
- [x] 3.4 [GREEN] Integrar o selo esportivo visual e o botão de registro de cadena em `frontend/lib/pages/via.dart` e `frontend/lib/view/function_library/via_functions.dart`
- [x] 3.5 [REFACTOR] Adicionar docstrings e validar acessibilidade e contraste das cores esportivas no tema dark Aresta

## 4. Tela de Perfil do Escalador e Pirâmide de Graus (TDD)

- [x] 4.1 [RED] Escrever testes unitários em `frontend/test/view/view_models/perfil_view_model_test.dart` cobrindo fluxo MVVM, reatividade com o repositório, carregamento e atualização do perfil e das estatísticas
- [x] 4.2 [GREEN] Implementar `PerfilViewModel` em `frontend/lib/view/view_models/perfil_view_model.dart`
- [x] 4.3 [RED] Escrever testes de widget em `frontend/test/widgets/caderneta/grafico_piramide_graus_test.dart` e `card_estatistica_test.dart` validando renderização proporcional das barras da pirâmide e formatação dos números
- [x] 4.4 [GREEN] Implementar `GraficoPiramideGraus` e `CardEstatistica` em `frontend/lib/widgets/caderneta/`
- [x] 4.5 [RED] Escrever testes de widget em `frontend/test/pages/perfil_test.dart` cobrindo cabeçalho com cópia de `autorIdPublico`, alternância de modalidades (Vias / Boulders), lista de histórico cronológico e exclusão de cadena com confirmação
- [x] 4.6 [GREEN] Implementar `PerfilPage` em `frontend/lib/pages/perfil.dart`
- [x] 4.7 [REFACTOR] Documentar todos os componentes com docstrings e garantir conformidade visual e responsividade

## 5. Roteamento, Verificação Completa e Governança

- [x] 5.1 Adicionar rota e atalho para o `PerfilPage` na navegação do aplicativo
- [x] 5.2 Executar a suíte completa de testes (`flutter test --coverage`) e verificar 100% de cobertura de testes nos novos arquivos sem quebra de testes existentes
- [x] 5.3 Atualizar os arquivos `README.md` pertinentes refletindo o novo módulo de Caderneta e Perfil
