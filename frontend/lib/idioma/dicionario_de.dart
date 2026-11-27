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
  ChaveTexto.modEstimativaSemTransito:
      'Fahrzeit ohne Verkehr: {tempo} ({distancia})',
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
      'Aresta nutzt 3 Wetter- und Radarquellen SOWIE 3 öffentliche Ressourcen aus NASA-Missionen, um eine Trefferquote von ~86% bei der Anzeige dieser Daten zu erreichen. Nutze dieses Werkzeug als Orientierungshilfe statt als absolute Wahrheit.',
  ChaveTexto.explorarAvisoClimaConfirmar: 'OK, auf Karte zeigen',
  ChaveTexto.climaChuvaFraca: 'Leichter Regen',
  ChaveTexto.climaChuvaModerada: 'Mäßiger Regen',
  ChaveTexto.climaChuvaForte: 'Starkregen',
  ChaveTexto.climaTempestadeSevera: 'Schweres Gewitter',
  ChaveTexto.climaFocoIsolado: 'Isolierter Wärmeherd',
  ChaveTexto.climaFocoQueimada: 'Brandherd',
  ChaveTexto.climaIncendioAtivo: 'Aktiver Waldbrand',
  ChaveTexto.climaIncendioSevero: 'Schwerer Waldbrand',

