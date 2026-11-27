// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'modelo_idioma_app.dart';

/// Dicionário completo em Alemão (`de-DE`) com terminologia autêntica de escalada em rocha.
const Map<ChaveTexto, String> dicionarioAlemao = {
  // Seletor de idioma
  ChaveTexto.seletorIdiomaTitulo: 'APP-SPRACHE',
  ChaveTexto.seletorIdiomaSubtitulo:
      'Wähle die Sprache für alle Ansichten in Aresta Climb.',
  ChaveTexto.seletorIdiomaTooltip: 'App-Sprache wechseln',

  // Navegação e ações globais
  ChaveTexto.navInicio: 'START',
  ChaveTexto.navExplorar: 'ENTDECKEN',
  ChaveTexto.navMeusCroquis: 'MEINE TOPOS',
  ChaveTexto.navComunidade: 'COMMUNITY',
  ChaveTexto.navInicioCurto: 'Start',
  ChaveTexto.navGps: 'GPS',
  ChaveTexto.comumVoltar: 'Zurück',
  ChaveTexto.comumSegureParaInicio: 'Gedrückt halten für Startseite',
  ChaveTexto.comumFechar: 'Schließen',
  ChaveTexto.comumCancelar: 'Abbrechen',
  ChaveTexto.comumCancelarCaixaAlta: 'ABBRECHEN',
  ChaveTexto.comumSalvar: 'Speichern',
  ChaveTexto.comumSalvarAlteracoes: 'Änderungen speichern',
  ChaveTexto.comumExcluir: 'Löschen',
  ChaveTexto.comumExcluirCaixaAlta: 'LÖSCHEN',
  ChaveTexto.comumEntendi: 'VERSTANDEN',
  ChaveTexto.comumTentarNovamente: 'Erneut versuchen',
  ChaveTexto.comumDesfazer: 'Rückgängig',
  ChaveTexto.comumLimpar: 'Zurücksetzen',
  ChaveTexto.comumAplicar: 'Anwenden',
  ChaveTexto.comumAplicarUmResultado: 'Anwenden (1 Treffer)',
  ChaveTexto.comumAplicarVariosResultados: 'Anwenden ({total} Treffer)',
  ChaveTexto.comumSemNome: 'Unbenannt',
  ChaveTexto.comumSemNomeCaixaAlta: 'UNBENANNT',
  ChaveTexto.comumLocalDesconhecido: 'ORT UNBEKANNT',
  ChaveTexto.comumPico: 'Felsgebiet',
  ChaveTexto.comumSetor: 'Sektor',
  ChaveTexto.comumGrupo: 'Teilgebiet',
  ChaveTexto.comumOffline: 'Offline',
  ChaveTexto.comumSalvoOffline: 'Offline gespeichert',
  ChaveTexto.comumSalvoOfflineCaixaAlta: 'OFFLINE VERFÜGBAR',
  ChaveTexto.comumCatalogo: 'Katalog',
  ChaveTexto.comumAbrindo: 'Öffne {titulo}...',
  ChaveTexto.comumBaixando: 'Lade {nome} herunter...',
  ChaveTexto.comumBaixadoSucesso: '{nome} heruntergeladen',
  ChaveTexto.comumSalvoOfflineToast: '{nome} offline gespeichert!',
  ChaveTexto.comumFalhaBaixar: 'Fehler beim Laden von {nome}',
  ChaveTexto.comumSemConexao: 'Keine Internetverbindung.',
  ChaveTexto.comumErroAbrirLink: 'Link konnte nicht geöffnet werden.',
  ChaveTexto.comumLinkCopiado: 'Link kopiert!',
  ChaveTexto.comumAbrirLink: 'LINK ÖFFNEN',
  ChaveTexto.comumAcessar: 'ÖFFNEN ',
  ChaveTexto.comumVerificandoAtualizacoes: 'Suche nach Updates...',
  ChaveTexto.comumErroVerificarAtualizacoes:
      'Fehler beim Prüfen auf Updates. Bitte später erneut versuchen.',
  ChaveTexto.comumConcluidoComFalhas: 'Mit Fehlern abgeschlossen: {falhas}',
  ChaveTexto.comumCatalogoAtualizadoSucesso: 'Katalog erfolgreich aktualisiert!',
  ChaveTexto.comumCatalogoJaAtualizado: 'Katalog ist bereits aktuell.',
  ChaveTexto.comumNenhumCroquiPrecisavaAtualizar:
      'Keine Topos mussten aktualisiert werden.',
  ChaveTexto.comumCroquisAtualizados: 'Topos wurden aktualisiert!',
  ChaveTexto.comumSincronizandoServing: 'Synchronisiere mit Server...',
  ChaveTexto.comumSemConexaoServing: 'Keine Verbindung zum Server.',
  ChaveTexto.comumErroSincronizarServing:
      'Synchronisierung fehlgeschlagen. Bitte später erneut versuchen.',
  ChaveTexto.comumSincronizadoComFalhas:
      'Synchronisiert mit Fehlern bei: {falhas}',
  ChaveTexto.comumCatalogoAtualizadoServing: 'Katalog vom Server aktualisiert!',
  ChaveTexto.comumCatalogoJaRecenteServing:
      'Katalog ist bereits auf dem neuesten Stand.',
  ChaveTexto.comumVersaoDesatualizadaToast:
      'Deine Aresta-Version ist veraltet. Bitte aktualisiere die App, um weiterhin Topos zu laden.',
  ChaveTexto.comumGuiaAtualizadoToast:
      'Der Führer für {nome} wurde aktualisiert!',
  ChaveTexto.comumErroSincronizarDadosToast:
      'Fehler beim Synchronisieren. Bitte später erneut versuchen.',
  ChaveTexto.comumCroquisBaixadosAtualizadosToast:
      'Deine gespeicherten Topos wurden aktualisiert!',
  ChaveTexto.comumAtualizadoAgora: 'gerade aktualisiert',
  ChaveTexto.comumAtualizadoHaAno: 'vor 1 Jahr aktualisiert',
  ChaveTexto.comumAtualizadoHaAnos: 'vor {n} Jahren aktualisiert',
  ChaveTexto.comumAtualizadoHaMes: 'vor 1 Monat aktualisiert',
  ChaveTexto.comumAtualizadoHaMeses: 'vor {n} Monaten aktualisiert',
  ChaveTexto.comumAtualizadoHaDia: 'vor 1 Tag aktualisiert',
  ChaveTexto.comumAtualizadoHaDias: 'vor {n} Tagen aktualisiert',
  ChaveTexto.comumAtualizadoHaHora: 'vor 1 Stunde aktualisiert',
  ChaveTexto.comumAtualizadoHaHoras: 'vor {n} Stunden aktualisiert',
  ChaveTexto.comumAtualizadoHaMinuto: 'vor 1 Minute aktualisiert',
  ChaveTexto.comumAtualizadoHaMinutos: 'vor {n} Minuten aktualisiert',
  ChaveTexto.comumEnviarFeedbackTooltip: 'Feedback / Fehler melden',
  ChaveTexto.comumFeedbackIndisponivelDev:
      'Feedback ist in dieser Entwicklungsumgebung nicht verfügbar.',
  ChaveTexto.comumSincronizarServingTooltip: 'Mit Server synchronisieren',
  ChaveTexto.comumBuscarPicosHint: 'Klettergebiete suchen...',
  ChaveTexto.comumMapaGeral: 'Übersichtskarte',

