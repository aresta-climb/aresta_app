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
  ChaveTexto.modEstimativaSemTransito:
      'Estimación sin tráfico: {tempo} ({distancia})',
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
      'Aresta utiliza 3 fuentes meteorológicas y de radar Y 3 recursos públicos de misiones de la NASA para lograr una tasa de ~86% de acierto al mostrar esta información. Usa esta herramienta como referencia y no como verdad absoluta.',
  ChaveTexto.explorarAvisoClimaConfirmar: 'OK, mostrar en el mapa',
  ChaveTexto.climaChuvaFraca: 'Lluvia débil',
  ChaveTexto.climaChuvaModerada: 'Lluvia moderada',
  ChaveTexto.climaChuvaForte: 'Lluvia fuerte',
  ChaveTexto.climaTempestadeSevera: 'Tormenta severa',
  ChaveTexto.climaFocoIsolado: 'Foco térmico aislado',
  ChaveTexto.climaFocoQueimada: 'Foco de quema',
  ChaveTexto.climaIncendioAtivo: 'Incendio activo',
  ChaveTexto.climaIncendioSevero: 'Incendio severo',

