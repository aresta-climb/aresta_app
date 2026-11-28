// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'modelo_idioma_app.dart';

/// Dicionário completo em Espanhol (`es-ES` / América Latina) com terminologia autêntica de escalada.
const Map<ChaveTexto, String> dicionarioEspanhol = {
  // Seletor de idioma
  ChaveTexto.seletorIdiomaTitulo: 'IDIOMA DE LA APLICACIÓN',
  ChaveTexto.seletorIdiomaSubtitulo:
      'Elige el idioma mostrado en todas las pantallas de Aresta Climb.',
  ChaveTexto.seletorIdiomaTooltip: 'Cambiar idioma de la aplicación',

  // Navegação e ações globais
  ChaveTexto.navInicio: 'INICIO',
  ChaveTexto.navExplorar: 'EXPLORAR',
  ChaveTexto.navMeusCroquis: 'MIS CROQUIS',
  ChaveTexto.navComunidade: 'COMUNIDAD',
  ChaveTexto.navInicioCurto: 'Inicio',
  ChaveTexto.navGps: 'GPS',
  ChaveTexto.comumVoltar: 'Volver',
  ChaveTexto.comumSegureParaInicio: 'Mantén pulsado para ir a Inicio',
  ChaveTexto.comumFechar: 'Cerrar',
  ChaveTexto.comumCancelar: 'Cancelar',
  ChaveTexto.comumCancelarCaixaAlta: 'CANCELAR',
  ChaveTexto.comumSalvar: 'Guardar',
  ChaveTexto.comumSalvarAlteracoes: 'Guardar Cambios',
  ChaveTexto.comumExcluir: 'Eliminar',
  ChaveTexto.comumExcluirCaixaAlta: 'ELIMINAR',
  ChaveTexto.comumEntendi: 'ENTENDIDO',
  ChaveTexto.comumTentarNovamente: 'Intentar de nuevo',
  ChaveTexto.comumDesfazer: 'Deshacer',
  ChaveTexto.comumLimpar: 'Limpiar',
  ChaveTexto.comumAplicar: 'Aplicar',
  ChaveTexto.comumAplicarUmResultado: 'Aplicar (1 resultado)',
  ChaveTexto.comumAplicarVariosResultados: 'Aplicar ({total} resultados)',
  ChaveTexto.comumSemNome: 'Sin Nombre',
  ChaveTexto.comumSemNomeCaixaAlta: 'SIN NOMBRE',
  ChaveTexto.comumLocalDesconhecido: 'LUGAR DESCONOCIDO',
  ChaveTexto.comumPico: 'Zona',
  ChaveTexto.comumSetor: 'Sector',
  ChaveTexto.comumGrupo: 'Grupo',
  ChaveTexto.comumOffline: 'Sin conexión',
  ChaveTexto.comumSalvoOffline: 'Guardado offline',
  ChaveTexto.comumSalvoOfflineCaixaAlta: 'GUARDADO OFFLINE',
  ChaveTexto.comumCatalogo: 'Catálogo',
  ChaveTexto.comumAbrindo: 'Abriendo {titulo}...',
  ChaveTexto.comumBaixando: 'Descargando {nome}...',
  ChaveTexto.comumBaixadoSucesso: '{nome} descargado',
  ChaveTexto.comumSalvoOfflineToast: '¡{nome} guardado offline!',
  ChaveTexto.comumFalhaBaixar: 'Error al descargar {nome}',
  ChaveTexto.comumSemConexao: 'Sin conexión a internet.',
  ChaveTexto.comumErroAbrirLink: 'Error al abrir el enlace.',
  ChaveTexto.comumLinkCopiado: '¡Enlace copiado!',
  ChaveTexto.comumAbrirLink: 'ABRIR ENLACE',
  ChaveTexto.comumAcessar: 'ABRIR ',
  ChaveTexto.comumVerificandoAtualizacoes: 'Buscando actualizaciones...',
  ChaveTexto.comumErroVerificarAtualizacoes:
      'Error al buscar actualizaciones. Inténtalo más tarde.',
  ChaveTexto.comumConcluidoComFalhas: 'Completado con errores: {falhas}',
  ChaveTexto.comumCatalogoAtualizadoSucesso: '¡Catálogo actualizado con éxito!',
  ChaveTexto.comumCatalogoJaAtualizado: 'El catálogo ya está actualizado.',
  ChaveTexto.comumNenhumCroquiPrecisavaAtualizar:
      'Ningún croquis necesitaba actualizarse.',
  ChaveTexto.comumCroquisAtualizados: '¡Los croquis fueron actualizados!',
  ChaveTexto.comumSincronizandoServing: 'Sincronizando con el servidor...',
  ChaveTexto.comumSemConexaoServing: 'Sin conexión con el servidor.',
  ChaveTexto.comumErroSincronizarServing:
      'Error al sincronizar con el servidor. Inténtalo más tarde.',
  ChaveTexto.comumSincronizadoComFalhas: 'Sincronizado con errores en: {falhas}',
  ChaveTexto.comumCatalogoAtualizadoServing:
      '¡Catálogo actualizado desde el servidor!',
  ChaveTexto.comumCatalogoJaRecenteServing:
      'El catálogo ya está en la última versión.',
  ChaveTexto.comumVersaoDesatualizadaToast:
      'Tu versión de Aresta está desactualizada. Actualízala para seguir descargando croquis.',
  ChaveTexto.comumGuiaAtualizadoToast: '¡La guía de {nome} fue actualizada!',
  ChaveTexto.comumErroSincronizarDadosToast:
      'Error al sincronizar los datos. Inténtalo más tarde.',
  ChaveTexto.comumCroquisBaixadosAtualizadosToast:
      '¡Tus croquis descargados han sido actualizados!',
  ChaveTexto.comumAtualizadoAgora: 'actualizado ahora',
  ChaveTexto.comumAtualizadoHaAno: 'actualizado hace 1 año',
  ChaveTexto.comumAtualizadoHaAnos: 'actualizado hace {n} años',
  ChaveTexto.comumAtualizadoHaMes: 'actualizado hace 1 mes',
  ChaveTexto.comumAtualizadoHaMeses: 'actualizado hace {n} meses',
  ChaveTexto.comumAtualizadoHaDia: 'actualizado hace 1 día',
  ChaveTexto.comumAtualizadoHaDias: 'actualizado hace {n} días',
  ChaveTexto.comumAtualizadoHaHora: 'actualizado hace 1 hora',
  ChaveTexto.comumAtualizadoHaHoras: 'actualizado hace {n} horas',
  ChaveTexto.comumAtualizadoHaMinuto: 'actualizado hace 1 minuto',
  ChaveTexto.comumAtualizadoHaMinutos: 'actualizado hace {n} minutos',
  ChaveTexto.comumEnviarFeedbackTooltip: 'Enviar Sugerencia / Error',
  ChaveTexto.comumFeedbackIndisponivelDev:
      'El envío de comentarios no está disponible en este entorno de desarrollo.',
  ChaveTexto.comumSincronizarServingTooltip: 'Sincronizar con servidor',
  ChaveTexto.comumBuscarPicosHint: 'Buscar zonas para escalar...',
  ChaveTexto.comumMapaGeral: 'Mapa General',

  // Sistema, prévia experimental, versão e migração
  ChaveTexto.sistemaModoExperimentalAtivo: 'MODO EXPERIMENTAL ACTIVO',
  ChaveTexto.sistemaSair: 'SALIR',
  ChaveTexto.sistemaSessaoPreviaEncerradaTitulo: 'Sesión de Vista Previa Cerrada',
  ChaveTexto.sistemaSessaoPreviaEncerradaCorpo:
      'La conexión con el Editor de Escritorio ha finalizado. Como la vista previa es temporal, restauramos automáticamente el catálogo oficial de Aresta Climb.',
  ChaveTexto.sistemaFaseBetaTitulo: 'Fase Beta Abierta',
  ChaveTexto.sistemaFaseBetaIntro:
      'Aresta Climb es una iniciativa independiente en desarrollo activo junto a la comunidad escaladora.',
  ChaveTexto.sistemaFaseBetaItem1Titulo: 'Nuevos sectores y croquis continuos',
  ChaveTexto.sistemaFaseBetaItem1Corpo:
      'Nuestra base de vías, bloques, croquis y mapas crece y se actualiza constantemente.',
  ChaveTexto.sistemaFaseBetaItem2Titulo: 'Funciones en constante evolución',
  ChaveTexto.sistemaFaseBetaItem2Corpo:
      'Filtros avanzados, navegación 3D y mejoras de rendimiento están en camino.',
  ChaveTexto.sistemaFaseBetaItem3Titulo: 'Construcción comunitaria',
  ChaveTexto.sistemaFaseBetaItem3Corpo:
      'Tu experiencia en la roca es clave para pulir detalles y priorizar lo importante.',
  ChaveTexto.sistemaInstagramOficial: 'Instagram Oficial',
  ChaveTexto.sistemaComunidadeWhatsapp: 'Comunidad en WhatsApp',
  ChaveTexto.sistemaEnviarSugestao: 'Enviar Sugerencia',
  ChaveTexto.sistemaRodapeVersaoBeta: 'Aresta Climb v{versao} (Beta Abierta)',
  ChaveTexto.sistemaAtualizeParaBaixar:
      'Actualiza Aresta para volver a descargar y sincronizar croquis.',
  ChaveTexto.sistemaAtualizacaoRecomendada:
      'Actualización Recomendada: hay una nueva versión disponible.',
  ChaveTexto.sistemaAtualizar: 'ACTUALIZAR',
  ChaveTexto.sistemaAtualizacaoNecessaria: 'ACTUALIZACIÓN\nNECESARIA',
  ChaveTexto.sistemaVersaoAntigaCorpo:
      'Tu versión de Aresta es muy antigua y ya no tiene soporte. Actualízala en la tienda para seguir explorando croquis.',
  ChaveTexto.sistemaAtualizarAgora: 'ACTUALIZAR AHORA',
  ChaveTexto.sistemaPreviaFalhaConectar:
      'No se pudo conectar a la sesión de vista previa "{codigo}".',
  ChaveTexto.sistemaDeepLinkNaoEncontrado:
      'No se encontró la vía o sector para el código "{uid}". Verifica tu conexión o descarga la zona primero.',
  ChaveTexto.sistemaMigracaoVerificando: 'Verificando conexión a internet...',
  ChaveTexto.sistemaMigracaoBaixando: 'Descargando nuevo catálogo de croquis...',
  ChaveTexto.sistemaMigracaoErro:
      'No se pudo actualizar la base de datos. Verifica tu conexión a internet.',
  ChaveTexto.sistemaMigracaoTitulo: 'ACTUALIZACIÓN DE BASE DE DATOS',
  ChaveTexto.sistemaMigracaoCorpo:
      'Esta nueva versión incluye mejoras estructurales en el catálogo y necesita sincronizar por internet una sola vez.',

  // Página Inicial (Home) e Busca Global
  ChaveTexto.homeMeuPerfilTooltip: 'Mi Perfil',
  ChaveTexto.homeConfiguracoesTooltip: 'Ajustes',
  ChaveTexto.homeSincronizarTooltip: 'Sincronizar catálogo y croquis',
  ChaveTexto.homeBoasVindas: '¡BIENVENIDO!',
  ChaveTexto.homeBoraPraPedra: '¿VAMOS A LA ROCA?',
  ChaveTexto.homeDescricaoHeroi:
      'La guía definitiva para tu escalada. Explora sectores, vías y bloques locales y guarda los croquis para acceder 100% sin conexión.',
  ChaveTexto.homeBuscaHint: 'Buscar zonas, sectores o vías...',
  ChaveTexto.homeErroAbrirSalvo:
      'Error al abrir el croquis guardado. Intenta sincronizar de nuevo.',
  ChaveTexto.homeCroquiNaoSalvoOffline:
      'Este croquis aún no está guardado offline. Conéctate a internet para abrirlo.',
  ChaveTexto.homeMaisProximosTitulo: 'MÁS CERCANOS A TI',
  ChaveTexto.homePermitaLocalizacao:
      'Permite el acceso a tu ubicación para ver las zonas más cercanas.',
  ChaveTexto.homePermitirLocalizacaoBtn: 'Permitir Ubicación',
  ChaveTexto.homeAguardandoGps: 'Esperando señal GPS...',
  ChaveTexto.homeNenhumPicoLocalizado: 'No se encontraron zonas con ubicación.',
  ChaveTexto.homeVerMais: 'VER MÁS ->',
  ChaveTexto.homeComoFunciona: 'CÓMO FUNCIONA',
  ChaveTexto.homeGuiaRapidoTitulo: 'GUÍA RÁPIDA DE ARESTA',
  ChaveTexto.homeGuiaRapidoSubtitulo:
      'Todo lo que necesitas para ir directo de la app a la pared.',
  ChaveTexto.homePasso1Titulo: 'ENCUENTRA LA ZONA',
  ChaveTexto.homePasso1Desc:
      'Consulta el tiempo de viaje o explora el Geoide 3D/2D con relieve, GPS en vivo, radar de lluvia, incendios y humedad de la roca.',
  ChaveTexto.homePasso2Titulo: 'GUARDA OFFLINE',
  ChaveTexto.homePasso2Desc:
      'Abre cualquier zona al instante estando online o descarga la guía completa para usarla 100% sin señal al pie de vía.',
  ChaveTexto.homePasso3Titulo: 'CROQUIS INTERACTIVO',
  ChaveTexto.homePasso3Desc:
      'Toca las líneas en la pared para ver grados y seguros, y revisa o reporta alertas rápidas en la roca (🐝, 🪨, 🔩, ⚠️).',
  ChaveTexto.homePasso4Titulo: 'LIBRETA Y COMUNIDAD',
  ChaveTexto.homePasso4Desc:
      'Registra encadenes, vota el grado y despliega videos y betas de la comunidad solo cuando quieras (ocultos por defecto contra spoilers).',
  ChaveTexto.homePasso5Titulo: 'ATAJO AL INICIO',
  ChaveTexto.homePasso5Desc:
      'Toca volver (←) para subir un nivel o mantén pulsado el botón volver para saltar directo al Inicio.',
  ChaveTexto.homePasso6Titulo: 'COMPARTE',
  ChaveTexto.homePasso6Desc:
      'Envía enlaces de vías, sectores y zonas a tu cordada para abrirlos directo en la app o navegador.',
  ChaveTexto.homeConservacaoTitulo: 'CONSERVACIÓN Y ACCESO',
  ChaveTexto.homeConservacaoCorpo:
      'El acceso a las zonas de escalada depende del cuidado, la ética y el respeto a las comunidades locales. Escalar con responsabilidad mantiene las rocas abiertas.',
  ChaveTexto.buscaTodos: 'Todos',
  ChaveTexto.buscaPicos: 'Zonas',
  ChaveTexto.buscaSetores: 'Sectores',
  ChaveTexto.buscaDica:
      'Consejo: busca por zonas, sectores, vías o grados (ej: 7a, V4)',
  ChaveTexto.buscaNenhumResultado: 'No se encontraron resultados.',
  ChaveTexto.buscaFiltroPrefixo: 'Filtro: {filtro}',

  // Modalidades, contagens e estilos de escalada/ascensão
  ChaveTexto.modEsportiva: 'Deportiva',
  ChaveTexto.modEsportivas: 'Deportivas',
  ChaveTexto.modEsportivasMinusculo: 'deportivas',
  ChaveTexto.modMovel: 'Clásica / Trad',
  ChaveTexto.modMoveis: 'Trad',
  ChaveTexto.modMoveisMinusculo: 'trad',
  ChaveTexto.modMovelTrad: 'Clásica / Trad',
  ChaveTexto.modBoulder: 'Bloque',
  ChaveTexto.modBoulders: 'Bloques',
  ChaveTexto.modBouldersMinusculo: 'bloques',
  ChaveTexto.modMultienfiada: 'Multilargo',
  ChaveTexto.modMultienfiadas: 'Multilargos',
  ChaveTexto.modMultiplasEnfiadasMinusculo: 'multilargos',
  ChaveTexto.modParedao: 'Pared / Multilargo',
  ChaveTexto.modHighline: 'Highline',
  ChaveTexto.modHighlines: 'Highlines',
  ChaveTexto.modHighlinesMinusculo: 'highlines',
  ChaveTexto.modMista: 'Mixta',
  ChaveTexto.modOutro: 'Otro',
  ChaveTexto.modOutras: 'Otras',
  ChaveTexto.modVia: 'Vía',
  ChaveTexto.modVias: 'Vías',
  ChaveTexto.modViasMinusculo: 'vías',
  ChaveTexto.modEscaladaMinusculo: 'escalada',
  ChaveTexto.modEscaladasMinusculo: 'escaladas',
  ChaveTexto.modSetorMinusculo: 'sector',
  ChaveTexto.modSetoresMinusculo: 'sectores',
  ChaveTexto.modSetoresCaixaAlta: 'SECTORES',
  ChaveTexto.modDeTotal: '{qtd} de {total} {plural}',
  ChaveTexto.viagemSheetTitulo: 'Estimación de viaje',
  ChaveTexto.viagemSheetTempoMedioRotulo: 'Tiempo medio (flujo normal)',
  ChaveTexto.viagemSheetDistanciaEstradaRotulo: 'Distancia por carretera',
  ChaveTexto.viagemSheetNotaExplicativa:
      'Calculado sin conexión con las vías y límites de OpenStreetMap desde tu ubicación actual. No incluye tráfico en tiempo real — en horas punta puede tardar más.',
  ChaveTexto.viagemSheetFecharBtn: 'Entendido',
  ChaveTexto.estiloAVista: 'A Vista',
  ChaveTexto.estiloFlash: 'Flash',
  ChaveTexto.estiloTrabalhado: 'Encadenado',
  ChaveTexto.estiloTentativa: 'Intento',
  ChaveTexto.estiloGuiado: 'De primero',
  ChaveTexto.estiloTopRope: 'Top Rope',
  ChaveTexto.estiloSolo: 'Solo',
  ChaveTexto.estiloTentativaSingular: 'pegue',
  ChaveTexto.estiloTentativaPlural: 'pegues',

  // Aba Explorar, Globo 3D/2D e Clima
  ChaveTexto.explorarBuscaHint: 'Buscar zona, ciudad o vía...',
  ChaveTexto.explorarTrocarServing: 'Cambiar servidor',
  ChaveTexto.explorarAteKm: 'Hasta {km} km',
  ChaveTexto.explorarViasBrasileiro: 'Vías (Escala BR)',
  ChaveTexto.explorarBoulderEscalaV: 'Bloque (Escala V)',
  ChaveTexto.explorarFiltrosOrdenacao: 'Filtros y Orden',
  ChaveTexto.explorarOrdenacaoSecao: 'ORDENAR POR',
  ChaveTexto.explorarMaisProximos: 'Más cercanos',
  ChaveTexto.explorarAlfabeticoAZ: 'Alfabético (A-Z)',
  ChaveTexto.explorarMaisEscaladas: 'Más vías',
  ChaveTexto.explorarModalidadesSecao: 'MODALIDADES',
  ChaveTexto.explorarDificuldadeSecao: 'DIFICULTAD EN CATÁLOGO',
  ChaveTexto.explorarAlcanceSecao: 'ALCANCE Y DISPONIBILIDAD',
  ChaveTexto.explorarSalvosOffline: 'Guardados Offline',
  ChaveTexto.explorarVerNPicos: 'Ver {total} zonas',
  ChaveTexto.explorarModoMapa: 'Mapa',
  ChaveTexto.explorarModoDividir: 'Dividir',
  ChaveTexto.explorarModoLista: 'Lista',
  ChaveTexto.explorarContagemPicos: '{n} ZONAS',
  ChaveTexto.explorarNenhumPicoEncontrado: 'No se encontraron zonas.',
  ChaveTexto.explorarSetorPrincipal: 'Sector Principal',
  ChaveTexto.explorarAcimaDoMar: '{metros} m sobre el mar',
  ChaveTexto.climaSeco: 'Seco',
  ChaveTexto.climaPossivelmenteUmido: 'Posiblemente húmedo',
  ChaveTexto.climaRochaSecaSemChuva:
      'Probablemente seco · Sin lluvia cercana (4 días)',
  ChaveTexto.climaContagemUmDia: '1 día',
  ChaveTexto.climaContagemDias: '{dias} días',
  ChaveTexto.climaChuvaProximaHoje: 'lluvia cercana hoy ({data})',
  ChaveTexto.climaChuvaProximaUmDia: 'lluvia cercana hace 1 día ({data})',
  ChaveTexto.climaChuvaProximaDias: 'lluvia cercana hace {dias} días ({data})',
  ChaveTexto.climaNotaJanelaQuatroDias:
      'Ventana conservadora de 4 días reiniciada con cada lluvia regional. Verifica siempre la roca en el lugar.',
  ChaveTexto.climaNotaEstimativaSatelite:
      'Estimación regional por satélite — las filtraciones locales pueden variar.',
  ChaveTexto.explorarBotaoClimaMapa: 'Lluvia y Fuego',
  ChaveTexto.explorarAvisoClimaTitulo: 'Aviso de uso',
  ChaveTexto.explorarAvisoClimaCorpo:
      'Aresta utiliza 3 fuentes meteorológicas y de radar (Open-Meteo, RainViewer e INPE BDQueimadas) Y 3 recursos públicos de misiones de la NASA (FIRMS VIIRS/MODIS, SRTM 30m y Blue Marble) para lograr una tasa de ~85% de acierto al mostrar esta información. Usa esta herramienta como referencia y no como verdad absoluta.',
  ChaveTexto.explorarAvisoClimaConfirmar: 'OK, mostrar en el mapa',
  ChaveTexto.explorarBotaoVerEstatisticasClima: 'Ver estadísticas',
  ChaveTexto.estatClimaTituloPagina: 'CÓMO LLEGAMOS AL ~85%',
  ChaveTexto.estatClimaSubtituloHeroi:
      'Cruzamos datos desde 2024 en las mismas regiones de nuestras 29 zonas para poner el algoritmo a prueba — desde la hipótesis nula hasta la Tabla Z, logrando entre 83% y 87% de efectividad (~85% promedio).',
  ChaveTexto.estatClimaSecaoComposicaoTitulo: '1. CRUCE DE DATOS DESDE 2024',
  ChaveTexto.estatClimaComposicaoChuvaMapa:
      'Burbujas regionales de lluvia (≥ 0,2 mm/día)',
  ChaveTexto.estatClimaComposicaoUmidade4d:
      'Ventana conservadora de 4 días en la roca',
  ChaveTexto.estatClimaComposicaoIncendioNasa:
      'Perímetros de fuego activo (NASA VIIRS 375m)',
  ChaveTexto.estatClimaSecaoMatrizTitulo: '2. PRUEBA CONTRA LA HIPÓTESIS NULA (H₀)',
  ChaveTexto.estatClimaMatrizExplicacao:
      'Tomamos datos cruzados desde 2024 en las mismas regiones de las 29 zonas (5.133 días-sector) para comprobar si el algoritmo — combinando Open-Meteo, radar RainViewer, INPE y sensores de la NASA — lograba el efecto deseado:',
  ChaveTexto.estatClimaHipoteseNulaExplicacao:
      'Primero probamos los datos directamente contra una hipótesis nula (H₀ = 50% al azar y base climática de 58,5%) para ver si tenía efecto real o era suerte. Superó el azar por +27,7 desviaciones estándar:',
  ChaveTexto.estatClimaCelulaTpDetalhe: 'Lluvia prevista y real',
  ChaveTexto.estatClimaCelulaFpDetalhe: 'Alerta preventiva',
  ChaveTexto.estatClimaCelulaFnDetalhe: 'Lluvia local aislada',
  ChaveTexto.estatClimaCelulaTnDetalhe: 'Roca seca confirmada',
  ChaveTexto.estatClimaCalcTaxaBrutaTitulo: 'Tasa de acierto en lluvia (p̂)',
  ChaveTexto.estatClimaCalcH0MoedaTitulo: 'Contra H₀ = 50% (al azar)',
  ChaveTexto.estatClimaCalcAcuraciaGlobalTitulo: 'Acierto total (seco + lluvia)',
  ChaveTexto.estatClimaCalcErroPadraoTitulo: 'Error estándar muestral (SE)',
  ChaveTexto.estatClimaCalcFaixaZTitulo: 'Rango en Tabla Z (95%, Z = 1,96)',
  ChaveTexto.estatClimaCalcMediaFinalTitulo: 'Efectividad media (83%–87%)',
  ChaveTexto.estatClimaSecaoTabelaZTitulo:
      '3. EN LA TABLA Z: 83% A 87% (~85% PROM.)',
  ChaveTexto.estatClimaTabelaZExplicacao:
      'Tras confirmar un efecto sólido, llevamos la comparación a una Tabla Z para hallar el porcentaje real de aciertos del proceso. Con estos cálculos (Z = 1,96 al 95% y Z = +2,57 sobre 83%), llegamos a entre 83,7% y 87,2% de efectividad — o ~85% en promedio:',
  ChaveTexto.estatClimaGraficoH0Rotulo: 'Distribución Nula (H₀)',
  ChaveTexto.estatClimaGraficoCaudaRotulo: 'Cola derecha (+27,7σ a +49,0σ)',
  ChaveTexto.estatClimaColunaZ: 'Puntaje Z',
  ChaveTexto.estatClimaColunaPhi: 'Φ(Z) Acum.',
  ChaveTexto.estatClimaColunaCauda: 'Cola 1−Φ',
  ChaveTexto.estatClimaColunaNota: 'Lectura en Tabla Z',
  ChaveTexto.estatClimaZNotaMedia: 'Centro de hipótesis nula (50%)',
  ChaveTexto.estatClimaZNota90: 'Umbral unilateral del 90%',
  ChaveTexto.estatClimaZNota95: 'Umbral unilateral estándar (α = 0,05)',
  ChaveTexto.estatClimaZNotaIC95: 'IC bilateral del 95% ([83,7%, 87,2%])',
  ChaveTexto.estatClimaZNota99: 'Umbral unilateral del 99% (α = 0,01)',
  ChaveTexto.estatClimaZNotaTeste83:
      'Prueba Aresta p̂ = 85,5% vs H₀ ≤ 83% (p = 0,0051)',
  ChaveTexto.estatClimaZNota999: 'Umbral del 99,9% (α = 0,001)',
  ChaveTexto.estatClimaZNotaFimTabela:
      'Fin de la Tabla Z impresa (Aresta: Z = +27,7σ)',
  ChaveTexto.estatClimaSecaoFontesTitulo: '4. FUENTES ESPECÍFICAS UTILIZADAS',
  ChaveTexto.estatClimaGrupoFontesMeteo:
      '3 FUENTES METEOROLÓGICAS, RADAR Y MONITOREO',
  ChaveTexto.estatClimaGrupoFontesNasa:
      '3 RECURSOS PÚBLICOS DE MISIONES DE LA NASA',
  ChaveTexto.estatClimaFonteOpenMeteoDesc:
      'Modelos numéricos NOAA GFS, DWD ICON y ECMWF IFS para lluvia horaria observada de 5 días, frentes activos y viento a 10 m.',
  ChaveTexto.estatClimaFonteRainViewerDesc:
      'Mosaico global de radar Doppler en vivo para ubicar células convectivas y núcleos de lluvia intensa.',
  ChaveTexto.estatClimaFonteInpeDesc:
      'Programa BDQueimadas del INPE para monitoreo diario de focos de calor en biomas brasileños.',
  ChaveTexto.estatClimaFonteFirmsDesc:
      'Sensores térmicos orbitales VIIRS (375 m) y MODIS (1 km) de las misiones Suomi NPP, NOAA-20 y Aqua/Terra.',
  ChaveTexto.estatClimaFonteSrtmDesc:
      'Shuttle Radar Topography Mission (30 m vía AWS Terrarium) para altimetría real, sombreado y curvas de nivel.',
  ChaveTexto.estatClimaFonteBlueMarbleDesc:
      'Mosaico satelital terrestre Next Generation de la NASA empleado en el globo.',
  ChaveTexto.estatClimaAvisoFinal:
      'Los microclimas de pared, filtraciones, orientación solar y viento local alteran el secado real de la roca. Evalúa siempre las condiciones en persona.',
  ChaveTexto.climaChuvaFraca: 'Lluvia débil',
  ChaveTexto.climaChuvaModerada: 'Lluvia moderada',
  ChaveTexto.climaChuvaForte: 'Lluvia fuerte',
  ChaveTexto.climaTempestadeSevera: 'Tormenta severa',
  ChaveTexto.climaFocoIsolado: 'Foco térmico aislado',
  ChaveTexto.climaFocoQueimada: 'Foco de quema',
  ChaveTexto.climaIncendioAtivo: 'Incendio activo',
  ChaveTexto.climaIncendioSevero: 'Incendio severo',

  // Meus Croquis e Modais Offline
  ChaveTexto.meusCroquisTitulo: 'MIS CROQUIS',
  ChaveTexto.meusCroquisSubtitulo: 'ALMACENAMIENTO OFFLINE',
  ChaveTexto.meusCroquisVazio: 'Aún no tienes croquis guardados offline.',
  ChaveTexto.meusCroquisAbrirOffline: 'ABRIR OFFLINE',
  ChaveTexto.meusCroquisErroAbrir: 'Error al abrir la guía offline.',
  ChaveTexto.meusCroquisExcluirTitulo: '¿Eliminar?',
  ChaveTexto.meusCroquisExcluirPergunta:
      '¿Deseas eliminar la guía de {nome}?',
  ChaveTexto.meusCroquisExcluidoToast: 'Guía eliminada.',
  ChaveTexto.meusCroquisErroExcluirToast: 'Error al eliminar la guía.',
  ChaveTexto.meusCroquisGuiaRemovidoToast:
      'Guía eliminada del almacenamiento offline.',
  ChaveTexto.offlineSalvarComTamanho: 'Guardar Offline ({tamanho})',
  ChaveTexto.offlineSalvarSemTamanho: 'Guardar Offline',
  ChaveTexto.offlineModoOnlineTitulo: 'MODO ONLINE',
  ChaveTexto.offlineModoOnlineDesc:
      'Estás navegando con internet. Guarda la guía completa para usarla sin señal en la roca.',
  ChaveTexto.offlineBaixandoPct: 'DESCARGANDO ({pct}%)...',
  ChaveTexto.offlineSalvarParaPedraTitulo: '¿GUARDAR PARA LA ROCA?',
  ChaveTexto.offlineSalvarParaPedraCorpo:
      'Recuerda: en la roca suele no haber señal. Para consultar los croquis y grados de {nome} sin conexión, guarda la guía offline.',
  ChaveTexto.offlineSairSemSalvar: 'Salir sin Guardar',
  ChaveTexto.offlineSemConexaoTitulo: 'ESTÁS SIN CONEXIÓN',
  ChaveTexto.offlineSemConexaoCorpo:
      'Este contenido pertenece al croquis {nome}, que aún no está guardado offline en tu dispositivo. Conéctate a internet e inténtalo de nuevo.',
  ChaveTexto.offlineAindaSemConexao:
      'Sigues sin conexión a internet. Verifica tu red e inténtalo de nuevo.',
  ChaveTexto.offlineTentandoConectar: 'Intentando conectar...',

  // Página do Pico, Subpáginas, Setor, Grupo, Filtros de Índice e Croqui Interativo
  ChaveTexto.picoCompartilharTooltip: 'Compartir zona',
  ChaveTexto.picoExcluirGuiaTooltip: 'Eliminar guía',
  ChaveTexto.picoBuscarBoulderTooltip: 'Buscar bloque',
  ChaveTexto.picoBuscarViaTooltip: 'Buscar vía',
  ChaveTexto.picoCardSetoresTitulo: 'Sectores y Vías',
  ChaveTexto.picoCardSetoresSubtitulo:
      'Explora sectores, vías y bloques con filtros y mapas integrados',
  ChaveTexto.picoCardExplorarTitulo: 'Explorar Zona',
  ChaveTexto.picoCardExplorarSubtitulo:
      'Cómo llegar, mapas generales, clima e información útil.',
  ChaveTexto.picoCardRegrasTitulo: 'Reglas y recomendaciones',
  ChaveTexto.picoCardRegrasSubtitulo:
      'Normas ambientales, seguridad básica, ética y buena convivencia.',
  ChaveTexto.picoCardComunidadeTitulo: 'Comunidad',
  ChaveTexto.picoCardComunidadeSubtitulo:
      'Redes sociales, grupo de WhatsApp, patrocinadores y comercio local.',
  ChaveTexto.picoCardCreditosSubtitulo:
      'Conoce a los autores, colaboradores y agradecimientos.',
  ChaveTexto.picoVoltarMapaSetor: 'Volver al Mapa del Sector',
  ChaveTexto.picoCroquiPor: 'Croquis por {autores}',
  ChaveTexto.picoInfoLocal: 'Información del Lugar',
  ChaveTexto.picoCampoNome: 'Nombre',
  ChaveTexto.picoCampoEstado: 'Estado',
  ChaveTexto.picoMaisInfoSecao: 'Más Información',
  ChaveTexto.picoMapasGerais: 'Mapas Generales',
  ChaveTexto.picoNenhumElemento: 'Ningún elemento disponible.',
  ChaveTexto.picoBuscarBoulderHint: 'Buscar bloque (ej: V4) o sector...',
  ChaveTexto.picoBuscarEscaladaHint: 'Buscar vía (ej: 7a) o sector...',
  ChaveTexto.picoDificuldadePrefixo: 'Dificultad: {grau}',
  ChaveTexto.picoUltimaAtualizacaoNaoInformada:
      'Última actualización: No informada',
  ChaveTexto.picoUltimaAtualizacaoHoje: 'Última actualización: Hoy a las {hora}',
  ChaveTexto.picoUltimaAtualizacaoOntem:
      'Última actualización: Ayer a las {hora}',
  ChaveTexto.picoUltimaAtualizacaoData:
      'Última actualización: {data} a las {hora}',
  ChaveTexto.picoSubExplorarTitulo: 'EXPLORAR EL LUGAR',
  ChaveTexto.picoSubIntroSubtitulo: 'Presentación general e introducción.',
  ChaveTexto.picoSubSobreLocal: 'Sobre el lugar',
  ChaveTexto.picoSubSobreLocalSubtitulo:
      'Historia de la montaña, primeras ascensiones y curiosidades locales.',
  ChaveTexto.picoSubComoChegar: 'Cómo llegar',
  ChaveTexto.picoSubComoChegarSubtitulo:
      'Instrucciones de aproximación y acceso a la base de la pared.',
  ChaveTexto.picoSubAbrirMaps: 'Abrir en Google Maps',
  ChaveTexto.picoSubAbrirMapsSubtitulo:
      'Ver ubicación y trazar ruta hacia la zona.',
  ChaveTexto.picoSubExtrasSubtitulo: 'Información adicional del lugar.',
  ChaveTexto.picoSubComunidadeTitulo: 'COMUNIDAD',
  ChaveTexto.picoSubInformacoes: 'Información',
  ChaveTexto.picoSubAssociacaoLocal: 'Asociación Local',
  ChaveTexto.picoSubParceiros: 'Aliados',
  ChaveTexto.picoSubComercioLocal: 'Comercio local',
  ChaveTexto.picoSubApoieTitulo: 'APOYA LA ZONA',
  ChaveTexto.picoSubDoacaoPix: 'Donación vía Pix',
  ChaveTexto.picoSubDoacaoPixSubtitulo:
      'Ayuda a financiar chapas y descuelgues de acero inoxidable.\nClave: {chave}',
  ChaveTexto.picoSubPixCopiadoToast: '¡Clave Pix copiada al portapapeles!',
  ChaveTexto.picoSubProdutos: 'Productos de la zona',
  ChaveTexto.picoSubPatrocinador: 'Sé un patrocinador',
  ChaveTexto.picoSubPatrocinadorSubtitulo:
      'Asocia tu marca de forma ética y ecológica con la roca.',
  ChaveTexto.picoSubEnviarInfo: 'Enviar información',
  ChaveTexto.picoSubEnviarInfoSubtitulo:
      'Colabora sugiriendo nuevas vías o correcciones.',
  ChaveTexto.picoRegrasTitulo: 'REGLAS Y RECOMENDACIONES',
  ChaveTexto.picoRegrasVazio:
      'No hay reglas específicas registradas para este lugar. Sigue las normas éticas y ambientales habituales.',
  ChaveTexto.picoGpsEmBreve: 'Funciones GPS próximamente',
  ChaveTexto.setorTituloPagina: 'SECTORES Y VÍAS',
  ChaveTexto.setorCompartilharTooltip: 'Compartir sector',
  ChaveTexto.setorCompartilharGrupoTooltip: 'Compartir grupo',
  ChaveTexto.setorNenhumSetorDisponivel: 'Ningún sector disponible.',
  ChaveTexto.setorNenhumaViaDisponivel: 'Ninguna vía disponible.',
  ChaveTexto.setorNenhumBoulderDisponivel: 'Ningún bloque disponible.',
  ChaveTexto.setorNenhumSetorCadastrado:
      'Aún no hay sectores ni vías registrados para este lugar.',
  ChaveTexto.setorNenhumSetorFiltrado:
      'Ningún sector coincide con los filtros seleccionados.',
  ChaveTexto.setorNenhumaEscaladaFiltrada:
      'Ninguna vía coincide con los filtros seleccionados.',
  ChaveTexto.setorVerNoCroqui: 'Ver en croquis',
  ChaveTexto.setorAbrirCroquiSemantics: 'Abrir croquis del sector {nome}',
  ChaveTexto.filtroPadrao: 'ESTÁNDAR',
  ChaveTexto.filtroPadraoMisto: 'Estándar',
  ChaveTexto.filtroGrau: 'GRADO',
  ChaveTexto.filtroGrauMisto: 'Grado',
  ChaveTexto.filtroAlfabetico: 'ALFABÉTICO',
  ChaveTexto.filtroAtivoSingular: '1 activo',
  ChaveTexto.filtroAtivoPlural: '{n} activos',
  ChaveTexto.filtroLocalizacao: 'Ubicación',
  ChaveTexto.filtroConquistaAutores: 'Apertura (Equipadores)',
  ChaveTexto.filtroApenasClassicas: 'Solo Clásicas (★)',
  ChaveTexto.filtroClassicas: 'Clásicas (★)',
  ChaveTexto.filtroModalidadeInativa: 'Modalidad inactiva',
  ChaveTexto.filtroTodosGrausFaixa: 'Todos los grados ({min} a {max})',
  ChaveTexto.filtroTodosGraus: 'Todos los grados',
  ChaveTexto.filtroGrauUnico: 'Grado: {grau}',
  ChaveTexto.filtroGrauFaixa: 'Grado: {min} a {max}',
  ChaveTexto.filtroConectorA: 'a',
  ChaveTexto.filtroFaixaGrauVias: 'Rango de Grado (Vías)',
  ChaveTexto.filtroFaixaGrauBoulders: 'Rango de Grado (Bloques)',
  ChaveTexto.filtroFaixaGrau: 'Rango de Grado',
  ChaveTexto.filtroAddSetorOuGrupo: 'Añadir sector o grupo...',
  ChaveTexto.filtroAddSetor: 'Añadir sector...',
  ChaveTexto.filtroTodosSetoresGruposAdd:
      'Todos los sectores o grupos añadidos',
  ChaveTexto.filtroTodosSetoresAdd: 'Todos los sectores añadidos',
  ChaveTexto.filtroNenhumLocalAtual: 'Ningún lugar en los filtros actuales',
  ChaveTexto.filtroNenhumSetorAtual: 'Ningún sector en los filtros actuales',
  ChaveTexto.filtroAddConquistador: 'Añadir equipador...',
  ChaveTexto.filtroTodosConquistadoresAdd: 'Todos los equipadores añadidos',
  ChaveTexto.filtroNenhumConquistadorAtual:
      'Ningún equipador en los filtros actuales',
  ChaveTexto.croquiMapasInterativosContagem: 'Croquis Interactivos ({n})',
  ChaveTexto.croquiAbrirMapaInterativo: 'Abrir Croquis Interactivo',
  ChaveTexto.croquiTituloPagina: 'Croquis Interactivo',
  ChaveTexto.croquiMaisInfo: 'Más Info',
  ChaveTexto.croquiVerMapas: 'Ver mapas',
  ChaveTexto.croquiIrParaSetor: 'Ir al Sector',
  ChaveTexto.croquiIrParaGrupo: 'Ir al Grupo',
  ChaveTexto.croquiCentralizarTooltip: 'Centrar imagen',
  ChaveTexto.croquiPaginacaoDe: '{atual} de {total}',

  // Detalhes da Via, Consenso de Grau, Especificações Técnicas e Alertas de Segurança
  ChaveTexto.viaClassica: 'CLÁSICA',
  ChaveTexto.viaGrauMaximo: 'GRADO MÁXIMO',
  ChaveTexto.viaGrauOficial: 'GRADO OFICIAL',
  ChaveTexto.viaConsensoComunidade: 'CONSENSO DE LA COMUNIDAD',
  ChaveTexto.viaSemVotos: 'Sin votos',
  ChaveTexto.viaNAvaliacoes: '{n} valoraciones',
  ChaveTexto.viaDistribuicaoVotos: 'DISTRIBUCIÓN DE VOTOS ({n})',
  ChaveTexto.viaGrauJustoCurto: 'Justo',
  ChaveTexto.viaGrauJustoZero: 'Grado Justo (0)',
  ChaveTexto.viaGrauJustoComNota: 'Justo ({grau})',
  ChaveTexto.viaRegistreParaAvaliar: 'Registra tu ascensión para valorar',
  ChaveTexto.viaConfirmamGrauPct: '{pct}% confirman el grado',
  ChaveTexto.viaSugeremGrauPct: '{pct}% sugieren {sinal}',
  ChaveTexto.viaLinhaNumero: 'Línea #{n}',
  ChaveTexto.viaVerNoCroquiInterativo: 'VER EN CROQUIS INTERACTIVO',
  ChaveTexto.viaCompartilharTooltip: 'Compartir vía',
  ChaveTexto.viaReportarAlertaTooltip: 'Reportar alerta de seguridad',
  ChaveTexto.viaEntreParaReportarToast:
      'Inicia sesión en Perfil para reportar alertas de seguridad.',
  ChaveTexto.viaAlertaRegistradoToast: '¡Alerta de seguridad registrada!',
  ChaveTexto.viaEntreParaVotarToast:
      'Inicia sesión en Perfil para votar el grado de la vía.',
  ChaveTexto.viaVotoAtualizadoToast: '¡Voto de grado actualizado!',
  ChaveTexto.viaComentarioAtualizadoToast: '¡Comentario actualizado!',
  ChaveTexto.viaComentarioExcluidoToast: 'Comentario eliminado.',
  ChaveTexto.viaAncoragemPrefixo: 'Descuelgue: {tipo}',
  ChaveTexto.viaEnfiadasContagem: 'LARGOS ({n})',
  ChaveTexto.viaProtecoesAbrev: '{n} seg.',
  ChaveTexto.viaMovelPrefixo: 'Móvil: {equip}',
  ChaveTexto.viaHistoricoConquista: 'HISTORIA Y APERTURA',
  ChaveTexto.viaConquistadores: 'EQUIPADORES / APERTURISTAS',
  ChaveTexto.viaAbertura: 'APERTURA',
  ChaveTexto.viaManutencao: 'MANTENIMIENTO',
  ChaveTexto.viaApoieManutencaoPix: 'Apoya el Reequipamiento (Pix: {chave})',
  ChaveTexto.viaPixManutencaoCopiadoToast:
      '¡Clave Pix copiada al portapapeles!',
  ChaveTexto.viaVideosBetasContagem: 'VIDEOS Y BETAS ({n})',
  ChaveTexto.viaBetasComunidadeContagem: 'BETAS DE LA COMUNIDAD ({n})',
  ChaveTexto.viaEditarComentarioTooltip: 'Editar comentario',
  ChaveTexto.viaExcluirComentarioTooltip: 'Eliminar comentario',
  ChaveTexto.viaEditarComentarioTitulo: 'Editar Comentario',
  ChaveTexto.viaEditarComentarioSubtitulo:
      'Actualiza tu nota o beta público en esta vía.',
  ChaveTexto.viaExcluirComentarioTitulo: '¿Eliminar Comentario?',
  ChaveTexto.viaExcluirComentarioCorpo:
      'Tu comentario público se eliminará permanentemente de esta vía.',
  ChaveTexto.viaProjeto: 'Proyecto',
  ChaveTexto.viaMediaPrefixo: 'Media {media}',
  ChaveTexto.viaArtificialLivre: 'Artificial {art} ({livre} en libre)',
  ChaveTexto.viaArtificialPuro: 'Artificial {art}',
  ChaveTexto.viaGuiaOficialConquistador: 'Guía Oficial / Aperturista',
  ChaveTexto.viaSpecExtensao: 'LONGITUD',
  ChaveTexto.viaSpecParede: 'INCLINACIÓN',
  ChaveTexto.viaSpecExposicao: 'EXPOSICIÓN',
  ChaveTexto.viaSpecEnfiadas: 'LARGOS',
  ChaveTexto.viaSpecComprimento: 'RECORRIDO',
  ChaveTexto.viaSpecMaiorEnfiada: 'LARGO MAYOR',
  ChaveTexto.viaSpecDuracao: 'DURACIÓN',
  ChaveTexto.viaSpecTipo: 'TIPO',
  ChaveTexto.viaSpecDistancia: 'DISTANCIA',
  ChaveTexto.viaSpecAltura: 'ALTURA',
  ChaveTexto.viaSpecProtecoes: 'SEGUROS',
  ChaveTexto.viaSecaoDescricao: 'Descripción',
  ChaveTexto.viaSecaoPecasMoveis: 'Material Móvil',
  ChaveTexto.viaSecaoRackEquipamento: 'Rack y Equipo',
  ChaveTexto.viaSecaoDescricaoAcesso: 'Descripción de Acceso',
  ChaveTexto.viaSecaoDescricaoAncoragem: 'Descripción del Descuelgue',
  ChaveTexto.viaEnfiadaNumero: 'Largo {n}',
  ChaveTexto.viaBetaEmOrigem: 'Beta en {origem}',
  ChaveTexto.viaAssistirVideoBeta: 'Ver Video Beta',
  ChaveTexto.viaVideo: 'Video',
  ChaveTexto.alertaPrefixoSemantics: 'Alerta: {rotulo}',
  ChaveTexto.alertaFaunaTitulo: 'Fauna',
  ChaveTexto.alertaFaunaDesc:
      'Abejas, avispas, serpientes, aves anidando u otros animales en la vía.',
  ChaveTexto.alertaRochaInstavelTitulo: 'Roca o Agarre Inestable',
  ChaveTexto.alertaRochaInstavelDesc:
      'Bloque suelto, laja peligrosa o canto a punto de romperse.',
  ChaveTexto.alertaProtecaoPrecariaTitulo: 'Seguro Precario',
  ChaveTexto.alertaProtecaoPrecariaDesc:
      'Chapa suelta, corrosión severa o reunión dañada.',
  ChaveTexto.alertaExposicaoTitulo: 'Exposición E4+',
  ChaveTexto.alertaExposicaoDesc:
      'Aleje severo (E4+), riesgo de caída al suelo o seguros distantes.',
  ChaveTexto.alertaCriadoPorVoce: 'CREADO POR TI',
  ChaveTexto.alertaConfirmadoMaisUm: 'CONFIRMADO (+1)',
  ChaveTexto.alertaReportadoPorEm:
      'Reportado por {autor} el {data} • {n}x confirmado',
  ChaveTexto.alertaEntreParaConfirmar:
      'Inicia sesión en Perfil para confirmar o actualizar esta alerta.',
  ChaveTexto.alertaAindaEstaLa: '¿Sigue ahí?',
  ChaveTexto.alertaNaoJaResolveu: 'No, ya se resolvió',
  ChaveTexto.alertaReportadoPorVoceCheck: '✓ Reportado por ti',
  ChaveTexto.alertaConfirmadoPorVoceCheck: '✓ Confirmado por ti',
  ChaveTexto.alertaSimAindaEstaLa: 'Sí, sigue ahí',
  ChaveTexto.alertaEditarBtn: 'Editar alerta',
  ChaveTexto.alertaExcluirBtn: 'Eliminar alerta',
  ChaveTexto.alertaResolvidoToast: 'Alerta marcada como resuelta.',
  ChaveTexto.alertaResolvidoNaViaToast:
      'Alerta en {nome} marcada como resuelta.',
  ChaveTexto.alertaAtualizadoToast: '¡Alerta actualizada!',
  ChaveTexto.alertaFalhaAtualizarToast: 'No se pudo actualizar esta alerta.',
  ChaveTexto.alertaExcluidoToast: 'Alerta eliminada.',
  ChaveTexto.alertaEditarModalTitulo: 'Editar Alerta en la Vía',
  ChaveTexto.alertaReportarModalTitulo: 'Reportar Alerta en la Vía',
  ChaveTexto.alertaEditarModalSub:
      'Actualiza la categoría o el detalle de esta alerta de seguridad.',
  ChaveTexto.alertaReportarModalSub:
      'Avisa a otros escaladores sobre riesgos inmediatos en esta línea.',
  ChaveTexto.alertaDetalheLabel: 'Detalle rápido (opcional)',
  ChaveTexto.alertaDetalheHint: 'Ej.: Panal cerca de la 3ª chapa',
  ChaveTexto.alertaEnviarBtn: 'Enviar Alerta',
  ChaveTexto.alertaExcluirModalTitulo: '¿Eliminar Alerta?',
  ChaveTexto.alertaExcluirModalCorpo:
      'Esta alerta de seguridad se eliminará permanentemente de la vía.',
  ChaveTexto.alertaAtivoUmConfirmacao: 'Activa • 1 confirmación',
  ChaveTexto.alertaAtivoVariasConfirmacoes: 'Activa • {n} confirmaciones',
  ChaveTexto.alertaResolvidoStatus: 'Resuelta',
  ChaveTexto.alertaMarcarResolvido: 'Marcar resuelta',

  // Autenticação, Perfil, Caderneta, Comunidade, Configurações, Feedback e Compartilhamento
  ChaveTexto.authEntrarTitulo: 'Inicia sesión en tu cuenta',
  ChaveTexto.authEntrarSubtitulo:
      'Entra sin contraseña usando tu cuenta social o un código de 6 dígitos enviado por correo para sincronizar tu libreta.',
  ChaveTexto.authContinuarGoogle: 'Continuar con Google',
  ChaveTexto.authContinuarApple: 'Continuar con Apple',
  ChaveTexto.authOuCodigoEmail: 'o recibe un código por correo',
  ChaveTexto.authEmailLabel: 'Correo electrónico',
  ChaveTexto.authAguardeSegundos: 'Espera {s}s',
  ChaveTexto.authReceberCodigoEmail: 'Recibir código por correo',
  ChaveTexto.authCodigo6DigitosLabel: 'Código de 6 dígitos',
  ChaveTexto.authConfirmarCodigo: 'Confirmar código',
  ChaveTexto.authReenviarComSegundos: 'Reenviar código ({s}s)',
  ChaveTexto.authReenviarCodigo: 'Reenviar código',
  ChaveTexto.authUsarOutroEmail: 'Usar otro correo',
  ChaveTexto.authAbrirConfigApp: 'Abrir ajustes de la app',
  ChaveTexto.authLimiteTemporario:
      'Límite temporal alcanzado. Espera {s}s para solicitar otro código.',
  ChaveTexto.authCodigoEnviadoPara:
      'Enviamos un código de 6 dígitos a {email}. Revisa tu bandeja de entrada y spam.',
  ChaveTexto.authErroEnviarCodigo:
      'No se pudo enviar el código de acceso. Inténtalo de nuevo.',
  ChaveTexto.authErroValidarCodigo:
      'No se pudo validar el código de acceso. Inténtalo de nuevo.',
  ChaveTexto.authErroGoogle:
      'No se pudo iniciar sesión con Google. Inténtalo de nuevo.',
  ChaveTexto.authErroApple:
      'No se pudo iniciar sesión con Apple. Inténtalo de nuevo.',
  ChaveTexto.authSemConexao:
      'Sin conexión a internet. Verifica tu señal e inténtalo de nuevo.',
  ChaveTexto.authSrvChaveInvalida:
      'Clave de servidor inválida. Inténtalo de nuevo.',
  ChaveTexto.authSrvCodigoExpirado:
      'El código de acceso expiró o no es válido.',
  ChaveTexto.authSrvEmailInvalido: 'Ingresa un correo electrónico válido.',
  ChaveTexto.authSrvProvedorDesabilitado:
      'El proveedor de autenticación no está habilitado.',
  ChaveTexto.authSrvCredencialInvalida:
      'No se pudo validar la credencial nativa en el servidor.',
  ChaveTexto.authSrvLimiteEnvio:
      'Límite de envío alcanzado. Espera unos instantes e inténtalo de nuevo.',
  ChaveTexto.authSrvSessaoExpirada:
      'Tu sesión expiró. Inicia sesión nuevamente.',
  ChaveTexto.authSrvCancelado: 'Autenticación cancelada por el escalador.',
  ChaveTexto.authSrvCooldownAposUm:
      'Por seguridad, solo puedes solicitar un nuevo código tras 1 segundo.',
  ChaveTexto.authSrvCooldownAposVarios:
      'Por seguridad, solo puedes solicitar un nuevo código tras {s} segundos.',
  ChaveTexto.authSrvCooldownCadaUm:
      'Por seguridad, solo puedes solicitar un nuevo código cada 1 segundo.',
  ChaveTexto.authSrvCooldownCadaVarios:
      'Por seguridad, solo puedes solicitar un nuevo código cada {s} segundos.',
  ChaveTexto.perfilEscaladorPadrao: 'Escalador',
  ChaveTexto.perfilEscaladorAresta: 'Escalador Aresta',
  ChaveTexto.perfilEditarBtn: 'Editar perfil',
  ChaveTexto.perfilMetricaCadenas: 'ENCADENES',
  ChaveTexto.perfilMetricaTentativas: 'PEGUES',
  ChaveTexto.perfilMetricaPicos: 'ZONAS',
  ChaveTexto.perfilMetricaVias: 'VÍAS',
  ChaveTexto.perfilEntrarConta: 'Iniciar sesión',
  ChaveTexto.perfilMinhaCaderneta: 'Mi libreta',
  ChaveTexto.perfilDadosPrivacidade: 'Datos y privacidad',
  ChaveTexto.perfilSair: 'Cerrar sesión',
  ChaveTexto.perfilExcluirConta: 'Eliminar cuenta',
  ChaveTexto.perfilIdCopiadoToast: '¡ID público copiado!',
  ChaveTexto.perfilSemConexaoExcluir:
      'Sin conexión a internet. Conéctate para eliminar tu cuenta.',
  ChaveTexto.perfilErroExcluirConta:
      'No se pudo eliminar la cuenta en este momento.',
  ChaveTexto.perfilDialogEditarTitulo: 'Editar Perfil',
  ChaveTexto.perfilAlterarFoto: 'Cambiar foto de perfil',
  ChaveTexto.perfilNomeAtletaLabel: 'Nombre del escalador',
  ChaveTexto.perfilPrivacidadeTitulo: 'Datos y Privacidad',
  ChaveTexto.perfilPrivacidadeCorpo:
      'Aresta Climb respeta la soberanía y privacidad de tus datos. Tu libreta es estrictamente privada. Tus votos públicos y alertas usan únicamente tu ID de Autor público sin exponer datos personales.',
  ChaveTexto.perfilIdPublicoLabel: 'ID DE AUTOR PÚBLICO (NANOID)',
  ChaveTexto.perfilCopiarIdTooltip: 'Copiar ID público',
  ChaveTexto.perfilSairPergunta: '¿Seguro que deseas salir?',
  ChaveTexto.perfilSairCorpo:
      'Tu libreta personal e historial permanecen guardados de forma segura en este dispositivo.',
  ChaveTexto.perfilExcluirPergunta: '¿Eliminar cuenta permanentemente?',
  ChaveTexto.perfilExcluirCorpo:
      'Esta acción es irreversible. Tu cuenta, foto de perfil y encadenes sincronizados se borrarán permanentemente de la nube y de este dispositivo.',
  ChaveTexto.cadTituloPagina: 'MI LIBRETA',
  ChaveTexto.cadAscensaoAtualizadaToast: '¡Ascensión actualizada en tu libreta!',
  ChaveTexto.cadViaIndisponivelOffline:
      'Vía no disponible offline en este momento.',
  ChaveTexto.cadTotalCadenas: 'Total de Encadenes',
  ChaveTexto.cadTaxaAVistaFlash: 'Tasa A Vista/Flash',
  ChaveTexto.cadMaiorGrauVias: 'Máximo Grado (Vías)',
  ChaveTexto.cadMaiorGrauBoulders: 'Máximo Grado (Bloques)',
  ChaveTexto.cadPiramideTitulo: 'Pirámide de Grados',
  ChaveTexto.cadNenhumaAscensaoModalidade:
      'Ninguna ascensión registrada en esta modalidad.',
  ChaveTexto.cadHistoricoContagem: 'Historial de Ascensiones ({n})',
  ChaveTexto.cadMeusAlertasContagem: 'Mis Alertas en la Roca ({n})',
  ChaveTexto.cadNenhumaAscensaoAinda: 'Ninguna ascensión registrada aún',
  ChaveTexto.cadNenhumaAscensaoSub:
      'Tus encadenes guardados en las páginas de las vías aparecerán aquí.',
  ChaveTexto.cadEditarAscensaoTooltip: 'Editar ascensión',
  ChaveTexto.cadExcluirAscensaoTooltip: 'Eliminar ascensión',
  ChaveTexto.cadExcluirAscensaoTitulo: '¿Eliminar Ascensión?',
  ChaveTexto.cadExcluirAscensaoCorpo:
      'Esto eliminará este registro permanentemente de tu libreta.',
  ChaveTexto.cadEstiloEsportivoLabel: 'Estilo de Escalada',
  ChaveTexto.cadTentativasPegasLabel: 'Intentos / Pegues',
  ChaveTexto.cadDataAscensaoLabel: 'Fecha de Ascensión',
  ChaveTexto.cadNotasPrivadasLabel: 'Notas Privadas (Crux / Beta)',
  ChaveTexto.cadNotasPrivadasHint:
      'Ej: Talón izquierdo en la 3ª chapa, llevar cinta larga...',
  ChaveTexto.cadCadenaSalvaToast: '¡Encadene guardado en la libreta!',
  ChaveTexto.cadTentativaSalvaToast: '¡Intento guardado en la libreta!',
  ChaveTexto.cadContribuicaoPublica: 'CONTRIBUCIÓN PÚBLICA',
  ChaveTexto.cadPercepcaoGrau: 'Percepción del grado de la línea:',
  ChaveTexto.cadBetaOpcionalLabel: 'Beta de la Comunidad (opcional)',
  ChaveTexto.cadBetaOpcionalHint:
      'Ej.: Cinta 3 larga; buena lectura por la izquierda en el crux.',
  ChaveTexto.cadConecteParaContribuir:
      'Conecta tu cuenta en Perfil para enviar votos y betas públicos a la guía comunitaria.',
  ChaveTexto.cadEditarModalTitulo: 'Editar Ascensión',
  ChaveTexto.cadRegistrarModalTitulo: 'Registrar Ascensión',
  ChaveTexto.cadSalvarEContribuir: 'Guardar Encadene y Contribuir',
  ChaveTexto.cadSalvarNaCaderneta: 'Guardar en la Libreta',
  ChaveTexto.cadEncadenadaEm: 'Encadenada el {data} ({estilo})',
  ChaveTexto.cadTentativaEm: 'Intento el {data}',
  ChaveTexto.cadNovaAscensaoBtn: 'Nueva Ascensión / Intento',
  ChaveTexto.cadRegistrarCadenaBtn: 'Registrar Encadene / Intento',
  ChaveTexto.comunidadeHeader: 'MEDIOS, APOYOS Y COMUNIDAD',
  ChaveTexto.comunidadeSobreTimeTitulo: 'SOBRE EL EQUIPO',
  ChaveTexto.comunidadeSobreTimeSub:
      'Conoce a los desarrolladores y colaboradores del proyecto Aresta.',
  ChaveTexto.comunidadeWhatsappTitulo: 'GRUPO DE WHATSAPP',
  ChaveTexto.comunidadeWhatsappSub:
      'Participa para resolver dudas, dar ideas y recibir avisos de Aresta.',
  ChaveTexto.comunidadeInstagramTitulo: 'INSTAGRAM OFICIAL',
  ChaveTexto.comunidadeInstagramSub:
      'Sigue las últimas novedades, actualizaciones y detrás de escena.',
  ChaveTexto.comunidadeLinkedinTitulo: 'LINKEDIN DEL PROYECTO',
  ChaveTexto.comunidadeLinkedinSub:
      'Sigue novedades, crecimiento y el lado institucional de Aresta.',
  ChaveTexto.comunidadeDiscordTitulo: 'DISCORD DE DESARROLLADORES',
  ChaveTexto.comunidadeDiscordSub:
      'Habla con el equipo, sigue el código y colabora con el futuro de Aresta.',
  ChaveTexto.comunidadeGithubTitulo: 'GITHUB DE ARESTA',
  ChaveTexto.comunidadeGithubSub:
      'Accede al perfil con los repositorios abiertos en GitHub.',
  ChaveTexto.comunidadeTermosTitulo: 'Términos de Uso y Privacidad',
  ChaveTexto.comunidadeTermosSub:
      'Asunción voluntaria de riesgos y directrices de privacidad offline.',
  ChaveTexto.comunidadeRodapeVersao: 'Aresta Climb v{versao} • Beta Abierta',
  ChaveTexto.comunidadeIniciativaLivre:
      'Una iniciativa independiente por el montañismo libre.',
  ChaveTexto.comunidadeTermosModalHeader: 'TÉRMINOS Y PRIVACIDAD',
  ChaveTexto.comunidadePoliticaModalHeader: 'POLÍTICA DE PRIVACIDAD',
  ChaveTexto.timeConhecaSubtitulo: 'CONOCE A QUIENES HACEN ARESTA',
  ChaveTexto.timeOpenSourceTitulo: 'ARESTA ES OPEN SOURCE',
  ChaveTexto.timeOpenSourceCorpo:
      '¿Te gustaría contribuir? ¡Entra a nuestro Discord y envíanos un mensaje!',
  ChaveTexto.timeCargoDesigner: 'Diseñadora',
  ChaveTexto.timeCargoProduto: 'Producto / Marketing',
  ChaveTexto.timeCargoProdutoQuebra: 'Producto/\nMarketing',
  ChaveTexto.timeCargoBackend: 'Backend',
  ChaveTexto.timeCargoFrontend: 'Frontend',
  ChaveTexto.legalTermosTitulo: 'Términos de Uso',
  ChaveTexto.legalPoliticaTitulo: 'Política de Privacidad',
  ChaveTexto.legalErroTermos:
      'Error al cargar los términos. Inténtalo más tarde.',
  ChaveTexto.legalErroPolitica: 'Error al cargar la política.',
  ChaveTexto.legalBannerAtualizacao:
      '🌟 Actualizamos nuestros documentos legales. Por favor revísalos y confirma tu aceptación.',
  ChaveTexto.legalDataAtualizacao: 'Fecha de actualización: {data}',
  ChaveTexto.legalAceitoEm: 'Aceptado el {data} a las {hora}',
  ChaveTexto.legalConcordoCheckbox:
      'He leído y acepto los Términos de Uso y la Política de Privacidad.',
  ChaveTexto.legalAceitarContinuar: 'Aceptar Términos y Continuar',
  ChaveTexto.configTitulo: 'Ajustes',
  ChaveTexto.configIdiomaTitulo: 'IDIOMA',
  ChaveTexto.configIdiomaSubtitulo:
      'Cambia al instante el idioma de toda la aplicación.',
  ChaveTexto.configAparenciaTitulo: 'APARIENCIA',
  ChaveTexto.configAparenciaSub: 'Personaliza el tema de la aplicación.',
  ChaveTexto.configEscolherTemaManual: 'Elegir tema manualmente',
  ChaveTexto.configTemaEscuro: 'OSCURO',
  ChaveTexto.configPerfilCadernetaTitulo: 'PERFIL Y LIBRETA',
  ChaveTexto.configPerfilCadernetaSub:
      'Muestra u oculta tu perfil y registro de encadenes sin borrar tus datos locales.',
  ChaveTexto.configExibirPerfilSwitch: 'Mostrar Perfil y Libreta en pantallas',
  ChaveTexto.configConectarEditorTitulo: 'Conectar Editor',
  ChaveTexto.configConectarEditorInstrucao:
      'Ingresa el código de 8 caracteres del Editor o escanea el código QR.',
  ChaveTexto.configConectarEditorHint: 'ej: k9x2-p83a o URL completa',
  ChaveTexto.configEscanearQrBtn: 'ESCANEAR CÓDIGO QR',
  ChaveTexto.configComoFuncionaEditor:
      '¿Cómo funciona el Editor de Escritorio? Saber más',
  ChaveTexto.configConectarBtn: 'CONECTAR',
  ChaveTexto.configModoExperimentalTitulo: 'MODO EXPERIMENTAL / VISTA PREVIA',
  ChaveTexto.configModoExperimentalSub:
      'Visualizando croquis sincronizados en tiempo real con el Editor.',
  ChaveTexto.configVoltarModoOficialBtn: 'VOLVER AL MODO OFICIAL',
  ChaveTexto.configModoOficialTitulo: 'MODO OFICIAL',
  ChaveTexto.configModoOficialSub:
      'Conectado a la base oficial de Aresta Climb. Puedes conectar el Editor de Escritorio para probar nuevos croquis en vivo.',
  ChaveTexto.configConectarEditorPreviaBtn: 'CONECTAR AL EDITOR / PREVIA',
  ChaveTexto.configComoFazerSaibaMais: '¿Cómo hacerlo? Saber más',
  ChaveTexto.configVoltandoOficialToast: 'Volviendo al catálogo oficial...',
  ChaveTexto.configReativandoExpToast:
      'Reactivando datos experimentales locales...',
  ChaveTexto.configReativarExpBtn: 'REACTIVAR MODO EXPERIMENTAL',
  ChaveTexto.configApagarTudoTitulo: '¿Borrar Todo?',
  ChaveTexto.configApagarTudoCorpo:
      'Esto borrará permanentemente el índice experimental y todas las zonas descargadas en modo previo. ¿Continuar?',
  ChaveTexto.configApagarTudoBtn: 'BORRAR TODO',
  ChaveTexto.configAmbienteExpLimpoToast: 'Entorno experimental limpio.',
  ChaveTexto.configLimparExpBtn: 'LIMPIAR DATOS EXPERIMENTALES',
  ChaveTexto.configConectadoEditorToast: '¡Conectado al repositorio del editor!',
  ChaveTexto.configErroIndiceStatus:
      'Error: No se pudo acceder al índice (Estado {status})',
  ChaveTexto.configErroConexaoUrl: 'Error de conexión: Verifica la URL',
  ChaveTexto.qrTituloPagina: 'Escanear Código QR',
  ChaveTexto.qrAponteCamera: 'Apunta la cámara al código QR\ndel repositorio',
  ChaveTexto.feedbackPerguntaTipo: '¿Sobre qué es tu sugerencia?',
  ChaveTexto.feedbackSobreCroqui: 'Sobre el Croquis',
  ChaveTexto.feedbackSobreApp: 'Sobre la App',
  ChaveTexto.feedbackHintDescricao: 'Describe el problema o sugerencia...',
  ChaveTexto.feedbackAvisoPublico:
      'Comentario público. No se exponen datos personales.',
  ChaveTexto.feedbackEnviarBtn: 'Enviar',
  ChaveTexto.shareConfiraPico:
      'Mira el croquis de {pico}{loc} en Aresta:\n{url}',
  ChaveTexto.shareConfiraGrupo: 'Mira {grupo} en {pico} en Aresta:\n{url}',
  ChaveTexto.shareConfiraSetor: 'Mira {setor} en {pico} en Aresta:\n{url}',
  ChaveTexto.shareConfiraEscalada:
      'Mira {via}{grau}{setor} en {pico} en Aresta:\n{url}',
  ChaveTexto.shareModalTitulo: 'Compartir',
  ChaveTexto.shareModalSubtitulo:
      'Elige entre tarjeta visual para Stories o enlace clicable',
  ChaveTexto.shareBtnImagemStories: 'Compartir Imagen (Stories)',
  ChaveTexto.shareBtnLinkRapido: 'Compartir Enlace (WhatsApp)',
  ChaveTexto.shareLinkCopiadoParaStoriesToast:
      '¡Enlace copiado! Pégalo en el sticker de Enlace en Stories si quieres.',
  ChaveTexto.shareAcaoToastCaderneta: 'Compartir',
  ChaveTexto.shareSeloAscensaoTooltip: 'Compartir ascensión',
  ChaveTexto.shareCardTipoPico: 'ZONA DE ESCALADA',
  ChaveTexto.shareCardTipoGrupo: 'GRUPO DE SECTORES',
  ChaveTexto.shareCardTipoSetor: 'SECTOR DE ESCALADA',
  ChaveTexto.shareCardContagemSetores: '{n} sectores',
  ChaveTexto.shareCardContagemUmSetor: '1 sector',
  ChaveTexto.shareCardContagemEscaladas: '{n} escaladas',
  ChaveTexto.shareCardContagemUmaEscalada: '1 escalada',
  ChaveTexto.shareCardFaixaGraus: 'Grados {faixa}',
  ChaveTexto.gpsDesligadoUltimaConhecida:
      'GPS apagado; centrando en tu última ubicación conocida.',
  ChaveTexto.gpsAtiveAparelho:
      'Activa el GPS del dispositivo para centrar en tu ubicación.',
  ChaveTexto.gpsPermissaoNegada: 'Permiso de ubicación denegado.',
  ChaveTexto.gpsSinalIndisponivel:
      'No se pudo obtener señal de GPS en este momento.',
  ChaveTexto.filtroSecaoFiltros: 'FILTROS',
  ChaveTexto.filtroModalidadesTitulo: 'Modalidades',
  ChaveTexto.setorNenhumaEscaladaFiltrosAtuais:
      'Ninguna escalada coincide con los filtros actuales.',
  ChaveTexto.modEsportivaMinusculo: 'deportiva',
  ChaveTexto.modMovelMinusculo: 'clásica',
  ChaveTexto.modBoulderMinusculo: 'bloque',
  ChaveTexto.modMultienfiadaMinusculo: 'multilargo',
  ChaveTexto.modMultienfiadasMinusculo: 'multilargos',
  ChaveTexto.modHighlineMinusculo: 'highline',
  ChaveTexto.comumFecharCaixaAlta: 'CERRAR',
  ChaveTexto.authValidacaoCodigo6Digitos:
      'Ingresa el código numérico de 6 dígitos enviado por correo.',
  ChaveTexto.authServicoIndisponivel:
      'Servicio de autenticación no disponible en este momento.',
  ChaveTexto.configTestarObsolescenciaBtn: 'PROBAR AVISO DE OBSOLESCENCIA',
  ChaveTexto.configTestarBloqueioBtn: 'PROBAR PANTALLA DE BLOQUEO',
  ChaveTexto.notifBaixandoPct: 'Descargando... {pct}%',
  ChaveTexto.notifCroquiSalvoOffline: '✓ Croquis guardado para uso offline.',
  ChaveTexto.notifFalhaBaixarCroqui:
      'Error al descargar el croquis. Verifica tu conexión.',
  ChaveTexto.feedbackRecebidoObrigado:
      '¡Comentarios recibidos! Muchas gracias por ayudar a mejorar la app.',
  ChaveTexto.sistemaMigracaoTentarNovamente: 'Reintentar',
};
