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

