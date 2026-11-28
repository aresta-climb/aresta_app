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

  // Sistema, prévia experimental, versão e migração
  ChaveTexto.sistemaModoExperimentalAtivo: 'EXPERIMENTELLER MODUS AKTIV',
  ChaveTexto.sistemaSair: 'BEENDEN',
  ChaveTexto.sistemaSessaoPreviaEncerradaTitulo: 'Vorschau-Sitzung beendet',
  ChaveTexto.sistemaSessaoPreviaEncerradaCorpo:
      'Die Verbindung zum Desktop-Editor wurde getrennt. Wir haben automatisch den offiziellen Aresta-Climb-Katalog wiederhergestellt.',
  ChaveTexto.sistemaFaseBetaTitulo: 'Offene Beta-Phase',
  ChaveTexto.sistemaFaseBetaIntro:
      'Aresta Climb ist eine unabhängige Initiative und wird aktiv gemeinsam mit der Kletter-Community entwickelt.',
  ChaveTexto.sistemaFaseBetaItem1Titulo: 'Laufend neue Sektoren & Topos',
  ChaveTexto.sistemaFaseBetaItem1Corpo:
      'Unsere Datenbank mit Routen, Bouldern, Topos und Karten wächst ständig.',
  ChaveTexto.sistemaFaseBetaItem2Titulo: 'Stetige Weiterentwicklung',
  ChaveTexto.sistemaFaseBetaItem2Corpo:
      'Erweiterte Filter, 3D-Navigation und Performance-Verbesserungen folgen laufend.',
  ChaveTexto.sistemaFaseBetaItem3Titulo: 'Gemeinsam mit Kletterern gebaut',
  ChaveTexto.sistemaFaseBetaItem3Corpo:
      'Dein Feedback direkt vom Fels hilft uns, das Wichtigste zuerst umzusetzen.',
  ChaveTexto.sistemaInstagramOficial: 'Offizielles Instagram',
  ChaveTexto.sistemaComunidadeWhatsapp: 'WhatsApp-Community',
  ChaveTexto.sistemaEnviarSugestao: 'Vorschlag senden',
  ChaveTexto.sistemaRodapeVersaoBeta: 'Aresta Climb v{versao} (Open Beta)',
  ChaveTexto.sistemaAtualizeParaBaixar:
      'Aktualisiere Aresta, um wieder Topos herunterzuladen und zu synchronisieren.',
  ChaveTexto.sistemaAtualizacaoRecomendada:
      'Update empfohlen: Eine neue Version ist verfügbar.',
  ChaveTexto.sistemaAtualizar: 'AKTUALISIEREN',
  ChaveTexto.sistemaAtualizacaoNecessaria: 'UPDATE\nERFORDERLICH',
  ChaveTexto.sistemaVersaoAntigaCorpo:
      'Deine Aresta-Version ist veraltet und wird nicht mehr unterstützt. Bitte aktualisiere die App im Store.',
  ChaveTexto.sistemaAtualizarAgora: 'JETZT AKTUALISIEREN',
  ChaveTexto.sistemaPreviaFalhaConectar:
      'Verbindung zur Vorschau-Sitzung „{codigo}“ fehlgeschlagen.',
  ChaveTexto.sistemaDeepLinkNaoEncontrado:
      'Route oder Sektor für Code „{uid}“ nicht gefunden. Prüfe deine Verbindung oder lade das Gebiet zuerst herunter.',
  ChaveTexto.sistemaMigracaoVerificando: 'Prüfe Internetverbindung...',
  ChaveTexto.sistemaMigracaoBaixando: 'Lade neuen Topo-Katalog herunter...',
  ChaveTexto.sistemaMigracaoErro:
      'Datenbank konnte nicht aktualisiert werden. Bitte prüfe deine Internetverbindung.',
  ChaveTexto.sistemaMigracaoTitulo: 'DATENBANK-UPDATE',
  ChaveTexto.sistemaMigracaoCorpo:
      'Diese neue Version enthält strukturelle Verbesserungen am Topo-Katalog und muss einmalig online synchronisiert werden.',

  // Página Inicial (Home) e Busca Global
  ChaveTexto.homeMeuPerfilTooltip: 'Mein Profil',
  ChaveTexto.homeConfiguracoesTooltip: 'Einstellungen',
  ChaveTexto.homeSincronizarTooltip: 'Katalog und Topos synchronisieren',
  ChaveTexto.homeBoasVindas: 'WILLKOMMEN!',
  ChaveTexto.homeBoraPraPedra: 'AB AN DEN FELS?',
  ChaveTexto.homeDescricaoHeroi:
      'Der digitale Kletterführer für draußen. Entdecke lokale Sektoren, Routen und Boulder und speichere Topos komplett offline.',
  ChaveTexto.homeBuscaHint: 'Gebiete, Sektoren oder Routen suchen...',
  ChaveTexto.homeErroAbrirSalvo:
      'Fehler beim Öffnen des gespeicherten Topos. Bitte erneut synchronisieren.',
  ChaveTexto.homeCroquiNaoSalvoOffline:
      'Dieses Topo ist noch nicht offline gespeichert. Verbinde dich mit dem Internet, um es zu öffnen.',
  ChaveTexto.homeMaisProximosTitulo: 'IN DEINER NÄHE',
  ChaveTexto.homePermitaLocalizacao:
      'Erlaube den Standortzugriff, um die nächstgelegenen Klettergebiete zu sehen.',
  ChaveTexto.homePermitirLocalizacaoBtn: 'Standort freigeben',
  ChaveTexto.homeAguardandoGps: 'Warte auf GPS-Signal...',
  ChaveTexto.homeNenhumPicoLocalizado: 'Keine Gebiete mit Koordinaten gefunden.',
  ChaveTexto.homeVerMais: 'MEHR ANZEIGEN ->',
  ChaveTexto.homeComoFunciona: 'SO FUNKTIONIERT ES',
  ChaveTexto.homeGuiaRapidoTitulo: 'ARESTA-SCHNELLSTART',
  ChaveTexto.homeGuiaRapidoSubtitulo:
      'Alles, was du brauchst – direkt von der App an die Wand.',
  ChaveTexto.homePasso1Titulo: 'GEBIET FINDEN',
  ChaveTexto.homePasso1Desc:
      'Sieh dir die Fahrzeit an oder erkunde das 3D/2D-Geoid mit Relief, Live-GPS, Regenradar, Waldbränden und Felsfeuchte.',
  ChaveTexto.homePasso2Titulo: 'OFFLINE SPEICHERN',
  ChaveTexto.homePasso2Desc:
      'Öffne jedes Gebiet sofort online oder lade den kompletten Führer herunter – für 100 % Offline-Nutzung am Wandfuß.',
  ChaveTexto.homePasso3Titulo: 'INTERAKTIVES TOPO',
  ChaveTexto.homePasso3Desc:
      'Tippe auf Routenlinien im Wandfoto für Grade und Haken und prüfe oder melde Gefahrenhinweise am Fels (🐝, 🪨, 🔩, ⚠️).',
  ChaveTexto.homePasso4Titulo: 'TOURENBUCH & COMMUNITY',
  ChaveTexto.homePasso4Desc:
      'Logge Begehungen, stimme über Grade ab und klappe Beta-Videos & Kommentare nur bei Bedarf auf (standardmäßig spoilerfrei).',
  ChaveTexto.homePasso5Titulo: 'DIREKT ZUM START',
  ChaveTexto.homePasso5Desc:
      'Tippe auf Zurück (←) für eine Ebene höher oder halte Zurück gedrückt, um direkt zur Startseite zu springen.',
  ChaveTexto.homePasso6Titulo: 'TEILEN',
  ChaveTexto.homePasso6Desc:
      'Teile Direktlinks zu Routen, Sektoren und Gebieten mit deiner Seilschaft.',
  ChaveTexto.homeConservacaoTitulo: 'NATURSCHUTZ & ZUGANG',
  ChaveTexto.homeConservacaoCorpo:
      'Der Zugang zu den Felsen hängt von Rücksicht, Ethik und Respekt gegenüber Anwohnern und Natur ab. Verantwortungsvolles Klettern hält unsere Gebiete offen.',
  ChaveTexto.buscaTodos: 'Alle',
  ChaveTexto.buscaPicos: 'Gebiete',
  ChaveTexto.buscaSetores: 'Sektoren',
  ChaveTexto.buscaDica:
      'Tipp: Suche nach Gebieten, Sektoren, Routen oder Graden (z. B. 7a, V4)',
  ChaveTexto.buscaNenhumResultado: 'Keine Ergebnisse gefunden.',
  ChaveTexto.buscaFiltroPrefixo: 'Filter: {filtro}',

  // Modalidades, contagens e estilos de escalada/ascensão
  ChaveTexto.modEsportiva: 'Sportklettern',
  ChaveTexto.modEsportivas: 'Sportrouten',
  ChaveTexto.modEsportivasMinusculo: 'Sportrouten',
  ChaveTexto.modMovel: 'Trad',
  ChaveTexto.modMoveis: 'Trad-Routen',
  ChaveTexto.modMoveisMinusculo: 'Trad-Routen',
  ChaveTexto.modMovelTrad: 'Trad / Clean',
  ChaveTexto.modBoulder: 'Boulder',
  ChaveTexto.modBoulders: 'Boulder',
  ChaveTexto.modBouldersMinusculo: 'Boulder',
  ChaveTexto.modMultienfiada: 'Mehrseillänge',
  ChaveTexto.modMultienfiadas: 'Mehrseillängen',
  ChaveTexto.modMultiplasEnfiadasMinusculo: 'Mehrseillängen',
  ChaveTexto.modParedao: 'Bigwall / Mehrseillänge',
  ChaveTexto.modHighline: 'Highline',
  ChaveTexto.modHighlines: 'Highlines',
  ChaveTexto.modHighlinesMinusculo: 'Highlines',
  ChaveTexto.modMista: 'Mixed',
  ChaveTexto.modOutro: 'Sonstige',
  ChaveTexto.modOutras: 'Sonstige',
  ChaveTexto.modVia: 'Route',
  ChaveTexto.modVias: 'Routen',
  ChaveTexto.modViasMinusculo: 'Routen',
  ChaveTexto.modEscaladaMinusculo: 'Linie',
  ChaveTexto.modEscaladasMinusculo: 'Linien',
  ChaveTexto.modSetorMinusculo: 'Sektor',
  ChaveTexto.modSetoresMinusculo: 'Sektoren',
  ChaveTexto.modSetoresCaixaAlta: 'SEKTOREN',
  ChaveTexto.modDeTotal: '{qtd} von {total} {plural}',
  ChaveTexto.viagemSheetTitulo: 'Reisezeitschätzung',
  ChaveTexto.viagemSheetTempoMedioRotulo: 'Durchschnittszeit (normaler Verkehr)',
  ChaveTexto.viagemSheetDistanciaEstradaRotulo: 'Straßenentfernung',
  ChaveTexto.viagemSheetNotaExplicativa:
      'Offline anhand der Straßen und Tempolimits von OpenStreetMap ab deinem aktuellen Standort berechnet. Echtzeitverkehr ist nicht enthalten — zu Stoßzeiten kann es länger dauern.',
  ChaveTexto.viagemSheetFecharBtn: 'Verstanden',
  ChaveTexto.estiloAVista: 'Onsight',
  ChaveTexto.estiloFlash: 'Flash',
  ChaveTexto.estiloTrabalhado: 'Rotpunkt',
  ChaveTexto.estiloTentativa: 'Versuch',
  ChaveTexto.estiloGuiado: 'Vorstieg',
  ChaveTexto.estiloTopRope: 'Toprope',
  ChaveTexto.estiloSolo: 'Solo',
  ChaveTexto.estiloTentativaSingular: 'Versuch',
  ChaveTexto.estiloTentativaPlural: 'Versuche',

  // Aba Explorar, Globo 3D/2D e Clima
  ChaveTexto.explorarBuscaHint: 'Gebiet, Stadt oder Route suchen...',
  ChaveTexto.explorarTrocarServing: 'Server wechseln',
  ChaveTexto.explorarAteKm: 'Bis {km} km',
  ChaveTexto.explorarViasBrasileiro: 'Routen (BR-Skala)',
  ChaveTexto.explorarBoulderEscalaV: 'Boulder (V-Skala)',
  ChaveTexto.explorarFiltrosOrdenacao: 'Filter & Sortierung',
  ChaveTexto.explorarOrdenacaoSecao: 'SORTIERUNG',
  ChaveTexto.explorarMaisProximos: 'Nächstgelegene',
  ChaveTexto.explorarAlfabeticoAZ: 'Alphabetisch (A-Z)',
  ChaveTexto.explorarMaisEscaladas: 'Meiste Routen',
  ChaveTexto.explorarModalidadesSecao: 'DISZIPLINEN',
  ChaveTexto.explorarDificuldadeSecao: 'SCHWIERIGKEIT IM KATALOG',
  ChaveTexto.explorarAlcanceSecao: 'UMKREIS & VERFÜGBARKEIT',
  ChaveTexto.explorarSalvosOffline: 'Offline gespeichert',
  ChaveTexto.explorarVerNPicos: '{total} Gebiete anzeigen',
  ChaveTexto.explorarModoMapa: 'Karte',
  ChaveTexto.explorarModoDividir: 'Geteilt',
  ChaveTexto.explorarModoLista: 'Liste',
  ChaveTexto.explorarContagemPicos: '{n} GEBIETE',
  ChaveTexto.explorarNenhumPicoEncontrado: 'Kein Felsgebiet gefunden.',
  ChaveTexto.explorarSetorPrincipal: 'Hauptsektor',
  ChaveTexto.explorarAcimaDoMar: '{metros} m ü. d. Meer',
  ChaveTexto.climaSeco: 'Trocken',
  ChaveTexto.climaPossivelmenteUmido: 'Eventuell feucht',
  ChaveTexto.climaRochaSecaSemChuva:
      'Wahrscheinlich trocken · Kein Regen (4 Tage)',
  ChaveTexto.climaContagemUmDia: '1 Tag',
  ChaveTexto.climaContagemDias: '{dias} Tage',
  ChaveTexto.climaChuvaProximaHoje: 'Regen in der Nähe heute ({data})',
  ChaveTexto.climaChuvaProximaUmDia: 'Regen in der Nähe vor 1 Tag ({data})',
  ChaveTexto.climaChuvaProximaDias:
      'Regen in der Nähe vor {dias} Tagen ({data})',
  ChaveTexto.climaNotaJanelaQuatroDias:
      'Konservatives 4-Tage-Fenster, das bei jedem Regen in der Region neu startet. Fels vor Ort prüfen.',
  ChaveTexto.climaNotaEstimativaSatelite:
      'Regionale Satellitenschätzung — lokale Nässe kann abweichen.',
  ChaveTexto.explorarBotaoClimaMapa: 'Regen & Feuer',
  ChaveTexto.explorarAvisoClimaTitulo: 'Nutzungshinweis',
  ChaveTexto.explorarAvisoClimaCorpo:
      'Aresta nutzt 3 Wetter- und Radarquellen (Open-Meteo, RainViewer, INPE BDQueimadas) SOWIE 3 öffentliche Ressourcen aus NASA-Missionen (FIRMS VIIRS/MODIS, SRTM 30m, Blue Marble), um eine Trefferquote von ~85% bei der Anzeige dieser Daten zu erreichen. Nutze dieses Werkzeug als Orientierungshilfe statt als absolute Wahrheit.',
  ChaveTexto.explorarAvisoClimaConfirmar: 'OK, auf Karte zeigen',
  ChaveTexto.explorarBotaoVerEstatisticasClima: 'Statistik prüfen',
  ChaveTexto.estatClimaTituloPagina: 'WIE WIR AUF ~85% KAMEN',
  ChaveTexto.estatClimaSubtituloHeroi:
      'Wir haben Vergleichsdaten ab 2024 aus denselben Regionen unserer 29 Felsen geprüft — von der Nullhypothese bis zur Z-Tabelle ergaben sich 83% bis 87% Trefferquote (~85% im Schnitt).',
  ChaveTexto.estatClimaSecaoComposicaoTitulo: '1. DATENABGLEICH AB 2024',
  ChaveTexto.estatClimaComposicaoChuvaMapa:
      'Regionale Regenblasen (≥ 0,2 mm/Tag)',
  ChaveTexto.estatClimaComposicaoUmidade4d:
      'Konservatives 4-Tage-Nässefenster am Fels',
  ChaveTexto.estatClimaComposicaoIncendioNasa:
      'Aktive Waldbrandperimeter (NASA VIIRS 375m)',
  ChaveTexto.estatClimaSecaoMatrizTitulo: '2. TEST GEGEN DIE NULLHYPOTHESE (H₀)',
  ChaveTexto.estatClimaMatrizExplicacao:
      'Wir nahmen Referenzdaten ab 2024 aus genau denselben Regionen unserer 29 Gebiete (5.133 Gebietstage), um zu prüfen, ob der Algorithmus — mit Open-Meteo, RainViewer-Radar, INPE und NASA-Sensoren — die gewünschte Wirkung erzielt:',
  ChaveTexto.estatClimaHipoteseNulaExplicacao:
      'Zuerst testeten wir direkt gegen eine Nullhypothese (H₀ = 50% Münzwurf sowie 58,5% Klimabasis), um zu sehen, ob überhaupt ein echter Effekt vorliegt. Das Signal lag +27,7 Standardabweichungen über dem Zufall:',
  ChaveTexto.estatClimaCelulaTpDetalhe: 'Regen erkannt & echt',
  ChaveTexto.estatClimaCelulaFpDetalhe: 'Vorsorglicher Alarm',
  ChaveTexto.estatClimaCelulaFnDetalhe: 'Lokaler Schauer verpasst',
  ChaveTexto.estatClimaCelulaTnDetalhe: 'Trockener Fels bestätigt',
  ChaveTexto.estatClimaCalcTaxaBrutaTitulo: 'Trefferquote bei Regen (p̂)',
  ChaveTexto.estatClimaCalcH0MoedaTitulo: 'Gegen H₀ = 50% (Münzwurf)',
  ChaveTexto.estatClimaCalcAcuraciaGlobalTitulo: 'Gesamtquote (trocken + nass)',
  ChaveTexto.estatClimaCalcErroPadraoTitulo: 'Standardfehler (SE)',
  ChaveTexto.estatClimaCalcFaixaZTitulo: 'Z-Tabellen-Spanne (95%, Z = 1,96)',
  ChaveTexto.estatClimaCalcMediaFinalTitulo: 'Mittlere Trefferquote (83%–87%)',
  ChaveTexto.estatClimaSecaoTabelaZTitulo:
      '3. IN DER Z-TABELLE: 83% BIS 87% (~85%)',
  ChaveTexto.estatClimaTabelaZExplicacao:
      'Nach diesem klaren Befund legten wir die Vergleichsdaten in eine Z-Tabelle, um den genauen Prozentsatz korrekter Treffer zu bestimmen. Mit den Berechnungen unten (Z = 1,96 für 95% und Z = +2,57 über 83%) kamen wir auf 83,7% bis 87,2% Wirksamkeit — rund ~85% im Mittel:',
  ChaveTexto.estatClimaGraficoH0Rotulo: 'Nullverteilung (H₀)',
  ChaveTexto.estatClimaGraficoCaudaRotulo: 'Rechter Rand (+27,7σ bis +49,0σ)',
  ChaveTexto.estatClimaColunaZ: 'Z-Wert',
  ChaveTexto.estatClimaColunaPhi: 'Φ(Z) Kumul.',
  ChaveTexto.estatClimaColunaCauda: 'Rand 1−Φ',
  ChaveTexto.estatClimaColunaNota: 'Z-Tabellenwert',
  ChaveTexto.estatClimaZNotaMedia: 'Zentrum der Nullhypothese (50%)',
  ChaveTexto.estatClimaZNota90: 'Einseitige 90%-Schwelle',
  ChaveTexto.estatClimaZNota95: 'Einseitige Standardschwelle (α = 0,05)',
  ChaveTexto.estatClimaZNotaIC95: 'Zweiseitiges 95%-KI ([83,7%, 87,2%])',
  ChaveTexto.estatClimaZNota99: 'Einseitige 99%-Schwelle (α = 0,01)',
  ChaveTexto.estatClimaZNotaTeste83:
      'Aresta-Test p̂ = 85,5% vs H₀ ≤ 83% (p = 0,0051)',
  ChaveTexto.estatClimaZNota999: '99,9%-Schwelle (α = 0,001)',
  ChaveTexto.estatClimaZNotaFimTabela:
      'Ende gedruckter Z-Tabellen (Aresta: Z = +27,7σ)',
  ChaveTexto.estatClimaSecaoFontesTitulo: '4. VERWENDETE DATENQUELLEN',
  ChaveTexto.estatClimaGrupoFontesMeteo:
      '3 WETTER-, RADAR- & UMWELTQUELLEN',
  ChaveTexto.estatClimaGrupoFontesNasa:
      '3 ÖFFENTLICHE RESSOURCEN AUS NASA-MISSIONEN',
  ChaveTexto.estatClimaFonteOpenMeteoDesc:
      'Numerische Modelle NOAA GFS, DWD ICON und ECMWF IFS für 5-Tage-Niederschlag, Sturmfronten und 10-m-Wind.',
  ChaveTexto.estatClimaFonteRainViewerDesc:
      'Globales Live-Dopplerradar-Mosaik zur Ortung konvektiver Regenzellen und Starkregenkernen.',
  ChaveTexto.estatClimaFonteInpeDesc:
      'INPE-BDQueimadas-Programm zur täglichen Überwachung von Hitzepunkten in Brasilien.',
  ChaveTexto.estatClimaFonteFirmsDesc:
      'Orbitale Thermalsensoren VIIRS (375 m) und MODIS (1 km) der Missionen Suomi NPP, NOAA-20 und Aqua/Terra.',
  ChaveTexto.estatClimaFonteSrtmDesc:
      'Shuttle Radar Topography Mission (30 m über AWS Terrarium) für reale Geländehöhen und Höhenlinien.',
  ChaveTexto.estatClimaFonteBlueMarbleDesc:
      'NASA Blue Marble Next Generation Satellitenmosaik für die Globus-Basiskarte.',
  ChaveTexto.estatClimaAvisoFinal:
      'Mikroklima, Sickerwasser in Rissen, Sonnenausrichtung und lokaler Wind beeinflussen die Felstrocknung. Prüfe die Bedingungen immer vor Ort.',
  ChaveTexto.climaChuvaFraca: 'Leichter Regen',
  ChaveTexto.climaChuvaModerada: 'Mäßiger Regen',
  ChaveTexto.climaChuvaForte: 'Starkregen',
  ChaveTexto.climaTempestadeSevera: 'Schweres Gewitter',
  ChaveTexto.climaFocoIsolado: 'Isolierter Wärmeherd',
  ChaveTexto.climaFocoQueimada: 'Brandherd',
  ChaveTexto.climaIncendioAtivo: 'Aktiver Waldbrand',
  ChaveTexto.climaIncendioSevero: 'Schwerer Waldbrand',

  // Meus Croquis e Modais Offline
  ChaveTexto.meusCroquisTitulo: 'MEINE TOPOS',
  ChaveTexto.meusCroquisSubtitulo: 'OFFLINE-SPEICHER',
  ChaveTexto.meusCroquisVazio: 'Noch keine Topos offline gespeichert.',
  ChaveTexto.meusCroquisAbrirOffline: 'OFFLINE ÖFFNEN',
  ChaveTexto.meusCroquisErroAbrir: 'Fehler beim Öffnen des Offline-Führers.',
  ChaveTexto.meusCroquisExcluirTitulo: 'Löschen?',
  ChaveTexto.meusCroquisExcluirPergunta:
      'Offline-Führer für {nome} wirklich löschen?',
  ChaveTexto.meusCroquisExcluidoToast: 'Führer gelöscht.',
  ChaveTexto.meusCroquisErroExcluirToast: 'Fehler beim Löschen des Führers.',
  ChaveTexto.meusCroquisGuiaRemovidoToast:
      'Führer aus dem Offline-Speicher entfernt.',
  ChaveTexto.offlineSalvarComTamanho: 'Offline speichern ({tamanho})',
  ChaveTexto.offlineSalvarSemTamanho: 'Offline speichern',
  ChaveTexto.offlineModoOnlineTitulo: 'ONLINE-MODUS',
  ChaveTexto.offlineModoOnlineDesc:
      'Du surfst gerade online. Speichere den kompletten Führer für den Einsatz ohne Empfang am Fels.',
  ChaveTexto.offlineBaixandoPct: 'LÄDT HERUNTER ({pct}%)...',
  ChaveTexto.offlineSalvarParaPedraTitulo: 'FÜR DEN FELS SPEICHERN?',
  ChaveTexto.offlineSalvarParaPedraCorpo:
      'Denk daran: Am Fels gibt es oft keinen Empfang. Speichere {nome} offline, um Topos und Grade jederzeit abzurufen.',
  ChaveTexto.offlineSairSemSalvar: 'Ohne Speichern verlassen',
  ChaveTexto.offlineSemConexaoTitulo: 'DU BIST OFFLINE',
  ChaveTexto.offlineSemConexaoCorpo:
      'Dieser Inhalt gehört zu {nome} und ist noch nicht offline auf deinem Gerät gespeichert. Verbinde dich mit dem Internet und versuche es erneut.',
  ChaveTexto.offlineAindaSemConexao:
      'Weiterhin keine Verbindung. Prüfe dein Netz und versuche es erneut.',
  ChaveTexto.offlineTentandoConectar: 'Verbinde...',

  // Página do Pico, Subpáginas, Setor, Grupo, Filtros de Índice e Croqui Interativo
  ChaveTexto.picoCompartilharTooltip: 'Gebiet teilen',
  ChaveTexto.picoExcluirGuiaTooltip: 'Führer löschen',
  ChaveTexto.picoBuscarBoulderTooltip: 'Boulder suchen',
  ChaveTexto.picoBuscarViaTooltip: 'Route suchen',
  ChaveTexto.picoCardSetoresTitulo: 'Sektoren & Routen',
  ChaveTexto.picoCardSetoresSubtitulo:
      'Sektoren, Routen und Boulder mit Filtern und Karten erkunden',
  ChaveTexto.picoCardExplorarTitulo: 'Gebiet erkunden',
  ChaveTexto.picoCardExplorarSubtitulo:
      'Zustieg, Übersichtskarten, Wetter und nützliche Infos.',
  ChaveTexto.picoCardRegrasTitulo: 'Regeln & Hinweise',
  ChaveTexto.picoCardRegrasSubtitulo:
      'Naturschutzregeln, Sicherheitshinweise und Kletterethik vor Ort.',
  ChaveTexto.picoCardComunidadeTitulo: 'Community',
  ChaveTexto.picoCardComunidadeSubtitulo:
      'Social Media, WhatsApp-Gruppe, Partner und lokale Angebote.',
  ChaveTexto.picoCardCreditosSubtitulo:
      'Autoren, Mitwirkende und Danksagungen.',
  ChaveTexto.picoVoltarMapaSetor: 'Zurück zur Sektorkarte',
  ChaveTexto.picoCroquiPor: 'Topo von {autores}',
  ChaveTexto.picoInfoLocal: 'Gebietsinformationen',
  ChaveTexto.picoCampoNome: 'Name',
  ChaveTexto.picoCampoEstado: 'Bundesstaat',
  ChaveTexto.picoMaisInfoSecao: 'Weitere Informationen',
  ChaveTexto.picoMapasGerais: 'Übersichtskarten',
  ChaveTexto.picoNenhumElemento: 'Keine Einträge verfügbar.',
  ChaveTexto.picoBuscarBoulderHint: 'Boulder (z. B. V4) oder Sektor suchen...',
  ChaveTexto.picoBuscarEscaladaHint: 'Route (z. B. 7a) oder Sektor suchen...',
  ChaveTexto.picoDificuldadePrefixo: 'Grad: {grau}',
  ChaveTexto.picoUltimaAtualizacaoNaoInformada: 'Letztes Update: Unbekannt',
  ChaveTexto.picoUltimaAtualizacaoHoje: 'Letztes Update: Heute um {hora}',
  ChaveTexto.picoUltimaAtualizacaoOntem: 'Letztes Update: Gestern um {hora}',
  ChaveTexto.picoUltimaAtualizacaoData: 'Letztes Update: {data} um {hora}',
  ChaveTexto.picoSubExplorarTitulo: 'GEBIET ERKUNDEN',
  ChaveTexto.picoSubIntroSubtitulo: 'Überblick und Einführung zum Gebiet.',
  ChaveTexto.picoSubSobreLocal: 'Über das Gebiet',
  ChaveTexto.picoSubSobreLocalSubtitulo:
      'Geschichte des Felsmassivs, Erstbegehungen und Besonderheiten.',
  ChaveTexto.picoSubComoChegar: 'Zustieg & Anfahrt',
  ChaveTexto.picoSubComoChegarSubtitulo:
      'Wegbeschreibung und Navigation bis zum Wandfuß.',
  ChaveTexto.picoSubAbrirMaps: 'In Google Maps öffnen',
  ChaveTexto.picoSubAbrirMapsSubtitulo:
      'Standort anzeigen und Route zum Gebiet berechnen.',
  ChaveTexto.picoSubExtrasSubtitulo: 'Zusätzliche Infos zum Gebiet.',
  ChaveTexto.picoSubComunidadeTitulo: 'COMMUNITY',
  ChaveTexto.picoSubInformacoes: 'Informationen',
  ChaveTexto.picoSubAssociacaoLocal: 'Lokaler Kletterverein',
  ChaveTexto.picoSubParceiros: 'Partner',
  ChaveTexto.picoSubComercioLocal: 'Lokales Gewerbe',
  ChaveTexto.picoSubApoieTitulo: 'GEBIET UNTERSTÜTZEN',
  ChaveTexto.picoSubDoacaoPix: 'Spende per Pix',
  ChaveTexto.picoSubDoacaoPixSubtitulo:
      'Unterstütze Edelstahl-Bohrhaken und Umlenker.\nSchlüssel: {chave}',
  ChaveTexto.picoSubPixCopiadoToast: 'Pix-Schlüssel kopiert!',
  ChaveTexto.picoSubProdutos: 'Gebiets-Produkte',
  ChaveTexto.picoSubPatrocinador: 'Sponsor werden',
  ChaveTexto.picoSubPatrocinadorSubtitulo:
      'Verbinde deine Marke nachhaltig mit dem Klettersport.',
  ChaveTexto.picoSubEnviarInfo: 'Information einsenden',
  ChaveTexto.picoSubEnviarInfoSubtitulo:
      'Neue Routen oder Korrekturen vorschlagen.',
  ChaveTexto.picoRegrasTitulo: 'REGELN & HINWEISE',
  ChaveTexto.picoRegrasVazio:
      'Keine speziellen Regeln hinterlegt. Bitte beachte die allgemeinen Naturschutz- und Kletterregeln.',
  ChaveTexto.picoGpsEmBreve: 'GPS-Funktionen folgen in Kürze',
  ChaveTexto.setorTituloPagina: 'SEKTOREN & ROUTEN',
  ChaveTexto.setorCompartilharTooltip: 'Sektor teilen',
  ChaveTexto.setorCompartilharGrupoTooltip: 'Teilgebiet teilen',
  ChaveTexto.setorNenhumSetorDisponivel: 'Kein Sektor verfügbar.',
  ChaveTexto.setorNenhumaViaDisponivel: 'Keine Route verfügbar.',
  ChaveTexto.setorNenhumBoulderDisponivel: 'Kein Boulder verfügbar.',
  ChaveTexto.setorNenhumSetorCadastrado:
      'Derzeit sind keine Sektoren oder Routen eingetragen.',
  ChaveTexto.setorNenhumSetorFiltrado:
      'Kein Sektor entspricht den gewählten Filtern.',
  ChaveTexto.setorNenhumaEscaladaFiltrada:
      'Keine Linie entspricht den gewählten Filtern.',
  ChaveTexto.setorVerNoCroqui: 'Im Topo zeigen',
  ChaveTexto.setorAbrirCroquiSemantics: 'Topo für Sektor {nome} öffnen',
  ChaveTexto.filtroPadrao: 'STANDARD',
  ChaveTexto.filtroPadraoMisto: 'Standard',
  ChaveTexto.filtroGrau: 'GRAD',
  ChaveTexto.filtroGrauMisto: 'Grad',
  ChaveTexto.filtroAlfabetico: 'ALPHABETISCH',
  ChaveTexto.filtroAtivoSingular: '1 aktiv',
  ChaveTexto.filtroAtivoPlural: '{n} aktiv',
  ChaveTexto.filtroLocalizacao: 'Standort',
  ChaveTexto.filtroConquistaAutores: 'Erstbegehung (Erschließer)',
  ChaveTexto.filtroApenasClassicas: 'Nur Klassiker (★)',
  ChaveTexto.filtroClassicas: 'Klassiker (★)',
  ChaveTexto.filtroModalidadeInativa: 'Disziplin inaktiv',
  ChaveTexto.filtroTodosGrausFaixa: 'Alle Grade ({min} bis {max})',
  ChaveTexto.filtroTodosGraus: 'Alle Grade',
  ChaveTexto.filtroGrauUnico: 'Grad: {grau}',
  ChaveTexto.filtroGrauFaixa: 'Grad: {min} bis {max}',
  ChaveTexto.filtroConectorA: 'bis',
  ChaveTexto.filtroFaixaGrauVias: 'Gradbereich (Routen)',
  ChaveTexto.filtroFaixaGrauBoulders: 'Gradbereich (Boulder)',
  ChaveTexto.filtroFaixaGrau: 'Gradbereich',
  ChaveTexto.filtroAddSetorOuGrupo: 'Sektor oder Teilgebiet hinzufügen...',
  ChaveTexto.filtroAddSetor: 'Sektor hinzufügen...',
  ChaveTexto.filtroTodosSetoresGruposAdd:
      'Alle Sektoren und Teilgebiete ausgewählt',
  ChaveTexto.filtroTodosSetoresAdd: 'Alle Sektoren ausgewählt',
  ChaveTexto.filtroNenhumLocalAtual: 'Kein Ort in aktuellen Filtern',
  ChaveTexto.filtroNenhumSetorAtual: 'Kein Sektor in aktuellen Filtern',
  ChaveTexto.filtroAddConquistador: 'Erstbegeher hinzufügen...',
  ChaveTexto.filtroTodosConquistadoresAdd: 'Alle Erstbegeher ausgewählt',
  ChaveTexto.filtroNenhumConquistadorAtual:
      'Kein Erstbegeher in aktuellen Filtern',
  ChaveTexto.croquiMapasInterativosContagem: 'Interaktive Topos ({n})',
  ChaveTexto.croquiAbrirMapaInterativo: 'Interaktives Topo öffnen',
  ChaveTexto.croquiTituloPagina: 'Interaktives Topo',
  ChaveTexto.croquiMaisInfo: 'Details',
  ChaveTexto.croquiVerMapas: 'Karten',
  ChaveTexto.croquiIrParaSetor: 'Zum Sektor',
  ChaveTexto.croquiIrParaGrupo: 'Zum Teilgebiet',
  ChaveTexto.croquiCentralizarTooltip: 'Bild zentrieren',
  ChaveTexto.croquiPaginacaoDe: '{atual} von {total}',

  // Detalhes da Via, Consenso de Grau, Especificações Técnicas e Alertas de Segurança
  ChaveTexto.viaClassica: 'KLASSIKER',
  ChaveTexto.viaGrauMaximo: 'MAXIMALGRAD',
  ChaveTexto.viaGrauOficial: 'OFFIZIELLER GRAD',
  ChaveTexto.viaConsensoComunidade: 'COMMUNITY-KONSENS',
  ChaveTexto.viaSemVotos: 'Keine Stimmen',
  ChaveTexto.viaNAvaliacoes: '{n} Bewertungen',
  ChaveTexto.viaDistribuicaoVotos: 'STIMMENVERTEILUNG ({n})',
  ChaveTexto.viaGrauJustoCurto: 'Passend',
  ChaveTexto.viaGrauJustoZero: 'Passender Grad (0)',
  ChaveTexto.viaGrauJustoComNota: 'Passend ({grau})',
  ChaveTexto.viaRegistreParaAvaliar: 'Begehung eintragen, um abzustimmen',
  ChaveTexto.viaConfirmamGrauPct: '{pct}% bestätigen den Grad',
  ChaveTexto.viaSugeremGrauPct: '{pct}% schlagen {sinal} vor',
  ChaveTexto.viaLinhaNumero: 'Linie #{n}',
  ChaveTexto.viaVerNoCroquiInterativo: 'IM INTERAKTIVEN TOPO ZEIGEN',
  ChaveTexto.viaCompartilharTooltip: 'Route teilen',
  ChaveTexto.viaReportarAlertaTooltip: 'Sicherheitswarnung melden',
  ChaveTexto.viaEntreParaReportarToast:
      'Melde dich im Profil an, um Sicherheitswarnungen zu senden.',
  ChaveTexto.viaAlertaRegistradoToast: 'Sicherheitswarnung gespeichert!',
  ChaveTexto.viaEntreParaVotarToast:
      'Melde dich im Profil an, um über den Grad abzustimmen.',
  ChaveTexto.viaVotoAtualizadoToast: 'Gradbewertung aktualisiert!',
  ChaveTexto.viaComentarioAtualizadoToast: 'Kommentar aktualisiert!',
  ChaveTexto.viaComentarioExcluidoToast: 'Kommentar gelöscht.',
  ChaveTexto.viaAncoragemPrefixo: 'Umlenkung: {tipo}',
  ChaveTexto.viaEnfiadasContagem: 'SEILLÄNGEN ({n})',
  ChaveTexto.viaProtecoesAbrev: '{n} Haken',
  ChaveTexto.viaMovelPrefixo: 'Trad: {equip}',
  ChaveTexto.viaHistoricoConquista: 'HISTORIE & ERSTBEGEHUNG',
  ChaveTexto.viaConquistadores: 'ERSTBEGEHER',
  ChaveTexto.viaAbertura: 'ERSCHLIESSUNG',
  ChaveTexto.viaManutencao: 'SANIERUNG',
  ChaveTexto.viaApoieManutencaoPix: 'Sanierung unterstützen (Pix: {chave})',
  ChaveTexto.viaPixManutencaoCopiadoToast: 'Pix-Schlüssel kopiert!',
  ChaveTexto.viaVideosBetasContagem: 'VIDEOS & BETA ({n})',
  ChaveTexto.viaBetasComunidadeContagem: 'COMMUNITY-BETA ({n})',
  ChaveTexto.viaEditarComentarioTooltip: 'Kommentar bearbeiten',
  ChaveTexto.viaExcluirComentarioTooltip: 'Kommentar löschen',
  ChaveTexto.viaEditarComentarioTitulo: 'Kommentar bearbeiten',
  ChaveTexto.viaEditarComentarioSubtitulo:
      'Aktualisiere deinen öffentlichen Hinweis oder Beta zu dieser Route.',
  ChaveTexto.viaExcluirComentarioTitulo: 'Kommentar löschen?',
  ChaveTexto.viaExcluirComentarioCorpo:
      'Dein öffentlicher Kommentar wird dauerhaft von dieser Route entfernt.',
  ChaveTexto.viaProjeto: 'Projekt',
  ChaveTexto.viaMediaPrefixo: 'Ø {media}',
  ChaveTexto.viaArtificialLivre: 'Techno {art} ({livre} frei)',
  ChaveTexto.viaArtificialPuro: 'Techno {art}',
  ChaveTexto.viaGuiaOficialConquistador: 'Offizieller Führer / Erstbegeher',
  ChaveTexto.viaSpecExtensao: 'LÄNGE',
  ChaveTexto.viaSpecParede: 'WANDNEIGUNG',
  ChaveTexto.viaSpecExposicao: 'ERNSTHAFTIGKEIT',
  ChaveTexto.viaSpecEnfiadas: 'SEILLÄNGEN',
  ChaveTexto.viaSpecComprimento: 'GESAMTLÄNGE',
  ChaveTexto.viaSpecMaiorEnfiada: 'LÄNGSTE SL',
  ChaveTexto.viaSpecDuracao: 'DAUER',
  ChaveTexto.viaSpecTipo: 'TYP',
  ChaveTexto.viaSpecDistancia: 'DISTANZ',
  ChaveTexto.viaSpecAltura: 'HÖHE',
  ChaveTexto.viaSpecProtecoes: 'SICHERUNGEN',
  ChaveTexto.viaSecaoDescricao: 'Beschreibung',
  ChaveTexto.viaSecaoPecasMoveis: 'Mobile Sicherungen',
  ChaveTexto.viaSecaoRackEquipamento: 'Rack & Material',
  ChaveTexto.viaSecaoDescricaoAcesso: 'Zustiegsbeschreibung',
  ChaveTexto.viaSecaoDescricaoAncoragem: 'Umlenkung / Standplatz',
  ChaveTexto.viaEnfiadaNumero: '{n}. Seillänge',
  ChaveTexto.viaBetaEmOrigem: 'Beta auf {origem}',
  ChaveTexto.viaAssistirVideoBeta: 'Beta-Video ansehen',
  ChaveTexto.viaVideo: 'Video',
  ChaveTexto.alertaPrefixoSemantics: 'Warnung: {rotulo}',
  ChaveTexto.alertaFaunaTitulo: 'Wildtiere',
  ChaveTexto.alertaFaunaDesc:
      'Bienen, Wespen, Schlangen, brütende Vögel oder andere Tiere in der Wand.',
  ChaveTexto.alertaRochaInstavelTitulo: 'Loser Fels / Griffausbruch',
  ChaveTexto.alertaRochaInstavelDesc:
      'Loser Block, hohle Schuppe oder ausbruchsgefährdeter Griff.',
  ChaveTexto.alertaProtecaoPrecariaTitulo: 'Fragwürdige Sicherung',
  ChaveTexto.alertaProtecaoPrecariaDesc:
      'Lockere Lasche, starke Korrosion oder beschädigter Umlenker.',
  ChaveTexto.alertaExposicaoTitulo: 'Hohe Exposition (E4+)',
  ChaveTexto.alertaExposicaoDesc:
      'Weiter Hakenabstand (E4+), Bodensturzgefahr oder ernste Passage.',
  ChaveTexto.alertaCriadoPorVoce: 'VON DIR GEMELDET',
  ChaveTexto.alertaConfirmadoMaisUm: 'BESTÄTIGT (+1)',
  ChaveTexto.alertaReportadoPorEm:
      'Gemeldet von {autor} am {data} • {n}x bestätigt',
  ChaveTexto.alertaEntreParaConfirmar:
      'Melde dich im Profil an, um diese Warnung zu bestätigen oder zu ändern.',
  ChaveTexto.alertaAindaEstaLa: 'Noch aktuell?',
  ChaveTexto.alertaNaoJaResolveu: 'Nein, behoben',
  ChaveTexto.alertaReportadoPorVoceCheck: '✓ Von dir gemeldet',
  ChaveTexto.alertaConfirmadoPorVoceCheck: '✓ Von dir bestätigt',
  ChaveTexto.alertaSimAindaEstaLa: 'Ja, noch aktuell',
  ChaveTexto.alertaEditarBtn: 'Warnung bearbeiten',
  ChaveTexto.alertaExcluirBtn: 'Warnung löschen',
  ChaveTexto.alertaResolvidoToast: 'Warnung als behoben markiert.',
  ChaveTexto.alertaResolvidoNaViaToast:
      'Warnung in {nome} als behoben markiert.',
  ChaveTexto.alertaAtualizadoToast: 'Warnung aktualisiert!',
  ChaveTexto.alertaFalhaAtualizarToast:
      'Warnung konnte nicht aktualisiert werden.',
  ChaveTexto.alertaExcluidoToast: 'Warnung gelöscht.',
  ChaveTexto.alertaEditarModalTitulo: 'Routenwarnung bearbeiten',
  ChaveTexto.alertaReportarModalTitulo: 'Routenwarnung melden',
  ChaveTexto.alertaEditarModalSub:
      'Aktualisiere Kategorie oder Details dieser Sicherheitswarnung.',
  ChaveTexto.alertaReportarModalSub:
      'Warne andere Kletterer vor akuten Gefahren in dieser Linie.',
  ChaveTexto.alertaDetalheLabel: 'Kurzer Hinweis (optional)',
  ChaveTexto.alertaDetalheHint: 'z. B. Bienennest am 3. Bohrhaken',
  ChaveTexto.alertaEnviarBtn: 'Warnung senden',
  ChaveTexto.alertaExcluirModalTitulo: 'Warnung löschen?',
  ChaveTexto.alertaExcluirModalCorpo:
      'Diese Sicherheitswarnung wird dauerhaft von der Route entfernt.',
  ChaveTexto.alertaAtivoUmConfirmacao: 'Aktiv • 1 Bestätigung',
  ChaveTexto.alertaAtivoVariasConfirmacoes: 'Aktiv • {n} Bestätigungen',
  ChaveTexto.alertaResolvidoStatus: 'Behoben',
  ChaveTexto.alertaMarcarResolvido: 'Als behoben markieren',

  // Autenticação, Perfil, Caderneta, Comunidade, Configurações, Feedback e Compartilhamento
  ChaveTexto.authEntrarTitulo: 'Anmelden',
  ChaveTexto.authEntrarSubtitulo:
      'Melde dich passwortlos per Konto oder 6-stelligem E-Mail-Code an, um dein Tourenbuch zu synchronisieren.',
  ChaveTexto.authContinuarGoogle: 'Weiter mit Google',
  ChaveTexto.authContinuarApple: 'Weiter mit Apple',
  ChaveTexto.authOuCodigoEmail: 'oder Code per E-Mail erhalten',
  ChaveTexto.authEmailLabel: 'E-Mail',
  ChaveTexto.authAguardeSegundos: 'Warte {s}s',
  ChaveTexto.authReceberCodigoEmail: 'Code per E-Mail senden',
  ChaveTexto.authCodigo6DigitosLabel: '6-stelliger Code',
  ChaveTexto.authConfirmarCodigo: 'Code bestätigen',
  ChaveTexto.authReenviarComSegundos: 'Erneut senden ({s}s)',
  ChaveTexto.authReenviarCodigo: 'Code erneut senden',
  ChaveTexto.authUsarOutroEmail: 'Andere E-Mail verwenden',
  ChaveTexto.authAbrirConfigApp: 'App-Einstellungen öffnen',
  ChaveTexto.authLimiteTemporario:
      'Zeitlimit erreicht. Bitte warte {s}s für einen neuen Code.',
  ChaveTexto.authCodigoEnviadoPara:
      'Wir haben einen 6-stelligen Code an {email} gesendet. Prüfe Posteingang und Spam.',
  ChaveTexto.authErroEnviarCodigo:
      'Zugangscode konnte nicht gesendet werden. Bitte erneut versuchen.',
  ChaveTexto.authErroValidarCodigo:
      'Zugangscode konnte nicht geprüft werden. Bitte erneut versuchen.',
  ChaveTexto.authErroGoogle:
      'Google-Anmeldung fehlgeschlagen. Bitte erneut versuchen.',
  ChaveTexto.authErroApple:
      'Apple-Anmeldung fehlgeschlagen. Bitte erneut versuchen.',
  ChaveTexto.authSemConexao:
      'Keine Internetverbindung. Prüfe deinen Empfang und versuche es erneut.',
  ChaveTexto.authSrvChaveInvalida:
      'Ungültiger Serverschlüssel. Bitte erneut versuchen.',
  ChaveTexto.authSrvCodigoExpirado:
      'Der Zugangscode ist abgelaufen oder ungültig.',
  ChaveTexto.authSrvEmailInvalido:
      'Bitte gib eine gültige E-Mail-Adresse ein.',
  ChaveTexto.authSrvProvedorDesabilitado:
      'Anmeldeanbieter ist auf dem Server deaktiviert.',
  ChaveTexto.authSrvCredencialInvalida:
      'Anmeldedaten konnten nicht bestätigt werden.',
  ChaveTexto.authSrvLimiteEnvio:
      'Sendelimit erreicht. Bitte kurz warten und erneut versuchen.',
  ChaveTexto.authSrvSessaoExpirada:
      'Deine Sitzung ist abgelaufen. Bitte neu anmelden.',
  ChaveTexto.authSrvCancelado: 'Anmeldung abgebrochen.',
  ChaveTexto.authSrvCooldownAposUm:
      'Aus Sicherheitsgründen kannst du erst nach 1 Sekunde einen neuen Code anfordern.',
  ChaveTexto.authSrvCooldownAposVarios:
      'Aus Sicherheitsgründen kannst du erst nach {s} Sekunden einen neuen Code anfordern.',
  ChaveTexto.authSrvCooldownCadaUm:
      'Aus Sicherheitsgründen ist nur alle 1 Sekunde ein neuer Code möglich.',
  ChaveTexto.authSrvCooldownCadaVarios:
      'Aus Sicherheitsgründen ist nur alle {s} Sekunden ein neuer Code möglich.',
  ChaveTexto.perfilEscaladorPadrao: 'Kletterer',
  ChaveTexto.perfilEscaladorAresta: 'Aresta-Kletterer',
  ChaveTexto.perfilEditarBtn: 'Profil bearbeiten',
  ChaveTexto.perfilMetricaCadenas: 'BEGEHUNGEN',
  ChaveTexto.perfilMetricaTentativas: 'VERSUCHE',
  ChaveTexto.perfilMetricaPicos: 'GEBIETE',
  ChaveTexto.perfilMetricaVias: 'ROUTEN',
  ChaveTexto.perfilEntrarConta: 'Anmelden',
  ChaveTexto.perfilMinhaCaderneta: 'Mein Tourenbuch',
  ChaveTexto.perfilDadosPrivacidade: 'Daten & Datenschutz',
  ChaveTexto.perfilSair: 'Abmelden',
  ChaveTexto.perfilExcluirConta: 'Konto löschen',
  ChaveTexto.perfilIdCopiadoToast: 'Öffentliche ID kopiert!',
  ChaveTexto.perfilSemConexaoExcluir:
      'Keine Internetverbindung. Verbinde dich, um dein Konto zu löschen.',
  ChaveTexto.perfilErroExcluirConta:
      'Konto konnte momentan nicht gelöscht werden.',
  ChaveTexto.perfilDialogEditarTitulo: 'Profil bearbeiten',
  ChaveTexto.perfilAlterarFoto: 'Profilbild ändern',
  ChaveTexto.perfilNomeAtletaLabel: 'Name des Kletterers',
  ChaveTexto.perfilPrivacidadeTitulo: 'Daten & Datenschutz',
  ChaveTexto.perfilPrivacidadeCorpo:
      'Aresta Climb schützt deine Datenhoheit. Dein Tourenbuch ist privat. Öffentliche Gradstimmen und Warnungen nutzen ausschließlich deine anonyme Autor-ID.',
  ChaveTexto.perfilIdPublicoLabel: 'ÖFFENTLICHE AUTOR-ID (NANOID)',
  ChaveTexto.perfilCopiarIdTooltip: 'Öffentliche ID kopieren',
  ChaveTexto.perfilSairPergunta: 'Wirklich abmelden?',
  ChaveTexto.perfilSairCorpo:
      'Dein lokales Tourenbuch bleibt sicher auf diesem Gerät erhalten.',
  ChaveTexto.perfilExcluirPergunta: 'Konto dauerhaft löschen?',
  ChaveTexto.perfilExcluirCorpo:
      'Dies kann nicht rückgängig gemacht werden. Konto, Profilbild und alle synchronisierten Begehungen werden dauerhaft gelöscht.',
  ChaveTexto.cadTituloPagina: 'MEIN TOURENBUCH',
  ChaveTexto.cadAscensaoAtualizadaToast: 'Begehung im Tourenbuch aktualisiert!',
  ChaveTexto.cadViaIndisponivelOffline:
      'Route ist derzeit offline nicht verfügbar.',
  ChaveTexto.cadTotalCadenas: 'Begehungen gesamt',
  ChaveTexto.cadTaxaAVistaFlash: 'Onsight-/Flash-Quote',
  ChaveTexto.cadMaiorGrauVias: 'Schwerste Route',
  ChaveTexto.cadMaiorGrauBoulders: 'Schwerster Boulder',
  ChaveTexto.cadPiramideTitulo: 'Gradpyramide',
  ChaveTexto.cadNenhumaAscensaoModalidade:
      'Noch keine Begehungen in dieser Disziplin.',
  ChaveTexto.cadHistoricoContagem: 'Begehungsverlauf ({n})',
  ChaveTexto.cadMeusAlertasContagem: 'Meine Felswarnungen ({n})',
  ChaveTexto.cadNenhumaAscensaoAinda: 'Noch keine Begehungen eingetragen',
  ChaveTexto.cadNenhumaAscensaoSub:
      'Deine gespeicherten Begehungen erscheinen hier.',
  ChaveTexto.cadEditarAscensaoTooltip: 'Begehung bearbeiten',
  ChaveTexto.cadExcluirAscensaoTooltip: 'Begehung löschen',
  ChaveTexto.cadExcluirAscensaoTitulo: 'Begehung löschen?',
  ChaveTexto.cadExcluirAscensaoCorpo:
      'Dieser Eintrag wird dauerhaft aus deinem Tourenbuch entfernt.',
  ChaveTexto.cadEstiloEsportivoLabel: 'Kletterstil',
  ChaveTexto.cadTentativasPegasLabel: 'Versuche',
  ChaveTexto.cadDataAscensaoLabel: 'Datum der Begehung',
  ChaveTexto.cadNotasPrivadasLabel: 'Private Notizen (Crux / Beta)',
  ChaveTexto.cadNotasPrivadasHint:
      'z. B. Linker Heelhook an der 3. Exe, lange Schlinge mitnehmen...',
  ChaveTexto.cadCadenaSalvaToast: 'Begehung im Tourenbuch gespeichert!',
  ChaveTexto.cadTentativaSalvaToast: 'Versuch im Tourenbuch gespeichert!',
  ChaveTexto.cadContribuicaoPublica: 'ÖFFENTLICHER BEITRAG',
  ChaveTexto.cadPercepcaoGrau: 'Wie hat sich der Grad angefühlt?',
  ChaveTexto.cadBetaOpcionalLabel: 'Community-Beta (optional)',
  ChaveTexto.cadBetaOpcionalHint:
      'z. B. 3. Exe verlängern; links herum in der Schlüsselstelle.',
  ChaveTexto.cadConecteParaContribuir:
      'Melde dich im Profil an, um Gradstimmen und öffentliche Beta beizutragen.',
  ChaveTexto.cadEditarModalTitulo: 'Begehung bearbeiten',
  ChaveTexto.cadRegistrarModalTitulo: 'Begehung eintragen',
  ChaveTexto.cadSalvarEContribuir: 'Speichern & Beitragen',
  ChaveTexto.cadSalvarNaCaderneta: 'Im Tourenbuch speichern',
  ChaveTexto.cadEncadenadaEm: 'Durchstieg am {data} ({estilo})',
  ChaveTexto.cadTentativaEm: 'Versuch am {data}',
  ChaveTexto.cadNovaAscensaoBtn: 'Neue Begehung / Versuch',
  ChaveTexto.cadRegistrarCadenaBtn: 'Durchstieg / Versuch loggen',
  ChaveTexto.comunidadeHeader: 'MEDIEN, SUPPORT & COMMUNITY',
  ChaveTexto.comunidadeSobreTimeTitulo: 'ÜBER DAS TEAM',
  ChaveTexto.comunidadeSobreTimeSub:
      'Lerne die Entwickler und Mitwirkenden hinter Aresta kennen.',
  ChaveTexto.comunidadeWhatsappTitulo: 'WHATSAPP-GRUPPE',
  ChaveTexto.comunidadeWhatsappSub:
      'Fragen stellen, Ideen teilen und Neuigkeiten erhalten.',
  ChaveTexto.comunidadeInstagramTitulo: 'OFFIZIELLES INSTAGRAM',
  ChaveTexto.comunidadeInstagramSub:
      'Neuigkeiten, Updates und Blicke hinter die Kulissen.',
  ChaveTexto.comunidadeLinkedinTitulo: 'PROJEKT-LINKEDIN',
  ChaveTexto.comunidadeLinkedinSub:
      'Meilensteine und Projektneuigkeiten von Aresta.',
  ChaveTexto.comunidadeDiscordTitulo: 'ENTWICKLER-DISCORD',
  ChaveTexto.comunidadeDiscordSub:
      'Sprich mit dem Team, verfolge den Code und gestalte Aresta mit.',
  ChaveTexto.comunidadeGithubTitulo: 'ARESTA AUF GITHUB',
  ChaveTexto.comunidadeGithubSub:
      'Entdecke unsere Open-Source-Repositories auf GitHub.',
  ChaveTexto.comunidadeTermosTitulo: 'Nutzungsbedingungen & Datenschutz',
  ChaveTexto.comunidadeTermosSub:
      'Eigenverantwortung beim Klettern und Offline-Datenschutz.',
  ChaveTexto.comunidadeRodapeVersao: 'Aresta Climb v{versao} • Open Beta',
  ChaveTexto.comunidadeIniciativaLivre:
      'Eine unabhängige Initiative für freies Klettern.',
  ChaveTexto.comunidadeTermosModalHeader: 'BEDINGUNGEN & DATENSCHUTZ',
  ChaveTexto.comunidadePoliticaModalHeader: 'DATENSCHUTZERKLÄRUNG',
  ChaveTexto.timeConhecaSubtitulo: 'DAS TEAM HINTER ARESTA',
  ChaveTexto.timeOpenSourceTitulo: 'ARESTA IST OPEN SOURCE',
  ChaveTexto.timeOpenSourceCorpo:
      'Möchtest du mitwirken? Komm auf unseren Discord und schreib uns!',
  ChaveTexto.timeCargoDesigner: 'Design',
  ChaveTexto.timeCargoProduto: 'Produkt / Marketing',
  ChaveTexto.timeCargoProdutoQuebra: 'Produkt/\nMarketing',
  ChaveTexto.timeCargoBackend: 'Backend',
  ChaveTexto.timeCargoFrontend: 'Frontend',
  ChaveTexto.legalTermosTitulo: 'Nutzungsbedingungen',
  ChaveTexto.legalPoliticaTitulo: 'Datenschutzerklärung',
  ChaveTexto.legalErroTermos:
      'Bedingungen konnten nicht geladen werden. Bitte später erneut versuchen.',
  ChaveTexto.legalErroPolitica: 'Datenschutzerklärung konnte nicht geladen werden.',
  ChaveTexto.legalBannerAtualizacao:
      '🌟 Wir haben unsere Rechtstexte aktualisiert. Bitte lies sie durch und bestätige.',
  ChaveTexto.legalDataAtualizacao: 'Stand: {data}',
  ChaveTexto.legalAceitoEm: 'Akzeptiert am {data} um {hora}',
  ChaveTexto.legalConcordoCheckbox:
      'Ich habe die Nutzungsbedingungen und die Datenschutzerklärung gelesen und stimme zu.',
  ChaveTexto.legalAceitarContinuar: 'Akzeptieren & Weiter',
  ChaveTexto.configTitulo: 'Einstellungen',
  ChaveTexto.configIdiomaTitulo: 'SPRACHE',
  ChaveTexto.configIdiomaSubtitulo:
      'Wechsle sofort die Anzeigesprache der gesamten App.',
  ChaveTexto.configAparenciaTitulo: 'DARSTELLUNG',
  ChaveTexto.configAparenciaSub: 'App-Design anpassen.',
  ChaveTexto.configEscolherTemaManual: 'Design manuell wählen',
  ChaveTexto.configTemaEscuro: 'DUNKEL',
  ChaveTexto.configPerfilCadernetaTitulo: 'PROFIL & TOURENBUCH',
  ChaveTexto.configPerfilCadernetaSub:
      'Profil und Tourenbuch ein- oder ausblenden, ohne lokale Daten zu löschen.',
  ChaveTexto.configExibirPerfilSwitch: 'Profil & Tourenbuch anzeigen',
  ChaveTexto.configConectarEditorTitulo: 'Editor verbinden',
  ChaveTexto.configConectarEditorInstrucao:
      'Gib den 8-stelligen Code aus dem Desktop-Editor ein oder scanne den QR-Code.',
  ChaveTexto.configConectarEditorHint: 'z. B. k9x2-p83a oder vollständige URL',
  ChaveTexto.configEscanearQrBtn: 'QR-CODE SCANNEN',
  ChaveTexto.configComoFuncionaEditor:
      'Wie funktioniert der Desktop-Editor? Mehr erfahren',
  ChaveTexto.configConectarBtn: 'VERBINDEN',
  ChaveTexto.configModoExperimentalTitulo: 'EXPERIMENTELLER / VORSCHAU-MODUS',
  ChaveTexto.configModoExperimentalSub:
      'Live-Synchronisierung mit dem Desktop-Editor aktiv.',
  ChaveTexto.configVoltarModoOficialBtn: 'ZURÜCK ZUM OFFIZIELLEN MODUS',
  ChaveTexto.configModoOficialTitulo: 'OFFIZIELLER MODUS',
  ChaveTexto.configModoOficialSub:
      'Verbunden mit dem offiziellen Aresta-Climb-Katalog. Verbinde den Desktop-Editor für Live-Vorschauen.',
  ChaveTexto.configConectarEditorPreviaBtn: 'MIT EDITOR / VORSCHAU VERBINDEN',
  ChaveTexto.configComoFazerSaibaMais: 'Wie geht das? Mehr erfahren',
  ChaveTexto.configVoltandoOficialToast: 'Wechsle zum offiziellen Katalog...',
  ChaveTexto.configReativandoExpToast:
      'Stelle lokale Vorschau-Daten wieder her...',
  ChaveTexto.configReativarExpBtn: 'VORSCHAU-MODUS REAKTIVIEREN',
  ChaveTexto.configApagarTudoTitulo: 'Alles löschen?',
  ChaveTexto.configApagarTudoCorpo:
      'Dadurch werden der Vorschau-Index und alle darin geladenen Gebiete dauerhaft gelöscht. Fortfahren?',
  ChaveTexto.configApagarTudoBtn: 'ALLES LÖSCHEN',
  ChaveTexto.configAmbienteExpLimpoToast: 'Vorschau-Daten gelöscht.',
  ChaveTexto.configLimparExpBtn: 'VORSCHAU-DATEN LÖSCHEN',
  ChaveTexto.configConectadoEditorToast: 'Mit Editor-Repository verbunden!',
  ChaveTexto.configErroIndiceStatus:
      'Fehler: Index nicht erreichbar (Status {status})',
  ChaveTexto.configErroConexaoUrl: 'Verbindungsfehler: URL prüfen',
  ChaveTexto.qrTituloPagina: 'QR-Code scannen',
  ChaveTexto.qrAponteCamera: 'Richte die Kamera auf den\nRepository-QR-Code',
  ChaveTexto.feedbackPerguntaTipo: 'Worum geht es bei deinem Feedback?',
  ChaveTexto.feedbackSobreCroqui: 'Zum Topo',
  ChaveTexto.feedbackSobreApp: 'Zur App',
  ChaveTexto.feedbackHintDescricao: 'Problem oder Vorschlag beschreiben...',
  ChaveTexto.feedbackAvisoPublico:
      'Öffentliches Feedback. Es werden keine persönlichen Daten veröffentlicht.',
  ChaveTexto.feedbackEnviarBtn: 'Senden',
  ChaveTexto.shareConfiraPico:
      'Schau dir das Topo von {pico}{loc} in Aresta an:\n{url}',
  ChaveTexto.shareConfiraGrupo:
      'Schau dir {grupo} ({pico}) in Aresta an:\n{url}',
  ChaveTexto.shareConfiraSetor:
      'Schau dir {setor} ({pico}) in Aresta an:\n{url}',
  ChaveTexto.shareConfiraEscalada:
      'Schau dir {via}{grau}{setor} ({pico}) in Aresta an:\n{url}',
  ChaveTexto.shareModalTitulo: 'Teilen',
  ChaveTexto.shareModalSubtitulo:
      'Wähle zwischen visueller Story-Karte oder klickbarem Link',
  ChaveTexto.shareBtnImagemStories: 'Bild teilen (Stories)',
  ChaveTexto.shareBtnLinkRapido: 'Link teilen (WhatsApp)',
  ChaveTexto.shareLinkCopiadoParaStoriesToast:
      'Link kopiert! Füge ihn bei Bedarf in den Link-Sticker in den Stories ein.',
  ChaveTexto.shareAcaoToastCaderneta: 'Teilen',
  ChaveTexto.shareSeloAscensaoTooltip: 'Begehung teilen',
  ChaveTexto.shareCardTipoPico: 'KLETTERGEBIET',
  ChaveTexto.shareCardTipoGrupo: 'SEKTORENGRUPPE',
  ChaveTexto.shareCardTipoSetor: 'KLETTERSEKTOR',
  ChaveTexto.shareCardContagemSetores: '{n} Sektoren',
  ChaveTexto.shareCardContagemUmSetor: '1 Sektor',
  ChaveTexto.shareCardContagemEscaladas: '{n} Routen',
  ChaveTexto.shareCardContagemUmaEscalada: '1 Route',
  ChaveTexto.shareCardFaixaGraus: 'Grade {faixa}',
  ChaveTexto.gpsDesligadoUltimaConhecida:
      'GPS ausgeschaltet; zentriere auf letzten bekannten Standort.',
  ChaveTexto.gpsAtiveAparelho:
      'Aktiviere das Geräte-GPS, um auf deinen Standort zu zentrieren.',
  ChaveTexto.gpsPermissaoNegada: 'Standortberechtigung verweigert.',
  ChaveTexto.gpsSinalIndisponivel:
      'Derzeit konnte kein GPS-Signal empfangen werden.',
  ChaveTexto.filtroSecaoFiltros: 'FILTER',
  ChaveTexto.filtroModalidadesTitulo: 'Disziplinen',
  ChaveTexto.setorNenhumaEscaladaFiltrosAtuais:
      'Keine Routen entsprechen den aktiven Filtern.',
  ChaveTexto.modEsportivaMinusculo: 'Sportroute',
  ChaveTexto.modMovelMinusculo: 'Trad-Route',
  ChaveTexto.modBoulderMinusculo: 'Boulder',
  ChaveTexto.modMultienfiadaMinusculo: 'Mehrseillänge',
  ChaveTexto.modMultienfiadasMinusculo: 'Mehrseillängen',
  ChaveTexto.modHighlineMinusculo: 'Highline',
  ChaveTexto.comumFecharCaixaAlta: 'SCHLIESSEN',
  ChaveTexto.authValidacaoCodigo6Digitos:
      'Gib den per E-Mail gesendeten 6-stelligen Zahlencode ein.',
  ChaveTexto.authServicoIndisponivel:
      'Authentifizierungsdienst ist derzeit nicht verfügbar.',
  ChaveTexto.configTestarObsolescenciaBtn: 'VERALTUNGSHINWEIS TESTEN',
  ChaveTexto.configTestarBloqueioBtn: 'SPERRBILDSCHIRM TESTEN',
  ChaveTexto.notifBaixandoPct: 'Wird geladen... {pct}%',
  ChaveTexto.notifCroquiSalvoOffline:
      '✓ Topo für die Offline-Nutzung gespeichert.',
  ChaveTexto.notifFalhaBaixarCroqui:
      'Topo-Download fehlgeschlagen. Verbindung prüfen.',
  ChaveTexto.feedbackRecebidoObrigado:
      'Feedback erhalten! Vielen Dank für deine Hilfe zur Verbesserung der App.',
  ChaveTexto.sistemaMigracaoTentarNovamente: 'Erneut versuchen',
};
