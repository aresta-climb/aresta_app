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

