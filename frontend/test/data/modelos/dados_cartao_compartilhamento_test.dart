// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/data/modelos/dados_cartao_compartilhamento.dart';
import 'package:frontend/services/editor_croqui.dart';
import 'package:frontend/services/repositorio_dataset.dart';
import 'package:frontend/utils/modelos_apresentacao_via.dart';

void main() {
  group('DadosCartaoCompartilhamento', () {
    test('TipoEntidadeCompartilhavel expõe códigos canônicos de telemetria', () {
      expect(TipoEntidadeCompartilhavel.pico.codigoTelemetria, 'pico');
      expect(TipoEntidadeCompartilhavel.grupo.codigoTelemetria, 'grupo');
      expect(TipoEntidadeCompartilhavel.setor.codigoTelemetria, 'setor');
      expect(TipoEntidadeCompartilhavel.via.codigoTelemetria, 'via');
    });

    test('dePico consolida thumbnail, localização, setores, escaladas e modalidades traduzidas', () {
      final pico = Pico(
        nome: 'Pedra Grande',
        estado: 'Igarapé - MG',
        setoresOuGrupos: [
          SetorOuGrupo(
            setor: ArquivoSetor(
              conteudo: Setor(
                nome: 'Setor Principal',
                escaladas: [
                  Escalada(
                    viaEsportiva: ViaEsportiva(nome: 'Via 1'),
                  ),
                ],
              ),
            ),
          ),
          SetorOuGrupo(
            grupo: ArquivoGrupo(
              conteudo: Grupo(
                nome: 'Grupo Sherpa',
                setores: [
                  ArquivoSetor(
                    conteudo: Setor(
                      nome: 'Bloco Democracia',
                      escaladas: [
                        Escalada(boulder: Boulder(nome: 'Boulder 1')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
      final croqui = Croqui(
        id: 'br_mg_igarape_pedra_grande',
        uid: 'uidPico1234567',
        nome: 'Pedra Grande',
        caminhoThumbnail: 'thumbnails/pedra.webp',
        picos: [pico],
      );

      final dados = DadosCartaoCompartilhamento.dePico(
        idCroqui: 'br_mg_igarape_pedra_grande',
        croqui: croqui,
        pico: pico,
      );

      expect(dados.tipoEntidade, TipoEntidadeCompartilhavel.pico);
      expect(dados.uid, 'uidPico1234567');
      expect(dados.titulo, 'Pedra Grande');
      expect(dados.subtituloLocalizacao, 'Igarapé - MG');
      expect(dados.etiquetaCategoria, 'PICO DE ESCALADA');
      expect(dados.caminhoImagemHeroi, 'thumbnails/pedra.webp');
      expect(dados.chipsResumo, contains('2 setores'));
      expect(dados.chipsResumo, contains('2 escaladas'));
      expect(dados.chipsResumo.any((c) => c.contains('Esportiva')), isTrue);
      expect(dados.localizacaoPico, 'Igarapé - MG');
      expect(dados.nomePico, 'Pedra Grande');
    });

    test('dePico recorre ao mapa geral válido quando thumbnail do croqui está vazia e trata 1 setor / 1 escalada', () {
      final pico = Pico(
        nome: 'Sete Quedas',
        mapasGerais: ArquivoMapas(
          conteudo: ColecaoDeMapas(
            mapas: [
              Mapa(caminhoImagemMapa: '', larguraMapa: 100, alturaMapa: 100),
              Mapa(
                caminhoImagemMapa: 'mapas/geral.webp',
                larguraMapa: 800,
                alturaMapa: 600,
              ),
            ],
          ),
        ),
        setoresOuGrupos: [
          SetorOuGrupo(
            setor: ArquivoSetor(
              conteudo: Setor(
                nome: 'Setor Único',
                escaladas: [
                  Escalada(highline: Highline(nome: 'Linha Alta')),
                ],
              ),
            ),
          ),
        ],
      );
      final croqui = Croqui(
        id: 'br_mg_sete_quedas',
        uid: 'uidPicoUnico12',
        picos: [pico],
      );

      final dados = DadosCartaoCompartilhamento.dePico(
        idCroqui: 'br_mg_sete_quedas',
        croqui: croqui,
        pico: pico,
      );

      expect(dados.caminhoImagemHeroi, 'mapas/geral.webp');
      expect(dados.chipsResumo, contains('1 setor'));
      expect(dados.chipsResumo, contains('1 escalada'));
      expect(dados.chipsResumo, contains('Highline'));
    });

    test('deGrupo aplica cascata de imagem (capa -> mapa -> setor filho -> croqui) e resolve nome do pico', () {
      final repo = DatasetRepository(editorDeCroqui: EditorDeCroqui());
      repo.activeDataset.value = ConjuntoDadosCroqui(
        metadadosDisponiveis: const [],
        croquisBaixados: [
          Croqui(
            id: 'br_mg_igarape_pedra_grande',
            nome: 'Pedra Grande',
            caminhoThumbnail: 'thumbnails/croqui.webp',
          ),
        ],
        picosDisponiveis: const [],
        picosBaixados: const [],
      );

      final grupoComCapa = Grupo(
        uid: 'uidGrupo000001',
        nome: 'Grupo Sherpa',
        caminhoImagemCapa: 'capas/sherpa.webp',
        setores: [
          ArquivoSetor(
            conteudo: Setor(
              nome: 'SubSetor A',
              escaladas: [Escalada(viaMovel: ViaMovel(nome: 'Fissura'))],
            ),
          ),
        ],
      );

      final dadosCapa = DadosCartaoCompartilhamento.deGrupo(
        idCroqui: 'br_mg_igarape_pedra_grande',
        grupo: grupoComCapa,
      );

      expect(dadosCapa.tipoEntidade, TipoEntidadeCompartilhavel.grupo);
      expect(dadosCapa.titulo, 'Grupo Sherpa');
      expect(dadosCapa.subtituloLocalizacao, 'Pedra Grande');
      expect(dadosCapa.etiquetaCategoria, 'GRUPO DE SETORES');
      expect(dadosCapa.caminhoImagemHeroi, 'capas/sherpa.webp');
      expect(dadosCapa.chipsResumo, contains('1 setor'));
      expect(dadosCapa.chipsResumo, contains('1 escalada'));
      expect(dadosCapa.nomeGrupo, 'Grupo Sherpa');

      final grupoFallbackSetor = Grupo(
        uid: 'uidGrupo000002',
        nome: 'Grupo Sem Capa',
        setores: [
          ArquivoSetor(
            conteudo: Setor(
              nome: 'Setor Filho',
              mapas: [
                Mapa(
                  caminhoImagemMapa: 'mapas/filho.webp',
                  larguraMapa: 600,
                  alturaMapa: 400,
                ),
              ],
            ),
          ),
        ],
      );
      expect(
        DadosCartaoCompartilhamento.deGrupo(
          idCroqui: 'br_mg_igarape_pedra_grande',
          grupo: grupoFallbackSetor,
        ).caminhoImagemHeroi,
        'mapas/filho.webp',
      );

      final grupoFallbackCroqui = Grupo(
        uid: 'uidGrupo000003',
        nome: 'Grupo Só Thumbnail',
      );
      expect(
        DadosCartaoCompartilhamento.deGrupo(
          idCroqui: 'br_mg_igarape_pedra_grande',
          grupo: grupoFallbackCroqui,
        ).caminhoImagemHeroi,
        'thumbnails/croqui.webp',
      );
    });

    test('deSetor calcula faixa de graus ordenada, modalidades e cascata de imagem', () {
      final setor = Setor(
        uid: 'uidSetor000001',
        nome: 'Setor Principal',
        mapas: [
          Mapa(
            caminhoImagemMapa: 'mapas/setor.webp',
            larguraMapa: 1000,
            alturaMapa: 750,
          ),
        ],
        escaladas: [
          Escalada(
            viaEsportiva: ViaEsportiva(
              nome: 'Fácil',
              dificuldade: GrauVia_GrauVia.BR_5,
            ),
          ),
          Escalada(
            viaEsportiva: ViaEsportiva(
              nome: 'Dura',
              dificuldade: GrauVia_GrauVia.BR_7B,
            ),
          ),
          Escalada(
            viaEsportiva: ViaEsportiva(
              nome: 'Projeto Aberto',
              dificuldade: GrauVia_GrauVia.PROJETO,
            ),
          ),
        ],
      );

      final dados = DadosCartaoCompartilhamento.deSetor(
        idCroqui: 'crag_x',
        setor: setor,
        grupoContext: Grupo(
          nome: 'Grupo Sul',
          caminhoImagemCapa: 'capas/grupo.webp',
        ),
        nomePicoPreferencial: 'Serra do Cipó',
      );

      expect(dados.tipoEntidade, TipoEntidadeCompartilhavel.setor);
      expect(dados.titulo, 'Setor Principal');
      expect(dados.subtituloLocalizacao, 'Serra do Cipó • Grupo Sul');
      expect(dados.etiquetaCategoria, 'SETOR DE ESCALADA');
      expect(dados.caminhoImagemHeroi, 'mapas/setor.webp');
      expect(dados.chipsResumo, contains('3 escaladas'));
      expect(dados.chipsResumo, contains('Graus 5º – 7b'));
      expect(dados.nomeSetor, 'Setor Principal');
      expect(dados.nomePico, 'Serra do Cipó');

      final setorGrauUnico = Setor(
        uid: 'uidSetor000002',
        nome: 'Setor Isolado',
        escaladas: [
          Escalada(boulder: Boulder(nome: 'B1', dificuldade: GrauBoulder_GrauBoulder.V3)),
        ],
      );
      final dadosUnico = DadosCartaoCompartilhamento.deSetor(
        idCroqui: 'crag_x',
        setor: setorGrauUnico,
        grupoContext: Grupo(
          nome: 'Grupo Sul',
          caminhoImagemCapa: 'capas/grupo.webp',
        ),
        nomePicoPreferencial: 'Serra do Cipó',
      );
      expect(dadosUnico.caminhoImagemHeroi, 'capas/grupo.webp');
      expect(dadosUnico.chipsResumo, contains('Graus v3'));
    });

    test('deEscalada consolida grau, clássica, rótulo de linha, atributos, selo pessoal e cascata de imagem', () {
      final escalada = Escalada(
        uid: 'uidVia00000001',
        viaEsportiva: ViaEsportiva(
          nome: 'Aresta Clássica',
          dificuldade: GrauVia_GrauVia.BR_6SUP,
          destaque: true,
          extensao: 24,
          quantidadeProtecoesIntermediarias: 8,
          quantidadeProtecoesParada: 2,
          tipoAncoragem: 'Parada dupla com argolas',
        ),
      );

      final dados = DadosCartaoCompartilhamento.deEscalada(
        idCroqui: 'br_mg_igarape_pedra_grande',
        escalada: escalada,
        pico: Pico(nome: 'Pedra Grande'),
        setor: Setor(nome: 'Setor Principal'),
        estadoCroqui: EstadoCroquiVia(
          mapasMiniatura: [
            Mapa(
              caminhoImagemMapa: 'mapas/via_topo.webp',
              larguraMapa: 900,
              alturaMapa: 600,
            ),
          ],
          rotuloLinhaNoMapa: '4',
        ),
        seloPessoal: const SeloPessoalCompartilhamento(
          ehCadena: true,
          textoResumo: 'Encadenada em 14/09 (Flash)',
        ),
      );

      expect(dados.tipoEntidade, TipoEntidadeCompartilhavel.via);
      expect(dados.uid, 'uidVia00000001');
      expect(dados.titulo, 'Aresta Clássica');
      expect(dados.grauDestaque, '6ºsup');
      expect(dados.ehClassica, isTrue);
      expect(dados.etiquetaCategoria, 'ESPORTIVA');
      expect(dados.subtituloLocalizacao, 'Pedra Grande • Setor Principal');
      expect(dados.caminhoImagemHeroi, 'mapas/via_topo.webp');
      expect(dados.rotuloLinhaNoMapa, '4');
      expect(dados.seloPessoal?.ehCadena, isTrue);
      expect(dados.seloPessoal?.textoResumo, 'Encadenada em 14/09 (Flash)');
      expect(dados.chipsResumo, containsAll(['24m', '8+2']));
      expect(dados.chipsResumo, contains('Parada dupla com argolas'));
    });

    test('deEscalada recorre à capa do setor/croqui quando não há mapa e omite setor Geral do subtítulo', () {
      final escalada = Escalada(
        uid: 'uidViaGeral001',
        viaMultiplasEnfiadas: ViaMultiplasEnfiadas(
          nome: 'Grande Diedro',
          dificuldadeMaxima: GrauVia_GrauVia.BR_7A,
        ),
      );

      final dados = DadosCartaoCompartilhamento.deEscalada(
        idCroqui: 'br_rj_dedo',
        escalada: escalada,
        pico: Pico(nome: 'Dedo de Deus'),
        setor: Setor(nome: 'Geral'),
        croqui: Croqui(
          id: 'br_rj_dedo',
          nome: 'Dedo de Deus',
          caminhoThumbnail: 'thumbnails/dedo.webp',
        ),
      );

      expect(dados.subtituloLocalizacao, 'Dedo de Deus');
      expect(dados.caminhoImagemHeroi, 'thumbnails/dedo.webp');
      expect(dados.nomeSetor, 'Geral');
    });

    test('deEscalada cobre fallback de modalidade notSet, capa de setor/grupo e thumbnail de sessão online', () {
      final repo = DatasetRepository(editorDeCroqui: EditorDeCroqui());
      repo.gerenciadorSessaoOnline.registrarCroquiOnline(
        'crag_online_thumb',
        Croqui(
          id: 'crag_online_thumb',
          nome: 'Pico Online',
          caminhoThumbnail: 'thumbnails/online.webp',
        ),
      );

      final escaladaSemTipo = Escalada(uid: 'uidSemTipo0001');

      final comCapaSetor = DadosCartaoCompartilhamento.deEscalada(
        idCroqui: 'crag_online_thumb',
        escalada: escaladaSemTipo,
        setor: Setor(
          nome: 'Setor Com Capa',
          caminhoImagemCapa: 'capas/setor_via.webp',
        ),
      );
      expect(comCapaSetor.etiquetaCategoria, isNotEmpty);
      expect(comCapaSetor.caminhoImagemHeroi, 'capas/setor_via.webp');

      final comCapaGrupo = DadosCartaoCompartilhamento.deEscalada(
        idCroqui: 'crag_online_thumb',
        escalada: escaladaSemTipo,
        setor: Setor(nome: 'Setor Sem Capa'),
        grupo: Grupo(
          nome: 'Grupo Com Capa',
          caminhoImagemCapa: 'capas/grupo_via.webp',
        ),
      );
      expect(comCapaGrupo.caminhoImagemHeroi, 'capas/grupo_via.webp');

      final comThumbOnline = DadosCartaoCompartilhamento.deEscalada(
        idCroqui: 'crag_online_thumb',
        escalada: escaladaSemTipo,
      );
      expect(comThumbOnline.caminhoImagemHeroi, 'thumbnails/online.webp');

      final grupoComCroqui = DadosCartaoCompartilhamento.deGrupo(
        idCroqui: 'crag_sem_cache',
        grupo: Grupo(uid: 'uidG', nome: 'Grupo C'),
        croqui: Croqui(
          picos: [Pico(nome: 'Pico Via Croqui')],
          caminhoThumbnail: 'thumbnails/grupo_via_croqui.webp',
        ),
      );
      expect(grupoComCroqui.nomePico, 'Pico Via Croqui');
      expect(grupoComCroqui.caminhoImagemHeroi, 'thumbnails/grupo_via_croqui.webp');

      final setorFallbackCroqui = DadosCartaoCompartilhamento.deSetor(
        idCroqui: 'crag_sem_cache',
        setor: Setor(uid: 'uidS', nome: 'Setor D'),
        croqui: Croqui(caminhoThumbnail: 'thumbnails/setor_via_croqui.webp'),
      );
      expect(setorFallbackCroqui.caminhoImagemHeroi, 'thumbnails/setor_via_croqui.webp');
    });
  });
}
