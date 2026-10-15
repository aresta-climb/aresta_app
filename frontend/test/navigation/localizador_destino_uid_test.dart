// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';
import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/navigation/localizador_destino_uid.dart';
import 'package:frontend/services/dataset/modelos/metadados_indice.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/repositorio_dataset.dart';

void main() {
  late EditorDeCroqui editorDeCroqui;
  late DatasetRepository datasetRepo;
  late LocalizadorDestinoUid localizador;

  late Pico picoTeste;
  late Croqui croquiTeste;
  late Setor setorDireto;
  late Grupo grupoTeste;
  late Setor setorNoGrupo;
  late Escalada viaNoSetorDireto;
  late Escalada viaNoSetorDoGrupo;
  late Botao botaoTeste;

  const String uidCroqui = 'pQ9mRt2Kx1Vw8L';
  const String uidGrupo = 'g8Rk2L1x9Y7zWq';
  const String uidSetorDireto = 's1Lk9P1x4Vw8Mn';
  const String uidSetorNoGrupo = 's2Lk9P1x4Vw8Mn';
  const String uidViaSetorDireto = 'v1siJek3FiG3aB';
  const String uidViaSetorDoGrupo = 'v2siJek3FiG3aB';
  const String uidBotao = 'b1siJek3FiG3aB';
  const String uidInexistente = 'z9zzZzZzZzZzZz';

  setUp(() {
    editorDeCroqui = EditorDeCroqui();
    datasetRepo = DatasetRepository(editorDeCroqui: editorDeCroqui);
    localizador = LocalizadorDestinoUid(datasetRepo: datasetRepo);

    // 1. Constrói estrutura hierárquica completa com UIDs NanoID 14c
    croquiTeste = Croqui()
      ..id = 'br_mg_igarape_pedra_grande'
      ..uid = uidCroqui;

    picoTeste = Pico()..nome = 'Pedra Grande de Igarapé';

    // Via em setor direto
    viaNoSetorDireto = Escalada()
      ..uid = uidViaSetorDireto
      ..viaEsportiva = (ViaEsportiva()..nome = 'Teto da Savassinha');

    setorDireto = Setor()
      ..nome = 'Savassinha'
      ..uid = uidSetorDireto;
    setorDireto.escaladas.add(viaNoSetorDireto);

    picoTeste.setoresOuGrupos.add(
      SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setorDireto),
    );

    // Via em setor dentro de grupo
    viaNoSetorDoGrupo = Escalada()
      ..uid = uidViaSetorDoGrupo
      ..boulder = (Boulder()..nome = 'Bloco do Totem');

    setorNoGrupo = Setor()
      ..nome = 'Setor do Bloco'
      ..uid = uidSetorNoGrupo;
    setorNoGrupo.escaladas.add(viaNoSetorDoGrupo);

    grupoTeste = Grupo()
      ..nome = 'Grupo Estacionamento'
      ..uid = uidGrupo;
    grupoTeste.setores.add(ArquivoSetor()..conteudo = setorNoGrupo);

    picoTeste.setoresOuGrupos.add(
      SetorOuGrupo()..grupo = (ArquivoGrupo()..conteudo = grupoTeste),
    );

    botaoTeste = Botao()
      ..uid = uidBotao
      ..texto = 'Ver Mapa Geral';
    croquiTeste.botoes.add(botaoTeste);

    croquiTeste.picos.add(picoTeste);

    // 2. Configura dataset com metadados do índice e picos baixados
    final resumoIndice = ResumoCroqui()
      ..id = 'br_mg_igarape_pedra_grande'
      ..croquiUid = uidCroqui
      ..nome = 'Pedra Grande de Igarapé';

    datasetRepo.activeDataset.value = TopoDataset(
      picosBaixados: [
        {
          'id': 'br_mg_igarape_pedra_grande',
          'data': {'pico': picoTeste, 'croqui': croquiTeste},
        },
      ],
      picosDisponiveis: [resumoIndice.paraResumoPico()],
      metadadosDisponiveis: [resumoIndice],
    );
  });

  group('LocalizadorDestinoUid', () {
    test('localiza Croqui a partir de croquiUid do índice de metadados', () async {
      final destino = await localizador.localizar(uidCroqui);

      expect(destino, isNotNull);
      expect(destino!.idCroqui, equals('br_mg_igarape_pedra_grande'));
      expect(destino.tipoDestino, equals('pico'));
      expect(destino.noNavegacao, isA<PicoNode>());
      final picoNode = destino.noNavegacao as PicoNode;
      expect(picoNode.cragId, equals('br_mg_igarape_pedra_grande'));
    });

    test('localiza Via em setor direto com linhagem correta da árvore', () async {
      final destino = await localizador.localizar(uidViaSetorDireto);

      expect(destino, isNotNull);
      expect(destino!.idCroqui, equals('br_mg_igarape_pedra_grande'));
      expect(destino.tipoDestino, equals('via'));
      expect(destino.nomeEntidade, equals('Teto da Savassinha'));
      expect(destino.noNavegacao, isA<ViaNode>());

      final viaNode = destino.noNavegacao as ViaNode;
      expect(viaNode.escaladaNome, equals('Teto da Savassinha'));
      expect(viaNode.setorNome, equals('Savassinha'));
      expect(viaNode.grupoNome, isNull);
      expect(viaNode.parent, isA<SetorNode>());

      final setorNode = viaNode.parent as SetorNode;
      expect(setorNode.setorNome, equals('Savassinha'));
      expect(setorNode.parent, isA<PicoNode>());
    });

    test('localiza Via dentro de setor pertencente a um Grupo', () async {
      final destino = await localizador.localizar(uidViaSetorDoGrupo);

      expect(destino, isNotNull);
      expect(destino!.idCroqui, equals('br_mg_igarape_pedra_grande'));
      expect(destino.tipoDestino, equals('via'));
      expect(destino.nomeEntidade, equals('Bloco do Totem'));
      expect(destino.noNavegacao, isA<ViaNode>());

      final viaNode = destino.noNavegacao as ViaNode;
      expect(viaNode.escaladaNome, equals('Bloco do Totem'));
      expect(viaNode.setorNome, equals('Setor do Bloco'));
      expect(viaNode.grupoNome, equals('Grupo Estacionamento'));
      expect(viaNode.parent, isA<SetorNode>());

      final setorNode = viaNode.parent as SetorNode;
      expect(setorNode.parent, isA<GrupoNode>());

      final grupoNode = setorNode.parent as GrupoNode;
      expect(grupoNode.grupoNome, equals('Grupo Estacionamento'));
      expect(grupoNode.parent, isA<PicoNode>());
    });

    test('localiza Setor direto com linhagem até PicoNode', () async {
      final destino = await localizador.localizar(uidSetorDireto);

      expect(destino, isNotNull);
      expect(destino!.idCroqui, equals('br_mg_igarape_pedra_grande'));
      expect(destino.tipoDestino, equals('setor'));
      expect(destino.nomeEntidade, equals('Savassinha'));
      expect(destino.noNavegacao, isA<SetorNode>());

      final setorNode = destino.noNavegacao as SetorNode;
      expect(setorNode.setorNome, equals('Savassinha'));
      expect(setorNode.parent, isA<PicoNode>());
    });

    test('localiza Setor dentro de Grupo com GrupoNode como pai', () async {
      final destino = await localizador.localizar(uidSetorNoGrupo);

      expect(destino, isNotNull);
      expect(destino!.idCroqui, equals('br_mg_igarape_pedra_grande'));
      expect(destino.tipoDestino, equals('setor'));
      expect(destino.nomeEntidade, equals('Setor do Bloco'));
      expect(destino.noNavegacao, isA<SetorNode>());

      final setorNode = destino.noNavegacao as SetorNode;
      expect(setorNode.parent, isA<GrupoNode>());
      final grupoNode = setorNode.parent as GrupoNode;
      expect(grupoNode.grupoNome, equals('Grupo Estacionamento'));
    });

    test('localiza Grupo diretamente com PicoNode como pai', () async {
      final destino = await localizador.localizar(uidGrupo);

      expect(destino, isNotNull);
      expect(destino!.idCroqui, equals('br_mg_igarape_pedra_grande'));
      expect(destino.tipoDestino, equals('grupo'));
      expect(destino.nomeEntidade, equals('Grupo Estacionamento'));
      expect(destino.noNavegacao, isA<GrupoNode>());

      final grupoNode = destino.noNavegacao as GrupoNode;
      expect(grupoNode.grupoNome, equals('Grupo Estacionamento'));
      expect(grupoNode.parent, isA<PicoNode>());
    });

    test('localiza Botão interativo retornando PicoNode', () async {
      final destino = await localizador.localizar(uidBotao);

      expect(destino, isNotNull);
      expect(destino!.tipoDestino, equals('pico'));
      expect(destino.nomeEntidade, equals('Ver Mapa Geral'));
      expect(destino.noNavegacao, isA<PicoNode>());
    });

    test('localiza entidade presente na sessão online em memória', () async {
      const String uidViaRemota = 'vOnline1234567';
      final croquiOnline = Croqui()
        ..id = 'br_mg_cipo'
        ..uid = 'cOnline1234567';
      final picoOnline = Pico()..nome = 'Serra do Cipó';
      final setorOnline = Setor()..nome = 'Vale da Lapinha';
      final viaOnline = Escalada()
        ..uid = uidViaRemota
        ..viaEsportiva = (ViaEsportiva()..nome = 'Gafanhoto');
      setorOnline.escaladas.add(viaOnline);
      picoOnline.setoresOuGrupos.add(
        SetorOuGrupo()..setor = (ArquivoSetor()..conteudo = setorOnline),
      );
      croquiOnline.picos.add(picoOnline);

      datasetRepo.gerenciadorSessaoOnline.registrarCroquiOnline(
        'br_mg_cipo',
        croquiOnline,
      );

      final destino = await localizador.localizar(uidViaRemota);

      expect(destino, isNotNull);
      expect(destino!.idCroqui, equals('br_mg_cipo'));
      expect(destino.tipoDestino, equals('via'));
      expect(destino.nomeEntidade, equals('Gafanhoto'));
      expect(destino.noNavegacao, isA<ViaNode>());
    });

    test('retorna null para UID inexistente no acervo', () async {
      final destino = await localizador.localizar(uidInexistente);
      expect(destino, isNull);
    });
  });
}
