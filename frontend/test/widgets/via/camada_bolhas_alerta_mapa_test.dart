// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/services/configuracao_recursos.dart';
import 'package:frontend/theme/cores_app.dart';
import 'package:frontend/utils/consulta_dataset.dart';
import 'package:frontend/view/view_models/alertas_mapa_interativo_view_model.dart';
import 'package:frontend/widgets/via/bolha_alerta_seguranca_via.dart';
import 'package:frontend/widgets/via/camada_bolhas_alerta_mapa.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/comunidade/repositorio_interacoes_via_fake.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);
  });

  tearDown(ConfiguracaoRecursos.redefinirParaTestes);

  testWidgets(
    'CamadaBolhasAlertaMapa renderiza bolhas estilo Waze ancoradas no mapa e permite confirmar ou Desfazer',
    (tester) async {
      const uidVia = 'viaMapaAlerta1';
      final alerta = AlertaSegurancaVia.criar(
        uid: 'alertaMapa0001',
        escaladaUid: uidVia,
        categoria: CategoriaAlertaSeguranca.abelhasInsetos,
        detalhe: 'Marimbondos no diedro',
      );
      final repoFake = RepositorioInteracoesViaFake()
        ..semearDados(uidVia, DadosComunidadeVia(alertasAtivos: [alerta]));

      final ref = Mapa_Referencia(alvoUid: uidVia, pontosUids: ['p1']);
      final mapa = Mapa(
        caminhoImagemMapa: 'mapas/setor.webp',
        larguraMapa: 400,
        alturaMapa: 400,
        pontosDeInteresse: [
          Mapa_PontoDeInteresse(
            uid: 'p1',
            circulo: BoundingCirculo(x: 200, y: 200, raio: 20),
          ),
        ],
        referencias: [ref],
      );

      final vm = AlertasMapaInterativoViewModel(
        mapa: mapa,
        referenciasResolvidas: {
          ref: ResolvedDataset(
            tipo: TipoEntidadeResolved.escalada,
            escalada: Escalada(
              uid: uidVia,
              viaEsportiva: ViaEsportiva(nome: 'Faraó'),
            ),
          ),
        },
        repositorioInteracoes: repoFake,
        duracaoJanelaDesfazer: const Duration(seconds: 4),
      );
  });
}
