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
          refSetor: ResolvedDataset(
            tipo: TipoEntidadeResolved.setor,
            setor: setor2Andar,
          ),
          refGrupo: ResolvedDataset(
            tipo: TipoEntidadeResolved.grupo,
            grupo: grupoNorte,
          ),
          refBotao: ResolvedDataset(tipo: TipoEntidadeResolved.botao),
        },
        repositorioInteracoes: repoFake,
        duracaoJanelaDesfazer: const Duration(milliseconds: 50),
      );

      await Future<void>.delayed(Duration.zero);
      expect(
        repoFake.escaladasSincronizadas,
        containsAll([uidFarao, uidSetorVia, uidGrupoVia]),
      );

      final bolhas = vm.bolhasNoMapa;
      expect(bolhas, hasLength(3));

      final bolhaFarao = bolhas.firstWhere((b) => b.escaladaUid == uidFarao);
      expect(bolhaFarao.relX, closeTo(0.20, 0.001));
      expect(bolhaFarao.relY, closeTo(0.70, 0.001));
      expect(bolhaFarao.nomeEscalada, 'Faraó');
      expect(vm.obterAlertasDaEscalada(uidFarao), hasLength(1));
      expect(vm.obterAlertasDaEscalada('   '), isEmpty);
      expect(vm.obterAlertasDoSetor(setor2Andar), hasLength(1));

      // Iniciar resolução com Desfazer oculta no mapa imediatamente e restaura ao desfazer
      vm.iniciarResolucaoAlertaComDesfazer(uidFarao, 'alertaAbelha01');
      expect(vm.bolhasNoMapa.any((b) => b.escaladaUid == uidFarao), isFalse);

      vm.desfazerResolucaoAlerta('alertaAbelha01');
      expect(vm.bolhasNoMapa.any((b) => b.escaladaUid == uidFarao), isTrue);

      // Confirmar que ainda está lá incrementa contagem; falha retorna false
      expect(
        await vm.confirmarAlerta(
          uidFarao,
          'alertaAbelha01',
          aindaEstaLa: true,
        ),
        isTrue,
      );
      expect(
        vm.obterAlertasDaEscalada(uidFarao).single.confirmacoesAtivas,
        2,
      );
      repoFake.erroSimulado = StateError('Erro de confirmação');
      expect(
        await vm.confirmarAlerta(
          uidFarao,
          'alertaAbelha01',
          aindaEstaLa: true,
        ),
        isFalse,
      );

      // atualizarContextoMapa lida com falha de sync e projeta retângulo, polígono e linhas alternativas
      const uidRet = 'viaRetangulo01';
      const uidPol = 'viaPoligono002';
      const uidCaixa = 'viaLinhaCaixa3';
      const uidNos = 'viaLinhaNos004';
      const uidSit = 'boulderSit0005';
      repoFake.erroSimulado = null;
      for (final u in [uidRet, uidPol, uidCaixa, uidNos, uidSit]) {
        repoFake.semearDados(
          u,
          DadosComunidadeVia(
            alertasAtivos: [
              AlertaSegurancaVia.criar(
                escaladaUid: u,
                categoria: CategoriaAlertaSeguranca.protecaoPrecaria,
              ),
            ],
          ),
        );
      }
      repoFake.erroSimulado = StateError('Sync adiado');

      final refRet = Mapa_Referencia(alvoUid: uidRet, pontosUids: ['p_ret']);
      final refPol = Mapa_Referencia(alvoUid: uidPol, pontosUids: ['p_pol']);
      final refPolVazio = Mapa_Referencia(alvoUid: uidPol, pontosUids: ['p_pol_vazio']);
      final refCaixa = Mapa_Referencia(alvoUid: uidCaixa, pontosUids: ['p_caixa']);
      final refNos = Mapa_Referencia(alvoUid: uidNos, pontosUids: ['p_nos']);
      final refSit = Mapa_Referencia(alvoUid: uidSit, pontosUids: ['p_sit']);
      final refNotSet = Mapa_Referencia(alvoUid: uidNos, pontosUids: ['p_vazio', 'p_linha_vazia']);

      final mapa2 = Mapa(
        larguraMapa: 500,
        alturaMapa: 500,
        pontosDeInteresse: [
          Mapa_PontoDeInteresse(
            uid: 'p_ret',
            retangulo: BoundingRetangulo(x: 100, y: 100, comprimento: 20, largura: 20),
          ),
          Mapa_PontoDeInteresse(
            uid: 'p_pol',
            poligono: BoundingPoligono(coordenadas: [200, 200, 300, 300]),
          ),
          Mapa_PontoDeInteresse(
            uid: 'p_pol_vazio',
            poligono: BoundingPoligono(coordenadas: [10]),
          ),
          Mapa_PontoDeInteresse(
            uid: 'p_caixa',
            linha: LinhaTrajeto(
              compilado: DadosCompiladosLinha(
                caixaDelimitadora: BoundingRetangulo(x: 150, y: 250),
              ),
            ),
          ),
          Mapa_PontoDeInteresse(
            uid: 'p_sit',
            linha: LinhaTrajeto(
              compilado: DadosCompiladosLinha(
                marcadores: [
                  MarcadorCompilado(
                    tipo: NoTrajeto_TipoNo.INICIO_AGACHADO,
                    x: 180,
                    y: 420,
                  ),
                ],
              ),
            ),
          ),
          Mapa_PontoDeInteresse(
            uid: 'p_nos',
            linha: LinhaTrajeto(
              conteudo: DadosConteudoLinha(
                nos: [NoTrajeto(x: 350, y: 150)],
              ),
            ),
          ),
          Mapa_PontoDeInteresse(uid: 'p_vazio'),
          Mapa_PontoDeInteresse(uid: 'p_linha_vazia', linha: LinhaTrajeto()),
        ],
      );

      vm.atualizarContextoMapa(
        mapa: mapa2,
        referenciasResolvidas: {
          refRet: ResolvedDataset(
            tipo: TipoEntidadeResolved.escalada,
            escalada: Escalada(uid: uidRet, viaEsportiva: ViaEsportiva(nome: 'R1')),
          ),
          refPol: ResolvedDataset(
            tipo: TipoEntidadeResolved.escalada,
            escalada: Escalada(uid: uidPol, viaEsportiva: ViaEsportiva(nome: 'R2')),
          ),
          refPolVazio: ResolvedDataset(
            tipo: TipoEntidadeResolved.escalada,
            escalada: Escalada(uid: uidPol, viaEsportiva: ViaEsportiva(nome: 'R2')),
          ),
          refCaixa: ResolvedDataset(
            tipo: TipoEntidadeResolved.escalada,
            escalada: Escalada(uid: uidCaixa, viaEsportiva: ViaEsportiva(nome: 'R3')),
          ),
          refSit: ResolvedDataset(
            tipo: TipoEntidadeResolved.escalada,
            escalada: Escalada(uid: uidSit, boulder: Boulder(nome: 'B5')),
          ),
          refNos: ResolvedDataset(
            tipo: TipoEntidadeResolved.escalada,
            escalada: Escalada(uid: uidNos, viaEsportiva: ViaEsportiva(nome: 'R4')),
          ),
          refNotSet: ResolvedDataset(
            tipo: TipoEntidadeResolved.escalada,
            escalada: Escalada(uid: uidNos, viaEsportiva: ViaEsportiva(nome: 'R4')),
          ),
        },
      );
      await Future<void>.delayed(Duration.zero);
      repoFake.erroSimulado = null;
      expect(vm.bolhasNoMapa, hasLength(5));

      // Quando perfilHabilitado é false, oculta todas as bolhas e alertas
      ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(false);
      expect(vm.bolhasNoMapa, isEmpty);
      expect(vm.obterAlertasDoSetor(setor2Andar), isEmpty);
      ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);

      // Resolução definitiva por expiração e por dispose
      vm.iniciarResolucaoAlertaComDesfazer(uidSetorVia, 'alertaBloco002');
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(repoFake.obterDadosEscalada(uidSetorVia).alertasAtivos, isEmpty);

      vm.iniciarResolucaoAlertaComDesfazer(uidGrupoVia, 'alertaMolhada3');
      vm.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(repoFake.obterDadosEscalada(uidGrupoVia).alertasAtivos, isEmpty);
    },
  );
}
