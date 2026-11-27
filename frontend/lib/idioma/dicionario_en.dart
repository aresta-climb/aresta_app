// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'modelo_idioma_app.dart';

/// Dicionário completo em Inglês (`en-US`) com terminologia autêntica de escalada em rocha.
const Map<ChaveTexto, String> dicionarioIngles = {
  // Seletor de idioma
  ChaveTexto.seletorIdiomaTitulo: 'APP LANGUAGE',
  ChaveTexto.seletorIdiomaSubtitulo:
      'Choose the language displayed across all Aresta Climb screens.',
  ChaveTexto.seletorIdiomaTooltip: 'Switch app language',

  // Navegação e ações globais
  ChaveTexto.navInicio: 'HOME',
  ChaveTexto.navExplorar: 'EXPLORE',
  ChaveTexto.navMeusCroquis: 'MY TOPOS',
  ChaveTexto.navComunidade: 'COMMUNITY',
  ChaveTexto.navInicioCurto: 'Home',
  ChaveTexto.navGps: 'GPS',
  ChaveTexto.comumVoltar: 'Back',
  ChaveTexto.comumSegureParaInicio: 'Hold to jump to Home',
  ChaveTexto.comumFechar: 'Close',
  ChaveTexto.comumCancelar: 'Cancel',
  ChaveTexto.comumCancelarCaixaAlta: 'CANCEL',
  ChaveTexto.comumSalvar: 'Save',
  ChaveTexto.comumSalvarAlteracoes: 'Save Changes',
  ChaveTexto.comumExcluir: 'Delete',
  ChaveTexto.comumExcluirCaixaAlta: 'DELETE',
  ChaveTexto.comumEntendi: 'GOT IT',
  ChaveTexto.comumTentarNovamente: 'Try again',
  ChaveTexto.comumDesfazer: 'Undo',
  ChaveTexto.comumLimpar: 'Clear',
  ChaveTexto.comumAplicar: 'Apply',
  ChaveTexto.comumAplicarUmResultado: 'Apply (1 result)',
  ChaveTexto.comumAplicarVariosResultados: 'Apply ({total} results)',
  ChaveTexto.comumSemNome: 'Unnamed',
  ChaveTexto.comumSemNomeCaixaAlta: 'UNNAMED',
  ChaveTexto.comumLocalDesconhecido: 'UNKNOWN LOCATION',
  ChaveTexto.comumPico: 'Crag',
  ChaveTexto.comumSetor: 'Sector',
  ChaveTexto.comumGrupo: 'Area',
  ChaveTexto.comumOffline: 'Offline',
  ChaveTexto.comumSalvoOffline: 'Saved offline',
  ChaveTexto.comumSalvoOfflineCaixaAlta: 'SAVED OFFLINE',
  ChaveTexto.comumCatalogo: 'Catalog',
  ChaveTexto.comumAbrindo: 'Opening {titulo}...',
  ChaveTexto.comumBaixando: 'Downloading {nome}...',
  ChaveTexto.comumBaixadoSucesso: '{nome} downloaded',
  ChaveTexto.comumSalvoOfflineToast: '{nome} saved offline!',
  ChaveTexto.comumFalhaBaixar: 'Failed to download {nome}',
  ChaveTexto.comumSemConexao: 'No internet connection.',
  ChaveTexto.comumErroAbrirLink: 'Could not open link.',
  ChaveTexto.comumLinkCopiado: 'Link copied!',
  ChaveTexto.comumAbrirLink: 'OPEN LINK',
  ChaveTexto.comumAcessar: 'OPEN ',
  ChaveTexto.comumVerificandoAtualizacoes: 'Checking for updates...',
  ChaveTexto.comumErroVerificarAtualizacoes:
      'Error checking for updates. Please try again later.',
  ChaveTexto.comumConcluidoComFalhas: 'Completed with errors: {falhas}',
  ChaveTexto.comumCatalogoAtualizadoSucesso: 'Catalog updated successfully!',
  ChaveTexto.comumCatalogoJaAtualizado: 'Catalog is already up to date.',
  ChaveTexto.comumNenhumCroquiPrecisavaAtualizar: 'No topos needed updating.',
  ChaveTexto.comumCroquisAtualizados: 'Topos have been updated!',
  ChaveTexto.comumSincronizandoServing: 'Syncing with serving...',
  ChaveTexto.comumSemConexaoServing: 'No connection to serving.',
  ChaveTexto.comumErroSincronizarServing:
      'Error syncing with serving. Please try again later.',
  ChaveTexto.comumSincronizadoComFalhas: 'Synced with errors on: {falhas}',
  ChaveTexto.comumCatalogoAtualizadoServing: 'Catalog updated from serving!',
  ChaveTexto.comumCatalogoJaRecenteServing:
      'Catalog is already on the latest serving version.',
  ChaveTexto.comumVersaoDesatualizadaToast:
      'Your Aresta version is outdated. Update to keep downloading topos.',
  ChaveTexto.comumGuiaAtualizadoToast: 'The guide for {nome} was updated!',
  ChaveTexto.comumErroSincronizarDadosToast:
      'Error syncing data. Please try again later.',
  ChaveTexto.comumCroquisBaixadosAtualizadosToast:
      'Your downloaded topos have been updated!',
  ChaveTexto.comumAtualizadoAgora: 'updated just now',
  ChaveTexto.comumAtualizadoHaAno: 'updated 1 year ago',
  ChaveTexto.comumAtualizadoHaAnos: 'updated {n} years ago',
  ChaveTexto.comumAtualizadoHaMes: 'updated 1 month ago',
  ChaveTexto.comumAtualizadoHaMeses: 'updated {n} months ago',
  ChaveTexto.comumAtualizadoHaDia: 'updated 1 day ago',
  ChaveTexto.comumAtualizadoHaDias: 'updated {n} days ago',
  ChaveTexto.comumAtualizadoHaHora: 'updated 1 hour ago',
  ChaveTexto.comumAtualizadoHaHoras: 'updated {n} hours ago',
  ChaveTexto.comumAtualizadoHaMinuto: 'updated 1 minute ago',
  ChaveTexto.comumAtualizadoHaMinutos: 'updated {n} minutes ago',
  ChaveTexto.comumEnviarFeedbackTooltip: 'Send Feedback / Report Bug',
  ChaveTexto.comumFeedbackIndisponivelDev:
      'Feedback submission is unavailable in this development environment.',
  ChaveTexto.comumSincronizarServingTooltip: 'Sync with serving',
  ChaveTexto.comumBuscarPicosHint: 'Search crags to climb...',
  ChaveTexto.comumMapaGeral: 'Overview Map',

  // Sistema, prévia experimental, versão e migração
  ChaveTexto.sistemaModoExperimentalAtivo: 'EXPERIMENTAL MODE ACTIVE',
  ChaveTexto.sistemaSair: 'EXIT',
  ChaveTexto.sistemaSessaoPreviaEncerradaTitulo: 'Preview Session Ended',
  ChaveTexto.sistemaSessaoPreviaEncerradaCorpo:
      'The connection with Desktop Editor has ended. Since preview mode is temporary, we automatically restored the official Aresta Climb catalog for you.',
  ChaveTexto.sistemaFaseBetaTitulo: 'Open Beta Phase',
  ChaveTexto.sistemaFaseBetaIntro:
      'Aresta Climb is an independent initiative in active development alongside the climbing community.',
  ChaveTexto.sistemaFaseBetaItem1Titulo: 'Continuous new sectors & topos',
  ChaveTexto.sistemaFaseBetaItem1Corpo:
      'Our database of routes, boulders, topos, and maps grows and updates frequently.',
  ChaveTexto.sistemaFaseBetaItem2Titulo: 'Constantly evolving features',
  ChaveTexto.sistemaFaseBetaItem2Corpo:
      'Advanced filters, 3D navigation tools, and performance upgrades are on the way.',
  ChaveTexto.sistemaFaseBetaItem3Titulo: 'Community-driven build',
  ChaveTexto.sistemaFaseBetaItem3Corpo:
      'Your real-world feedback at the crag helps us refine details and prioritize what matters.',
  ChaveTexto.sistemaInstagramOficial: 'Official Instagram',
  ChaveTexto.sistemaComunidadeWhatsapp: 'WhatsApp Community',
  ChaveTexto.sistemaEnviarSugestao: 'Send Suggestion',
  ChaveTexto.sistemaRodapeVersaoBeta: 'Aresta Climb v{versao} (Open Beta)',
  ChaveTexto.sistemaAtualizeParaBaixar:
      'Update Aresta to resume downloading and syncing topos.',
  ChaveTexto.sistemaAtualizacaoRecomendada:
      'Recommended Update: a new version is available.',
  ChaveTexto.sistemaAtualizar: 'UPDATE',
  ChaveTexto.sistemaAtualizacaoNecessaria: 'UPDATE\nREQUIRED',
  ChaveTexto.sistemaVersaoAntigaCorpo:
      'Your version of Aresta is outdated and no longer supported. To keep using the app and exploring topos, please update from the store.',
  ChaveTexto.sistemaAtualizarAgora: 'UPDATE NOW',
  ChaveTexto.sistemaPreviaFalhaConectar:
      'Could not connect to preview session "{codigo}".',
  ChaveTexto.sistemaDeepLinkNaoEncontrado:
      'Could not find the route or sector for code "{uid}". Check your internet connection or download the crag first.',
  ChaveTexto.sistemaMigracaoVerificando: 'Checking internet connection...',
  ChaveTexto.sistemaMigracaoBaixando: 'Downloading updated topo catalog...',
  ChaveTexto.sistemaMigracaoErro:
      'Could not update the database. Please check your internet connection.',
  ChaveTexto.sistemaMigracaoTitulo: 'DATABASE UPDATE',
  ChaveTexto.sistemaMigracaoCorpo:
      'This new app version includes structural updates to the topo catalog and needs to sync online once.',

  // Página Inicial (Home) e Busca Global
  ChaveTexto.homeMeuPerfilTooltip: 'My Profile',
  ChaveTexto.homeConfiguracoesTooltip: 'Settings',
  ChaveTexto.homeSincronizarTooltip: 'Sync catalog and topos',
  ChaveTexto.homeBoasVindas: 'WELCOME!',
  ChaveTexto.homeBoraPraPedra: 'READY TO CLIMB?',
  ChaveTexto.homeDescricaoHeroi:
      'The definitive outdoor climbing guide. Explore local crags, routes, and boulders, and save full topos for 100% offline access.',
  ChaveTexto.homeBuscaHint: 'Search crags, sectors, or routes...',
  ChaveTexto.homeErroAbrirSalvo:
      'Error opening saved topo. Please try syncing again.',
  ChaveTexto.homeCroquiNaoSalvoOffline:
      'This topo is not saved offline yet. Connect to the internet to open it.',
  ChaveTexto.homeMaisProximosTitulo: 'CLOSEST TO YOU',
  ChaveTexto.homePermitaLocalizacao:
      'Allow location access to see the crags closest to you.',
  ChaveTexto.homePermitirLocalizacaoBtn: 'Allow Location',
  ChaveTexto.homeAguardandoGps: 'Waiting for GPS signal...',
  ChaveTexto.homeNenhumPicoLocalizado: 'No crags with coordinates found.',
  ChaveTexto.homeVerMais: 'SEE MORE ->',
  ChaveTexto.homeComoFunciona: 'HOW IT WORKS',
  ChaveTexto.homeGuiaRapidoTitulo: 'ARESTA QUICK GUIDE',
  ChaveTexto.homeGuiaRapidoSubtitulo:
      'Everything you need to go straight from the app to the rock.',
  ChaveTexto.homePasso1Titulo: 'FIND THE CRAG',
  ChaveTexto.homePasso1Desc:
      'Check drive time in the carousel or explore the 3D/2D Geoid with terrain, live GPS, storm radar, wildfire tracking, and rock wetness.',
  ChaveTexto.homePasso2Titulo: 'SAVE OFFLINE',
  ChaveTexto.homePasso2Desc:
      'Open any crag instantly while online or download the full guide to navigate 100% offline at the cliff base.',
  ChaveTexto.homePasso3Titulo: 'INTERACTIVE TOPO',
  ChaveTexto.homePasso3Desc:
      'Tap route lines on the wall photo to check grades and bolts, and view or report live rock hazards (🐝, 🪨, 🔩, ⚠️).',
  ChaveTexto.homePasso4Titulo: 'LOGBOOK & COMMUNITY',
  ChaveTexto.homePasso4Desc:
      'Log sends, vote on grade consensus, and expand community beta videos & notes only when you want (collapsed by default against spoilers).',
  ChaveTexto.homePasso5Titulo: 'FAST JUMP TO HOME',
  ChaveTexto.homePasso5Desc:
      'Tap back (←) to go up one level, or press and hold the back button to jump straight back to Home.',
  ChaveTexto.homePasso6Titulo: 'SHARE',
  ChaveTexto.homePasso6Desc:
      'Send direct links for routes, sectors, and crags so your climbing partners open them right in the app or browser.',
  ChaveTexto.homeConservacaoTitulo: 'CONSERVATION & ACCESS',
  ChaveTexto.homeConservacaoCorpo:
      'Crag access depends on care, ethics, and respect for local communities. Every area has its rules, stewards, and history. Climbing responsibly keeps our crags open.',
  ChaveTexto.buscaTodos: 'All',
  ChaveTexto.buscaPicos: 'Crags',
  ChaveTexto.buscaSetores: 'Sectors',
  ChaveTexto.buscaDica:
      'Tip: search by crags, sectors, routes, or grades (e.g. 7a, V4)',
  ChaveTexto.buscaNenhumResultado: 'No results found.',
  ChaveTexto.buscaFiltroPrefixo: 'Filter: {filtro}',

