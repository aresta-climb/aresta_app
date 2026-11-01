// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/openapi/generated/dart/catalogo.dart';
import 'package:frontend/data/modelos/cadena.dart';
import 'package:frontend/data/modelos/tipo_ascensao.dart';
import 'package:frontend/data/modelos/tipo_escalada.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/services/caderneta/resolvedor_metadados_caderneta.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _PathProviderTemporarioFake extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String caminho;
  _PathProviderTemporarioFake(this.caminho);

  @override
  Future<String?> getApplicationDocumentsPath() async => caminho;

  @override
  Future<String?> getTemporaryPath() async => '$caminho/temp';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory dirTemp;
  late RepositorioCadernetaLocal repoCaderneta;
  late RepositorioCatalogo repoCatalogo;

  setUp(() async {
    dirTemp = await Directory.systemTemp.createTemp(
      'resolvedor_metadados_caderneta_test_',
    );
    PathProviderPlatform.instance = _PathProviderTemporarioFake(dirTemp.path);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repoCaderneta = RepositorioCadernetaLocal(preferencias: prefs);
    await repoCaderneta.inicializar();

    repoCatalogo = RepositorioCatalogo(
      provedorCaminhoBanco: () async => '${dirTemp.path}/catalogo.db',
      fabricaBanco: databaseFactoryFfi,
    );
  });

  tearDown(() async {
    await repoCatalogo.fechar();
    if (dirTemp.existsSync()) {
      try {
        dirTemp.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  group('ResolvedorMetadadosCaderneta', () {
    test('retorna zero picos distintos e metadados nulos quando a caderneta está vazia', () async {
      final resolvedor = ResolvedorMetadadosCaderneta(
        repositorioCaderneta: repoCaderneta,
        repositorioCatalogo: repoCatalogo,
      );
      await resolvedor.atualizar();

      expect(resolvedor.obterTotalPicosDistintos(), equals(0));
      expect(resolvedor.obterNomeDaVia('uidInexistente'), isNull);
      expect(resolvedor.obterGrauDaVia('uidInexistente'), isNull);

      resolvedor.dispose();
    });

    test('hidrata nomes, graus normalizados e picos distintos a partir do catalogo.db SQLite real', () async {
      await repoCatalogo.aplicarDelta(
        const RespostaSyncCatalogo(
          acao: 'apply_delta',
          versaoDestino: 'v1',
          upserts: UpsertsSyncCatalogo(
            croquis: [
              CatalogoCroqui(
                croquiUid: 'croquiPedraR14',
                idSlug: 'br_mg_sabara_pedra_rachada',
                nome: 'Pedra Rachada',
              ),
              CatalogoCroqui(
                croquiUid: 'croquiSerraC14',
                idSlug: 'br_mg_serra_do_cipo',
                nome: 'Serra do Cipó',
              ),
            ],
            entidades: [
              CatalogoEntidade(
                uid: 'viaPedra1NanoX',
                tipo: 'escalada',
                croquiUid: 'croquiPedraR14',
                nome: 'Via Deslize',
                escaladaGrau: '6sup',
                escaladaTipo: 'esportiva',
              ),
              CatalogoEntidade(
                uid: 'blocoPedra2Nan',
                tipo: 'escalada',
                croquiUid: 'croquiPedraR14',
                nome: 'Bloco da Gruta',
                escaladaGrau: 'v4',
                escaladaTipo: 'boulder',
              ),
              CatalogoEntidade(
                uid: 'viaCipo1NanoXY',
                tipo: 'escalada',
                croquiUid: 'croquiSerraC14',
                nome: 'Fenda do Cipó',
                escaladaGrau: '7b',
                escaladaTipo: 'tradicional',
              ),
              CatalogoEntidade(
                uid: 'highlineCipo1X',
                tipo: 'escalada',
                croquiUid: 'croquiSerraC14',
                nome: 'Fita Aérea',
                escaladaGrau: '45m',
                escaladaTipo: 'highline',
              ),
            ],
          ),
        ),
      );

      await repoCaderneta.salvarCadena(
        Cadena.criar(
          escaladaUid: 'viaPedra1NanoX',
          dataAscensao: DateTime(2026, 10, 1),
          tipoAscensao: TipoAscensao.aVista,
          tipoEscalada: TipoEscalada.guiado,
        ),
      );
      await repoCaderneta.salvarCadena(
        Cadena.criar(
          escaladaUid: 'blocoPedra2Nan',
          dataAscensao: DateTime(2026, 10, 2),
          tipoAscensao: TipoAscensao.flash,
          tipoEscalada: TipoEscalada.boulder,
        ),
      );

      final resolvedor = ResolvedorMetadadosCaderneta(
        repositorioCaderneta: repoCaderneta,
        repositorioCatalogo: repoCatalogo,
      );
      await resolvedor.atualizar();

      // Duas escaladas no mesmo croqui contam como 1 pico distinto
      expect(resolvedor.obterTotalPicosDistintos(), equals(1));
      expect(resolvedor.obterNomeDaVia('viaPedra1NanoX'), equals('Via Deslize'));
      // Normaliza '6sup' do catálogo para '6ºsup' compatível com a pirâmide de graus
      expect(resolvedor.obterGrauDaVia('viaPedra1NanoX'), equals('6ºsup'));
      expect(resolvedor.obterNomeDaVia('blocoPedra2Nan'), equals('Bloco da Gruta'));
      expect(resolvedor.obterGrauDaVia('blocoPedra2Nan'), equals('V4'));

      // Ao salvar cadena em um segundo pico e em highline, reage automaticamente
      var notificou = false;
      resolvedor.addListener(() => notificou = true);

      await repoCaderneta.salvarCadena(
        Cadena.criar(
          escaladaUid: 'viaCipo1NanoXY',
          dataAscensao: DateTime(2026, 10, 3),
          tipoAscensao: TipoAscensao.trabalhado,
          tipoEscalada: TipoEscalada.guiado,
        ),
      );
      await repoCaderneta.salvarCadena(
        Cadena.criar(
          escaladaUid: 'highlineCipo1X',
          dataAscensao: DateTime(2026, 10, 4),
          tipoAscensao: TipoAscensao.trabalhado,
          tipoEscalada: TipoEscalada.guiado,
        ),
      );
      await resolvedor.atualizar();

      expect(notificou, isTrue);
      expect(resolvedor.obterTotalPicosDistintos(), equals(2));
      expect(resolvedor.obterNomeDaVia('viaCipo1NanoXY'), equals('Fenda do Cipó'));
      expect(resolvedor.obterGrauDaVia('viaCipo1NanoXY'), equals('7b'));
      // Highline não possui grau esportivo de escalada para a pirâmide
      expect(resolvedor.obterNomeDaVia('highlineCipo1X'), equals('Fita Aérea'));
      expect(resolvedor.obterGrauDaVia('highlineCipo1X'), isNull);

      resolvedor.dispose();
    });
  });
}
