// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/data/modelos/interacao_via.dart';
import 'package:frontend/services/configuracao_recursos.dart';
import 'package:frontend/services/controlador_interacoes_usuario.dart';
import 'package:frontend/utils/consulta_dataset.dart';
import 'package:frontend/view/view_models/alertas_mapa_interativo_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/comunidade/repositorio_interacoes_via_fake.dart';

void main() {
  late RepositorioInteracoesViaFake repoFake;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);
    ControladorInteracoesUsuario.redefinirParaTestes();
    repoFake = RepositorioInteracoesViaFake();
  });

  tearDown(() {
    ConfiguracaoRecursos.redefinirParaTestes();
    ControladorInteracoesUsuario.redefinirParaTestes();
  });

  test(
    'sincroniza vias do mapa em lote, projeta bolhas em linhas/círculos/setores e suporta Desfazer',
    () async {
      const uidFarao = 'faraoUid123456';
      const uidSetorVia = 'setorViaUid789';
      const uidGrupoVia = 'grupoViaUid321';

      final alertaAbelha = AlertaSegurancaVia.criar(
        uid: 'alertaAbelha01',
        escaladaUid: uidFarao,
        categoria: CategoriaAlertaSeguranca.abelhasInsetos,
        detalhe: 'Colmeia na 4ª chapeleta',
      );
      final alertaBloco = AlertaSegurancaVia.criar(
        uid: 'alertaBloco002',
        escaladaUid: uidSetorVia,
        categoria: CategoriaAlertaSeguranca.rochaAgarraInstavel,
      );
      final alertaMolhada = AlertaSegurancaVia.criar(
        uid: 'alertaMolhada3',
        escaladaUid: uidGrupoVia,
        categoria: CategoriaAlertaSeguranca.viaMolhada,
      );

      repoFake
        ..semearDados(uidFarao, DadosComunidadeVia(alertasAtivos: [alertaAbelha]))
        ..semearDados(uidSetorVia, DadosComunidadeVia(alertasAtivos: [alertaBloco]))
        ..semearDados(uidGrupoVia, DadosComunidadeVia(alertasAtivos: [alertaMolhada]));
  });
}
