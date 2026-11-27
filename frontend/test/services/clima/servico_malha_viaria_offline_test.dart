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

