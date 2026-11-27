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

  // Sistema, prévia experimental, versão e migração
  ChaveTexto.sistemaModoExperimentalAtivo: 'MODO EXPERIMENTAL ATIVO',
  ChaveTexto.sistemaSair: 'SAIR',
  ChaveTexto.sistemaSessaoPreviaEncerradaTitulo: 'Sessão de Prévia Encerrada',
  ChaveTexto.sistemaSessaoPreviaEncerradaCorpo:
      'A conexão com o Editor Desktop foi finalizada. Como o modo de prévia é temporário, restauramos automaticamente o catálogo oficial do Aresta Climb para você continuar navegando.',
  ChaveTexto.sistemaFaseBetaTitulo: 'Fase Beta Aberta',
  ChaveTexto.sistemaFaseBetaIntro:
      'O Aresta Climb é uma iniciativa independente e está em desenvolvimento ativo com a comunidade de escaladores.',
  ChaveTexto.sistemaFaseBetaItem1Titulo: 'Novos setores e croquis contínuos',
  ChaveTexto.sistemaFaseBetaItem1Corpo:
      'Nossa base de vias, croquis e mapas é expandida e atualizada frequentemente.',
  ChaveTexto.sistemaFaseBetaItem2Titulo: 'Recursos em constante evolução',
  ChaveTexto.sistemaFaseBetaItem2Corpo:
      'Filtros avançados, ferramentas de navegação e melhorias de performance estão a caminho.',
  ChaveTexto.sistemaFaseBetaItem3Titulo: 'Construção comunitária',
  ChaveTexto.sistemaFaseBetaItem3Corpo:
      'Sua experiência na rocha é essencial para identificarmos ajustes e priorizarmos o que importa.',
  ChaveTexto.sistemaInstagramOficial: 'Instagram Oficial',
  ChaveTexto.sistemaComunidadeWhatsapp: 'Comunidade no WhatsApp',
  ChaveTexto.sistemaEnviarSugestao: 'Enviar Sugestão',
  ChaveTexto.sistemaRodapeVersaoBeta: 'Aresta Climb v{versao} (Beta Aberto)',
  ChaveTexto.sistemaAtualizeParaBaixar:
      'Atualize o Aresta para voltar a baixar e sincronizar croquis.',
  ChaveTexto.sistemaAtualizacaoRecomendada:
      'Atualização Recomendada: uma nova versão está disponível.',
  ChaveTexto.sistemaAtualizar: 'ATUALIZAR',
  ChaveTexto.sistemaAtualizacaoNecessaria: 'ATUALIZAÇÃO\nNECESSÁRIA',
  ChaveTexto.sistemaVersaoAntigaCorpo:
      'Sua versão do Aresta é muito antiga e não é mais suportada. Para continuar usando o app e explorando croquis, por favor, atualize-o na loja.',
  ChaveTexto.sistemaAtualizarAgora: 'ATUALIZAR AGORA',
  ChaveTexto.sistemaPreviaFalhaConectar:
      'Não foi possível conectar à sessão de prévia "{codigo}".',
  ChaveTexto.sistemaDeepLinkNaoEncontrado:
      'Não foi possível encontrar a via ou setor correspondente ao código "{uid}". Verifique sua conexão à internet ou baixe o pico previamente.',
  ChaveTexto.sistemaMigracaoVerificando:
      'Verificando conexão com a internet...',
  ChaveTexto.sistemaMigracaoBaixando: 'Baixando novo catálogo de croquis...',
  ChaveTexto.sistemaMigracaoErro:
      'Não foi possível atualizar o banco de dados. Verifique sua conexão com a internet.',
  ChaveTexto.sistemaMigracaoTitulo: 'ATUALIZAÇÃO DE BASE DE DADOS',
  ChaveTexto.sistemaMigracaoCorpo:
      'Esta nova versão do aplicativo inclui atualizações estruturais no catálogo de croquis e precisa sincronizar pela internet uma única vez.',

  // Página Inicial (Home) e Busca Global
  ChaveTexto.homeMeuPerfilTooltip: 'Meu Perfil',
  ChaveTexto.homeConfiguracoesTooltip: 'Configurações',
  ChaveTexto.homeSincronizarTooltip: 'Sincronizar catálogo e croquis',
  ChaveTexto.homeBoasVindas: 'BEM VINDO!',
  ChaveTexto.homeBoraPraPedra: 'BORA PRA PEDRA?',
  ChaveTexto.homeDescricaoHeroi:
      'O guia definitivo para facilitar a sua escalada. Explore setores, vias e boulders locais e salve os croquis para acessar totalmente offline.',
  ChaveTexto.homeBuscaHint: 'Buscar picos, setores ou vias...',
  ChaveTexto.homeErroAbrirSalvo:
      'Erro ao abrir o croqui salvo. Tente sincronizar novamente.',
  ChaveTexto.homeCroquiNaoSalvoOffline:
      'Este croqui ainda não está salvo offline. Conecte-se à internet para abri-lo.',
  ChaveTexto.homeMaisProximosTitulo: 'MAIS PRÓXIMOS DE VOCÊ',
  ChaveTexto.homePermitaLocalizacao:
      'Permita o acesso à localização para ver os picos mais próximos de você.',
  ChaveTexto.homePermitirLocalizacaoBtn: 'Permitir Localização',
  ChaveTexto.homeAguardandoGps: 'Aguardando sinal de GPS...',
  ChaveTexto.homeNenhumPicoLocalizado: 'Nenhum pico com localização encontrada.',
  ChaveTexto.homeVerMais: 'VER MAIS ->',
  ChaveTexto.homeComoFunciona: 'COMO FUNCIONA',
  ChaveTexto.homeGuiaRapidoTitulo: 'GUIA RÁPIDO DO ARESTA',
  ChaveTexto.homeGuiaRapidoSubtitulo:
      'Tudo o que você precisa pra sair do app direto pro paredão.',
  ChaveTexto.homePasso1Titulo: 'ENCONTRE O PICO',
  ChaveTexto.homePasso1Desc:
      'Veja o tempo de viagem no carrossel ou explore o Globo 3D/2D com relevo, seu GPS ao vivo, radar de chuva e nível de umidade da rocha.',
  ChaveTexto.homePasso2Titulo: 'SALVE OFFLINE',
  ChaveTexto.homePasso2Desc:
      'Abra qualquer pico na hora estando online ou baixe o guia completo para navegar 100% sem sinal na base da falésia.',
  ChaveTexto.homePasso3Titulo: 'CROQUI INTERATIVO',
  ChaveTexto.homePasso3Desc:
      'Toque nas linhas do paredão para consultar graus e proteções, e confira ou reporte alertas rápidos na rocha (🐝, 🪨, 🔩, ⚠️).',
  ChaveTexto.homePasso4Titulo: 'CADERNETA & COMUNIDADE',
  ChaveTexto.homePasso4Desc:
      'Registre cadenas, vote no consenso de grau e expanda vídeos e betas da comunidade só quando quiser (fechados por padrão contra spoilers).',
  ChaveTexto.homePasso5Titulo: 'ATALHO PARA O INÍCIO',
  ChaveTexto.homePasso5Desc:
      'Toque em voltar (←) para subir um nível ou mantenha o botão voltar pressionado para saltar direto de volta ao Início.',
  ChaveTexto.homePasso6Titulo: 'COMPARTILHE',
  ChaveTexto.homePasso6Desc:
      'Envie links de vias, setores e picos para sua cordada abrir direto no app ou navegador.',
  ChaveTexto.homeConservacaoTitulo: 'CONSERVAÇÃO E ACESSO',
  ChaveTexto.homeConservacaoCorpo:
      'O acesso aos picos depende de cuidado, ética e envolvimento com as comunidades locais. Cada local tem suas regras, seus guardiões e sua história. Escalar com responsabilidade é garantir que os picos continuem abertos.',
  ChaveTexto.buscaTodos: 'Todos',
  ChaveTexto.buscaPicos: 'Picos',
  ChaveTexto.buscaSetores: 'Setores',
  ChaveTexto.buscaDica:
      'Dica: pesquise por picos, setores, vias ou graus (ex: 7a, V4)',
  ChaveTexto.buscaNenhumResultado: 'Nenhum resultado encontrado.',
  ChaveTexto.buscaFiltroPrefixo: 'Filtro: {filtro}',

