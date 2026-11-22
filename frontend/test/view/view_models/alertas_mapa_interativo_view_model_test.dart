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

      final viaFarao = Escalada(
        uid: uidFarao,
        viaEsportiva: ViaEsportiva(nome: 'Faraó'),
      );
      final viaDoSetor = Escalada(
        uid: uidSetorVia,
        viaEsportiva: ViaEsportiva(nome: 'Cleópatra'),
      );
      final setor2Andar = Setor(
        uid: 'setor2AndarUid',
        nome: 'Setor 2º Andar',
        escaladas: [viaDoSetor],
      );
      final grupoNorte = Grupo(
        uid: 'grupoNorteUid1',
        nome: 'Face Norte',
        setores: [
          ArquivoSetor(
            conteudo: Setor(
              uid: 'setorInterno01',
              nome: 'Setor Interno',
              escaladas: [
                Escalada(
                  uid: uidGrupoVia,
                  viaEsportiva: ViaEsportiva(nome: 'Aresta Norte'),
                ),
              ],
            ),
          ),
        ],
      );

      final poiLinha = Mapa_PontoDeInteresse(
        uid: 'poi_linha_28',
        linha: LinhaTrajeto(
          compilado: DadosCompiladosLinha(
            caminhoSvg: 'M 200 700 L 200 300',
            marcadores: [
              MarcadorCompilado(
                tipo: NoTrajeto_TipoNo.CIRCULO_IDENTIFICADOR,
                x: 200,
                y: 700,
                rotulo: '28',
              ),
            ],
          ),
        ),
      );
      final poiSetor = Mapa_PontoDeInteresse(
        uid: 'poi_setor_2',
        circulo: BoundingCirculo(x: 500, y: 400, raio: 40),
      );
      final poiGrupo = Mapa_PontoDeInteresse(
        uid: 'poi_grupo_n',
        quadrado: BoundingQuadrado(x: 800, y: 200, lado: 50),
      );
      final refBotao = Mapa_Referencia(alvoUid: 'btn1', pontosUids: ['poi_inex']);

      final refVia = Mapa_Referencia(
        alvoUid: uidFarao,
        pontosUids: ['poi_linha_28'],
      );
      final refSetor = Mapa_Referencia(
        alvoUid: 'setor2AndarUid',
        pontosUids: ['poi_setor_2'],
      );
      final refGrupo = Mapa_Referencia(
        alvoUid: 'grupoNorteUid1',
        pontosUids: ['poi_grupo_n'],
      );

      final mapa = Mapa(
        caminhoImagemMapa: 'mapas/bau_2andar.webp',
        larguraMapa: 1000,
        alturaMapa: 1000,
        pontosDeInteresse: [poiLinha, poiSetor, poiGrupo],
        referencias: [refVia, refSetor, refGrupo, refBotao],
      );

      final vm = AlertasMapaInterativoViewModel(
        mapa: mapa,
        referenciasResolvidas: {
          refVia: ResolvedDataset(
            tipo: TipoEntidadeResolved.escalada,
            escalada: viaFarao,
          ),
      });
  });
}
