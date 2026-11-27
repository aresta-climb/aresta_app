// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/data/modelos/dados_cartao_compartilhamento.dart';
import 'package:frontend/idioma/tradutor_app.dart';
import 'package:frontend/services/compartilhamento/servico_compartilhamento.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/firebase/telemetria.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../fakes/servico_compartilhamento_fake.dart';
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
        'formato': 'link',
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

    test('formata mensagens de compartilhamento de pico, grupo, setor e escalada em outros idiomas sem prefixos gramaticais do português', () async {
      SharedPreferences.setMockInitialValues({});
      addTearDown(ControladorIdiomaApp.instancia.restaurarPadraoEmMemoria);

      await ControladorIdiomaApp.instancia.definirIdioma(IdiomaApp.ingles);

      await ServicoCompartilhamento.instancia.compartilharPico(
        idCroqui: 'br_mg_cipo',
        uid: 'uidPico1234567',
        nomePico: 'Serra do Cipó',
        localizacao: 'MG',
      );
      expect(
        textosCompartilhados.single,
        'Check out the topo for Serra do Cipó (MG) on Aresta:\nhttps://aresta.cc/s/uidPico1234567',
      );

      textosCompartilhados.clear();
      await ServicoCompartilhamento.instancia.compartilharGrupo(
        idCroqui: 'br_mg_cipo',
        uid: 'uidGrupo123456',
        nomeGrupo: 'Grupo Grande',
        nomePico: 'Serra do Cipó',
      );
      expect(
        textosCompartilhados.single,
        'Check out Grupo Grande at Serra do Cipó on Aresta:\nhttps://aresta.cc/s/uidGrupo123456',
      );

      textosCompartilhados.clear();
      await ServicoCompartilhamento.instancia.compartilharSetor(
        idCroqui: 'br_mg_cipo',
        uid: 'uidSetor123456',
        nomeSetor: 'Fenda',
        nomePico: 'Serra do Cipó',
      );
      expect(
        textosCompartilhados.single,
        'Check out Fenda at Serra do Cipó on Aresta:\nhttps://aresta.cc/s/uidSetor123456',
      );

      textosCompartilhados.clear();
      await ServicoCompartilhamento.instancia.compartilharEscalada(
        idCroqui: 'br_mg_cipo',
        uid: 'uidVia12345678',
        nomeEscalada: 'Diedro',
        grau: '7a',
        nomeSetor: 'Fenda',
        nomePico: 'Serra do Cipó',
      );
      expect(
        textosCompartilhados.single,
        'Check out Diedro (7a) (Fenda) at Serra do Cipó on Aresta:\nhttps://aresta.cc/s/uidVia12345678',
      );
    });

    test('compartilharLinkPorDados roteia Pico, Grupo, Setor e Via mantendo formato link', () async {
      await ServicoCompartilhamento.instancia.compartilharLinkPorDados(
        const DadosCartaoCompartilhamento(
          tipoEntidade: TipoEntidadeCompartilhavel.pico,
          idCroqui: 'crag1',
          uid: 'uidP1',
          titulo: 'Pedra Grande',
          subtituloLocalizacao: 'MG',
          etiquetaCategoria: 'PICO',
          nomePico: 'Pedra Grande',
          localizacaoPico: 'MG',
        ),
      );
      await ServicoCompartilhamento.instancia.compartilharLinkPorDados(
        const DadosCartaoCompartilhamento(
          tipoEntidade: TipoEntidadeCompartilhavel.grupo,
          idCroqui: 'crag1',
          uid: 'uidG1',
          titulo: 'Grupo Sherpa',
          subtituloLocalizacao: 'Pedra Grande',
          etiquetaCategoria: 'GRUPO',
          nomePico: 'Pedra Grande',
          nomeGrupo: 'Grupo Sherpa',
        ),
      );
      await ServicoCompartilhamento.instancia.compartilharLinkPorDados(
        const DadosCartaoCompartilhamento(
          tipoEntidade: TipoEntidadeCompartilhavel.setor,
          idCroqui: 'crag1',
          uid: 'uidS1',
          titulo: 'Setor Principal',
          subtituloLocalizacao: 'Pedra Grande',
          etiquetaCategoria: 'SETOR',
          nomePico: 'Pedra Grande',
          nomeSetor: 'Setor Principal',
        ),
      );
      await ServicoCompartilhamento.instancia.compartilharLinkPorDados(
        const DadosCartaoCompartilhamento(
          tipoEntidade: TipoEntidadeCompartilhavel.via,
          idCroqui: 'crag1',
          uid: 'uidV1',
          titulo: 'Aresta Clássica',
          subtituloLocalizacao: 'Pedra Grande • Setor Principal',
          etiquetaCategoria: 'ESPORTIVA',
          nomePico: 'Pedra Grande',
          nomeSetor: 'Setor Principal',
          grauDestaque: '6ºsup',
        ),
      );

      expect(textosCompartilhados, hasLength(4));
      expect(textosCompartilhados[0], contains('https://aresta.cc/s/uidP1'));
      expect(textosCompartilhados[1], contains('https://aresta.cc/s/uidG1'));
      expect(textosCompartilhados[2], contains('https://aresta.cc/s/uidS1'));
      expect(textosCompartilhados[3], contains('https://aresta.cc/s/uidV1'));
    });

    test('compartilharImagemStories copia link para clipboard, registra telemetria imagem_stories, envia PNG puro via share_plus e limpa pasta temporária', () async {
      const channel = MethodChannel('dev.fluttercommunity.plus/share');
      MethodCall? chamadaCapturada;
      String? textoClipboard;
      late Directory dirTempCriado;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        chamadaCapturada = call;
        return 'dev.fluttercommunity.plus/share/success';
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall call) async {
        if (call.method == 'Clipboard.setData') {
          final args = call.arguments as Map<dynamic, dynamic>;
          textoClipboard = args['text'] as String?;
        }
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      final servico = ServicoCompartilhamento(
        provedorDiretorioTemporario: () async {
          dirTempCriado = await Directory.systemTemp.createTemp(
            'aresta_share_test_',
          );
          return dirTempCriado;
        },
      );

      const dados = DadosCartaoCompartilhamento(
        tipoEntidade: TipoEntidadeCompartilhavel.via,
        idCroqui: 'br_mg_igarape_pedra_grande',
        uid: 'x8siJek3FiG3aB',
        titulo: 'Aresta Clássica',
        subtituloLocalizacao: 'Pedra Grande',
        etiquetaCategoria: 'ESPORTIVA',
        nomePico: 'Pedra Grande',
      );

      final url = await servico.compartilharImagemStories(
        dados: dados,
        bytesPng: ServicoCompartilhamentoFake.pngMinimoValido,
      );

      expect(url, 'https://aresta.cc/s/x8siJek3FiG3aB');
      expect(textoClipboard, 'https://aresta.cc/s/x8siJek3FiG3aB');
      expect(mockTelemetry.recordedParams['compartilhar_entidade'], {
        'id_croqui': 'br_mg_igarape_pedra_grande',
        'tipo_entidade': 'via',
        'uid': 'x8siJek3FiG3aB',
        'abrir_mapa': 'false',
        'origem': 'pagina_detalhe',
        'formato': 'imagem_stories',
      });
      expect(chamadaCapturada, isNotNull);
      expect(chamadaCapturada!.method, 'share');
      final args = Map<String, dynamic>.from(
        chamadaCapturada!.arguments as Map,
      );
      expect(args['text'], isNull);
      expect(args['mimeTypes'], equals(['image/png']));
      expect(
        (args['paths'] as List).single.toString(),
        endsWith('aresta_via_x8siJek3FiG3aB.png'),
      );
      expect(await dirTempCriado.exists(), isFalse);

      // Também exercita o provedor padrão de diretório temporário do sistema
      await ServicoCompartilhamento().compartilharImagemStories(
        dados: dados,
        bytesPng: ServicoCompartilhamentoFake.pngMinimoValido,
      );
      expect(chamadaCapturada!.method, 'share');
    });
  });
}
