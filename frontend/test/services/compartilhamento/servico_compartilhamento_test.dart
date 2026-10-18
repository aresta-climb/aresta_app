// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/services/compartilhamento/servico_compartilhamento.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import '../../mocks/mock_telemetria.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ServicoCompartilhamento', () {
    late MockTelemetryService mockTelemetry;
    late List<String> textosCompartilhados;

    setUp(() {
      mockTelemetry = MockTelemetryService();
      TelemetryService.instance = mockTelemetry;
      textosCompartilhados = [];
      ServicoCompartilhamento.instancia = ServicoCompartilhamento(
        executorCompartilhamento: (texto) async {
          textosCompartilhados.add(texto);
        },
      );
    });

    tearDown(() {
      ServicoCompartilhamento.restaurarPadrao();
    });

    test('compartilharPico formata mensagem com e sem localização, gera link /s/<uid> e registra telemetria', () async {
      await ServicoCompartilhamento.instancia.compartilharPico(
        idCroqui: 'br_mg_igarape_pedra_grande',
        uid: 'cUidPedra12345',
        nomePico: 'Pedra Grande',
        localizacao: 'Igarapé, MG',
      );

      expect(textosCompartilhados, hasLength(1));
      expect(
        textosCompartilhados.single,
        'Confira o croqui de Pedra Grande (Igarapé, MG) no Aresta:\nhttps://aresta.cc/s/cUidPedra12345',
      );
      expect(mockTelemetry.recordedEvents, contains('compartilhar_entidade'));
      expect(mockTelemetry.recordedParams['compartilhar_entidade'], {
        'id_croqui': 'br_mg_igarape_pedra_grande',
        'tipo_entidade': 'pico',
        'uid': 'cUidPedra12345',
        'abrir_mapa': 'false',
        'origem': 'pagina_detalhe',
      });

      textosCompartilhados.clear();
      await ServicoCompartilhamento.instancia.compartilharPico(
        idCroqui: 'br_mg_igarape_pedra_grande',
        uid: 'cUidPedra12345',
        nomePico: 'Pedra Grande',
        abrirMapa: true,
      );
      expect(
        textosCompartilhados.single,
        'Confira o croqui de Pedra Grande no Aresta:\nhttps://aresta.cc/sm/cUidPedra12345',
      );
    });

    test('compartilharGrupo formata mensagem natural sem duplicar a palavra Grupo, gera link /s/<uid> e registra telemetria', () async {
      await ServicoCompartilhamento.instancia.compartilharGrupo(
        idCroqui: 'br_mg_igarape_pedra_grande',
        uid: 'cqT5nqQ4pvPub7',
        nomeGrupo: 'Grupo Sherpa',
        nomePico: 'Pedra Grande',
      );

      expect(
        textosCompartilhados.single,
        'Confira o Grupo Sherpa, em Pedra Grande, no Aresta:\nhttps://aresta.cc/s/cqT5nqQ4pvPub7',
      );
      expect(
        mockTelemetry.recordedParams['compartilhar_entidade']!['tipo_entidade'],
        'grupo',
      );

      textosCompartilhados.clear();
      await ServicoCompartilhamento.instancia.compartilharGrupo(
        idCroqui: 'br_mg_sjdr_lenheiro',
        uid: 'uidTresPontoes',
        nomeGrupo: 'Três Pontões',
        nomePico: 'Serra do Lenheiro',
      );
      expect(
        textosCompartilhados.single,
        'Confira o grupo Três Pontões, em Serra do Lenheiro, no Aresta:\nhttps://aresta.cc/s/uidTresPontoes',
      );
    });

    test('compartilharSetor formata mensagem natural para Setor, Bloco, Falésia e nome simples, gera link /s/<uid> e registra telemetria', () async {
      await ServicoCompartilhamento.instancia.compartilharSetor(
        idCroqui: 'br_mg_igarape_pedra_grande',
        uid: 'hv7YWgTBQGyWOX',
        nomeSetor: 'Setor Estacionamento',
        nomePico: 'Pedra Grande',
      );

      expect(
        textosCompartilhados.single,
        'Confira o Setor Estacionamento, em Pedra Grande, no Aresta:\nhttps://aresta.cc/s/hv7YWgTBQGyWOX',
      );
      expect(
        mockTelemetry.recordedParams['compartilhar_entidade']!['tipo_entidade'],
        'setor',
      );

      textosCompartilhados.clear();
      await ServicoCompartilhamento.instancia.compartilharSetor(
        idCroqui: 'br_mg_igarape_pedra_grande',
        uid: 'sQ7YgEG6ONsPXt',
        nomeSetor: 'Bloco Democracia',
        nomePico: 'Pedra Grande',
      );
      expect(
        textosCompartilhados.single,
        'Confira o Bloco Democracia, em Pedra Grande, no Aresta:\nhttps://aresta.cc/s/sQ7YgEG6ONsPXt',
      );

      textosCompartilhados.clear();
      await ServicoCompartilhamento.instancia.compartilharSetor(
        idCroqui: 'br_mg_sjdr_lenheiro',
        uid: 'uidFalesia1234',
        nomeSetor: 'Falésia do Lenheiro',
        nomePico: 'Serra do Lenheiro',
      );
      expect(
        textosCompartilhados.single,
        'Confira a Falésia do Lenheiro, em Serra do Lenheiro, no Aresta:\nhttps://aresta.cc/s/uidFalesia1234',
      );

      textosCompartilhados.clear();
      await ServicoCompartilhamento.instancia.compartilharSetor(
        idCroqui: 'br_mg_cipo',
        uid: 'uidCachoeira12',
        nomeSetor: 'Cachoeira',
        nomePico: 'Serra do Cipó',
      );
      expect(
        textosCompartilhados.single,
        'Confira o setor Cachoeira, em Serra do Cipó, no Aresta:\nhttps://aresta.cc/s/uidCachoeira12',
      );
    });

    test('compartilharEscalada formata mensagem natural com e sem grau/setor, gera link /s/<uid> e registra telemetria', () async {
      await ServicoCompartilhamento.instancia.compartilharEscalada(
        idCroqui: 'br_mg_igarape_pedra_grande',
        uid: 'x8siJek3FiG3aB',
        nomeEscalada: 'Aresta Clássica',
        grau: '6ºsup',
        nomeSetor: 'Setor Principal',
        nomePico: 'Pedra Grande',
      );

      expect(
        textosCompartilhados.single,
        'Confira Aresta Clássica (6ºsup) no Setor Principal, em Pedra Grande, no Aresta:\nhttps://aresta.cc/s/x8siJek3FiG3aB',
      );
      expect(
        mockTelemetry.recordedParams['compartilhar_entidade']!['tipo_entidade'],
        'via',
      );

      textosCompartilhados.clear();
      await ServicoCompartilhamento.instancia.compartilharEscalada(
        idCroqui: 'br_mg_igarape_pedra_grande',
        uid: 'x8siJek3FiG3aB',
        nomeEscalada: 'Via Sem Grau',
        nomeSetor: 'Fenda',
        nomePico: 'Pedra Grande',
      );
      expect(
        textosCompartilhados.single,
        'Confira Via Sem Grau no setor Fenda, em Pedra Grande, no Aresta:\nhttps://aresta.cc/s/x8siJek3FiG3aB',
      );

      textosCompartilhados.clear();
      await ServicoCompartilhamento.instancia.compartilharEscalada(
        idCroqui: 'br_mg_sjdr_lenheiro',
        uid: 'uidViaFalesia1',
        nomeEscalada: 'Diedro',
        grau: '7a',
        nomeSetor: 'Falésia Principal',
        nomePico: 'Serra do Lenheiro',
      );
      expect(
        textosCompartilhados.single,
        'Confira Diedro (7a) na Falésia Principal, em Serra do Lenheiro, no Aresta:\nhttps://aresta.cc/s/uidViaFalesia1',
      );

      textosCompartilhados.clear();
      await ServicoCompartilhamento.instancia.compartilharEscalada(
        idCroqui: 'br_mg_igarape_pedra_grande',
        uid: 'x8siJek3FiG3aB',
        nomeEscalada: 'Via Geral',
        nomeSetor: 'Geral',
        nomePico: 'Pedra Grande',
      );
      expect(
        textosCompartilhados.single,
        'Confira Via Geral, em Pedra Grande, no Aresta:\nhttps://aresta.cc/s/x8siJek3FiG3aB',
      );
    });

    test('resolverNomeCroqui busca o nome real do croqui em DatasetRepository quando nomePico é vazio ou igual ao idCroqui', () {
      final repo = DatasetRepository(editorDeCroqui: EditorDeCroqui());

      // 1. A partir de indiceData
      repo.indiceData.value = Indice(
        croquis: [
          ResumoCroqui(
            id: 'br_mg_igarape_pedra_grande',
            nome: 'Pedra Grande',
          ),
        ],
      );
      expect(
        ServicoCompartilhamento.resolverNomeCroqui(
          'br_mg_igarape_pedra_grande',
          nomePreferencial: 'br_mg_igarape_pedra_grande',
        ),
        'Pedra Grande',
      );

      // 2. A partir de gerenciadorSessaoOnline
      repo.gerenciadorSessaoOnline.registrarCroquiOnline(
        'br_mg_ouro_preto_ouroboulder',
        Croqui(nome: 'Ouroboulder'),
      );
      expect(
        ServicoCompartilhamento.resolverNomeCroqui(
          'br_mg_ouro_preto_ouroboulder',
        ),
        'Ouroboulder',
      );

      // 3. A partir de activeDataset (picosDisponiveis, picosBaixados e croquisBaixados)
      repo.activeDataset.value = ConjuntoDadosCroqui(
        metadadosDisponiveis: const [],
        croquisBaixados: [
          Croqui(id: 'br_mg_cipo', picos: [Pico(nome: 'Serra do Cipó')]),
          Croqui(id: 'br_mg_itabirito', nome: 'Itabirito'),
        ],
        picosDisponiveis: [
          ResumoPico(
            id: 'br_mg_araxa_bocaina',
            nome: 'Horizonte Perdido (Bocaina)',
            local: 'MG',
            descricao: '',
            url: '',
            checksum: '',
            thumbnailUrl: '',
            isDownloaded: false,
          ),
        ],
        picosBaixados: [
          ResumoPico(
            id: 'br_mg_milho_verde',
            nome: 'Milho Verde',
            local: 'MG',
            descricao: '',
            url: '',
            checksum: '',
            thumbnailUrl: '',
            isDownloaded: true,
          ),
        ],
      );
      expect(
        ServicoCompartilhamento.resolverNomeCroqui('br_mg_cipo'),
        'Serra do Cipó',
      );
      expect(
        ServicoCompartilhamento.resolverNomeCroqui('br_mg_itabirito'),
        'Itabirito',
      );
      expect(
        ServicoCompartilhamento.resolverNomeCroqui('br_mg_araxa_bocaina'),
        'Horizonte Perdido (Bocaina)',
      );
      expect(
        ServicoCompartilhamento.resolverNomeCroqui('br_mg_milho_verde'),
        'Milho Verde',
      );

      // 4. A partir de gerenciadorSessaoOnline com picos.first.nome quando croqui.nome é vazio
      repo.gerenciadorSessaoOnline.registrarCroquiOnline(
        'br_mg_lapinha',
        Croqui(picos: [Pico(nome: 'Lapinha da Serra')]),
      );
      expect(
        ServicoCompartilhamento.resolverNomeCroqui('br_mg_lapinha'),
        'Lapinha da Serra',
      );

      // 5. Fallback para idCroqui se não existir em nenhuma fonte
      expect(
        ServicoCompartilhamento.resolverNomeCroqui('croqui_desconhecido'),
        'croqui_desconhecido',
      );
    });

    test('executor padrão invoca o plugin share_plus via MethodChannel', () async {
      ServicoCompartilhamento.restaurarPadrao();
      const channel = MethodChannel('dev.fluttercommunity.plus/share');
      MethodCall? chamadaCapturada;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        chamadaCapturada = call;
        return 'dev.fluttercommunity.plus/share/unavailable';
      });

      await ServicoCompartilhamento.instancia.compartilharGrupo(
        idCroqui: 'br_mg_igarape',
        uid: 'cqT5nqQ4pvPub7',
        nomeGrupo: 'Grupo Sherpa',
        nomePico: 'Pedra Grande',
      );

      expect(chamadaCapturada, isNotNull);
      expect(chamadaCapturada!.method, 'share');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
  });
}
