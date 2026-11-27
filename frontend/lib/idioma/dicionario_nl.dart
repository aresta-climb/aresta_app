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

