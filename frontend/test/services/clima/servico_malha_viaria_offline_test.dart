// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/modelos_rede_viaria_aresta.dart';
import 'package:frontend/services/clima/servico_malha_viaria_offline.dart';
import 'package:frontend/services/http/cliente_http_aresta.dart';
import 'package:http/http.dart' as http;

SnapshotMalhaViariaOffline _criarSnapshotViario(String versao, String codigo) {
  return SnapshotMalhaViariaOffline(
    geradoEm: DateTime.utc(2026, 11, 27, 12, 0),
    versaoHash: versao,
    rodovias: [
      RodoviaRegionalMapa.comLimites(
        ehPrincipal: true,
        nivelViario: 1,
        codigo: codigo,
        verticesLonLat: const [
          Offset(-43.9386, -19.9191),
          Offset(-43.6135, -19.3156),
        ],
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  tearDown(ServicoMalhaViariaOffline.redefinirParaTestes);

  group('ArmazenamentoMalhaViariaLocal', () {
    test('rotaciona slots atual e seguranca atomicamente e recupera corrupção a partir da cópia de segurança', () async {
      final tempRaiz = await Directory.systemTemp.createTemp('malha_viaria_test_');
      addTearDown(() => tempRaiz.delete(recursive: true));
      final subPasta = '${tempRaiz.path}/sub_nao_criada';

      final arm = ArmazenamentoMalhaViariaLocal(
        provedorDiretorioBase: () async => subPasta,
      );

      expect(await arm.lerSnapshot(), isNull);
      expect(await arm.lerCopiaSeguranca(), isNull);

      final v1 = _criarSnapshotViario('osm-v1', 'BR-040');
      await arm.salvarSnapshot(v1);
      expect((await arm.lerSnapshot())?.versaoHash, equals('osm-v1'));
      expect((await arm.lerCopiaSeguranca())?.versaoHash, equals('osm-v1'));

      final v2 = _criarSnapshotViario('osm-v2', 'MG-010');
      await arm.salvarSnapshot(v2);
      expect((await arm.lerSnapshot())?.versaoHash, equals('osm-v2'));
      expect((await arm.lerCopiaSeguranca())?.versaoHash, equals('osm-v1'));

      // Corrompe o arquivo atual com JSON inválido -> restaura automaticamente da cópia de segurança
      final arqAtual = File(
        '$subPasta/${ArmazenamentoMalhaViariaLocal.nomeArquivoAtual}',
      );
      await arqAtual.writeAsString('{json_truncado');
      final recuperado = await arm.lerSnapshot();
      expect(recuperado?.versaoHash, equals('osm-v1'));
      expect((await arm.lerSnapshot())?.versaoHash, equals('osm-v1'));

      // Corrompe ambos (lista JSON no atual e lixo na segurança) -> retorna null limpo
      final arqSeg = File(
        '$subPasta/${ArmazenamentoMalhaViariaLocal.nomeArquivoSeguranca}',
      );
      await arqAtual.writeAsString('[1, 2, 3]');
      await arqSeg.writeAsString('invalido');
      expect(await arm.lerSnapshot(), isNull);

      // Sem plugin path_provider registrado (ex.: widget tests headless) retorna null sem falhar
      final armSemPlugin = ArmazenamentoMalhaViariaLocal();
      await armSemPlugin.salvarSnapshot(v1);
      expect(await armSemPlugin.lerSnapshot(), isNull);
      expect(await armSemPlugin.lerCopiaSeguranca(), isNull);

      // Exercita construtor padrão com path_provider via canal simulado
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => tempRaiz.path,
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
      });
      final armPadrao = ArmazenamentoMalhaViariaLocal();
      expect(await armPadrao.lerSnapshot(), isNull);
    });
  });

  group('ClienteMalhaViariaSupabase e ServicoMalhaViariaOffline', () {
    test('opera 100% offline em áreas remotas e sincroniza incrementalmente via Supabase (atual -> copia_seguranca) quando conectado', () async {
      final tempDir = await Directory.systemTemp.createTemp('srv_viario_test_');
      addTearDown(() => tempDir.delete(recursive: true));

      var statusHttp = 200;
      var slotAtualVazio = false;
      var slotSegurancaVazio = false;
      var versaoServidor = 'osm-v1-semente';
      var consultasVersao = 0;
      var downloadsCompletos = 0;
      String? authRecebido;

      final servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => servidor.close(force: true));

      servidor.listen((req) async {
        authRecebido = req.headers.value('authorization');
        req.response.statusCode = statusHttp;
        if (statusHttp != 200) {
          await req.response.close();
          return;
        }
        final select = req.uri.queryParameters['select'] ?? '';
        final slot = req.uri.queryParameters['slot'] ?? '';
        final ehAtual = slot == 'eq.atual';
        if ((ehAtual && slotAtualVazio) || (!ehAtual && slotSegurancaVazio)) {
          req.response.write('[]');
          await req.response.close();
          return;
        }
        if (!select.contains('rodovias')) {
          consultasVersao++;
          req.response.write(
            jsonEncode([
              {'slot': ehAtual ? 'atual' : 'copia_seguranca', 'versao_hash': versaoServidor},
            ]),
          );
        } else {
          downloadsCompletos++;
          final snap = _criarSnapshotViario(versaoServidor, 'BR-381');
          req.response.write(jsonEncode([snap.paraMapa()]));
        }
        await req.response.close();
      });

      final cliente = ClienteMalhaViariaSupabase(
        urlBaseSupabase: 'http://127.0.0.1:${servidor.port}/',
        chaveAnonima: 'eyJhbGciOiJIUzI1NiJ9.teste',
        clienteHttp: ClienteHttpAresta.paraTestes(http.Client()),
      );
      final arm = ArmazenamentoMalhaViariaLocal(
        provedorDiretorioBase: () async => tempDir.path,
      );

      var agora = DateTime.utc(2026, 11, 27, 10, 0);
      final servico = ServicoMalhaViariaOffline(
        armazenamento: arm,
        fonteRemota: cliente,
        relogioUtc: () => agora,
      );
      addTearDown(servico.dispose);

      await servico.inicializar();
      await servico.inicializar();
      expect(servico.inicializado, isTrue);
      expect(servico.snapshotAtivo, isNull);
      expect(servico.versaoAtiva, isNull);

      // 1. Mesma versão da semente embarcada -> consulta apenas metadados (~100B) e NÃO baixa o JSON completo!
      final sincronizouMesmaVersao = await servico.sincronizarSeDisponivel(
        versaoSementeEmbarcada: 'osm-v1-semente',
      );
      expect(sincronizouMesmaVersao, isFalse);
      expect(authRecebido, equals('Bearer eyJhbGciOiJIUzI1NiJ9.teste'));
      expect(consultasVersao, equals(1));
      expect(downloadsCompletos, equals(0));

      // 2. Dentro do TTL de 6h sem forçar -> não faz nova requisição de rede
      agora = agora.add(const Duration(hours: 2));
      expect(await servico.sincronizarSeDisponivel(), isFalse);
      expect(consultasVersao, equals(1));

      // 3. Passado o TTL (ou forçado), catálogo ganhou novo pico no Supabase e slot atual está em manutenção -> usa copia_seguranca!
      agora = agora.add(const Duration(hours: 5));
      versaoServidor = 'osm-v2-novo-pico';
      slotAtualVazio = true;
      final concorrentes = await Future.wait([
        servico.sincronizarSeDisponivel(versaoSementeEmbarcada: 'osm-v1-semente'),
        servico.sincronizarSeDisponivel(versaoSementeEmbarcada: 'osm-v1-semente'),
      ]);
      expect(concorrentes, equals([true, true]));
      expect(downloadsCompletos, equals(1));
      expect(servico.versaoAtiva, equals('osm-v2-novo-pico'));
      expect(servico.snapshotAtivo?.rodovias.single.codigo, equals('BR-381'));

      // 4. Novo ciclo em área remota sem sinal (HTTP 503 / ambos slots vazios / versão vazia) -> preserva cópia offline local!
      slotAtualVazio = false;
      versaoServidor = '';
      expect(await servico.sincronizarSeDisponivel(forcar: true), isFalse);

      versaoServidor = 'osm-v3';
      slotAtualVazio = true;
      slotSegurancaVazio = true;
      expect(await servico.sincronizarSeDisponivel(forcar: true), isFalse);

      statusHttp = 503;
      expect(await servico.sincronizarSeDisponivel(forcar: true), isFalse);
      expect(servico.versaoAtiva, equals('osm-v2-novo-pico'));

      // 5. Reabertura totalmente offline em área remota hidrata direto do disco sem rede
      await servidor.close(force: true);
      final servicoOffline = ServicoMalhaViariaOffline(
        armazenamento: arm,
        fonteRemota: cliente,
        relogioUtc: () => agora,
      );
      addTearDown(servicoOffline.dispose);
      var notificouDisco = 0;
      servicoOffline.addListener(() => notificouDisco++);
      await servicoOffline.inicializar();
      expect(notificouDisco, equals(1));
      expect(servicoOffline.versaoAtiva, equals('osm-v2-novo-pico'));
      expect(await servicoOffline.sincronizarSeDisponivel(forcar: true), isFalse);

      expect(ServicoMalhaViariaOffline.instancia, isNotNull);
    });
  });
}
