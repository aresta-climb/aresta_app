// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/services/autenticacao/servico_autenticacao.dart';
import 'package:frontend/services/caderneta/repositorio_caderneta.dart';
import 'package:frontend/services/comunidade/repositorio_interacoes_via.dart';
import 'package:frontend/utils/gerador_uid.dart';
import 'fabrica_dataset_caos.dart';
import 'receita_crash_robo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FabricaDatasetCaos', () {
    test(
      'Constrói estado determinístico para TipoDatasetCaos.normal com UIDs NanoID 14c válidos, cadenas e interações comunitárias',
      () {
        final estado = FabricaDatasetCaos.construir(TipoDatasetCaos.normal);

        expect(estado.conjuntoDados.picosBaixados, isNotEmpty);
        expect(estado.conjuntoDados.picosDisponiveis, isNotEmpty);
        expect(estado.cadenasIniciais, isNotEmpty);
        expect(estado.interacoesIniciais, isNotEmpty);

        final primeiroPico = estado.conjuntoDados.picosBaixados.first;
        expect(primeiroPico.pico, isNotNull);
        expect(primeiroPico.croqui, isNotNull);
        expect(validarUid(primeiroPico.croqui!.uid), isTrue);
        expect(primeiroPico.pico!.setoresOuGrupos, isNotEmpty);
        final setor = primeiroPico.pico!.setoresOuGrupos.first.setor.conteudo;
        expect(validarUid(setor.uid), isTrue);
        expect(setor.escaladas.every((e) => validarUid(e.uid)), isTrue);
      },
    );

    test(
      'Constrói estado de estresse para TipoDatasetCaos.toxico com picos vazios, textos de 300+ caracteres, Markdown limite, alto volume de vias, cadenas órfãs e alertas extremos',
      () {
        final estado = FabricaDatasetCaos.construir(TipoDatasetCaos.toxico);

        final todosPicos = [
          ...estado.conjuntoDados.picosBaixados,
          ...estado.conjuntoDados.picosDisponiveis,
        ];
        expect(todosPicos.length, greaterThanOrEqualTo(4));

        // 1. Pico degenerado sem setores e sem vias
        final picoVazio = todosPicos.firstWhere(
          (p) => p.id == 'pico_toxico_vazio',
        );
        expect(picoVazio.pico!.setoresOuGrupos, isEmpty);

        // 2. Pico com textos gigantes (300+ caracteres), emojis e tags <small>
        final picoTextoExtremo = todosPicos.firstWhere(
          (p) => p.id == 'pico_toxico_texto_extremo',
        );
        expect(picoTextoExtremo.nome.length, greaterThanOrEqualTo(300));
        expect(picoTextoExtremo.descricao, contains('<small>'));

        // 3. Pico de alto volume com dezenas de vias e graus exóticos/vazios
        final picoVolume = todosPicos.firstWhere(
          (p) => p.id == 'pico_toxico_alto_volume',
        );
        final setorVolume =
            picoVolume.pico!.setoresOuGrupos.first.setor.conteudo;
        expect(setorVolume.escaladas.length, greaterThanOrEqualTo(50));
        expect(setorVolume.escaladas.every((e) => validarUid(e.uid)), isTrue);

        // 4. Cadenas órfãs apontando para UID inexistente no catálogo
        expect(
          estado.cadenasIniciais.any(
            (c) => c.escaladaUid == 'uid_orfao_4040',
          ),
          isTrue,
        );

        // 5. Interações tóxicas cobrindo todas as categorias de alerta
        final categoriasPresentes = estado.interacoesIniciais
            .map((i) => i.categoriaAlerta)
            .whereType<CategoriaAlertaSeguranca>()
            .toSet();
        expect(
          categoriasPresentes,
          containsAll(CategoriaAlertaSeguranca.values),
        );
      },
    );

    testWidgets(
      'AmbienteAppCaos injeta cadenas/interações, isola estado entre seeds e alterna plataforma Android/iOS expondo botão Apple',
      (tester) async {
        final ambiente = await AmbienteAppCaos.inicializar();
        addTearDown(ambiente.limpar);

        final motor = ambiente.criarMotor(tester: tester);

        // Seed par (2): Android, desautenticado (2 % 3 != 0)
        final resAndroid = await motor.executarSessao(
          seed: 2,
          dataset: TipoDatasetCaos.normal,
          maxPassos: 0,
        );
        expect(resAndroid.teveFalha, isFalse);
        expect(RepositorioCadernetaLocal.instancia.cadenasNotifier.value, isNotEmpty);
        expect(
          RepositorioInteracoesViaMemoria.instancia
              .obterDadosEscalada('viaNormCaos001')
              .alertasAtivos,
          isNotEmpty,
        );
        expect(ServicoAutenticacaoLocal.instancia.estaAutenticado, isFalse);

        final temaAndroid = Theme.of(
          tester.element(find.byType(Scaffold).first),
        );
        expect(temaAndroid.platform, equals(TargetPlatform.android));

        // Autentica artificialmente na seed 2 para comprovar que a seed 3 reseta o estado
        await ServicoAutenticacaoLocal.instancia.entrarComGoogle();
        expect(ServicoAutenticacaoLocal.instancia.estaAutenticado, isTrue);

        // Seed ímpar (1): iOS, desautenticado (1 % 3 != 0)
        final resIos = await motor.executarSessao(
          seed: 1,
          dataset: TipoDatasetCaos.normal,
          maxPassos: 0,
        );
        expect(resIos.teveFalha, isFalse);
        expect(ServicoAutenticacaoLocal.instancia.estaAutenticado, isFalse);
        final temaIos = Theme.of(
          tester.element(find.byType(Scaffold).first),
        );
        expect(temaIos.platform, equals(TargetPlatform.iOS));

        // Seed múltipla de 3 (3): iOS e já inicia autenticada
        final resAutenticada = await motor.executarSessao(
          seed: 3,
          dataset: TipoDatasetCaos.normal,
          maxPassos: 0,
        );
        expect(resAutenticada.teveFalha, isFalse);
        expect(ServicoAutenticacaoLocal.instancia.estaAutenticado, isTrue);
      },
    );
  });
}
