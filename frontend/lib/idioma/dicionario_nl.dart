// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'modelo_idioma_app.dart';

/// Dicionário completo em Neerlandês / Holandês (`nl-NL` — idioma oficial e mais falado
/// nos Países Baixos) com terminologia autêntica de escalada em rocha.
const Map<ChaveTexto, String> dicionarioHolandes = {
  // Seletor de idioma
  ChaveTexto.seletorIdiomaTitulo: 'APP-TAAL',
  ChaveTexto.seletorIdiomaSubtitulo:
      'Kies de taal die op alle schermen van Aresta Climb wordt weergegeven.',
  ChaveTexto.seletorIdiomaTooltip: 'App-taal wijzigen',

  // Navegação e ações globais
  ChaveTexto.navInicio: 'HOME',
  ChaveTexto.navExplorar: 'ONTDEKKEN',
  ChaveTexto.navMeusCroquis: "MIJN TOPO'S",
  ChaveTexto.navComunidade: 'COMMUNITY',
  ChaveTexto.navInicioCurto: 'Home',
  ChaveTexto.navGps: 'GPS',
  ChaveTexto.comumVoltar: 'Terug',
  ChaveTexto.comumSegureParaInicio: 'Ingedrukt houden voor Home',
  ChaveTexto.comumFechar: 'Sluiten',
  ChaveTexto.comumCancelar: 'Annuleren',
  ChaveTexto.comumCancelarCaixaAlta: 'ANNULEREN',
  ChaveTexto.comumSalvar: 'Opslaan',
  ChaveTexto.comumSalvarAlteracoes: 'Wijzigingen opslaan',
  ChaveTexto.comumExcluir: 'Verwijderen',
  ChaveTexto.comumExcluirCaixaAlta: 'VERWIJDEREN',
  ChaveTexto.comumEntendi: 'BEGREPEN',
  ChaveTexto.comumTentarNovamente: 'Opnieuw proberen',
  ChaveTexto.comumDesfazer: 'Ongedaan maken',
  ChaveTexto.comumLimpar: 'Wissen',
  ChaveTexto.comumAplicar: 'Toepassen',
  ChaveTexto.comumAplicarUmResultado: 'Toepassen (1 resultaat)',
  ChaveTexto.comumAplicarVariosResultados: 'Toepassen ({total} resultaten)',
  ChaveTexto.comumSemNome: 'Naamloos',
  ChaveTexto.comumSemNomeCaixaAlta: 'NAAMLOOS',
  ChaveTexto.comumLocalDesconhecido: 'ONBEKENDE LOCATIE',
  ChaveTexto.comumPico: 'Klimgebied',
  ChaveTexto.comumSetor: 'Sector',
  ChaveTexto.comumGrupo: 'Deelgebied',
  ChaveTexto.comumOffline: 'Offline',
  ChaveTexto.comumSalvoOffline: 'Offline opgeslagen',
  ChaveTexto.comumSalvoOfflineCaixaAlta: 'OFFLINE OPGESLAGEN',
  ChaveTexto.comumCatalogo: 'Catalogus',
  ChaveTexto.comumAbrindo: '{titulo} openen...',
  ChaveTexto.comumBaixando: '{nome} downloaden...',
  ChaveTexto.comumBaixadoSucesso: '{nome} gedownload',
  ChaveTexto.comumSalvoOfflineToast: '{nome} offline opgeslagen!',
  ChaveTexto.comumFalhaBaixar: 'Downloaden van {nome} mislukt',
  ChaveTexto.comumSemConexao: 'Geen internetverbinding.',
  ChaveTexto.comumErroAbrirLink: 'Kan de link niet openen.',
  ChaveTexto.comumLinkCopiado: 'Link gekopieerd!',
  ChaveTexto.comumAbrirLink: 'LINK OPENEN',
  ChaveTexto.comumAcessar: 'OPENEN ',
  ChaveTexto.comumVerificandoAtualizacoes: 'Controleren op updates...',
  ChaveTexto.comumErroVerificarAtualizacoes:
      'Fout bij controleren op updates. Probeer het later opnieuw.',
  ChaveTexto.comumConcluidoComFalhas: 'Voltooid met fouten: {falhas}',
  ChaveTexto.comumCatalogoAtualizadoSucesso: 'Catalogus succesvol bijgewerkt!',
  ChaveTexto.comumCatalogoJaAtualizado: 'Catalogus is al up-to-date.',
  ChaveTexto.comumNenhumCroquiPrecisavaAtualizar:
      "Geen topo's hoefden te worden bijgewerkt.",
  ChaveTexto.comumCroquisAtualizados: "Topo's zijn bijgewerkt!",
  ChaveTexto.comumSincronizandoServing: 'Synchroniseren met server...',
  ChaveTexto.comumSemConexaoServing: 'Geen verbinding met server.',
  ChaveTexto.comumErroSincronizarServing:
      'Fout bij synchroniseren met server. Probeer het later opnieuw.',
  ChaveTexto.comumSincronizadoComFalhas:
      'Gesynchroniseerd met fouten bij: {falhas}',
  ChaveTexto.comumCatalogoAtualizadoServing:
      'Catalogus bijgewerkt vanaf server!',
  ChaveTexto.comumCatalogoJaRecenteServing:
      'Catalogus heeft al de nieuwste versie.',
  ChaveTexto.comumVersaoDesatualizadaToast:
      "Je versie van Aresta is verouderd. Werk bij om topo's te blijven downloaden.",
  ChaveTexto.comumGuiaAtualizadoToast: 'De gids voor {nome} is bijgewerkt!',
  ChaveTexto.comumErroSincronizarDadosToast:
      'Fout bij synchroniseren van gegevens. Probeer het later opnieuw.',
  ChaveTexto.comumCroquisBaixadosAtualizadosToast:
      "Je gedownloade topo's zijn bijgewerkt!",
  ChaveTexto.comumAtualizadoAgora: 'zojuist bijgewerkt',
  ChaveTexto.comumAtualizadoHaAno: '1 jaar geleden bijgewerkt',
  ChaveTexto.comumAtualizadoHaAnos: '{n} jaar geleden bijgewerkt',
  ChaveTexto.comumAtualizadoHaMes: '1 maand geleden bijgewerkt',
  ChaveTexto.comumAtualizadoHaMeses: '{n} maanden geleden bijgewerkt',
  ChaveTexto.comumAtualizadoHaDia: '1 dag geleden bijgewerkt',
  ChaveTexto.comumAtualizadoHaDias: '{n} dagen geleden bijgewerkt',
  ChaveTexto.comumAtualizadoHaHora: '1 uur geleden bijgewerkt',
  ChaveTexto.comumAtualizadoHaHoras: '{n} uur geleden bijgewerkt',
  ChaveTexto.comumAtualizadoHaMinuto: '1 minuut geleden bijgewerkt',
  ChaveTexto.comumAtualizadoHaMinutos: '{n} minuten geleden bijgewerkt',
  ChaveTexto.comumEnviarFeedbackTooltip: 'Feedback / Bug melden',
  ChaveTexto.comumFeedbackIndisponivelDev:
      'Feedback verzenden is niet beschikbaar in deze ontwikkelomgeving.',
  ChaveTexto.comumSincronizarServingTooltip: 'Synchroniseren met server',
  ChaveTexto.comumBuscarPicosHint: 'Zoek klimgebieden...',
  ChaveTexto.comumMapaGeral: 'Overzichtskaart',

  // Sistema, prévia experimental, versão e migração
  ChaveTexto.sistemaModoExperimentalAtivo: 'EXPERIMENTELE MODUS ACTIEF',
  ChaveTexto.sistemaSair: 'SLUITEN',
  ChaveTexto.sistemaSessaoPreviaEncerradaTitulo: 'Voorbeeldsessie beëindigd',
  ChaveTexto.sistemaSessaoPreviaEncerradaCorpo:
      'De verbinding met de Desktop Editor is verbroken. Omdat de voorbeeldmodus tijdelijk is, hebben we automatisch de officiële Aresta Climb-catalogus hersteld.',
  ChaveTexto.sistemaFaseBetaTitulo: 'Open Bètafase',
  ChaveTexto.sistemaFaseBetaIntro:
      'Aresta Climb is een onafhankelijk initiatief dat actief samen met de klimgemeenschap wordt ontwikkeld.',
  ChaveTexto.sistemaFaseBetaItem1Titulo: "Doorlopend nieuwe sectoren & topo's",
  ChaveTexto.sistemaFaseBetaItem1Corpo:
      "Onze database met routes, boulders, topo's en kaarten wordt continu uitgebreid.",
  ChaveTexto.sistemaFaseBetaItem2Titulo: 'Functies in ontwikkeling',
  ChaveTexto.sistemaFaseBetaItem2Corpo:
      'Geavanceerde filters, 3D-navigatie en prestatieverbeteringen zijn onderweg.',
  ChaveTexto.sistemaFaseBetaItem3Titulo: 'Gebouwd met klimmers',
  ChaveTexto.sistemaFaseBetaItem3Corpo:
      'Jouw ervaring op de rots helpt ons details te verfijnen en prioriteiten te stellen.',
  ChaveTexto.sistemaInstagramOficial: 'Officieel Instagram',
  ChaveTexto.sistemaComunidadeWhatsapp: 'WhatsApp-community',
  ChaveTexto.sistemaEnviarSugestao: 'Suggestie sturen',
  ChaveTexto.sistemaRodapeVersaoBeta: 'Aresta Climb v{versao} (Open Bèta)',
  ChaveTexto.sistemaAtualizeParaBaixar:
      "Werk Aresta bij om weer topo's te downloaden en synchroniseren.",
  ChaveTexto.sistemaAtualizacaoRecomendada:
      'Aanbevolen update: er is een nieuwe versie beschikbaar.',
  ChaveTexto.sistemaAtualizar: 'BIJWERKEN',
  ChaveTexto.sistemaAtualizacaoNecessaria: 'UPDATE\nVEREIST',
  ChaveTexto.sistemaVersaoAntigaCorpo:
      'Je versie van Aresta is verouderd en wordt niet meer ondersteund. Werk de app bij in de store om verder te gaan.',
  ChaveTexto.sistemaAtualizarAgora: 'NU BIJWERKEN',
  ChaveTexto.sistemaPreviaFalhaConectar:
      'Kan niet verbinden met voorbeeldsessie "{codigo}".',
  ChaveTexto.sistemaDeepLinkNaoEncontrado:
      'Route of sector voor code "{uid}" niet gevonden. Controleer je internetverbinding of download eerst het klimgebied.',
  ChaveTexto.sistemaMigracaoVerificando: 'Internetverbinding controleren...',
  ChaveTexto.sistemaMigracaoBaixando: 'Nieuwe topocatalogus downloaden...',
  ChaveTexto.sistemaMigracaoErro:
      'Database bijwerken mislukt. Controleer je internetverbinding.',
  ChaveTexto.sistemaMigracaoTitulo: 'DATABASE-UPDATE',
  ChaveTexto.sistemaMigracaoCorpo:
      'Deze nieuwe versie bevat structurele verbeteringen aan de topocatalogus en moet eenmalig online synchroniseren.',

  // Página Inicial (Home) e Busca Global
  ChaveTexto.homeMeuPerfilTooltip: 'Mijn Profiel',
  ChaveTexto.homeConfiguracoesTooltip: 'Instellingen',
  ChaveTexto.homeSincronizarTooltip: "Catalogus en topo's synchroniseren",
  ChaveTexto.homeBoasVindas: 'WELKOM!',
  ChaveTexto.homeBoraPraPedra: 'KLAAR VOOR DE ROTS?',
  ChaveTexto.homeDescricaoHeroi:
      "De ultieme gids voor buitenklimmen. Ontdek lokale sectoren, routes en boulders en sla topo's volledig offline op.",
  ChaveTexto.homeBuscaHint: 'Zoek klimgebieden, sectoren of routes...',
  ChaveTexto.homeErroAbrirSalvo:
      'Fout bij openen van opgeslagen topo. Probeer opnieuw te synchroniseren.',
  ChaveTexto.homeCroquiNaoSalvoOffline:
      'Deze topo is nog niet offline opgeslagen. Maak verbinding met internet om hem te openen.',
  ChaveTexto.homeMaisProximosTitulo: 'DICHTST BIJ JOU',
  ChaveTexto.homePermitaLocalizacao:
      'Geef locatietoegang om de dichtstbijzijnde klimgebieden te zien.',
  ChaveTexto.homePermitirLocalizacaoBtn: 'Locatie toestaan',
  ChaveTexto.homeAguardandoGps: 'Wachten op GPS-signaal...',
  ChaveTexto.homeNenhumPicoLocalizado: 'Geen klimgebieden met locatie gevonden.',
  ChaveTexto.homeVerMais: 'MEER TONEN ->',
  ChaveTexto.homeComoFunciona: 'HOE HET WERKT',
  ChaveTexto.homeGuiaRapidoTitulo: 'ARESTA SNELGIDS',
  ChaveTexto.homeGuiaRapidoSubtitulo:
      'Alles wat je nodig hebt om direct van de app naar de rots te gaan.',
  ChaveTexto.homePasso1Titulo: 'VIND HET GEBIED',
  ChaveTexto.homePasso1Desc:
      'Bekijk de reistijd of verken de 3D/2D-geoïde met reliëf, live GPS, buienradar, bosbranden en rotsvochtigheid.',
  ChaveTexto.homePasso2Titulo: 'OFFLINE OPSLAAN',
  ChaveTexto.homePasso2Desc:
      'Open elk gebied direct online of download de volledige gids voor 100% offline gebruik onderaan de wand.',
  ChaveTexto.homePasso3Titulo: 'INTERACTIEVE TOPO',
  ChaveTexto.homePasso3Desc:
      'Tik op routelijnen op de wandfoto voor graden en haken, en bekijk of meld waarschuwingen op de rots (🐝, 🪨, 🔩, ⚠️).',
  ChaveTexto.homePasso4Titulo: 'LOGBOEK & COMMUNITY',
  ChaveTexto.homePasso4Desc:
      "Log beklimmingen, stem over de graad en klap community-video's en beta alleen open wanneer jij wilt (standaard spoilervrij).",
  ChaveTexto.homePasso5Titulo: 'SNEL NAAR HOME',
  ChaveTexto.homePasso5Desc:
      'Tik op terug (←) voor één stap terug of houd terug ingedrukt om direct naar Home te springen.',
  ChaveTexto.homePasso6Titulo: 'DELEN',
  ChaveTexto.homePasso6Desc:
      'Stuur directe links naar routes, sectoren en klimgebieden naar je klimpartners.',
  ChaveTexto.homeConservacaoTitulo: 'NATUURBEHOUD & TOEGANG',
  ChaveTexto.homeConservacaoCorpo:
      'Toegang tot klimgebieden hangt af van zorg, ethiek en respect voor lokale gemeenschappen. Verantwoord klimmen houdt onze rotsen open.',
  ChaveTexto.buscaTodos: 'Alles',
  ChaveTexto.buscaPicos: 'Gebieden',
  ChaveTexto.buscaSetores: 'Sectoren',
  ChaveTexto.buscaDica:
      'Tip: zoek op gebieden, sectoren, routes of graden (bijv. 7a, V4)',
  ChaveTexto.buscaNenhumResultado: 'Geen resultaten gevonden.',
  ChaveTexto.buscaFiltroPrefixo: 'Filter: {filtro}',

  // Modalidades, contagens e estilos de escalada/ascensão
  ChaveTexto.modEsportiva: 'Sportklimmen',
  ChaveTexto.modEsportivas: 'Sportroutes',
  ChaveTexto.modEsportivasMinusculo: 'sportroutes',
  ChaveTexto.modMovel: 'Trad',
  ChaveTexto.modMoveis: 'Trad-routes',
  ChaveTexto.modMoveisMinusculo: 'trad-routes',
  ChaveTexto.modMovelTrad: 'Trad',
  ChaveTexto.modBoulder: 'Boulder',
  ChaveTexto.modBoulders: 'Boulders',
  ChaveTexto.modBouldersMinusculo: 'boulders',
  ChaveTexto.modMultienfiada: 'Multi-pitch',
  ChaveTexto.modMultienfiadas: 'Multi-pitches',
  ChaveTexto.modMultiplasEnfiadasMinusculo: 'multi-pitches',
  ChaveTexto.modParedao: 'Big Wall / Multi-pitch',
  ChaveTexto.modHighline: 'Highline',
  ChaveTexto.modHighlines: 'Highlines',
  ChaveTexto.modHighlinesMinusculo: 'highlines',
  ChaveTexto.modMista: 'Mixed',
  ChaveTexto.modOutro: 'Overig',
  ChaveTexto.modOutras: 'Overige',
  ChaveTexto.modVia: 'Route',
  ChaveTexto.modVias: 'Routes',
  ChaveTexto.modViasMinusculo: 'routes',
  ChaveTexto.modEscaladaMinusculo: 'klim',
  ChaveTexto.modEscaladasMinusculo: 'klimmen',
  ChaveTexto.modSetorMinusculo: 'sector',
  ChaveTexto.modSetoresMinusculo: 'sectoren',
  ChaveTexto.modSetoresCaixaAlta: 'SECTOREN',
  ChaveTexto.modDeTotal: '{qtd} van {total} {plural}',
  ChaveTexto.modEstimativaSemTransito:
      'Reistijd zonder verkeer: {tempo} ({distancia})',
  ChaveTexto.estiloAVista: 'Onsight',
  ChaveTexto.estiloFlash: 'Flash',
  ChaveTexto.estiloTrabalhado: 'Redpoint',
  ChaveTexto.estiloTentativa: 'Poging',
  ChaveTexto.estiloGuiado: 'Voorklimmen',
  ChaveTexto.estiloTopRope: 'Toprope',
  ChaveTexto.estiloSolo: 'Solo',
  ChaveTexto.estiloTentativaSingular: 'poging',
  ChaveTexto.estiloTentativaPlural: 'pogingen',

  // Aba Explorar, Globo 3D/2D e Clima
  ChaveTexto.explorarBuscaHint: 'Zoek gebied, stad of route...',
  ChaveTexto.explorarTrocarServing: 'Server wisselen',
  ChaveTexto.explorarAteKm: 'Tot {km} km',
  ChaveTexto.explorarViasBrasileiro: 'Routes (BR-schaal)',
  ChaveTexto.explorarBoulderEscalaV: 'Boulder (V-schaal)',
  ChaveTexto.explorarFiltrosOrdenacao: 'Filters & Sorteren',
  ChaveTexto.explorarOrdenacaoSecao: 'SORTEREN OP',
  ChaveTexto.explorarMaisProximos: 'Dichtstbijzijnde',
  ChaveTexto.explorarAlfabeticoAZ: 'Alfabetisch (A-Z)',
  ChaveTexto.explorarMaisEscaladas: 'Meeste routes',
  ChaveTexto.explorarModalidadesSecao: 'DISCIPLINES',
  ChaveTexto.explorarDificuldadeSecao: 'MOEILIJKHEID IN CATALOGUS',
  ChaveTexto.explorarAlcanceSecao: 'BEREIK & BESCHIKBAARHEID',
  ChaveTexto.explorarSalvosOffline: 'Offline opgeslagen',
  ChaveTexto.explorarVerNPicos: '{total} gebieden bekijken',
  ChaveTexto.explorarModoMapa: 'Kaart',
  ChaveTexto.explorarModoDividir: 'Splitsen',
  ChaveTexto.explorarModoLista: 'Lijst',
  ChaveTexto.explorarContagemPicos: '{n} GEBIEDEN',
  ChaveTexto.explorarNenhumPicoEncontrado: 'Geen klimgebied gevonden.',
  ChaveTexto.explorarSetorPrincipal: 'Hoofdsector',
  ChaveTexto.explorarAcimaDoMar: '{metros} m boven zeeniveau',
  ChaveTexto.climaSeco: 'Droog',
  ChaveTexto.climaPossivelmenteUmido: 'Mogelijk vochtig',
  ChaveTexto.climaRochaSecaSemChuva:
      'Waarschijnlijk droog · Geen regen dichtbij (4 dagen)',
  ChaveTexto.climaContagemUmDia: '1 dag',
  ChaveTexto.climaContagemDias: '{dias} dagen',
  ChaveTexto.climaChuvaProximaHoje: 'regen dichtbij vandaag ({data})',
  ChaveTexto.climaChuvaProximaUmDia: 'regen dichtbij 1 dag geleden ({data})',
  ChaveTexto.climaChuvaProximaDias:
      'regen dichtbij {dias} dagen geleden ({data})',
  ChaveTexto.climaNotaJanelaQuatroDias:
      'Conservatief venster van 4 dagen dat bij elke regenbui in de regio opnieuw start. Controleer de rots ter plaatse.',
  ChaveTexto.climaNotaEstimativaSatelite:
      'Regionale satellietschatting — lokale lekkage kan variëren.',
  ChaveTexto.explorarBotaoClimaMapa: 'Regen & Vuur',
  ChaveTexto.explorarAvisoClimaTitulo: 'Gebruikswaarschuwing',
  ChaveTexto.explorarAvisoClimaCorpo:
      'Aresta gebruikt 3 weer- en radarbronnen EN 3 openbare bronnen van NASA-missies om een slagingskans van ~86% te behalen bij het tonen van deze informatie. Gebruik dit hulpmiddel als referentie in plaats van absolute waarheid.',
  ChaveTexto.explorarAvisoClimaConfirmar: 'OK, toon op kaart',
  ChaveTexto.climaChuvaFraca: 'Lichte regen',
  ChaveTexto.climaChuvaModerada: 'Matige regen',
  ChaveTexto.climaChuvaForte: 'Zware regen',
  ChaveTexto.climaTempestadeSevera: 'Zware storm',
  ChaveTexto.climaFocoIsolado: 'Geïsoleerde warmtehaard',
  ChaveTexto.climaFocoQueimada: 'Brandhaard',
  ChaveTexto.climaIncendioAtivo: 'Actieve bosbrand',
  ChaveTexto.climaIncendioSevero: 'Zware bosbrand',

  // Meus Croquis e Modais Offline
  ChaveTexto.meusCroquisTitulo: "MIJN TOPO'S",
  ChaveTexto.meusCroquisSubtitulo: 'OFFLINE OPSLAG',
  ChaveTexto.meusCroquisVazio: "Nog geen topo's offline opgeslagen.",
  ChaveTexto.meusCroquisAbrirOffline: 'OFFLINE OPENEN',
  ChaveTexto.meusCroquisErroAbrir: 'Fout bij openen van offline gids.',
  ChaveTexto.meusCroquisExcluirTitulo: 'Verwijderen?',
  ChaveTexto.meusCroquisExcluirPergunta:
      'Offline gids voor {nome} verwijderen?',
  ChaveTexto.meusCroquisExcluidoToast: 'Gids verwijderd.',
  ChaveTexto.meusCroquisErroExcluirToast: 'Fout bij verwijderen van gids.',
  ChaveTexto.meusCroquisGuiaRemovidoToast:
      'Gids verwijderd uit offline opslag.',
  ChaveTexto.offlineSalvarComTamanho: 'Offline opslaan ({tamanho})',
  ChaveTexto.offlineSalvarSemTamanho: 'Offline opslaan',
  ChaveTexto.offlineModoOnlineTitulo: 'ONLINE MODUS',
  ChaveTexto.offlineModoOnlineDesc:
      'Je bladert nu online. Sla de volledige gids op om zonder bereik bij de rots te gebruiken.',
  ChaveTexto.offlineBaixandoPct: 'DOWNLOADEN ({pct}%)...',
  ChaveTexto.offlineSalvarParaPedraTitulo: 'OPSLAAN VOOR DE ROTS?',
  ChaveTexto.offlineSalvarParaPedraCorpo:
      "Denk eraan: bij de rots is vaak geen bereik. Sla de gids op om de topo's en graden van {nome} offline te bekijken.",
  ChaveTexto.offlineSairSemSalvar: 'Verlaten zonder opslaan',
  ChaveTexto.offlineSemConexaoTitulo: 'JE BENT OFFLINE',
  ChaveTexto.offlineSemConexaoCorpo:
      'Deze inhoud hoort bij {nome} en staat nog niet offline op je toestel. Maak verbinding met internet en probeer het opnieuw.',
  ChaveTexto.offlineAindaSemConexao:
      'Nog steeds geen internetverbinding. Controleer je netwerk.',
  ChaveTexto.offlineTentandoConectar: 'Verbinden...',

  // Página do Pico, Subpáginas, Setor, Grupo, Filtros de Índice e Croqui Interativo
  ChaveTexto.picoCompartilharTooltip: 'Gebied delen',
  ChaveTexto.picoExcluirGuiaTooltip: 'Gids verwijderen',
  ChaveTexto.picoBuscarBoulderTooltip: 'Boulder zoeken',
  ChaveTexto.picoBuscarViaTooltip: 'Route zoeken',
  ChaveTexto.picoCardSetoresTitulo: 'Sectoren & Routes',
  ChaveTexto.picoCardSetoresSubtitulo:
      'Verken sectoren, routes en boulders met filters en kaarten',
  ChaveTexto.picoCardExplorarTitulo: 'Gebied verkennen',
  ChaveTexto.picoCardExplorarSubtitulo:
      'Aanlooproute, overzichtskaarten, weer en praktische info.',
  ChaveTexto.picoCardRegrasTitulo: 'Regels & richtlijnen',
  ChaveTexto.picoCardRegrasSubtitulo:
      'Natuurregels, veiligheid, klimethiek en lokale afspraken.',
  ChaveTexto.picoCardComunidadeTitulo: 'Community',
  ChaveTexto.picoCardComunidadeSubtitulo:
      'Social media, WhatsApp-kanaal, sponsors en lokale ondernemers.',
  ChaveTexto.picoCardCreditosSubtitulo:
      'Ontmoet de auteurs, bijdragers en dankbetuigingen.',
  ChaveTexto.picoVoltarMapaSetor: 'Terug naar sectorkaart',
  ChaveTexto.picoCroquiPor: 'Topo door {autores}',
  ChaveTexto.picoInfoLocal: 'Gebiedsinformatie',
  ChaveTexto.picoCampoNome: 'Naam',
  ChaveTexto.picoCampoEstado: 'Deelstaat',
  ChaveTexto.picoMaisInfoSecao: 'Meer informatie',
  ChaveTexto.picoMapasGerais: 'Overzichtskaarten',
  ChaveTexto.picoNenhumElemento: 'Geen items beschikbaar.',
  ChaveTexto.picoBuscarBoulderHint: 'Zoek boulder (bijv. V4) of sector...',
  ChaveTexto.picoBuscarEscaladaHint: 'Zoek route (bijv. 7a) of sector...',
  ChaveTexto.picoDificuldadePrefixo: 'Graad: {grau}',
  ChaveTexto.picoUltimaAtualizacaoNaoInformada: 'Laatste update: Onbekend',
  ChaveTexto.picoUltimaAtualizacaoHoje: 'Laatste update: Vandaag om {hora}',
  ChaveTexto.picoUltimaAtualizacaoOntem: 'Laatste update: Gisteren om {hora}',
  ChaveTexto.picoUltimaAtualizacaoData: 'Laatste update: {data} om {hora}',
  ChaveTexto.picoSubExplorarTitulo: 'GEBIED VERKENNEN',
  ChaveTexto.picoSubIntroSubtitulo: 'Algemene introductie van het gebied.',
  ChaveTexto.picoSubSobreLocal: 'Over het gebied',
  ChaveTexto.picoSubSobreLocalSubtitulo:
      'Geschiedenis van het massief, eerste beklimmingen en weetjes.',
  ChaveTexto.picoSubComoChegar: 'Bereikbaarheid',
  ChaveTexto.picoSubComoChegarSubtitulo:
      'Aanloopinstructies en navigatie tot onderaan de rots.',
  ChaveTexto.picoSubAbrirMaps: 'Openen in Google Maps',
  ChaveTexto.picoSubAbrirMapsSubtitulo:
      'Bekijk locatie en plan de route naar het gebied.',
  ChaveTexto.picoSubExtrasSubtitulo: 'Extra informatie over het gebied.',
  ChaveTexto.picoSubComunidadeTitulo: 'COMMUNITY',
  ChaveTexto.picoSubInformacoes: 'Informatie',
  ChaveTexto.picoSubAssociacaoLocal: 'Lokale klimvereniging',
  ChaveTexto.picoSubParceiros: 'Partners',
  ChaveTexto.picoSubComercioLocal: 'Lokale horeca & winkels',
  ChaveTexto.picoSubApoieTitulo: 'STEUN HET GEBIED',
  ChaveTexto.picoSubDoacaoPix: 'Donatie via Pix',
  ChaveTexto.picoSubDoacaoPixSubtitulo:
      'Help mee aan RVS-boorhaken en relais.\nSleutel: {chave}',
  ChaveTexto.picoSubPixCopiadoToast: 'Pix-sleutel gekopieerd!',
  ChaveTexto.picoSubProdutos: 'Producten van het gebied',
  ChaveTexto.picoSubPatrocinador: 'Word sponsor',
  ChaveTexto.picoSubPatrocinadorSubtitulo:
      'Verbind je merk duurzaam en ethisch met de klimsport.',
  ChaveTexto.picoSubEnviarInfo: 'Informatie insturen',
  ChaveTexto.picoSubEnviarInfoSubtitulo:
      'Draag bij met nieuwe routes of correcties.',
  ChaveTexto.picoRegrasTitulo: 'REGELS & RICHTLIJNEN',
  ChaveTexto.picoRegrasVazio:
      'Geen specifieke regels geregistreerd voor deze plek. Volg de algemene natuur- en klimethiek.',
  ChaveTexto.picoGpsEmBreve: 'GPS-functies binnenkort beschikbaar',
  ChaveTexto.setorTituloPagina: 'SECTOREN & ROUTES',
  ChaveTexto.setorCompartilharTooltip: 'Sector delen',
  ChaveTexto.setorCompartilharGrupoTooltip: 'Deelgebied delen',
  ChaveTexto.setorNenhumSetorDisponivel: 'Geen sector beschikbaar.',
  ChaveTexto.setorNenhumaViaDisponivel: 'Geen route beschikbaar.',
  ChaveTexto.setorNenhumBoulderDisponivel: 'Geen boulder beschikbaar.',
  ChaveTexto.setorNenhumSetorCadastrado:
      'Er zijn nog geen sectoren of routes geregistreerd voor dit gebied.',
  ChaveTexto.setorNenhumSetorFiltrado:
      'Geen sectoren gevonden met de geselecteerde filters.',
  ChaveTexto.setorNenhumaEscaladaFiltrada:
      'Geen klimmen gevonden met de geselecteerde filters.',
  ChaveTexto.setorVerNoCroqui: 'Bekijk op topo',
  ChaveTexto.setorAbrirCroquiSemantics: 'Open topo van sector {nome}',
  ChaveTexto.filtroPadrao: 'STANDAARD',
  ChaveTexto.filtroPadraoMisto: 'Standaard',
  ChaveTexto.filtroGrau: 'GRAAD',
  ChaveTexto.filtroGrauMisto: 'Graad',
  ChaveTexto.filtroAlfabetico: 'ALFABETISCH',
  ChaveTexto.filtroAtivoSingular: '1 actief',
  ChaveTexto.filtroAtivoPlural: '{n} actief',
  ChaveTexto.filtroLocalizacao: 'Locatie',
  ChaveTexto.filtroConquistaAutores: 'Eerste beklimming (Behakers)',
  ChaveTexto.filtroApenasClassicas: 'Alleen klassiekers (★)',
  ChaveTexto.filtroClassicas: 'Klassiekers (★)',
  ChaveTexto.filtroModalidadeInativa: 'Discipline inactief',
  ChaveTexto.filtroTodosGrausFaixa: 'Alle graden ({min} t/m {max})',
  ChaveTexto.filtroTodosGraus: 'Alle graden',
  ChaveTexto.filtroGrauUnico: 'Graad: {grau}',
  ChaveTexto.filtroGrauFaixa: 'Graad: {min} t/m {max}',
  ChaveTexto.filtroConectorA: 't/m',
  ChaveTexto.filtroFaixaGrauVias: 'Graadbereik (Routes)',
  ChaveTexto.filtroFaixaGrauBoulders: 'Graadbereik (Boulders)',
  ChaveTexto.filtroFaixaGrau: 'Graadbereik',
  ChaveTexto.filtroAddSetorOuGrupo: 'Sector of deelgebied toevoegen...',
  ChaveTexto.filtroAddSetor: 'Sector toevoegen...',
  ChaveTexto.filtroTodosSetoresGruposAdd:
      'Alle sectoren en deelgebieden toegevoegd',
  ChaveTexto.filtroTodosSetoresAdd: 'Alle sectoren toegevoegd',
  ChaveTexto.filtroNenhumLocalAtual: 'Geen locaties in huidige filters',
  ChaveTexto.filtroNenhumSetorAtual: 'Geen sectoren in huidige filters',
  ChaveTexto.filtroAddConquistador: 'Behaker toevoegen...',
  ChaveTexto.filtroTodosConquistadoresAdd: 'Alle behakers toegevoegd',
  ChaveTexto.filtroNenhumConquistadorAtual: 'Geen behakers in huidige filters',
  ChaveTexto.croquiMapasInterativosContagem: "Interactieve Topo's ({n})",
  ChaveTexto.croquiAbrirMapaInterativo: 'Interactieve Topo openen',
  ChaveTexto.croquiTituloPagina: 'Interactieve Topo',
  ChaveTexto.croquiMaisInfo: 'Meer info',
  ChaveTexto.croquiVerMapas: 'Kaarten',
  ChaveTexto.croquiIrParaSetor: 'Naar sector',
  ChaveTexto.croquiIrParaGrupo: 'Naar deelgebied',
  ChaveTexto.croquiCentralizarTooltip: 'Afbeelding centreren',
  ChaveTexto.croquiPaginacaoDe: '{atual} van {total}',

  // Detalhes da Via, Consenso de Grau, Especificações Técnicas e Alertas de Segurança
  ChaveTexto.viaClassica: 'KLASSIEKER',
  ChaveTexto.viaGrauMaximo: 'MAXIMALE GRAAD',
  ChaveTexto.viaGrauOficial: 'OFFICIËLE GRAAD',
  ChaveTexto.viaConsensoComunidade: 'COMMUNITY-CONSENSUS',
  ChaveTexto.viaSemVotos: 'Geen stemmen',
  ChaveTexto.viaNAvaliacoes: '{n} beoordelingen',
  ChaveTexto.viaDistribuicaoVotos: 'STEMVERDELING ({n})',
  ChaveTexto.viaGrauJustoCurto: 'Juist',
  ChaveTexto.viaGrauJustoZero: 'Juiste graad (0)',
  ChaveTexto.viaGrauJustoComNota: 'Juist ({grau})',
  ChaveTexto.viaRegistreParaAvaliar: 'Log je beklimming om te stemmen',
  ChaveTexto.viaConfirmamGrauPct: '{pct}% bevestigt de graad',
  ChaveTexto.viaSugeremGrauPct: '{pct}% stelt {sinal} voor',
  ChaveTexto.viaLinhaNumero: 'Lijn #{n}',
  ChaveTexto.viaVerNoCroquiInterativo: 'BEKIJK OP INTERACTIEVE TOPO',
  ChaveTexto.viaCompartilharTooltip: 'Route delen',
  ChaveTexto.viaReportarAlertaTooltip: 'Veiligheidswaarschuwing melden',
  ChaveTexto.viaEntreParaReportarToast:
      'Log in bij Profiel om veiligheidswaarschuwingen te melden.',
  ChaveTexto.viaAlertaRegistradoToast: 'Veiligheidswaarschuwing opgeslagen!',
  ChaveTexto.viaEntreParaVotarToast:
      'Log in bij Profiel om op de graad te stemmen.',
  ChaveTexto.viaVotoAtualizadoToast: 'Graadstem bijgewerkt!',
  ChaveTexto.viaComentarioAtualizadoToast: 'Opmerking bijgewerkt!',
  ChaveTexto.viaComentarioExcluidoToast: 'Opmerking verwijderd.',
  ChaveTexto.viaAncoragemPrefixo: 'Relais: {tipo}',
  ChaveTexto.viaEnfiadasContagem: 'TOUWLENGTES ({n})',
  ChaveTexto.viaProtecoesAbrev: '{n} haken',
  ChaveTexto.viaMovelPrefixo: 'Trad: {equip}',
  ChaveTexto.viaHistoricoConquista: 'HISTORIE & EERSTE BEKLIMMING',
  ChaveTexto.viaConquistadores: 'EERSTBEKLIMMERS / BEHAKERS',
  ChaveTexto.viaAbertura: 'GEOPEND',
  ChaveTexto.viaManutencao: 'ONDERHOUD',
  ChaveTexto.viaApoieManutencaoPix: 'Steun herbehaking (Pix: {chave})',
  ChaveTexto.viaPixManutencaoCopiadoToast: 'Pix-sleutel gekopieerd!',
  ChaveTexto.viaVideosBetasContagem: "VIDEO'S & BETA ({n})",
  ChaveTexto.viaBetasComunidadeContagem: 'COMMUNITY-BETA ({n})',
  ChaveTexto.viaEditarComentarioTooltip: 'Opmerking bewerken',
  ChaveTexto.viaExcluirComentarioTooltip: 'Opmerking verwijderen',
  ChaveTexto.viaEditarComentarioTitulo: 'Opmerking bewerken',
  ChaveTexto.viaEditarComentarioSubtitulo:
      'Werk je openbare notitie of beta voor deze route bij.',
  ChaveTexto.viaExcluirComentarioTitulo: 'Opmerking verwijderen?',
  ChaveTexto.viaExcluirComentarioCorpo:
      'Je openbare opmerking wordt definitief verwijderd van deze route.',
  ChaveTexto.viaProjeto: 'Project',
  ChaveTexto.viaMediaPrefixo: 'Gem. {media}',
  ChaveTexto.viaArtificialLivre: 'Artificieel {art} ({livre} vrij)',
  ChaveTexto.viaArtificialPuro: 'Artificieel {art}',
  ChaveTexto.viaGuiaOficialConquistador: 'Officiële gids / Behaker',
  ChaveTexto.viaSpecExtensao: 'LENGTE',
  ChaveTexto.viaSpecParede: 'WANDHOEK',
  ChaveTexto.viaSpecExposicao: 'EXPOSITIE',
  ChaveTexto.viaSpecEnfiadas: 'LENGTES',
  ChaveTexto.viaSpecComprimento: 'TOTAAL',
  ChaveTexto.viaSpecMaiorEnfiada: 'LANGSTE TL',
  ChaveTexto.viaSpecDuracao: 'DUUR',
  ChaveTexto.viaSpecTipo: 'STIJL',
  ChaveTexto.viaSpecDistancia: 'AFSTAND',
  ChaveTexto.viaSpecAltura: 'HOOGTE',
  ChaveTexto.viaSpecProtecoes: 'ZEKERINGEN',
  ChaveTexto.viaSecaoDescricao: 'Beschrijving',
  ChaveTexto.viaSecaoPecasMoveis: 'Mobiele zekeringen',
  ChaveTexto.viaSecaoRackEquipamento: 'Rack & Materiaal',
  ChaveTexto.viaSecaoDescricaoAcesso: 'Aanloopbeschrijving',
  ChaveTexto.viaSecaoDescricaoAncoragem: 'Relaisbeschrijving',
  ChaveTexto.viaEnfiadaNumero: 'Touwlengte {n}',
  ChaveTexto.viaBetaEmOrigem: 'Beta op {origem}',
  ChaveTexto.viaAssistirVideoBeta: 'Bekijk Beta-video',
  ChaveTexto.viaVideo: 'Video',
  ChaveTexto.alertaPrefixoSemantics: 'Waarschuwing: {rotulo}',
  ChaveTexto.alertaFaunaTitulo: 'Dieren / Fauna',
  ChaveTexto.alertaFaunaDesc:
      'Bijen, wespen, slangen, broedende vogels of andere dieren op de route.',
  ChaveTexto.alertaRochaInstavelTitulo: 'Losse rots of greep',
  ChaveTexto.alertaRochaInstavelDesc:
      'Los blok, gevaarlijke schilfer of greep die kan afbreken.',
  ChaveTexto.alertaProtecaoPrecariaTitulo: 'Slechte haak / zekering',
  ChaveTexto.alertaProtecaoPrecariaDesc:
      'Loszittende haakplaat, zware roest of beschadigd relais.',
  ChaveTexto.alertaExposicaoTitulo: 'Hoge expositie (E4+)',
  ChaveTexto.alertaExposicaoDesc:
      'Grote runout (E4+), kans op grondval of verre haken.',
  ChaveTexto.alertaCriadoPorVoce: 'DOOR JOU GEMELD',
  ChaveTexto.alertaConfirmadoMaisUm: 'BEVESTIGD (+1)',
  ChaveTexto.alertaReportadoPorEm:
      'Gemeld door {autor} op {data} • {n}x bevestigd',
  ChaveTexto.alertaEntreParaConfirmar:
      'Log in bij Profiel om deze waarschuwing te bevestigen of bij te werken.',
  ChaveTexto.alertaAindaEstaLa: 'Nog steeds aanwezig?',
  ChaveTexto.alertaNaoJaResolveu: 'Nee, opgelost',
  ChaveTexto.alertaReportadoPorVoceCheck: '✓ Door jou gemeld',
  ChaveTexto.alertaConfirmadoPorVoceCheck: '✓ Door jou bevestigd',
  ChaveTexto.alertaSimAindaEstaLa: 'Ja, nog aanwezig',
  ChaveTexto.alertaEditarBtn: 'Waarschuwing bewerken',
  ChaveTexto.alertaExcluirBtn: 'Waarschuwing verwijderen',
  ChaveTexto.alertaResolvidoToast: 'Waarschuwing gemarkeerd als opgelost.',
  ChaveTexto.alertaResolvidoNaViaToast:
      'Waarschuwing op {nome} gemarkeerd als opgelost.',
  ChaveTexto.alertaAtualizadoToast: 'Waarschuwing bijgewerkt!',
  ChaveTexto.alertaFalhaAtualizarToast:
      'Kan deze waarschuwing niet bijwerken.',
  ChaveTexto.alertaExcluidoToast: 'Waarschuwing verwijderd.',
  ChaveTexto.alertaEditarModalTitulo: 'Routewaarschuwing bewerken',
  ChaveTexto.alertaReportarModalTitulo: 'Routewaarschuwing melden',
  ChaveTexto.alertaEditarModalSub:
      'Werk de categorie of details van deze veiligheidswaarschuwing bij.',
  ChaveTexto.alertaReportarModalSub:
      "Waarschuw andere klimmers voor directe risico's op deze lijn.",
  ChaveTexto.alertaDetalheLabel: 'Korte toelichting (optioneel)',
  ChaveTexto.alertaDetalheHint: 'Bijv.: Bijennest vlak bij het 3e setje',
  ChaveTexto.alertaEnviarBtn: 'Waarschuwing sturen',
  ChaveTexto.alertaExcluirModalTitulo: 'Waarschuwing verwijderen?',
  ChaveTexto.alertaExcluirModalCorpo:
      'Deze veiligheidswaarschuwing wordt definitief van de route verwijderd.',
  ChaveTexto.alertaAtivoUmConfirmacao: 'Actief • 1 bevestiging',
  ChaveTexto.alertaAtivoVariasConfirmacoes: 'Actief • {n} bevestigingen',
  ChaveTexto.alertaResolvidoStatus: 'Opgelost',
  ChaveTexto.alertaMarcarResolvido: 'Markeer als opgelost',

  // Autenticação, Perfil, Caderneta, Comunidade, Configurações, Feedback e Compartilhamento
  ChaveTexto.authEntrarTitulo: 'Inloggen op je account',
  ChaveTexto.authEntrarSubtitulo:
      'Log wachtwoordloos in met je sociale account of een 6-cijferige e-mailcode om je klimlogboek te synchroniseren.',
  ChaveTexto.authContinuarGoogle: 'Doorgaan met Google',
  ChaveTexto.authContinuarApple: 'Doorgaan met Apple',
  ChaveTexto.authOuCodigoEmail: 'of ontvang een code per e-mail',
  ChaveTexto.authEmailLabel: 'E-mailadres',
  ChaveTexto.authAguardeSegundos: 'Wacht {s}s',
  ChaveTexto.authReceberCodigoEmail: 'Code per e-mail sturen',
  ChaveTexto.authCodigo6DigitosLabel: '6-cijferige code',
  ChaveTexto.authConfirmarCodigo: 'Code bevestigen',
  ChaveTexto.authReenviarComSegundos: 'Opnieuw sturen ({s}s)',
  ChaveTexto.authReenviarCodigo: 'Code opnieuw sturen',
  ChaveTexto.authUsarOutroEmail: 'Ander e-mailadres gebruiken',
  ChaveTexto.authAbrirConfigApp: 'App-instellingen openen',
  ChaveTexto.authLimiteTemporario:
      'Tijdelijke limiet bereikt. Wacht {s}s voordat je een nieuwe code aanvraagt.',
  ChaveTexto.authCodigoEnviadoPara:
      'We hebben een 6-cijferige code gestuurd naar {email}. Controleer je inbox en spam.',
  ChaveTexto.authErroEnviarCodigo:
      'Kan toegangscode niet verzenden. Probeer het opnieuw.',
  ChaveTexto.authErroValidarCodigo:
      'Kan toegangscode niet verifiëren. Probeer het opnieuw.',
  ChaveTexto.authErroGoogle:
      'Inloggen met Google mislukt. Probeer het opnieuw.',
  ChaveTexto.authErroApple: 'Inloggen met Apple mislukt. Probeer het opnieuw.',
  ChaveTexto.authSemConexao:
      'Geen internetverbinding. Controleer je bereik en probeer opnieuw.',
  ChaveTexto.authSrvChaveInvalida:
      'Ongeldige serversleutel. Probeer het opnieuw.',
  ChaveTexto.authSrvCodigoExpirado:
      'De toegangscode is verlopen of ongeldig.',
  ChaveTexto.authSrvEmailInvalido: 'Voer een geldig e-mailadres in.',
  ChaveTexto.authSrvProvedorDesabilitado:
      'Inlogprovider is niet ingeschakeld op de server.',
  ChaveTexto.authSrvCredencialInvalida:
      'Kan inloggegevens niet valideren op de server.',
  ChaveTexto.authSrvLimiteEnvio:
      'Verzendlimiet bereikt. Wacht even en probeer het opnieuw.',
  ChaveTexto.authSrvSessaoExpirada:
      'Je sessie is verlopen. Log opnieuw in.',
  ChaveTexto.authSrvCancelado: 'Inloggen geannuleerd.',
  ChaveTexto.authSrvCooldownAposUm:
      'Om veiligheidsredenen kun je na 1 seconde een nieuwe code aanvragen.',
  ChaveTexto.authSrvCooldownAposVarios:
      'Om veiligheidsredenen kun je na {s} seconden een nieuwe code aanvragen.',
  ChaveTexto.authSrvCooldownCadaUm:
      'Om veiligheidsredenen kun je elke 1 seconde een nieuwe code aanvragen.',
  ChaveTexto.authSrvCooldownCadaVarios:
      'Om veiligheidsredenen kun je elke {s} seconden een nieuwe code aanvragen.',
  ChaveTexto.perfilEscaladorPadrao: 'Klimmer',
  ChaveTexto.perfilEscaladorAresta: 'Aresta-klimmer',
  ChaveTexto.perfilEditarBtn: 'Profiel bewerken',
  ChaveTexto.perfilMetricaCadenas: 'TOPS',
  ChaveTexto.perfilMetricaTentativas: 'POGINGEN',
  ChaveTexto.perfilMetricaPicos: 'GEBIEDEN',
  ChaveTexto.perfilMetricaVias: 'ROUTES',
  ChaveTexto.perfilEntrarConta: 'Inloggen',
  ChaveTexto.perfilMinhaCaderneta: 'Mijn logboek',
  ChaveTexto.perfilDadosPrivacidade: 'Gegevens & privacy',
  ChaveTexto.perfilSair: 'Uitloggen',
  ChaveTexto.perfilExcluirConta: 'Account verwijderen',
  ChaveTexto.perfilIdCopiadoToast: 'Openbare ID gekopieerd!',
  ChaveTexto.perfilSemConexaoExcluir:
      'Geen internetverbinding. Maak verbinding om je account te verwijderen.',
  ChaveTexto.perfilErroExcluirConta:
      'Account kan momenteel niet worden verwijderd.',
  ChaveTexto.perfilDialogEditarTitulo: 'Profiel bewerken',
  ChaveTexto.perfilAlterarFoto: 'Profielfoto wijzigen',
  ChaveTexto.perfilNomeAtletaLabel: 'Naam van de klimmer',
  ChaveTexto.perfilPrivacidadeTitulo: 'Gegevens & Privacy',
  ChaveTexto.perfilPrivacidadeCorpo:
      'Aresta Climb respecteert jouw privacy. Je logboek is strikt privé. Openbare graadstemmen en waarschuwingen gebruiken enkel je anonieme Auteurs-ID zonder persoonlijke gegevens te delen.',
  ChaveTexto.perfilIdPublicoLabel: 'OPENBARE AUTEURS-ID (NANOID)',
  ChaveTexto.perfilCopiarIdTooltip: 'Openbare ID kopiëren',
  ChaveTexto.perfilSairPergunta: 'Weet je zeker dat je wilt uitloggen?',
  ChaveTexto.perfilSairCorpo:
      'Je persoonlijke logboek blijft veilig bewaard op dit toestel.',
  ChaveTexto.perfilExcluirPergunta: 'Account definitief verwijderen?',
  ChaveTexto.perfilExcluirCorpo:
      'Dit kan niet ongedaan worden gemaakt. Je account, profielfoto en gesynchroniseerde beklimmingen worden definitief gewist.',
  ChaveTexto.cadTituloPagina: 'MIJN LOGBOEK',
  ChaveTexto.cadAscensaoAtualizadaToast: 'Beklimming bijgewerkt in je logboek!',
  ChaveTexto.cadViaIndisponivelOffline:
      'Route is momenteel offline niet beschikbaar.',
  ChaveTexto.cadTotalCadenas: 'Totaal getopt',
  ChaveTexto.cadTaxaAVistaFlash: 'Onsight/Flash-ratio',
  ChaveTexto.cadMaiorGrauVias: 'Hoogste graad (Routes)',
  ChaveTexto.cadMaiorGrauBoulders: 'Hoogste graad (Boulders)',
  ChaveTexto.cadPiramideTitulo: 'Graadpiramide',
  ChaveTexto.cadNenhumaAscensaoModalidade:
      'Nog geen beklimmingen geregistreerd in deze discipline.',
  ChaveTexto.cadHistoricoContagem: 'Beklimmingshistorie ({n})',
  ChaveTexto.cadMeusAlertasContagem: 'Mijn rotswaarschuwingen ({n})',
  ChaveTexto.cadNenhumaAscensaoAinda: 'Nog geen beklimmingen gelogd',
  ChaveTexto.cadNenhumaAscensaoSub:
      'Je opgeslagen beklimmingen van routepagina’s verschijnen hier.',
  ChaveTexto.cadEditarAscensaoTooltip: 'Beklimming bewerken',
  ChaveTexto.cadExcluirAscensaoTooltip: 'Beklimming verwijderen',
  ChaveTexto.cadExcluirAscensaoTitulo: 'Beklimming verwijderen?',
  ChaveTexto.cadExcluirAscensaoCorpo:
      'Deze beklimming wordt definitief uit je logboek verwijderd.',
  ChaveTexto.cadEstiloEsportivoLabel: 'Klimstijl',
  ChaveTexto.cadTentativasPegasLabel: 'Pogingen',
  ChaveTexto.cadDataAscensaoLabel: 'Klimdatum',
  ChaveTexto.cadNotasPrivadasLabel: 'Privénotities (Crux / Beta)',
  ChaveTexto.cadNotasPrivadasHint:
      'Bijv.: Linker heelhook bij 3e haak, lang setje meenemen...',
  ChaveTexto.cadCadenaSalvaToast: 'Beklimming opgeslagen in logboek!',
  ChaveTexto.cadTentativaSalvaToast: 'Poging opgeslagen in logboek!',
  ChaveTexto.cadContribuicaoPublica: 'OPENBARE BIJDRAGE',
  ChaveTexto.cadPercepcaoGrau: 'Hoe voelde de moeilijkheidsgraad?',
  ChaveTexto.cadBetaOpcionalLabel: 'Community-beta (optioneel)',
  ChaveTexto.cadBetaOpcionalHint:
      'Bijv.: Setje 3 verlengen; linksom lezen in de crux.',
  ChaveTexto.cadConecteParaContribuir:
      'Log in bij Profiel om graadstemmen en openbare beta te delen.',
  ChaveTexto.cadEditarModalTitulo: 'Beklimming bewerken',
  ChaveTexto.cadRegistrarModalTitulo: 'Beklimming loggen',
  ChaveTexto.cadSalvarEContribuir: 'Opslaan & Delen',
  ChaveTexto.cadSalvarNaCaderneta: 'Opslaan in logboek',
  ChaveTexto.cadEncadenadaEm: 'Getopt op {data} ({estilo})',
  ChaveTexto.cadTentativaEm: 'Poging op {data}',
  ChaveTexto.cadNovaAscensaoBtn: 'Nieuwe beklimming / poging',
  ChaveTexto.cadRegistrarCadenaBtn: 'Beklimming / poging loggen',
  ChaveTexto.comunidadeHeader: 'MEDIA, STEUN & COMMUNITY',
  ChaveTexto.comunidadeSobreTimeTitulo: 'OVER HET TEAM',
  ChaveTexto.comunidadeSobreTimeSub:
      'Maak kennis met de ontwikkelaars en bijdragers achter Aresta.',
  ChaveTexto.comunidadeWhatsappTitulo: 'WHATSAPP-GROEP',
  ChaveTexto.comunidadeWhatsappSub:
      'Doe mee voor vragen, ideeën en nieuws over Aresta.',
  ChaveTexto.comunidadeInstagramTitulo: 'OFFICIEEL INSTAGRAM',
  ChaveTexto.comunidadeInstagramSub:
      'Volg het laatste nieuws, updates en een kijkje achter de schermen.',
  ChaveTexto.comunidadeLinkedinTitulo: 'PROJECT LINKEDIN',
  ChaveTexto.comunidadeLinkedinSub:
      'Volg nieuws, groei en mijlpalen van Aresta.',
  ChaveTexto.comunidadeDiscordTitulo: 'DEVELOPER DISCORD',
  ChaveTexto.comunidadeDiscordSub:
      'Praat met het team, volg de code en bouw mee aan Aresta.',
  ChaveTexto.comunidadeGithubTitulo: 'ARESTA GITHUB',
  ChaveTexto.comunidadeGithubSub:
      'Bekijk onze open-source repositories op GitHub.',
  ChaveTexto.comunidadeTermosTitulo: 'Gebruiksvoorwaarden & Privacy',
  ChaveTexto.comunidadeTermosSub:
      'Eigen risico bij buitenklimmen en offline-first privacyrichtlijnen.',
  ChaveTexto.comunidadeRodapeVersao: 'Aresta Climb v{versao} • Open Bèta',
  ChaveTexto.comunidadeIniciativaLivre:
      'Een onafhankelijk initiatief voor vrij buitenklimmen.',
  ChaveTexto.comunidadeTermosModalHeader: 'VOORWAARDEN & PRIVACY',
  ChaveTexto.comunidadePoliticaModalHeader: 'PRIVACYBELEID',
  ChaveTexto.timeConhecaSubtitulo: 'MAAK KENNIS MET HET TEAM',
  ChaveTexto.timeOpenSourceTitulo: 'ARESTA IS OPEN SOURCE',
  ChaveTexto.timeOpenSourceCorpo:
      'Wil je bijdragen? Kom naar onze Discord en stuur ons een bericht!',
  ChaveTexto.timeCargoDesigner: 'Designer',
  ChaveTexto.timeCargoProduto: 'Product / Marketing',
  ChaveTexto.timeCargoProdutoQuebra: 'Product/\nMarketing',
  ChaveTexto.timeCargoBackend: 'Backend',
  ChaveTexto.timeCargoFrontend: 'Frontend',
  ChaveTexto.legalTermosTitulo: 'Gebruiksvoorwaarden',
  ChaveTexto.legalPoliticaTitulo: 'Privacybeleid',
  ChaveTexto.legalErroTermos:
      'Fout bij laden van voorwaarden. Probeer het later opnieuw.',
  ChaveTexto.legalErroPolitica: 'Fout bij laden van privacybeleid.',
  ChaveTexto.legalBannerAtualizacao:
      '🌟 Onze juridische documenten zijn bijgewerkt. Lees ze door en bevestig je akkoord.',
  ChaveTexto.legalDataAtualizacao: 'Bijgewerkt op: {data}',
  ChaveTexto.legalAceitoEm: 'Geaccepteerd op {data} om {hora}',
  ChaveTexto.legalConcordoCheckbox:
      'Ik heb de Gebruiksvoorwaarden en het Privacybeleid gelezen en ga akkoord.',
  ChaveTexto.legalAceitarContinuar: 'Voorwaarden accepteren & doorgaan',
  ChaveTexto.configTitulo: 'Instellingen',
  ChaveTexto.configIdiomaTitulo: 'TAAL',
  ChaveTexto.configIdiomaSubtitulo:
      'Wijzig direct de weergavetaal van de hele app.',
  ChaveTexto.configAparenciaTitulo: 'WEERGAVE',
  ChaveTexto.configAparenciaSub: 'Pas het thema van de app aan.',
  ChaveTexto.configEscolherTemaManual: 'Thema handmatig kiezen',
  ChaveTexto.configTemaEscuro: 'DONKER',
  ChaveTexto.configPerfilCadernetaTitulo: 'PROFIEL & LOGBOEK',
  ChaveTexto.configPerfilCadernetaSub:
      'Toon of verberg je profiel en klimlogboek zonder lokale gegevens te wissen.',
  ChaveTexto.configExibirPerfilSwitch: 'Profiel & Logboek tonen',
  ChaveTexto.configConectarEditorTitulo: 'Editor verbinden',
  ChaveTexto.configConectarEditorInstrucao:
      'Voer de 8-cijferige code uit de Desktop Editor in of scan de QR-code.',
  ChaveTexto.configConectarEditorHint: 'bijv. k9x2-p83a of volledige URL',
  ChaveTexto.configEscanearQrBtn: 'QR-CODE SCANNEN',
  ChaveTexto.configComoFuncionaEditor:
      'Hoe werkt de Desktop Editor? Meer info',
  ChaveTexto.configConectarBtn: 'VERBINDEN',
  ChaveTexto.configModoExperimentalTitulo: 'EXPERIMENTELE / VOORBEELDMODUS',
  ChaveTexto.configModoExperimentalSub:
      "Live gesynchroniseerde topo's bekijken vanuit de Desktop Editor.",
  ChaveTexto.configVoltarModoOficialBtn: 'TERUG NAAR OFFICIËLE MODUS',
  ChaveTexto.configModoOficialTitulo: 'OFFICIËLE MODUS',
  ChaveTexto.configModoOficialSub:
      "Verbonden met de officiële Aresta Climb-catalogus. Verbind met de Desktop Editor om nieuwe topo's live te testen.",
  ChaveTexto.configConectarEditorPreviaBtn: 'VERBINDEN MET EDITOR / PREVIEW',
  ChaveTexto.configComoFazerSaibaMais: 'Hoe werkt dit? Meer info',
  ChaveTexto.configVoltandoOficialToast: 'Terugkeren naar officiële catalogus...',
  ChaveTexto.configReativandoExpToast:
      'Lokale voorbeeldgegevens herstellen...',
  ChaveTexto.configReativarExpBtn: 'VOORBEELDMODUS HERACTIVEREN',
  ChaveTexto.configApagarTudoTitulo: 'Alles wissen?',
  ChaveTexto.configApagarTudoCorpo:
      'Hiermee worden de voorbeeldindex en alle daarin gedownloade gebieden definitief gewist. Doorgaan?',
  ChaveTexto.configApagarTudoBtn: 'ALLES WISSEN',
  ChaveTexto.configAmbienteExpLimpoToast: 'Voorbeeldomgeving gewist.',
  ChaveTexto.configLimparExpBtn: 'VOORBEELDGEGEVENS WISSEN',
  ChaveTexto.configConectadoEditorToast: 'Verbonden met editor-repository!',
  ChaveTexto.configErroIndiceStatus:
      'Fout: Index niet bereikbaar (Status {status})',
  ChaveTexto.configErroConexaoUrl: 'Verbindingsfout: Controleer de URL',
  ChaveTexto.qrTituloPagina: 'QR-code scannen',
  ChaveTexto.qrAponteCamera: 'Richt de camera op de\nQR-code van de repository',
  ChaveTexto.feedbackPerguntaTipo: 'Waar gaat je suggestie over?',
  ChaveTexto.feedbackSobreCroqui: 'Over de Topo',
  ChaveTexto.feedbackSobreApp: 'Over de App',
  ChaveTexto.feedbackHintDescricao: 'Beschrijf het probleem of je idee...',
  ChaveTexto.feedbackAvisoPublico:
      'Openbare feedback. Er worden geen privégegevens gedeeld.',
  ChaveTexto.feedbackEnviarBtn: 'Versturen',
  ChaveTexto.shareConfiraPico:
      'Bekijk de topo van {pico}{loc} op Aresta:\n{url}',
  ChaveTexto.shareConfiraGrupo: 'Bekijk {grupo} bij {pico} op Aresta:\n{url}',
  ChaveTexto.shareConfiraSetor: 'Bekijk {setor} bij {pico} op Aresta:\n{url}',
  ChaveTexto.shareConfiraEscalada:
      'Bekijk {via}{grau}{setor} bij {pico} op Aresta:\n{url}',
  ChaveTexto.gpsDesligadoUltimaConhecida:
      'GPS uitgeschakeld; centreren op laatst bekende locatie.',
  ChaveTexto.gpsAtiveAparelho:
      'Schakel GPS in op je toestel om op je locatie te centreren.',
  ChaveTexto.gpsPermissaoNegada: 'Locatietoestemming geweigerd.',
  ChaveTexto.gpsSinalIndisponivel:
      'Kon op dit moment geen GPS-signaal ontvangen.',
  ChaveTexto.filtroSecaoFiltros: 'FILTERS',
  ChaveTexto.filtroModalidadesTitulo: 'Disciplines',
  ChaveTexto.setorNenhumaEscaladaFiltrosAtuais:
      'Geen klimmen gevonden met de huidige filters.',
  ChaveTexto.modEsportivaMinusculo: 'sportroute',
  ChaveTexto.modMovelMinusculo: 'trad-route',
  ChaveTexto.modBoulderMinusculo: 'boulder',
  ChaveTexto.modMultienfiadaMinusculo: 'multi-pitch',
  ChaveTexto.modMultienfiadasMinusculo: 'multi-pitches',
  ChaveTexto.modHighlineMinusculo: 'highline',
  ChaveTexto.comumFecharCaixaAlta: 'SLUITEN',
  ChaveTexto.authValidacaoCodigo6Digitos:
      'Voer de 6-cijferige code in die per e-mail is verzonden.',
  ChaveTexto.authServicoIndisponivel:
      'Authenticatieservice is momenteel niet beschikbaar.',
  ChaveTexto.configTestarObsolescenciaBtn: 'VEROUDERINGSWAARSCHUWING TESTEN',
  ChaveTexto.configTestarBloqueioBtn: 'BLOKKEERSCHERM TESTEN',
  ChaveTexto.notifBaixandoPct: 'Downloaden... {pct}%',
  ChaveTexto.notifCroquiSalvoOffline: '✓ Topo opgeslagen voor offline gebruik.',
  ChaveTexto.notifFalhaBaixarCroqui:
      'Downloaden van topo mislukt. Controleer je verbinding.',
  ChaveTexto.feedbackRecebidoObrigado:
      'Feedback ontvangen! Heel erg bedankt voor het helpen verbeteren van de app.',
  ChaveTexto.sistemaMigracaoTentarNovamente: 'Opnieuw proberen',
};
