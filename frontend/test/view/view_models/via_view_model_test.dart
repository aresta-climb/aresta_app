// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/beta.pb.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/services/configuracao_recursos.dart';
import 'package:frontend/services/controlador_interacoes_usuario.dart';
import 'package:frontend/view/view_models/via_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import '../../services/comunidade/repositorio_interacoes_via_fake.dart';
import '../../services/plataforma_lancador_url_fake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RepositorioInteracoesViaFake repoFake;
  late PlataformaLancadorUrlFake lancadorFake;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ConfiguracaoRecursos.redefinirParaTestes();
    ControladorInteracoesUsuario.redefinirParaTestes();
    repoFake = RepositorioInteracoesViaFake();
    lancadorFake = PlataformaLancadorUrlFake();
    UrlLauncherPlatform.instance = lancadorFake;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    ConfiguracaoRecursos.redefinirParaTestes();
    ControladorInteracoesUsuario.redefinirParaTestes();
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
    expect(vm.possuiUid, isTrue);
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
}
