// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/navigation/arvore_navegacao.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/utils/extrator_detalhes_tecnicos_via.dart';
import 'package:frontend/widgets/mapa_thumbnail.dart';
import 'package:frontend/widgets/via/bolha_alerta_seguranca_via.dart';
import 'package:frontend/widgets/via/cabecalho_e_heroi_via.dart';

void main() {
  Widget envolver(Widget filho) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [AppColors.dark]),
      home: Scaffold(body: SingleChildScrollView(child: filho)),
    );
  }

  testWidgets(
    'CabecalhoIdentidadeVia e CartaoGrauVia renderizam identidade, estado vazio e consenso em tela estreita',
    (tester) async {
      final escalada = Escalada(
        viaEsportiva: ViaEsportiva(nome: 'Aresta Solar', destaque: true),
      );

      await tester.pumpWidget(
        envolver(
          SizedBox(
            width: 220,
            child: Column(
              children: [
                CabecalhoIdentidadeVia(
                  nomeEscalada: 'Aresta Solar',
                  modalidade: 'Esportiva',
                  ehDestaque: true,
                  cragId: 'crag1',
                  escalada: escalada,
                  setor: Setor(nome: 'Principal'),
                  grupo: Grupo(nome: 'Norte'),
                ),
                const CartaoGrauVia(
                  rotuloGrauOficial: 'GRAU OFICIAL',
                  grauOficial: null,
                  complementoGrauOficial: 'Guia Oficial / Conquistador',
                  apresentacaoConsenso: ApresentacaoConsensoGrauVia.semVotos(),
                ),
                const CartaoGrauVia(
                  rotuloGrauOficial: 'GRAU OFICIAL',
                  grauOficial: '7c',
                  complementoGrauOficial: 'Guia Oficial / Conquistador',
                  apresentacaoConsenso: ApresentacaoConsensoGrauVia(
                    possuiVotos: true,
                    grauSugerido: '7c',
                    subtituloTendencia: '5 avaliações',
                    tituloDistribuicao: '',
                    votosSuaves: 0,
                    votosJustos: 5,
                    votosDuros: 0,
                    faixasDistribuicao: [],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Aresta Solar'), findsOneWidget);
      expect(find.text('ESPORTIVA'), findsOneWidget);
      expect(find.text('CLÁSSICA'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Sem votos'), findsOneWidget);
      expect(find.text('5 avaliações'), findsOneWidget);
    },
  );

  testWidgets(
    'AreaHeroiTopoGrauVia e SecaoMapaCroquiVia renderizam bolha flutuante, miniatura e botão de croqui',
    (tester) async {
      AlertaSegurancaVia? alertaTocado;
      var clicouCroqui = false;
      final alerta = AlertaSegurancaVia.criar(
        uid: 'alertaTopo0001',
        escaladaUid: 'x8siJek3FiG3aB',
        categoria: CategoriaAlertaSeguranca.abelhasInsetos,
      );
      final consenso = ExtratorDetalhesTecnicosVia.construirApresentacaoConsenso(
        const ConsensoGrauVia(
          grauSugerido: '7b',
          totalVotos: 10,
          distribuicaoDeltas: {1: 8, 0: 2},
        ),
        codigoGrauOficial: GrauVia_GrauVia.BR_7A.value,
        ehBoulder: false,
      );

      await tester.pumpWidget(
        envolver(
          AreaHeroiTopoGrauVia(
            estadoCroqui: const EstadoCroquiVia(
              itensNavegacaoCroqui: [
                CarrosselItemData(mapaCaminhoImagem: 'mapas/setor.webp'),
              ],
            ),
            cragId: 'crag1',
            nomeEscalada: 'Deslize',
            aoAbrirCroquiInterativo: () => clicouCroqui = true,
            exibirCartaoGrau: true,
            rotuloGrauOficial: 'GRAU OFICIAL',
            grauOficial: '7a',
            complementoGrauOficial: 'Guia Oficial / Conquistador',
            apresentacaoConsenso: consenso,
            alertasAtivos: [alerta],
            aoTocarAlerta: (a) => alertaTocado = a,
          ),
        ),
      );

      expect(find.text('VER NO CROQUI INTERATIVO'), findsOneWidget);
      expect(find.text('7b (+1)'), findsOneWidget);
      expect(find.byType(BolhaEmojiAlertaVia), findsOneWidget);

      await tester.tap(find.text('VER NO CROQUI INTERATIVO'));
      expect(clicouCroqui, isTrue);

      await tester.tap(find.byKey(const Key('bolha_alerta_ABELHAS_INSETOS')));
      expect(alertaTocado?.uid, 'alertaTopo0001');

      // Sem cartão de grau (ex.: Highline com alerta ativo)
      await tester.pumpWidget(
        envolver(
          AreaHeroiTopoGrauVia(
            estadoCroqui: const EstadoCroquiVia(),
            cragId: 'crag1',
            nomeEscalada: 'Fita Alta',
            aoAbrirCroquiInterativo: () {},
            exibirCartaoGrau: false,
            rotuloGrauOficial: 'GRAU OFICIAL',
            grauOficial: null,
            complementoGrauOficial: '',
            apresentacaoConsenso: null,
            alertasAtivos: [alerta],
            aoTocarAlerta: (_) {},
          ),
        ),
      );
      expect(find.byType(BolhaEmojiAlertaVia), findsOneWidget);

      // Miniatura direta quando há mapas válidos na própria escalada
      await tester.pumpWidget(
        envolver(
          SecaoMapaCroquiVia(
            cragId: 'crag1',
            nomeEscalada: 'Via Própria',
            estadoCroqui: EstadoCroquiVia(
              mapasMiniatura: [
                Mapa(
                  caminhoImagemMapa: 'mapas/proprio.webp',
                  larguraMapa: 1000,
                  alturaMapa: 800,
                ),
              ],
              aspectRatioMiniatura: 1.25,
              itensCarrosselMiniatura: const [
                CarrosselItemData(mapaCaminhoImagem: 'mapas/proprio.webp'),
              ],
            ),
            aoAbrirCroquiInterativo: () {},
          ),
        ),
      );
      expect(find.byType(MapaThumbnail), findsOneWidget);
    },
  );
}
