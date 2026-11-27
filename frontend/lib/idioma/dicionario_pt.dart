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
