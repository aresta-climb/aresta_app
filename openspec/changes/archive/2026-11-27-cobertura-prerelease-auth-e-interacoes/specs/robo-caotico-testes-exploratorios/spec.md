# Spec Delta

## ADDED Requirements

### Requirement: Isolamento de Estado e Alternância Multiplataforma por Semente
O ambiente do robô caótico SHALL reiniciar integralmente a sessão autenticada, a caderneta local, a fila de interações comunitárias e as preferências em memória a cada sessão, alternando deterministicamente a plataforma alvo (`TargetPlatform.android` ou `TargetPlatform.iOS`) e o estado inicial de autenticação conforme a `seed`.

#### Scenario: Alternância determinística entre Android e iOS por semente
- **WHEN** o robô caótico monta o cenário para sementes distintas
- **THEN** o ambiente DEVE alternar a plataforma do tema entre Android e iOS conforme a `seed`, tornando o botão de login com a Apple visível nas sessões iOS e oculto nas sessões Android sem vazar estado da sessão anterior.

#### Scenario: Simulação de cancelamento OAuth e falhas de rede na fila comunitária
- **WHEN** a sessão sorteia cancelamento voluntário do seletor OAuth ou aciona `alternarConectividade` para modo offline
- **THEN** o fake de autenticação DEVE simular cancelamento silencioso uma única vez sem impedir tentativas subsequentes e a fila comunitária DEVE reter mutações offline sem gerar falsos positivos de crash até o restabelecimento da conexão.

## MODIFIED Requirements

### Requirement: Exploração Caótica Determinística Guiada por Semente
O motor de testes exploratórios SHALL executar sequências de interações sobre o aplicativo completo utilizando um gerador pseudo-aleatório inicializado por uma semente (`seed`) explícita, garantindo que duas execuções sob a mesma `seed` e mesmo dataset inicial selecionem exatamente a mesma sequência de ações e tempos de avanço de quadro.

#### Scenario: Reprodução determinística da mesma semente
- **WHEN** o robô caótico é executado duas vezes consecutivas com a mesma `seed` e o mesmo dataset inicial em `flutter_test`
- **THEN** ambas as execuções DEVEM produzir a mesma lista ordenada de passos (`PassoRobo`) e atingir o mesmo estado final na árvore de navegação.

#### Scenario: Descoberta e sorteio de ações interativas e assíncronas
- **WHEN** o robô caótico executa um passo da caminhada exploratória
- **THEN** o motor DEVE inspecionar os widgets visíveis e atingíveis (`hitTestable`) na tela atual — incluindo botões padrão, bolhas de alerta (`BolhaEmojiAlertaVia`) e controles `GestureDetector` com `ValueKey<String>` e `onTap` ativo — e sortear entre ações de toque, rolagem, digitação de texto fuzz, acionamento de retorno (`AppNav.back` ou rota do sistema) e eventos externos simulados.

#### Scenario: Entradas de fuzzing para travessia de Magic Code OTP
- **WHEN** o robô caótico sorteia digitação de texto em campos da tela de autenticação sem senha
- **THEN** o conjunto de entradas fuzz DEVE incluir um endereço de e-mail válido, o código OTP numérico válido de 6 dígitos aceito pelo fake e um código inválido de 6 dígitos para exercitar tanto o avanço completo até a sessão autenticada quanto a exibição amigável de erro sem acionar `AppLogger.logError`.

### Requirement: Alimentação por Dataset Normal e Dataset Tóxico de Estresse
A infraestrutura de caos SHALL disponibilizar dois perfis determinísticos de dados iniciais (`normal` e `toxico`) com identificadores NanoID Base62 de 14 caracteres válidos para croquis, setores e escaladas, injetando efetivamente na montagem do cenário tanto `cadenasIniciais` na caderneta local quanto `interacoesIniciais` (alertas de segurança, votos de grau e comentários públicos).

#### Scenario: Execução exploratória sob Dataset Tóxico
- **WHEN** o robô é inicializado com o perfil `TipoDatasetCaos.toxico`
- **THEN** o estado inicial DEVE incluir picos sem setores, setores sem escaladas ou sem imagens, textos longos (300+ caracteres) com emojis e sintaxe Markdown limite, graus de escalada exóticos ou vazios, picos com alto volume de vias e registros de cadenas órfãs na Caderneta.

#### Scenario: Injeção real de cadenas e interações comunitárias iniciais na montagem do cenário
- **WHEN** o ambiente do robô monta o cenário inicial de qualquer perfil (`normal` ou `toxico`)
- **THEN** as cadenas de `cadenasIniciais` DEVEM estar persistidas no repositório da caderneta e os alertas de segurança, votos de grau e comentários de `interacoesIniciais` (próprios e de terceiros) DEVEM estar sincronizados no repositório de interações desde o primeiro quadro.
