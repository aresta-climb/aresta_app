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

