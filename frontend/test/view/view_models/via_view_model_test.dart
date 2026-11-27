// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/beta.pb.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/services/compartilhamento/servico_compartilhamento.dart';
import 'package:frontend/view/view_models/via_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import '../../mocks/mock_telemetria.dart';
import '../../services/comunidade/repositorio_interacoes_via_fake.dart';
import '../../services/plataforma_lancador_url_fake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RepositorioInteracoesViaFake repoFake;
  late PlataformaLancadorUrlFake lancadorFake;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repoFake = RepositorioInteracoesViaFake();
    lancadorFake = PlataformaLancadorUrlFake();
    UrlLauncherPlatform.instance = lancadorFake;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('extrai grau oficial, atributos técnicos, histórico, betas e Pix para ViaEsportiva', () async {
    String? textoCopiado;
    Uri? uriAberta;

    final escalada = Escalada(
      uid: 'x8siJek3FiG3aB',
      betas: [
        MidiaBeta(
          url: 'https://youtube.com/watch?v=123',
          titulo: 'Beta da Via Deslize',
          fonte: FonteMidia_Enum.YOUTUBE,
        ),
        MidiaBeta(
          url: 'https://instagram.com/p/abc',
          titulo: '',
          fonte: FonteMidia_Enum.INSTAGRAM,
        ),
        MidiaBeta(
          url: 'https://blog.escalada.br/post',
          titulo: 'Relato no Blog',
          fonte: FonteMidia_Enum.BLOG,
        ),
        MidiaBeta(
          url: '   ',
          titulo: 'Ignorado sem URL',
        ),
      ],
      viaEsportiva: ViaEsportiva(
        nome: 'Via Deslize',
        destaque: true,
        dificuldade: GrauVia_GrauVia.BR_7A,
        dificuldadeArtificial: GrauArtificial_GrauArtificial.A1_MAIS,
        exposicao: GrauExposicao_GrauExposicao.E2,
        tipoParede: TipoParede_TipoParede.NEGATIVO,
        extensao: 28,
        quantidadeProtecoesIntermediarias: 11,
        quantidadeProtecoesParada: 2,
        tipoAncoragem: 'Dupla com argola',
        conquistadores: ['João', 'Maria'],
        dataAbertura: '2012',
        dataManutencao: '2024',
        descricao: 'Crux técnico na barriga.',
        urlVideoBeta: 'https://vimeo.com/beta-local',
        chavePixManutencao: 'manutencao@aresta.cc',
      ),
    );

    final vm = ViaViewModel(
      escalada: escalada,
      repositorioInteracoes: repoFake,
      copiadorAreaTransferencia: (texto) async => textoCopiado = texto,
      lancadorUrlExterna: (uri) async {
        uriAberta = uri;
        return true;
      },
    );
    addTearDown(vm.dispose);

    expect(vm.nomeEscalada, 'Via Deslize');
    expect(vm.modalidade, 'Esportiva');
    expect(vm.ehDestaque, isTrue);
    expect(vm.ehHighline, isFalse);
    expect(vm.ehBoulder, isFalse);
    expect(vm.possuiUid, isTrue);
    expect(vm.codigoGrauOficial, GrauVia_GrauVia.BR_7A.value);
    expect(vm.grauOficialExibicao, '7a');
    expect(vm.rotuloGrauOficial, 'GRAU OFICIAL');
    expect(vm.complementoGrauOficial, contains('Artificial A1+'));
    expect(vm.tipoAncoragem, 'Dupla com argola');

    final rotulosSpecs = vm.atributosTecnicos.map((a) => a.rotulo).toList();
    expect(rotulosSpecs, containsAll(['EXTENSÃO', 'PROTEÇÕES', 'PAREDE', 'EXPOSIÇÃO']));
    expect(
      vm.atributosTecnicos.firstWhere((a) => a.rotulo == 'PROTEÇÕES').valor,
      '11+2',
    );

    expect(vm.secoesTexto, hasLength(1));
    expect(vm.secoesTexto.single.titulo, 'Descrição');
    expect(vm.secoesTexto.single.ehMarkdown, isTrue);

    expect(vm.possuiHistorico, isTrue);
    expect(vm.conquistadoresTexto, 'João, Maria');
    expect(vm.dataAbertura, '2012');
    expect(vm.dataManutencao, '2024');

    expect(vm.midiasBeta, hasLength(4));
    expect(vm.midiasBeta[0].origemRotulo, 'YouTube');
    expect(vm.midiasBeta[1].origemRotulo, 'Instagram');
    expect(vm.midiasBeta[1].titulo, 'Beta em Instagram');
    expect(vm.midiasBeta[2].origemRotulo, 'Blog');
    expect(vm.midiasBeta[3].origemRotulo, 'Vídeo');

    expect(await vm.copiarChavePix(), isTrue);
    expect(textoCopiado, 'manutencao@aresta.cc');

    expect(await vm.abrirMidiaBeta('https://youtube.com/watch?v=123'), isTrue);
    expect(uriAberta.toString(), 'https://youtube.com/watch?v=123');
    expect(await vm.abrirMidiaBeta('::url_invalida::'), isFalse);
  });

  test('formata corretamente ViaMovel, Boulder, ViaMultiplasEnfiadas (com enfiadas), Highline e escalada vazia', () async {
    // 1. Via Móvel / Mista com PROJETO e art. em livre + Móvel pura
    String? textoCanalClipboard;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        textoCanalClipboard = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });

    final movel = ViaViewModel(
      escalada: Escalada(
        betas: [
          MidiaBeta(
            url: 'https://tiktok.com/@beta/1',
            titulo: 'Beta curto',
            fonte: FonteMidia_Enum.TIKTOK,
          ),
          MidiaBeta(
            url: 'https://facebook.com/beta/2',
            titulo: 'Vídeo antigo',
            fonte: FonteMidia_Enum.FACEBOOK,
          ),
        ],
        viaMovel: ViaMovel(
          nome: 'Fenda Clássica',
          destaque: true,
          dificuldade: GrauVia_GrauVia.PROJETO,
          dificuldadeArtificial: GrauArtificial_GrauArtificial.A2,
          dificuldadeArtificialEmLivre: GrauVia_GrauVia.BR_8A,
          tipoParede: TipoParede_TipoParede.VERTICAL,
          exposicao: GrauExposicao_GrauExposicao.E3,
          extensao: 35,
          quantidadeProtecoesIntermediarias: 2,
          quantidadeProtecoesParada: 2,
          protecoesMoveis: 'Camalots #0.5 ao #3',
          tipoAncoragem: 'Parabolt duplo',
          conquistadores: ['Equipe Trad'],
          dataAbertura: '1999',
          dataManutencao: '2023',
          chavePixManutencao: 'pix-movel@aresta.cc',
          urlVideoBeta: 'https://youtu.be/movel',
        ),
      ),
      repositorioInteracoes: repoFake,
    );
    addTearDown(movel.dispose);
    expect(movel.modalidade, 'Mista');
    expect(movel.ehDestaque, isTrue);
    expect(movel.grauOficialExibicao, 'Projeto');
    expect(movel.complementoGrauOficial, contains('8a em livre'));
    expect(movel.conquistadoresTexto, 'Equipe Trad');
    expect(movel.dataAbertura, '1999');
    expect(movel.dataManutencao, '2023');
    expect(
      movel.atributosTecnicos.map((a) => a.rotulo),
      containsAll(['EXTENSÃO', 'PROTEÇÕES', 'PAREDE', 'EXPOSIÇÃO']),
    );
    expect(
      movel.midiasBeta.map((m) => m.origemRotulo),
      equals(['TikTok', 'Beta', 'Vídeo']),
    );
    expect(await movel.copiarChavePix(), isTrue);
    expect(textoCanalClipboard, 'pix-movel@aresta.cc');
    expect(await movel.abrirMidiaBeta('https://youtu.be/movel'), isTrue);
    expect(lancadorFake.urlsAbertas, contains('https://youtu.be/movel'));
    expect(
      movel.secoesTexto.any((s) => s.titulo == 'Peças Móveis' && !s.ehMarkdown),
      isTrue,
    );

    final movelPura = ViaViewModel(
      escalada: Escalada(
        viaMovel: ViaMovel(
          nome: 'Fenda Limpa',
          quantidadeProtecoesIntermediarias: 0,
        ),
      ),
      repositorioInteracoes: repoFake,
    );
    addTearDown(movelPura.dispose);
    expect(movelPura.modalidade, 'Móvel');

    // 2. Boulder
    final boulder = ViaViewModel(
      escalada: Escalada(
        boulder: Boulder(
          nome: 'Ovo da Serpente',
          destaque: true,
          dificuldade: GrauBoulder_GrauBoulder.V8,
          tipoParede: TipoParede_TipoParede.POSITIVO,
          conquistadores: ['Pedro'],
          dataAbertura: '2019',
          descricao: 'Saída sentada em reglete.',
          chavePixManutencao: 'pix-boulder',
          urlVideoBeta: 'https://youtu.be/boulder',
        ),
      ),
      repositorioInteracoes: repoFake,
    );
    addTearDown(boulder.dispose);
    expect(boulder.modalidade, 'Boulder');
    expect(boulder.ehDestaque, isTrue);
    expect(boulder.grauOficialExibicao, 'v8');
    expect(boulder.complementoGrauOficial, 'Guia Oficial / Conquistador');
    expect(boulder.atributosTecnicos.single.rotulo, 'PAREDE');
    expect(boulder.secoesTexto.single.titulo, 'Descrição');

    // 3. Via Múltiplas Enfiadas com enfiadas filhas
    final multi = ViaViewModel(
      escalada: Escalada(
        viaMultiplasEnfiadas: ViaMultiplasEnfiadas(
          nome: 'Parede Sul',
          dificuldadeMaxima: GrauVia_GrauVia.BR_7B,
          dificuldadeMedia: GrauVia_GrauVia.BR_6,
          dificuldadeArtificial: GrauArtificial_GrauArtificial.A1,
          dificuldadeArtificialEmLivre: GrauVia_GrauVia.BR_7C,
          exposicao: GrauExposicao_GrauExposicao.E3,
          duracao: GrauDuracao_GrauDuracao.D3,
          numeroEnfiadas: 4,
          comprimentoTotal: 140,
          comprimentoMaiorEnfiada: 45,
          quantidadeCosturasIntermediarias: 12,
          quantidadeEquipamentosParada: 2,
          tipoViaMultiplasEnfiadas:
              ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas.MISTA,
          equipamentoRecomendado: '1 jogo de friends',
          descricao: 'Via alpina clássica.',
          conquistadores: ['Equipe Sul'],
          dataAbertura: '1988',
          dataManutencao: '2020',
          chavePixManutencao: 'pix-multi',
          urlVideoBeta: 'https://youtu.be/multi',
          enfiadas: [
            Escalada(
              viaEsportiva: ViaEsportiva(
                nome: 'Diedro Inicial',
                dificuldade: GrauVia_GrauVia.BR_6,
                extensao: 35,
                quantidadeProtecoesIntermediarias: 8,
                quantidadeProtecoesParada: 2,
                descricao: 'Subir pelo diedro evidente.',
              ),
            ),
            Escalada(
              viaMovel: ViaMovel(
                nome: '',
                extensao: 45,
                protecoesMoveis: 'Friends médios',
              ),
            ),
            Escalada(
              boulder: Boulder(
                nome: 'Saída de Bloco',
                dificuldade: GrauBoulder_GrauBoulder.V2,
              ),
            ),
          ],
        ),
      ),
      repositorioInteracoes: repoFake,
    );
    addTearDown(multi.dispose);
    expect(multi.modalidade, 'Mista');
    expect(multi.ehDestaque, isFalse);
    expect(multi.rotuloGrauOficial, 'GRAU MÁXIMO');
    expect(multi.grauOficialExibicao, '7b');
    expect(multi.complementoGrauOficial, contains('Média 6º'));
    expect(multi.enfiadas, hasLength(3));
    expect(multi.enfiadas[0].titulo, 'Enfiada 1 • Diedro Inicial');
    expect(multi.enfiadas[0].grau, '6º');
    expect(multi.enfiadas[0].extensao, '35m');
    expect(multi.enfiadas[0].protecoes, '8+2');
    expect(multi.enfiadas[1].titulo, 'Enfiada 2');
    expect(multi.enfiadas[1].equipamentoMovel, 'Friends médios');
    expect(multi.enfiadas[2].grau, 'v2');
    expect(multi.enfiadas[2].extensao, isNull);
    expect(multi.enfiadas[2].protecoes, isNull);
    expect(multi.enfiadas[2].descricao, isNull);
    expect(
      multi.atributosTecnicos.map((a) => a.rotulo),
      containsAll([
        'ENFIADAS',
        'COMPRIMENTO',
        'MAIOR ENFIADA',
        'PROTEÇÕES',
        'DURAÇÃO',
        'EXPOSIÇÃO',
        'TIPO',
      ]),
    );
    expect(multi.secoesTexto.map((s) => s.titulo), equals(['Descrição', 'Rack & Equipamento']));
    expect(multi.conquistadoresTexto, 'Equipe Sul');
    expect(multi.dataAbertura, '1988');
    expect(multi.dataManutencao, '2020');
    expect(multi.chavePixManutencao, 'pix-multi');
    expect(multi.midiasBeta.single.url, 'https://youtu.be/multi');

    final multiFixa = ViaViewModel(
      escalada: Escalada(
        viaMultiplasEnfiadas: ViaMultiplasEnfiadas(
          nome: 'Parede Norte Fixa',
          tipoViaMultiplasEnfiadas:
              ViaMultiplasEnfiadas_TipoViaMultiplasEnfiadas.TODA_FIXA,
        ),
      ),
      repositorioInteracoes: repoFake,
    );
    addTearDown(multiFixa.dispose);
    expect(multiFixa.modalidade, 'Multienfiada');

    // 4. Highline
    final highline = ViaViewModel(
      escalada: Escalada(
        highline: Highline(
          nome: 'Travessia dos Ventos',
          destaque: true,
          distancia: 85,
          altura: 120,
          exposicao: 2,
          descricaoAcesso: 'Trilha pelo cume.',
          descricaoAncoragem: '4 parabolts em cada lado.',
          descricao: 'Vento constante à tarde.',
          conquistadores: ['Slack MG'],
          dataAbertura: '2021',
          dataManutencao: '2025',
          chavePixManutencao: 'pix-highline',
          urlVideoBeta: 'https://youtu.be/highline',
        ),
      ),
      repositorioInteracoes: repoFake,
    );
    addTearDown(highline.dispose);
    expect(highline.ehHighline, isTrue);
    expect(highline.exibirCartaoGrau, isFalse);
    expect(highline.atributosTecnicos.map((a) => a.rotulo), containsAll(['DISTÂNCIA', 'ALTURA', 'EXPOSIÇÃO']));
    expect(highline.secoesTexto, hasLength(3));

    // 5. Escalada vazia sem chave Pix nem grau
    final vazia = ViaViewModel(
      escalada: Escalada(),
      repositorioInteracoes: repoFake,
    );
    addTearDown(vazia.dispose);
    expect(vazia.modalidade, '');
    expect(vazia.ehDestaque, isFalse);
    expect(vazia.atributosTecnicos, isEmpty);
    expect(vazia.secoesTexto, isEmpty);
    expect(vazia.enfiadas, isEmpty);
    expect(vazia.midiasBeta, isEmpty);
    expect(vazia.exibirCartaoGrau, isFalse);
    expect(vazia.possuiHistorico, isFalse);
    expect(await vazia.copiarChavePix(), isFalse);
  });

  test('gerencia alertas, consenso e comentários reativamente por UID e absorve falha inicial de sync', () async {
    const uidVia = 'x8siJek3FiG3aB';
    repoFake.semearDados(
      uidVia,
      DadosComunidadeVia(
        consensoGrau: const ConsensoGrauVia(
          grauSugerido: '7b',
          totalVotos: 12,
          distribuicaoDeltas: {0: 3, 1: 9},
        ),
        comentarios: [
          ComentarioComunidadeVia(
            uid: 'c1Kq2L1x9Y7zWq',
            autorIdPublico: 'a1Lk9P1x4Vw8Mn',
            autorNomePublico: 'Mariana',
            criadoEm: DateTime.utc(2026, 11, 19),
            estiloAscensao: TipoAscensao.flash,
            texto: 'Chapeleta 3 com leve giro.',
          ),
        ],
      ),
    );

    // Via sem UID não expõe recursos dependentes de identificador remoto
    final vmSemUid = ViaViewModel(
      escalada: Escalada(
        viaEsportiva: ViaEsportiva(
          nome: 'Via Sem UID',
          dificuldade: GrauVia_GrauVia.BR_7A,
        ),
      ),
      repositorioInteracoes: repoFake,
    );
    expect(vmSemUid.podeReportarAlerta, isFalse);
    expect(vmSemUid.consensoGrau, isNull);
    expect(vmSemUid.apresentacaoConsenso, isNull);
    expect(vmSemUid.alertasAtivos, isEmpty);
    expect(vmSemUid.comentariosComunidade, isEmpty);
    expect(vmSemUid.notasComunidadeApresentacao, isEmpty);
    vmSemUid.dispose();

    // Falha transitória inicial de sincronização é absorvida com log de aviso sem quebrar dados locais
    repoFake.erroSimulado = StateError('Falha inicial de sync');
    final vm = ViaViewModel(
      escalada: Escalada(
        uid: uidVia,
        viaEsportiva: ViaEsportiva(
          nome: 'Via Comunitária',
          dificuldade: GrauVia_GrauVia.BR_7A,
        ),
      ),
      repositorioInteracoes: repoFake,
    );
    await Future<void>.delayed(Duration.zero);
    repoFake.erroSimulado = null;

    expect(vm.podeReportarAlerta, isTrue);
    expect(vm.consensoGrau?.grauSugerido, '7b');
    expect(vm.apresentacaoConsenso?.votosDuros, 9);
    expect(vm.comentariosComunidade, hasLength(1));
    expect(
      vm.notasComunidadeApresentacao.single.cabecalhoAutorData,
      'Mariana • 19/11/2026',
    );

    // Comandos de compartilhamento, telemetria de croqui e resolução de croqui no ViewModel
    String? linkCompartilhado;
    final telemetriaFake = MockTelemetryService();
    final vmComServicos = ViaViewModel(
      escalada: Escalada(
        uid: uidVia,
        viaEsportiva: ViaEsportiva(
          nome: 'Via Comunitária',
          dificuldade: GrauVia_GrauVia.BR_7A,
        ),
        mapas: [
          Mapa(
            caminhoImagemMapa: 'mapas/proprio.webp',
            larguraMapa: 800,
            alturaMapa: 400,
          ),
        ],
      ),
      repositorioInteracoes: repoFake,
      telemetria: telemetriaFake,
      servicoCompartilhamento: ServicoCompartilhamento(
        executorCompartilhamento: (texto) async => linkCompartilhado = texto,
      ),
    );
    vmComServicos.registrarVisualizacaoCroqui(cragId: 'crag1');
    await vmComServicos.compartilharEscalada(cragId: 'crag1');
    expect(linkCompartilhado, contains(uidVia));
    expect(
      vmComServicos.resolverEstadoCroqui().aspectRatioMiniatura,
      2.0,
    );
    vmComServicos.dispose();

    expect(
      await vm.reportarAlerta(
        CategoriaAlertaSeguranca.fauna,
        detalhe: 'Enxame no diedro',
      ),
      isTrue,
    );
    expect(vm.alertasAtivos, hasLength(1));
    final alertaId = vm.alertasAtivos.single.uid;

    expect(
      await vm.confirmarAlerta(alertaId, aindaEstaLa: false),
      isTrue,
    );
    expect(vm.alertasAtivos, isEmpty);

    // Simulação de falha determinística retorna false sem quebrar estado
    repoFake.erroSimulado = StateError('Erro simulado');
    expect(
      await vm.reportarAlerta(CategoriaAlertaSeguranca.exposicaoE4Mais),
      isFalse,
    );
    expect(
      await vm.confirmarAlerta(alertaId, aindaEstaLa: true),
      isFalse,
    );

    vm.dispose();
    // Notificação após dispose não lança FlutterError
    repoFake.semearDados(uidVia, const DadosComunidadeVia.vazio());
  });

  test('suporta voto direto nas pílulas de grau e janela de desfazer na resolução de alerta', () async {
    const uidVia = 'viaInterativa01';

    final vm = ViaViewModel(
      escalada: Escalada(
        uid: uidVia,
        viaEsportiva: ViaEsportiva(
          nome: 'Aresta Solar',
          dificuldade: GrauVia_GrauVia.BR_7A,
        ),
      ),
      repositorioInteracoes: repoFake,
      duracaoJanelaDesfazer: const Duration(milliseconds: 60),
    );

    // 1. Sem autenticação, votar retorna requerAutenticacao
    repoFake.autenticadoSimulado = false;
    expect(
      await vm.votarGrauComunidade(1),
      ResultadoVotoGrauVia.requerAutenticacao,
    );

    // 2. Autenticado, registra voto +1 (7b) e destaca pílula selecionada
    repoFake.autenticadoSimulado = true;
    expect(await vm.votarGrauComunidade(1), ResultadoVotoGrauVia.registrado);
    expect(vm.apresentacaoConsenso?.deltaVotoUsuario, 1);
    expect(
      vm.apresentacaoConsenso?.pilulasVoto.firstWhere((p) => p.delta == 1).selecionada,
      isTrue,
    );

    // 3. Falha determinística ao votar retorna ResultadoVotoGrauVia.falha
    repoFake.erroSimulado = StateError('Erro de voto');
    expect(await vm.votarGrauComunidade(0), ResultadoVotoGrauVia.falha);
    repoFake.erroSimulado = null;

    // 4. Resolver alerta com janela de Desfazer: ocultar imediatamente e restaurar ao desfazer
    await vm.reportarAlerta(CategoriaAlertaSeguranca.fauna);
    final alertaId = vm.alertasAtivos.single.uid;

    vm.iniciarResolucaoAlertaComDesfazer(alertaId);
    expect(vm.alertasAtivos, isEmpty);
    expect(repoFake.obterDadosEscalada(uidVia).alertasAtivos, hasLength(1));

    vm.desfazerResolucaoAlerta(alertaId);
    expect(vm.alertasAtivos, hasLength(1));
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(repoFake.obterDadosEscalada(uidVia).alertasAtivos, hasLength(1));

    // 5. Sem desfazer, expiração do timer efetiva a resolução no repositório
    vm.iniciarResolucaoAlertaComDesfazer(alertaId);
    expect(vm.alertasAtivos, isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(repoFake.obterDadosEscalada(uidVia).alertasAtivos, isEmpty);

    // 6. Edição e exclusão de comentários e alertas próprios + guardas de UID/autenticação/erro
    await repoFake.registrarAvaliacaoAscensao(
      escaladaUid: uidVia,
      deltaGrau: 0,
      comentarioPublico: 'Beta original',
    );
    expect(vm.notasComunidadeApresentacao.single.pertenceAoUsuarioAtual, isTrue);
    final comUid = vm.notasComunidadeApresentacao.single.uid;

    repoFake.autenticadoSimulado = false;
    expect(vm.notasComunidadeApresentacao.single.pertenceAoUsuarioAtual, isFalse);
    expect(await vm.editarComentario(comUid, 'Bloqueado'), isFalse);
    expect(await vm.excluirComentario(comUid), isFalse);
    expect(
      await vm.editarAlerta('qualquer', CategoriaAlertaSeguranca.fauna),
      isFalse,
    );
    expect(await vm.excluirAlerta('qualquer'), isFalse);
    repoFake.autenticadoSimulado = true;

    expect(await vm.editarComentario(comUid, 'Beta atualizado'), isTrue);
    expect(vm.notasComunidadeApresentacao.single.texto, 'Beta atualizado');

    repoFake.erroSimulado = StateError('Erro em comentário');
    expect(await vm.editarComentario(comUid, 'Falha'), isFalse);
    expect(await vm.excluirComentario(comUid), isFalse);
    repoFake.erroSimulado = null;
    expect(await vm.excluirComentario(comUid), isTrue);
    expect(vm.notasComunidadeApresentacao, isEmpty);

    await vm.reportarAlerta(CategoriaAlertaSeguranca.fauna, detalhe: 'Abelha');
    final meuAlertaUid = vm.alertasAtivos.single.uid;
    expect(
      await vm.editarAlerta(
        meuAlertaUid,
        CategoriaAlertaSeguranca.protecaoPrecaria,
        detalhe: 'Grampo 1 solto',
      ),
      isTrue,
    );
    expect(
      vm.alertasAtivos.single.categoria,
      CategoriaAlertaSeguranca.protecaoPrecaria,
    );

    repoFake.erroSimulado = StateError('Erro em alerta');
    expect(
      await vm.editarAlerta(meuAlertaUid, CategoriaAlertaSeguranca.fauna),
      isFalse,
    );
    expect(await vm.excluirAlerta(meuAlertaUid), isFalse);
    repoFake.erroSimulado = null;

    vm.iniciarResolucaoAlertaComDesfazer(meuAlertaUid);
    expect(await vm.excluirAlerta(meuAlertaUid), isTrue);
    expect(repoFake.obterDadosEscalada(uidVia).alertasAtivos, isEmpty);

    // 7. Se dispose ocorrer durante janela pendente, efetiva a resolução imediatamente
    await vm.reportarAlerta(CategoriaAlertaSeguranca.exposicaoE4Mais);
    final segundoAlertaId = vm.alertasAtivos.single.uid;
    vm.iniciarResolucaoAlertaComDesfazer(segundoAlertaId);
    vm.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(repoFake.obterDadosEscalada(uidVia).alertasAtivos, isEmpty);
  });
}
