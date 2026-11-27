// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'modelo_idioma_app.dart';

/// Dicionário canônico em Português Brasileiro (`pt-BR`), preservando fielmente a
/// terminologia esportiva de escalada do Brasil e 100% da compatibilidade da suíte existente.
const Map<ChaveTexto, String> dicionarioPortugues = {
  // Seletor de idioma
  ChaveTexto.seletorIdiomaTitulo: 'IDIOMA DO APLICATIVO',
  ChaveTexto.seletorIdiomaSubtitulo:
      'Escolha o idioma exibido em todas as telas do Aresta Climb.',
  ChaveTexto.seletorIdiomaTooltip: 'Alternar idioma do aplicativo',

  // Navegação e ações globais
  ChaveTexto.navInicio: 'INÍCIO',
  ChaveTexto.navExplorar: 'EXPLORAR',
  ChaveTexto.navMeusCroquis: 'MEUS CROQUIS',
  ChaveTexto.navComunidade: 'COMUNIDADE',
  ChaveTexto.navInicioCurto: 'Início',
  ChaveTexto.navGps: 'GPS',
  ChaveTexto.comumVoltar: 'Voltar',
  ChaveTexto.comumSegureParaInicio: 'Segure para ir ao início',
  ChaveTexto.comumFechar: 'Fechar',
  ChaveTexto.comumCancelar: 'Cancelar',
  ChaveTexto.comumCancelarCaixaAlta: 'CANCELAR',
  ChaveTexto.comumSalvar: 'Salvar',
  ChaveTexto.comumSalvarAlteracoes: 'Salvar Alterações',
  ChaveTexto.comumExcluir: 'Excluir',
  ChaveTexto.comumExcluirCaixaAlta: 'EXCLUIR',
  ChaveTexto.comumEntendi: 'ENTENDI',
  ChaveTexto.comumTentarNovamente: 'Tentar novamente',
  ChaveTexto.comumDesfazer: 'Desfazer',
  ChaveTexto.comumLimpar: 'Limpar',
  ChaveTexto.comumAplicar: 'Aplicar',
  ChaveTexto.comumAplicarUmResultado: 'Aplicar (1 resultado)',
  ChaveTexto.comumAplicarVariosResultados: 'Aplicar ({total} resultados)',
  ChaveTexto.comumSemNome: 'Sem Nome',
  ChaveTexto.comumSemNomeCaixaAlta: 'SEM NOME',
  ChaveTexto.comumLocalDesconhecido: 'LOCAL DESCONHECIDO',
  ChaveTexto.comumPico: 'Pico',
  ChaveTexto.comumSetor: 'Setor',
  ChaveTexto.comumGrupo: 'Grupo',
  ChaveTexto.comumOffline: 'Offline',
  ChaveTexto.comumSalvoOffline: 'Salvo offline',
  ChaveTexto.comumSalvoOfflineCaixaAlta: 'SALVO OFFLINE',
  ChaveTexto.comumCatalogo: 'Catálogo',
  ChaveTexto.comumAbrindo: 'Abrindo {titulo}...',
  ChaveTexto.comumBaixando: 'Baixando {nome}...',
  ChaveTexto.comumBaixadoSucesso: '{nome} baixado',
  ChaveTexto.comumSalvoOfflineToast: '{nome} salvo offline!',
  ChaveTexto.comumFalhaBaixar: 'Falha ao baixar {nome}',
  ChaveTexto.comumSemConexao: 'Sem conexão com a internet.',
  ChaveTexto.comumErroAbrirLink: 'Erro ao abrir o link.',
  ChaveTexto.comumLinkCopiado: 'Link copiado!',
  ChaveTexto.comumAbrirLink: 'ABRIR LINK',
  ChaveTexto.comumAcessar: 'ACESSAR ',
  ChaveTexto.comumVerificandoAtualizacoes: 'Verificando atualizações...',
  ChaveTexto.comumErroVerificarAtualizacoes:
      'Erro ao verificar atualizações. Tente novamente mais tarde.',
  ChaveTexto.comumConcluidoComFalhas: 'Concluído com falhas: {falhas}',
  ChaveTexto.comumCatalogoAtualizadoSucesso: 'Catálogo atualizado com sucesso!',
  ChaveTexto.comumCatalogoJaAtualizado: 'Catálogo já está atualizado.',
  ChaveTexto.comumNenhumCroquiPrecisavaAtualizar:
      'Nenhum croqui precisava ser atualizado.',
  ChaveTexto.comumCroquisAtualizados: 'Croquis foram atualizados!',
  ChaveTexto.comumSincronizandoServing: 'Sincronizando com o serving...',
  ChaveTexto.comumSemConexaoServing: 'Sem conexão com o serving.',
  ChaveTexto.comumErroSincronizarServing:
      'Erro ao sincronizar com o serving. Tente novamente mais tarde.',
  ChaveTexto.comumSincronizadoComFalhas: 'Sincronizado com falhas em: {falhas}',
  ChaveTexto.comumCatalogoAtualizadoServing:
      'Catálogo atualizado com o serving!',
  ChaveTexto.comumCatalogoJaRecenteServing:
      'Catálogo já está na versão mais recente do serving.',
  ChaveTexto.comumVersaoDesatualizadaToast:
      'Sua versão do Aresta está desatualizada. Atualize para continuar baixando croquis.',
  ChaveTexto.comumGuiaAtualizadoToast: 'O guia de {nome} foi atualizado!',
  ChaveTexto.comumErroSincronizarDadosToast:
      'Erro ao sincronizar os dados. Tente novamente mais tarde.',
  ChaveTexto.comumCroquisBaixadosAtualizadosToast:
      'Seus croquis baixados foram atualizados!',
  ChaveTexto.comumAtualizadoAgora: 'atualizado agora',
  ChaveTexto.comumAtualizadoHaAno: 'atualizado há 1 ano',
  ChaveTexto.comumAtualizadoHaAnos: 'atualizado há {n} anos',
  ChaveTexto.comumAtualizadoHaMes: 'atualizado há 1 mês',
  ChaveTexto.comumAtualizadoHaMeses: 'atualizado há {n} meses',
  ChaveTexto.comumAtualizadoHaDia: 'atualizado há 1 dia',
  ChaveTexto.comumAtualizadoHaDias: 'atualizado há {n} dias',
  ChaveTexto.comumAtualizadoHaHora: 'atualizado há 1 hora',
  ChaveTexto.comumAtualizadoHaHoras: 'atualizado há {n} horas',
  ChaveTexto.comumAtualizadoHaMinuto: 'atualizado há 1 minuto',
  ChaveTexto.comumAtualizadoHaMinutos: 'atualizado há {n} minutos',
  ChaveTexto.comumEnviarFeedbackTooltip: 'Enviar Feedback/Bug',
  ChaveTexto.comumFeedbackIndisponivelDev:
      'Envio de feedback indisponível neste ambiente de desenvolvimento.',
  ChaveTexto.comumSincronizarServingTooltip: 'Sincronizar com serving',
  ChaveTexto.comumBuscarPicosHint: 'Buscar picos para escalar...',
  ChaveTexto.comumMapaGeral: 'Mapa Geral',

