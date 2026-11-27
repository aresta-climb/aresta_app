# Páginas (`lib/pages/`)

Este diretório contém as telas do aplicativo. As páginas montam a estrutura de `Scaffold` e conectam eventos ao ViewModel correspondente. Em todas as páginas secundárias, a barra superior utiliza `BotaoVoltarComRetornoInicio` (toque volta um nível; segurar retorna à Home).

---

## 1. Páginas

| Página | Arquivo | Responsabilidade |
|---|---|---|
| `HomePage` | `home.dart` | Tela inicial com bolha rápida de idioma (`BotaoBolhaIdioma`), busca global, carrossel de croquis baixados, carrossel dos 6 picos mais próximos (`"VER MAIS ->"`) e atualizações recentes. |
| `BrowsePage` | `explorar.dart` | Aba unificada `Explorar`: globo 3D/2D offline e terreno bicúbico em 4 LODs (`SuperficieGloboExplorar`) com botão opcional de bolhas de chuva/incêndio na seção `Mapa` (`BotaoCamadaClimaMapa`, iniciado desligado com aviso de `~85%` de acerto listando as 6 fontes meteorológicas/NASA e atalho `"Ver estatísticas"`), botão de localização GPS e voo parabólico, barra de busca com seletor rápido de grau (`BarraBuscaFiltrosExplorar`), gaveta ajustável em 3 estágios (`GavetaDeslizanteExplorar`: `Mapa`, `Dividir` e `Lista`), altimetria externa e alertas conservadores de 4 dias de chuva próxima. |
| `PaginaEstatisticasClima` | `estatisticas_clima.dart` | Página dedicada à memória de cálculo estatístico da taxa de referência de `~85%`: detalha as 6 fontes oficiais (Open-Meteo, RainViewer, INPE BDQueimadas e 3 missões públicas da NASA), o hindcast de 180 dias (`N = 5.133` pico-dias nos 29 picos entre `NOAA GFS 0.25°` e `ECMWF ERA5`), a matriz de contingência 2×2, o intervalo de confiança de 95% (`Z = 1,96`) e a conferência cruzada na Tabela Normal Padrão `Z` (`Φ(Z)`) com curva gaussiana da cauda direita (`GraficoDistribuicaoZClima`). |
| `MeusCroquisPage` | `meus_croquis.dart` | Lista de croquis salvos para leitura offline com remoção local. |
| `ComunidadePage` | `comunidade.dart` | Aba com links para canais externos do projeto (WhatsApp, Instagram, Discord, GitHub). |
| `PicoDetailsPage` | `pico.dart` | Página raiz de um guia com capa, bolha rápida de idioma (`BotaoBolhaIdioma`), cartão conservador de condição hídrica de 4 dias (`CartaoCondicaoHidricaPico`), status online/offline, busca interna, exclusão local e acesso a setores, mapas e subpáginas. |
| `SetoresPage` | `pico_subpages/setores_page.dart` | Catálogo de setores e escaladas do pico com abas por modalidade, filtros e ordenação. |
| `GrupoPage` | `grupo.dart` | Detalhes de um grupo de setores com capa, descrição, mapa, abas de modalidade e filtros. |
| `SetorPage` | `setor.dart` | Detalhes de um setor com capa, descrição, mapa, abas de modalidade e lista de escaladas. |
| `ViaPage` | `via.dart` | Página de detalhes de uma escalada (`ViaViewModel`), contendo cabeçalho, croqui, grau oficial, consenso e votação de grau, alertas de segurança, seção da caderneta, atributos técnicos, enfiadas, vídeos/betas, comentários e chave Pix. |
| `MapasCarrosselPage` | `mapas_carrossel.dart` | Carrossel horizontal entre instâncias de `MapaInterativoPage`. |
| `MapaInterativoPage` | `mapa_interativo.dart` | Visualizador de croqui com pan/zoom, traçados vetoriais, bolhas de alerta sobre as vias, cartão de seleção e botão para subir na hierarquia de mapas. |
| `GPSPage` | `gps.dart` | Tela auxiliar de coordenadas e localização. |
| `QRScannerPage` | `qr_scanner.dart` | Leitura de QR Codes para deep links e sessões do Editor Desktop. |
| `SettingsPage` | `configuracoes.dart` | Configuração de idioma (`CartaoPreferenciaIdioma`), tema, visibilidade das interações de perfil/caderneta e conexão com o Editor Desktop. |
| `SobreTimePage` | `sobre_time.dart` | Apresentação dos integrantes e colaboradores do projeto. |
| `ExplorarLocalPage` | `pico_subpages/explorar_local_page.dart` | Informações de acesso, época de escalada, aproximação e atalho para o Google Maps. |
| `ComunidadePicoPage` | `pico_subpages/comunidade_pico_page.dart` | Contatos locais e canais associados ao pico. |
| `ApoiePicoPage` | `pico_subpages/apoie_pico_page.dart` | Dados Pix e informações de manutenção das vias e trilhas do pico. |
| `TermosDeUsoPage` | `termos_de_uso.dart` | Leitura e aceite dos Termos de Uso e Política de Privacidade. |
| `LoginPage` | `login.dart` | Autenticação sem senha (Google, Apple no iOS e código OTP de 6 dígitos por e-mail) e atalho `"Abrir configurações do app"` (saltando `PerfilNode` enquanto desautenticado). |
| `HubPerfilCadernetaPage` | `hub_perfil_caderneta.dart` | Perfil do escalador com foto, edição de nome, 4 métricas (`CADENAS`, `TENTATIVAS`, `PICOS`, `VIAS`), configurações, privacidade, saída e exclusão de conta (`perfil.dart` exporta o alias `PerfilPage`). |
| `CadernetaPage` | `caderneta.dart` | Pirâmide de graus (vias e boulders), seção de alertas criados/confirmados pelo usuário e histórico de ascensões. |
| `TelaSplashInicial` | `tela_splash_inicial.dart` | Tela exibida na abertura a frio enquanto o destino inicial é resolvido. |
| `DatabaseMigrationScreen` | `tela_migracao_banco.dart` | Tela exibida durante migrações do armazenamento local. |

---

## 2. Modo Ponta a Ponta (*Edge-to-Edge*) e Recuos do Sistema

Com `SystemUiMode.edgeToEdge` ativo (`configurarExibicaoPontaAPonta`), páginas que desenham até a borda inferior aplicam `SafeArea` ou somam `MediaQuery.paddingOf(context).bottom` para não sobrepor botões flutuantes, `SnackBar`s (`DespachanteSnackBarSeguro`), rodapés ou avisos do Google Maps à barra de navegação do sistema.

---

## 3. Ciclo de Vida de `PicoDetailsPage`

`PicoDetailsPage` recebe `PicoViewModel` injetado com a instância compartilhada `DatasetRepository.servicoCroquiOnline`:
- **`initState`**: Registra o listener do ViewModel e inicia o polling de ETag quando o croqui está apenas em sessão online.
- **`didUpdateWidget`**: Ao receber nova instância de `PicoViewModel` via `PageListenableBuilder`, remove o listener anterior, cancela o polling em andamento, chama `dispose()` no ViewModel antigo e conecta o novo.
- **`dispose`**: Remove listeners, limpa `onBackInterceptor` se pertencer à instância atual e descarta o ViewModel.
