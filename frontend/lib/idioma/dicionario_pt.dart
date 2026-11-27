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

  // Modalidades, contagens e estilos de escalada/ascensão
  ChaveTexto.modEsportiva: 'Esportiva',
  ChaveTexto.modEsportivas: 'Esportivas',
  ChaveTexto.modEsportivasMinusculo: 'esportivas',
  ChaveTexto.modMovel: 'Móvel',
  ChaveTexto.modMoveis: 'Móveis',
  ChaveTexto.modMoveisMinusculo: 'móveis',
  ChaveTexto.modMovelTrad: 'Móvel / Trad',
  ChaveTexto.modBoulder: 'Boulder',
  ChaveTexto.modBoulders: 'Boulders',
  ChaveTexto.modBouldersMinusculo: 'boulders',
  ChaveTexto.modMultienfiada: 'Multienfiada',
  ChaveTexto.modMultienfiadas: 'Multienfiadas',
  ChaveTexto.modMultiplasEnfiadasMinusculo: 'múltiplas enfiadas',
  ChaveTexto.modParedao: 'Paredão',
  ChaveTexto.modHighline: 'Highline',
  ChaveTexto.modHighlines: 'Highlines',
  ChaveTexto.modHighlinesMinusculo: 'highlines',
  ChaveTexto.modMista: 'Mista',
  ChaveTexto.modOutro: 'Outro',
  ChaveTexto.modOutras: 'Outras',
  ChaveTexto.modVia: 'Via',
  ChaveTexto.modVias: 'Vias',
  ChaveTexto.modViasMinusculo: 'vias',
  ChaveTexto.modEscaladaMinusculo: 'escalada',
  ChaveTexto.modEscaladasMinusculo: 'escaladas',
  ChaveTexto.modSetorMinusculo: 'setor',
  ChaveTexto.modSetoresMinusculo: 'setores',
  ChaveTexto.modSetoresCaixaAlta: 'SETORES',
  ChaveTexto.modDeTotal: '{qtd} de {total} {plural}',
  ChaveTexto.modEstimativaSemTransito:
      'Estimativa sem trânsito: {tempo} ({distancia})',
  ChaveTexto.estiloAVista: 'À Vista',
  ChaveTexto.estiloFlash: 'Flash',
  ChaveTexto.estiloTrabalhado: 'Trabalhado',
  ChaveTexto.estiloTentativa: 'Tentativa',
  ChaveTexto.estiloGuiado: 'Guiado',
  ChaveTexto.estiloTopRope: 'Top Rope',
  ChaveTexto.estiloSolo: 'Solo',
  ChaveTexto.estiloTentativaSingular: 'tentativa',
  ChaveTexto.estiloTentativaPlural: 'tentativas',

  // Aba Explorar, Globo 3D/2D e Clima
  ChaveTexto.explorarBuscaHint: 'Buscar pico, cidade ou via...',
  ChaveTexto.explorarTrocarServing: 'Trocar serving',
  ChaveTexto.explorarAteKm: 'Até {km} km',
  ChaveTexto.explorarViasBrasileiro: 'Vias (Brasileiro)',
  ChaveTexto.explorarBoulderEscalaV: 'Boulder (Escala V)',
  ChaveTexto.explorarFiltrosOrdenacao: 'Filtros e Ordenação',
  ChaveTexto.explorarOrdenacaoSecao: 'ORDENAÇÃO',
  ChaveTexto.explorarMaisProximos: 'Mais próximos',
  ChaveTexto.explorarAlfabeticoAZ: 'Alfabético (A-Z)',
  ChaveTexto.explorarMaisEscaladas: 'Mais escaladas',
  ChaveTexto.explorarModalidadesSecao: 'MODALIDADES',
  ChaveTexto.explorarDificuldadeSecao: 'DIFICULDADE NO CATÁLOGO',
  ChaveTexto.explorarAlcanceSecao: 'ALCANCE E DISPONIBILIDADE',
  ChaveTexto.explorarSalvosOffline: 'Salvos Offline',
  ChaveTexto.explorarVerNPicos: 'Ver {total} picos',
  ChaveTexto.explorarModoMapa: 'Mapa',
  ChaveTexto.explorarModoDividir: 'Dividir',
  ChaveTexto.explorarModoLista: 'Lista',
  ChaveTexto.explorarContagemPicos: '{n} PICOS',
  ChaveTexto.explorarNenhumPicoEncontrado: 'Nenhum pico encontrado.',
  ChaveTexto.explorarSetorPrincipal: 'Setor Principal',
  ChaveTexto.explorarAcimaDoMar: '{metros} m acima do mar',
  ChaveTexto.climaSeco: 'Seco',
  ChaveTexto.climaPossivelmenteUmido: 'Possivelmente úmido',
  ChaveTexto.climaRochaSecaSemChuva:
      'Provavelmente seco · Sem chuva próxima (4 dias)',
  ChaveTexto.climaContagemUmDia: '1 dia',
  ChaveTexto.climaContagemDias: '{dias} dias',
  ChaveTexto.climaChuvaProximaHoje: 'chuva próxima hoje ({data})',
  ChaveTexto.climaChuvaProximaUmDia: 'chuva próxima há 1 dia ({data})',
  ChaveTexto.climaChuvaProximaDias: 'chuva próxima há {dias} dias ({data})',
  ChaveTexto.climaNotaJanelaQuatroDias:
      'Janela conservadora de 4 dias reiniciada a cada chuva na região. Confira a rocha no local.',
  ChaveTexto.climaNotaEstimativaSatelite:
      'Estimativa regional por satélite — infiltrações locais podem variar.',
  ChaveTexto.explorarBotaoClimaMapa: 'Clima e Fogo',
  ChaveTexto.explorarAvisoClimaTitulo: 'Aviso de uso',
  ChaveTexto.explorarAvisoClimaCorpo:
      'O Aresta utiliza 3 fontes meteorológicas e de radar E 3 recursos públicos de missões da NASA para alcançar uma taxa de ~86% de acerto na exibição destas informações. Use esta ferramenta como referência, e não como verdade absoluta.',
  ChaveTexto.explorarAvisoClimaConfirmar: 'OK, exibir no mapa',
  ChaveTexto.climaChuvaFraca: 'Chuva fraca',
  ChaveTexto.climaChuvaModerada: 'Chuva moderada',
  ChaveTexto.climaChuvaForte: 'Chuva forte',
  ChaveTexto.climaTempestadeSevera: 'Tempestade severa',
  ChaveTexto.climaFocoIsolado: 'Foco térmico isolado',
  ChaveTexto.climaFocoQueimada: 'Foco de queimada',
  ChaveTexto.climaIncendioAtivo: 'Incêndio ativo',
  ChaveTexto.climaIncendioSevero: 'Incêndio severo',

  // Meus Croquis e Modais Offline
  ChaveTexto.meusCroquisTitulo: 'MEUS CROQUIS',
  ChaveTexto.meusCroquisSubtitulo: 'ARMAZENAMENTO OFFLINE',
  ChaveTexto.meusCroquisVazio: 'Nenhum croqui salvo offline ainda.',
  ChaveTexto.meusCroquisAbrirOffline: 'ABRIR OFFLINE',
  ChaveTexto.meusCroquisErroAbrir: 'Erro ao abrir o guia offline.',
  ChaveTexto.meusCroquisExcluirTitulo: 'Excluir?',
  ChaveTexto.meusCroquisExcluirPergunta: 'Deseja excluir o guia de {nome}?',
  ChaveTexto.meusCroquisExcluidoToast: 'Guia excluído.',
  ChaveTexto.meusCroquisErroExcluirToast: 'Erro ao excluir guia.',
  ChaveTexto.meusCroquisGuiaRemovidoToast:
      'Guia removido do armazenamento offline.',
  ChaveTexto.offlineSalvarComTamanho: 'Salvar Offline ({tamanho})',
  ChaveTexto.offlineSalvarSemTamanho: 'Salvar Offline',
  ChaveTexto.offlineModoOnlineTitulo: 'MODO ONLINE',
  ChaveTexto.offlineModoOnlineDesc:
      'Você está navegando via internet. Salve o guia completo para usar sem sinal na pedra.',
  ChaveTexto.offlineBaixandoPct: 'BAIXANDO ({pct}%)...',
  ChaveTexto.offlineSalvarParaPedraTitulo: 'SALVAR PARA A PEDRA?',
  ChaveTexto.offlineSalvarParaPedraCorpo:
      'Lembre-se: na rocha não há sinal de internet. Para consultar os croquis e graus de {nome} sem conexão, salve o guia offline.',
  ChaveTexto.offlineSairSemSalvar: 'Sair sem Salvar',
  ChaveTexto.offlineSemConexaoTitulo: 'VOCÊ ESTÁ SEM CONEXÃO',
  ChaveTexto.offlineSemConexaoCorpo:
      'Este conteúdo faz parte do croqui {nome}, que ainda não está salvo offline no seu aparelho. Quando voltar a ter conexão com a internet, tente novamente para abri-lo.',
  ChaveTexto.offlineAindaSemConexao:
      'Ainda sem conexão com a internet. Verifique sua rede e tente novamente.',
  ChaveTexto.offlineTentandoConectar: 'Tentando conectar...',

  // Página do Pico, Subpáginas, Setor, Grupo, Filtros de Índice e Croqui Interativo
  ChaveTexto.picoCompartilharTooltip: 'Compartilhar pico',
  ChaveTexto.picoExcluirGuiaTooltip: 'Excluir guia',
  ChaveTexto.picoBuscarBoulderTooltip: 'Buscar boulder',
  ChaveTexto.picoBuscarViaTooltip: 'Buscar via',
  ChaveTexto.picoCardSetoresTitulo: 'Setores & Escaladas',
  ChaveTexto.picoCardSetoresSubtitulo:
      'Explore setores, vias e boulders com filtros e mapas integrados',
  ChaveTexto.picoCardExplorarTitulo: 'Explorar Local',
  ChaveTexto.picoCardExplorarSubtitulo:
      'Como chegar, mapas gerais do croqui, clima e informações úteis.',
  ChaveTexto.picoCardRegrasTitulo: 'Regras e recomendações',
  ChaveTexto.picoCardRegrasSubtitulo:
      'Normas de conduta ecológica, segurança básica, ética e boa convivência.',
  ChaveTexto.picoCardComunidadeTitulo: 'Comunidade',
  ChaveTexto.picoCardComunidadeSubtitulo:
      'Redes sociais, canal de Whatsapp, patrocinadores e comércio local.',
  ChaveTexto.picoCardCreditosSubtitulo:
      'Conheça os autores, colaboradores e agradecimentos.',
  ChaveTexto.picoVoltarMapaSetor: 'Voltar para o Mapa do Setor',
  ChaveTexto.picoCroquiPor: 'Croqui por {autores}',
  ChaveTexto.picoInfoLocal: 'Informações do Local',
  ChaveTexto.picoCampoNome: 'Nome',
  ChaveTexto.picoCampoEstado: 'Estado',
  ChaveTexto.picoMaisInfoSecao: 'Mais Informações',
  ChaveTexto.picoMapasGerais: 'Mapas Gerais',
  ChaveTexto.picoNenhumElemento: 'Nenhum elemento disponível.',
  ChaveTexto.picoBuscarBoulderHint: 'Buscar boulder (ex: V4) ou setor...',
  ChaveTexto.picoBuscarEscaladaHint: 'Buscar escalada (ex: 7a) ou setor...',
  ChaveTexto.picoDificuldadePrefixo: 'Dificuldade: {grau}',
  ChaveTexto.picoUltimaAtualizacaoNaoInformada:
      'Última atualização: Não informada',
  ChaveTexto.picoUltimaAtualizacaoHoje: 'Última atualização: Hoje às {hora}',
  ChaveTexto.picoUltimaAtualizacaoOntem: 'Última atualização: Ontem às {hora}',
  ChaveTexto.picoUltimaAtualizacaoData:
      'Última atualização: {data} às {hora}',
  ChaveTexto.picoSubExplorarTitulo: 'EXPLORAR O LOCAL',
  ChaveTexto.picoSubIntroSubtitulo:
      'Apresentação geral e introdução ao local.',
  ChaveTexto.picoSubSobreLocal: 'Sobre o local',
  ChaveTexto.picoSubSobreLocalSubtitulo:
      'História do complexo de montanha, conquistas pioneiras e curiosidades locais.',
  ChaveTexto.picoSubComoChegar: 'Como chegar',
  ChaveTexto.picoSubComoChegarSubtitulo:
      'Instruções de acesso e navegação até a base da montanha.',
  ChaveTexto.picoSubAbrirMaps: 'Abrir no Google Maps',
  ChaveTexto.picoSubAbrirMapsSubtitulo:
      'Ver localização e traçar rota até o pico.',
  ChaveTexto.picoSubExtrasSubtitulo: 'Informações extras sobre o local.',
  ChaveTexto.picoSubComunidadeTitulo: 'COMUNIDADE',
  ChaveTexto.picoSubInformacoes: 'Informações',
  ChaveTexto.picoSubAssociacaoLocal: 'Associação Local',
  ChaveTexto.picoSubParceiros: 'Parceiros',
  ChaveTexto.picoSubComercioLocal: 'Comércio local',
  ChaveTexto.picoSubApoieTitulo: 'APOIE O PICO',
  ChaveTexto.picoSubDoacaoPix: 'Doação via Pix',
  ChaveTexto.picoSubDoacaoPixSubtitulo:
      'Ajude a comprar chapeletas e correntes de inox.\nChave: {chave}',
  ChaveTexto.picoSubPixCopiadoToast:
      'Chave PIX copiada para a área de transferência!',
  ChaveTexto.picoSubProdutos: 'Produtos do pico',
  ChaveTexto.picoSubPatrocinador: 'Seja um patrocinador',
  ChaveTexto.picoSubPatrocinadorSubtitulo:
      'Sua marca associada ética e ecologicamente à rocha.',
  ChaveTexto.picoSubEnviarInfo: 'Envie uma informação',
  ChaveTexto.picoSubEnviarInfoSubtitulo:
      'Contribuir sugerindo novas vias ou correções.',
  ChaveTexto.picoRegrasTitulo: 'REGRAS E RECOMENDAÇÕES',
  ChaveTexto.picoRegrasVazio:
      'Nenhuma regra específica cadastrada para este local. Por favor, siga as normas de conduta ética e ambiental padrão.',
  ChaveTexto.picoGpsEmBreve: 'Funcionalidades GPS em breve',
  ChaveTexto.setorTituloPagina: 'SETORES & ESCALADAS',
  ChaveTexto.setorCompartilharTooltip: 'Compartilhar setor',
  ChaveTexto.setorCompartilharGrupoTooltip: 'Compartilhar grupo',
  ChaveTexto.setorNenhumSetorDisponivel: 'Nenhum setor disponível.',
  ChaveTexto.setorNenhumaViaDisponivel: 'Nenhuma via disponível.',
  ChaveTexto.setorNenhumBoulderDisponivel: 'Nenhum boulder disponível.',
  ChaveTexto.setorNenhumSetorCadastrado:
      'Nenhum setor ou escalada cadastrado para este local no momento.',
  ChaveTexto.setorNenhumSetorFiltrado:
      'Nenhum setor encontrado com os filtros selecionados.',
  ChaveTexto.setorNenhumaEscaladaFiltrada:
      'Nenhuma escalada encontrada com os filtros selecionados.',
  ChaveTexto.setorVerNoCroqui: 'Ver no croqui',
  ChaveTexto.setorAbrirCroquiSemantics: 'Abrir croqui do setor {nome}',
  ChaveTexto.filtroPadrao: 'PADRÃO',
  ChaveTexto.filtroPadraoMisto: 'Padrão',
  ChaveTexto.filtroGrau: 'GRAU',
  ChaveTexto.filtroGrauMisto: 'Grau',
  ChaveTexto.filtroAlfabetico: 'ALFABÉTICO',
  ChaveTexto.filtroAtivoSingular: '1 ativo',
  ChaveTexto.filtroAtivoPlural: '{n} ativos',
  ChaveTexto.filtroLocalizacao: 'Localização',
  ChaveTexto.filtroConquistaAutores: 'Conquista (Autores)',
  ChaveTexto.filtroApenasClassicas: 'Apenas Clássicas (★)',
  ChaveTexto.filtroClassicas: 'Clássicas (★)',
  ChaveTexto.filtroModalidadeInativa: 'Modalidade inativa',
  ChaveTexto.filtroTodosGrausFaixa: 'Todos os graus ({min} a {max})',
  ChaveTexto.filtroTodosGraus: 'Todos os graus',
  ChaveTexto.filtroGrauUnico: 'Grau: {grau}',
  ChaveTexto.filtroGrauFaixa: 'Grau: {min} a {max}',
  ChaveTexto.filtroConectorA: 'a',
  ChaveTexto.filtroFaixaGrauVias: 'Faixa de Grau (Vias)',
  ChaveTexto.filtroFaixaGrauBoulders: 'Faixa de Grau (Boulders)',
  ChaveTexto.filtroFaixaGrau: 'Faixa de Grau',
  ChaveTexto.filtroAddSetorOuGrupo: 'Adicionar setor ou grupo...',
  ChaveTexto.filtroAddSetor: 'Adicionar setor...',
  ChaveTexto.filtroTodosSetoresGruposAdd:
      'Todos os setores ou grupos adicionados',
  ChaveTexto.filtroTodosSetoresAdd: 'Todos os setores adicionados',
  ChaveTexto.filtroNenhumLocalAtual: 'Nenhum local nos filtros atuais',
  ChaveTexto.filtroNenhumSetorAtual: 'Nenhum setor nos filtros atuais',
  ChaveTexto.filtroAddConquistador: 'Adicionar conquistador...',
  ChaveTexto.filtroTodosConquistadoresAdd:
      'Todos os conquistadores adicionados',
  ChaveTexto.filtroNenhumConquistadorAtual:
      'Nenhum conquistador nos filtros atuais',
  ChaveTexto.croquiMapasInterativosContagem: 'Mapas Interativos ({n})',
  ChaveTexto.croquiAbrirMapaInterativo: 'Abrir Mapa Interativo',
  ChaveTexto.croquiTituloPagina: 'Croqui Interativo',
  ChaveTexto.croquiMaisInfo: 'Mais Info',
  ChaveTexto.croquiVerMapas: 'Ver mapas',
  ChaveTexto.croquiIrParaSetor: 'Ir para Setor',
  ChaveTexto.croquiIrParaGrupo: 'Ir para Grupo',
  ChaveTexto.croquiCentralizarTooltip: 'Centralizar imagem',
  ChaveTexto.croquiPaginacaoDe: '{atual} de {total}',

  // Detalhes da Via, Consenso de Grau, Especificações Técnicas e Alertas de Segurança
  ChaveTexto.viaClassica: 'CLÁSSICA',
  ChaveTexto.viaGrauMaximo: 'GRAU MÁXIMO',
  ChaveTexto.viaGrauOficial: 'GRAU OFICIAL',
  ChaveTexto.viaConsensoComunidade: 'CONSENSO DA COMUNIDADE',
  ChaveTexto.viaSemVotos: 'Sem votos',
  ChaveTexto.viaNAvaliacoes: '{n} avaliações',
  ChaveTexto.viaDistribuicaoVotos: 'DISTRIBUIÇÃO DE VOTOS ({n})',
  ChaveTexto.viaGrauJustoCurto: 'Justo',
  ChaveTexto.viaGrauJustoZero: 'Grau Justo (0)',
  ChaveTexto.viaGrauJustoComNota: 'Justo ({grau})',
  ChaveTexto.viaRegistreParaAvaliar: 'Registre sua ascensão para avaliar',
  ChaveTexto.viaConfirmamGrauPct: '{pct}% confirmam o grau',
  ChaveTexto.viaSugeremGrauPct: '{pct}% sugerem {sinal}',
  ChaveTexto.viaLinhaNumero: 'Linha #{n}',
  ChaveTexto.viaVerNoCroquiInterativo: 'VER NO CROQUI INTERATIVO',
  ChaveTexto.viaCompartilharTooltip: 'Compartilhar escalada',
  ChaveTexto.viaReportarAlertaTooltip: 'Reportar alerta de segurança',
  ChaveTexto.viaEntreParaReportarToast:
      'Entre na sua conta na aba Perfil para reportar alertas de segurança.',
  ChaveTexto.viaAlertaRegistradoToast: 'Alerta de segurança registrado!',
  ChaveTexto.viaEntreParaVotarToast:
      'Entre na sua conta na aba Perfil para votar no grau da via.',
  ChaveTexto.viaVotoAtualizadoToast: 'Voto de grau atualizado!',
  ChaveTexto.viaComentarioAtualizadoToast: 'Comentário atualizado!',
  ChaveTexto.viaComentarioExcluidoToast: 'Comentário excluído.',
  ChaveTexto.viaAncoragemPrefixo: 'Ancoragem: {tipo}',
  ChaveTexto.viaEnfiadasContagem: 'ENFIADAS ({n})',
  ChaveTexto.viaProtecoesAbrev: '{n} prot.',
  ChaveTexto.viaMovelPrefixo: 'Móvel: {equip}',
  ChaveTexto.viaHistoricoConquista: 'HISTÓRICO & CONQUISTA',
  ChaveTexto.viaConquistadores: 'CONQUISTADORES',
  ChaveTexto.viaAbertura: 'ABERTURA',
  ChaveTexto.viaManutencao: 'MANUTENÇÃO',
  ChaveTexto.viaApoieManutencaoPix: 'Apoie a Manutenção (Copiar Pix: {chave})',
  ChaveTexto.viaPixManutencaoCopiadoToast:
      'Chave Pix copiada para a área de transferência!',
  ChaveTexto.viaVideosBetasContagem: 'VÍDEOS & BETAS ({n})',
  ChaveTexto.viaBetasComunidadeContagem: 'BETAS DA COMUNIDADE ({n})',
  ChaveTexto.viaEditarComentarioTooltip: 'Editar comentário',
  ChaveTexto.viaExcluirComentarioTooltip: 'Excluir comentário',
  ChaveTexto.viaEditarComentarioTitulo: 'Editar Comentário',
  ChaveTexto.viaEditarComentarioSubtitulo:
      'Atualize sua nota ou beta público nesta via.',
  ChaveTexto.viaExcluirComentarioTitulo: 'Excluir Comentário?',
  ChaveTexto.viaExcluirComentarioCorpo:
      'Seu comentário público será removido permanentemente desta via.',
  ChaveTexto.viaProjeto: 'Projeto',
  ChaveTexto.viaMediaPrefixo: 'Média {media}',
  ChaveTexto.viaArtificialLivre: 'Artificial {art} ({livre} em livre)',
  ChaveTexto.viaArtificialPuro: 'Artificial {art}',
  ChaveTexto.viaGuiaOficialConquistador: 'Guia Oficial / Conquistador',
  ChaveTexto.viaSpecExtensao: 'EXTENSÃO',
  ChaveTexto.viaSpecParede: 'PAREDE',
  ChaveTexto.viaSpecExposicao: 'EXPOSIÇÃO',
  ChaveTexto.viaSpecEnfiadas: 'ENFIADAS',
  ChaveTexto.viaSpecComprimento: 'COMPRIMENTO',
  ChaveTexto.viaSpecMaiorEnfiada: 'MAIOR ENFIADA',
  ChaveTexto.viaSpecDuracao: 'DURAÇÃO',
  ChaveTexto.viaSpecTipo: 'TIPO',
  ChaveTexto.viaSpecDistancia: 'DISTÂNCIA',
  ChaveTexto.viaSpecAltura: 'ALTURA',
  ChaveTexto.viaSpecProtecoes: 'PROTEÇÕES',
  ChaveTexto.viaSecaoDescricao: 'Descrição',
  ChaveTexto.viaSecaoPecasMoveis: 'Peças Móveis',
  ChaveTexto.viaSecaoRackEquipamento: 'Rack & Equipamento',
  ChaveTexto.viaSecaoDescricaoAcesso: 'Descrição do Acesso',
  ChaveTexto.viaSecaoDescricaoAncoragem: 'Descrição da Ancoragem',
  ChaveTexto.viaEnfiadaNumero: 'Enfiada {n}',
  ChaveTexto.viaBetaEmOrigem: 'Beta em {origem}',
  ChaveTexto.viaAssistirVideoBeta: 'Assistir Vídeo Beta',
  ChaveTexto.viaVideo: 'Vídeo',
  ChaveTexto.alertaPrefixoSemantics: 'Alerta: {rotulo}',
  ChaveTexto.alertaFaunaTitulo: 'Fauna',
  ChaveTexto.alertaFaunaDesc:
      'Abelhas, marimbondos, cobras, aves em ninho ou outros animais na via.',
  ChaveTexto.alertaRochaInstavelTitulo: 'Rocha ou Agarra Instável',
  ChaveTexto.alertaRochaInstavelDesc:
      'Bloco solto, laca perigosa ou agarra prestes a quebrar.',
  ChaveTexto.alertaProtecaoPrecariaTitulo: 'Proteção Precária',
  ChaveTexto.alertaProtecaoPrecariaDesc:
      'Chapeleta solta, corrosão severa ou ancoragem danificada.',
  ChaveTexto.alertaExposicaoTitulo: 'Exposição E4+',
  ChaveTexto.alertaExposicaoDesc:
      'Lance exposto severo (E4+), risco de queda no chão ou proteção distante.',
  ChaveTexto.alertaCriadoPorVoce: 'CRIADO POR VOCÊ',
  ChaveTexto.alertaConfirmadoMaisUm: 'CONFIRMADO (+1)',
  ChaveTexto.alertaReportadoPorEm:
      'Reportado por {autor} em {data} • {n}x confirmado',
  ChaveTexto.alertaEntreParaConfirmar:
      'Entre na sua conta na aba Perfil para confirmar ou atualizar este alerta.',
  ChaveTexto.alertaAindaEstaLa: 'Ainda está lá?',
  ChaveTexto.alertaNaoJaResolveu: 'Não, já resolveu',
  ChaveTexto.alertaReportadoPorVoceCheck: '✓ Reportado por você',
  ChaveTexto.alertaConfirmadoPorVoceCheck: '✓ Confirmado por você',
  ChaveTexto.alertaSimAindaEstaLa: 'Sim, ainda está lá',
  ChaveTexto.alertaEditarBtn: 'Editar alerta',
  ChaveTexto.alertaExcluirBtn: 'Excluir alerta',
  ChaveTexto.alertaResolvidoToast: 'Alerta marcado como resolvido.',
  ChaveTexto.alertaResolvidoNaViaToast:
      'Alerta em {nome} marcado como resolvido.',
  ChaveTexto.alertaAtualizadoToast: 'Alerta atualizado!',
  ChaveTexto.alertaFalhaAtualizarToast:
      'Não foi possível atualizar este alerta.',
  ChaveTexto.alertaExcluidoToast: 'Alerta excluído.',
  ChaveTexto.alertaEditarModalTitulo: 'Editar Alerta na Via',
  ChaveTexto.alertaReportarModalTitulo: 'Reportar Alerta na Via',
  ChaveTexto.alertaEditarModalSub:
      'Atualize a categoria ou o detalhe deste alerta de segurança.',
  ChaveTexto.alertaReportarModalSub:
      'Avise outros escaladores sobre riscos imediatos nesta linha.',
  ChaveTexto.alertaDetalheLabel: 'Detalhe rápido (opcional)',
  ChaveTexto.alertaDetalheHint: 'Ex.: Colmeia próxima à 3ª costura',
  ChaveTexto.alertaEnviarBtn: 'Enviar Alerta',
  ChaveTexto.alertaExcluirModalTitulo: 'Excluir Alerta?',
  ChaveTexto.alertaExcluirModalCorpo:
      'Este alerta de segurança será removido permanentemente da via.',
  ChaveTexto.alertaAtivoUmConfirmacao: 'Ativo • 1 confirmação',
  ChaveTexto.alertaAtivoVariasConfirmacoes: 'Ativo • {n} confirmações',
  ChaveTexto.alertaResolvidoStatus: 'Resolvido',
  ChaveTexto.alertaMarcarResolvido: 'Marcar resolvido',

  // Autenticação, Perfil, Caderneta, Comunidade, Configurações, Feedback e Compartilhamento
  ChaveTexto.authEntrarTitulo: 'Entrar na sua conta',
  ChaveTexto.authEntrarSubtitulo:
      'Entre sem senha usando sua conta social ou um código de 6 dígitos enviado por e-mail para sincronizar sua caderneta.',
  ChaveTexto.authContinuarGoogle: 'Continuar com o Google',
  ChaveTexto.authContinuarApple: 'Continuar com a Apple',
  ChaveTexto.authOuCodigoEmail: 'ou receba um código por e-mail',
  ChaveTexto.authEmailLabel: 'E-mail',
  ChaveTexto.authAguardeSegundos: 'Aguarde {s}s',
  ChaveTexto.authReceberCodigoEmail: 'Receber código por e-mail',
  ChaveTexto.authCodigo6DigitosLabel: 'Código de 6 dígitos',
  ChaveTexto.authConfirmarCodigo: 'Confirmar código',
  ChaveTexto.authReenviarComSegundos: 'Reenviar código ({s}s)',
  ChaveTexto.authReenviarCodigo: 'Reenviar código',
  ChaveTexto.authUsarOutroEmail: 'Usar outro e-mail',
  ChaveTexto.authAbrirConfigApp: 'Abrir configurações do app',
  ChaveTexto.authLimiteTemporario:
      'Limite temporário atingido. Aguarde {s}s para solicitar outro código.',
  ChaveTexto.authCodigoEnviadoPara:
      'Enviamos um código de 6 dígitos para {email}. Verifique sua caixa de entrada e spam.',
  ChaveTexto.authErroEnviarCodigo:
      'Não foi possível enviar o código de acesso. Tente novamente.',
  ChaveTexto.authErroValidarCodigo:
      'Não foi possível validar o código de acesso. Tente novamente.',
  ChaveTexto.authErroGoogle:
      'Não foi possível entrar com o Google. Tente novamente.',
  ChaveTexto.authErroApple:
      'Não foi possível entrar com a Apple. Tente novamente.',
  ChaveTexto.authSemConexao:
      'Sem conexão com a internet. Verifique o sinal e tente novamente.',
  ChaveTexto.authSrvChaveInvalida:
      'Chave de acesso do servidor inválida. Tente novamente.',
  ChaveTexto.authSrvCodigoExpirado:
      'O código de acesso expirou ou é inválido.',
  ChaveTexto.authSrvEmailInvalido: 'Informe um endereço de e-mail válido.',
  ChaveTexto.authSrvProvedorDesabilitado:
      'Provedor de autenticação não está habilitado no servidor.',
  ChaveTexto.authSrvCredencialInvalida:
      'Não foi possível validar a credencial nativa no servidor.',
  ChaveTexto.authSrvLimiteEnvio:
      'Limite de envio de códigos atingido. Aguarde alguns instantes e tente novamente.',
  ChaveTexto.authSrvSessaoExpirada:
      'Sua sessão expirou. Faça login novamente.',
  ChaveTexto.authSrvCancelado: 'Autenticação cancelada pelo escalador.',
  ChaveTexto.authSrvCooldownAposUm:
      'Por motivos de segurança, você só pode solicitar um novo código após 1 segundo.',
  ChaveTexto.authSrvCooldownAposVarios:
      'Por motivos de segurança, você só pode solicitar um novo código após {s} segundos.',
  ChaveTexto.authSrvCooldownCadaUm:
      'Por motivos de segurança, você só pode solicitar um novo código a cada 1 segundo.',
  ChaveTexto.authSrvCooldownCadaVarios:
      'Por motivos de segurança, você só pode solicitar um novo código a cada {s} segundos.',
  ChaveTexto.perfilEscaladorPadrao: 'Escalador',
  ChaveTexto.perfilEscaladorAresta: 'Escalador Aresta',
  ChaveTexto.perfilEditarBtn: 'Editar perfil',
  ChaveTexto.perfilMetricaCadenas: 'CADENAS',
  ChaveTexto.perfilMetricaTentativas: 'TENTATIVAS',
  ChaveTexto.perfilMetricaPicos: 'PICOS',
  ChaveTexto.perfilMetricaVias: 'VIAS',
  ChaveTexto.perfilEntrarConta: 'Entrar na conta',
  ChaveTexto.perfilMinhaCaderneta: 'Minha caderneta',
  ChaveTexto.perfilDadosPrivacidade: 'Dados e privacidade',
  ChaveTexto.perfilSair: 'Sair',
  ChaveTexto.perfilExcluirConta: 'Excluir conta',
  ChaveTexto.perfilIdCopiadoToast: 'ID público copiado!',
  ChaveTexto.perfilSemConexaoExcluir:
      'Sem conexão com a internet. Conecte-se para excluir sua conta.',
  ChaveTexto.perfilErroExcluirConta:
      'Não foi possível excluir a conta neste momento.',
  ChaveTexto.perfilDialogEditarTitulo: 'Editar Perfil',
  ChaveTexto.perfilAlterarFoto: 'Alterar foto de perfil',
  ChaveTexto.perfilNomeAtletaLabel: 'Nome do atleta',
  ChaveTexto.perfilPrivacidadeTitulo: 'Dados e Privacidade',
  ChaveTexto.perfilPrivacidadeCorpo:
      'O Aresta Climb respeita a soberania e a privacidade dos seus dados. Sua caderneta é estritamente privada. Contribuições públicas de graduação e alertas utilizam exclusivamente seu ID de Autor público, sem expor dados pessoais.',
  ChaveTexto.perfilIdPublicoLabel: 'ID DE AUTOR PÚBLICO (NANOID)',
  ChaveTexto.perfilCopiarIdTooltip: 'Copiar ID público',
  ChaveTexto.perfilSairPergunta: 'Deseja realmente sair?',
  ChaveTexto.perfilSairCorpo:
      'Sua caderneta pessoal e histórico permanecem preservados com segurança no dispositivo.',
  ChaveTexto.perfilExcluirPergunta: 'Excluir conta permanentemente?',
  ChaveTexto.perfilExcluirCorpo:
      'Esta ação é irreversível. Sua conta, foto de perfil e todas as cadenas sincronizadas serão apagadas permanentemente da nuvem e deste dispositivo.',
  ChaveTexto.cadTituloPagina: 'MINHA CADERNETA',
  ChaveTexto.cadAscensaoAtualizadaToast: 'Ascensão atualizada na caderneta!',
  ChaveTexto.cadViaIndisponivelOffline:
      'Via não disponível offline no momento.',
  ChaveTexto.cadTotalCadenas: 'Total de Cadenas',
  ChaveTexto.cadTaxaAVistaFlash: 'Taxa À Vista/Flash',
  ChaveTexto.cadMaiorGrauVias: 'Maior Grau (Vias)',
  ChaveTexto.cadMaiorGrauBoulders: 'Maior Grau (Boulders)',
  ChaveTexto.cadPiramideTitulo: 'Pirâmide de Graduação',
  ChaveTexto.cadNenhumaAscensaoModalidade:
      'Nenhuma ascensão registrada nesta modalidade.',
  ChaveTexto.cadHistoricoContagem: 'Histórico de Ascensões ({n})',
  ChaveTexto.cadMeusAlertasContagem: 'Meus Alertas na Rocha ({n})',
  ChaveTexto.cadNenhumaAscensaoAinda: 'Nenhuma ascensão registrada ainda',
  ChaveTexto.cadNenhumaAscensaoSub:
      'Suas cadenas salvas nas páginas das vias aparecerão aqui.',
  ChaveTexto.cadEditarAscensaoTooltip: 'Editar ascensão',
  ChaveTexto.cadExcluirAscensaoTooltip: 'Excluir ascensão',
  ChaveTexto.cadExcluirAscensaoTitulo: 'Excluir Ascensão?',
  ChaveTexto.cadExcluirAscensaoCorpo:
      'Esta ação removerá este registro esportivo permanentemente da sua caderneta.',
  ChaveTexto.cadEstiloEsportivoLabel: 'Estilo Esportivo',
  ChaveTexto.cadTentativasPegasLabel: 'Tentativas / Pegas',
  ChaveTexto.cadDataAscensaoLabel: 'Data da Ascensão',
  ChaveTexto.cadNotasPrivadasLabel: 'Notas Privadas (Crux / Métodos)',
  ChaveTexto.cadNotasPrivadasHint:
      'Ex: Crux no 3º grampo com calcanhar esquerdo, levar costura longa...',
  ChaveTexto.cadCadenaSalvaToast: 'Cadena salva na caderneta!',
  ChaveTexto.cadTentativaSalvaToast: 'Tentativa salva na caderneta!',
  ChaveTexto.cadContribuicaoPublica: 'CONTRIBUIÇÃO PÚBLICA',
  ChaveTexto.cadPercepcaoGrau: 'Percepção do grau técnico da linha:',
  ChaveTexto.cadBetaOpcionalLabel: 'Beta da Comunidade (opcional)',
  ChaveTexto.cadBetaOpcionalHint:
      'Ex.: Costura 3 longa; boa leitura pela esquerda no crux.',
  ChaveTexto.cadConecteParaContribuir:
      'Conecte sua conta na aba Perfil para enviar votos e dicas públicas ao guia comunitário.',
  ChaveTexto.cadEditarModalTitulo: 'Editar Ascensão',
  ChaveTexto.cadRegistrarModalTitulo: 'Registrar Ascensão',
  ChaveTexto.cadSalvarEContribuir: 'Salvar Cadena & Contribuir',
  ChaveTexto.cadSalvarNaCaderneta: 'Salvar na Caderneta',
  ChaveTexto.cadEncadenadaEm: 'Encadenada em {data} ({estilo})',
  ChaveTexto.cadTentativaEm: 'Tentativa em {data}',
  ChaveTexto.cadNovaAscensaoBtn: 'Nova Ascensão / Tentativa',
  ChaveTexto.cadRegistrarCadenaBtn: 'Registrar Cadena / Tentativa',
  ChaveTexto.comunidadeHeader: 'MÍDIAS, APOIOS E INTERATIVIDADES',
  ChaveTexto.comunidadeSobreTimeTitulo: 'SOBRE O TIME',
  ChaveTexto.comunidadeSobreTimeSub:
      'Conheça os desenvolvedores e colaboradores do projeto Aresta.',
  ChaveTexto.comunidadeWhatsappTitulo: 'GRUPO DO WHATSAPP',
  ChaveTexto.comunidadeWhatsappSub:
      'Participe para tirar dúvidas, dar ideias e receber avisos do Aresta.',
  ChaveTexto.comunidadeInstagramTitulo: 'INSTAGRAM OFICIAL',
  ChaveTexto.comunidadeInstagramSub:
      'Acompanhe as últimas novidades, atualizações e bastidores do aplicativo.',
  ChaveTexto.comunidadeLinkedinTitulo: 'LINKEDIN DO PROJETO',
  ChaveTexto.comunidadeLinkedinSub:
      'Acompanhe novidades, nosso crescimento e o lado corporativo do Aresta.',
  ChaveTexto.comunidadeDiscordTitulo: 'DISCORD DOS DESENVOLVEDORES',
  ChaveTexto.comunidadeDiscordSub:
      'Converse com a equipe, acompanhe o código e colabore com o futuro do Aresta.',
  ChaveTexto.comunidadeGithubTitulo: 'GITHUB DO ARESTA',
  ChaveTexto.comunidadeGithubSub:
      'Acesse o perfil com os repositórios do github.',
  ChaveTexto.comunidadeTermosTitulo: 'Termos de Uso e Privacidade',
  ChaveTexto.comunidadeTermosSub:
      'Controle voluntário de riscos e diretrizes de privacidade offline.',
  ChaveTexto.comunidadeRodapeVersao: 'Aresta Climb v{versao} • Beta Aberto',
  ChaveTexto.comunidadeIniciativaLivre:
      'Uma iniciativa independente pelo montanhismo livre do Brasil.',
  ChaveTexto.comunidadeTermosModalHeader: 'TERMOS E PRIVACIDADE',
  ChaveTexto.comunidadePoliticaModalHeader: 'POLÍTICA DE PRIVACIDADE',
  ChaveTexto.timeConhecaSubtitulo: 'CONHEÇA QUEM FAZ O ARESTA',
  ChaveTexto.timeOpenSourceTitulo: 'O ARESTA É OPEN SOURCE',
  ChaveTexto.timeOpenSourceCorpo:
      'Tem interesse em contribuir? Entre no nosso Discord e nos envie uma mensagem!',
  ChaveTexto.timeCargoDesigner: 'Designer',
  ChaveTexto.timeCargoProduto: 'Produto / Marketing',
  ChaveTexto.timeCargoProdutoQuebra: 'Produto/\nMarketing',
  ChaveTexto.timeCargoBackend: 'Backend',
  ChaveTexto.timeCargoFrontend: 'Frontend',
  ChaveTexto.legalTermosTitulo: 'Termos de Uso',
  ChaveTexto.legalPoliticaTitulo: 'Política de Privacidade',
  ChaveTexto.legalErroTermos:
      'Erro ao carregar os termos. Por favor, tente novamente mais tarde.',
  ChaveTexto.legalErroPolitica: 'Erro ao carregar a política.',
  ChaveTexto.legalBannerAtualizacao:
      '🌟 Atualizamos nossos documentos legais. Por favor, revise-os e confirme seu aceite.',
  ChaveTexto.legalDataAtualizacao: 'Data da atualização: {data}',
  ChaveTexto.legalAceitoEm: 'Aceito em {data} às {hora}',
  ChaveTexto.legalConcordoCheckbox:
      'Li e concordo com os Termos de Uso e a Política de Privacidade.',
  ChaveTexto.legalAceitarContinuar: 'Aceitar Termos e Continuar',
  ChaveTexto.configTitulo: 'Configurações',
  ChaveTexto.configIdiomaTitulo: 'IDIOMA',
  ChaveTexto.configIdiomaSubtitulo:
      'Altere instantaneamente o idioma de toda a interface do aplicativo.',
  ChaveTexto.configAparenciaTitulo: 'APARÊNCIA',
