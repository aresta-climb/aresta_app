// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/aresta_api/proto/generated/croqui.pb.dart';
import 'package:frontend/utils/resolvedor_rotulos_referencia.dart';

void main() {
  group('extrairRotuloReferencia', () {
    test('retorna vazio se ref.pontosUids for vazio', () {
      final mapa = Mapa();
      final ref = Mapa_Referencia(alvoUid: 'esc-1');
      expect(extrairRotuloReferencia(mapa, ref), '');
    });

    test('retorna rótulo de POI convencional com rotulo', () {
      final mapa = Mapa(
        pontosDeInteresse: [
          Mapa_PontoDeInteresse(
            uid: 'p1',
            rotulo: '12',
            circulo: BoundingCirculo(x: 10, y: 10, raio: 5),
          ),
        ],
      );
      final ref = Mapa_Referencia(pontosUids: ['p1']);
      expect(extrairRotuloReferencia(mapa, ref), '12');
    });

    test('retorna vazio se POI convencional tiver rotulo vazio (sem fallback para id ou uid)', () {
      final mapa = Mapa(
        pontosDeInteresse: [
          Mapa_PontoDeInteresse(
            uid: 'crayzy',
            rotulo: '',
            circulo: BoundingCirculo(x: 10, y: 10, raio: 5),
          ),
        ],
      );
      final ref = Mapa_Referencia(pontosUids: ['crayzy']);
      expect(extrairRotuloReferencia(mapa, ref), '');
    });

    test('ignora pontos referenciados que não existem no mapa', () {
      final mapa = Mapa(
        pontosDeInteresse: [
          Mapa_PontoDeInteresse(
            uid: 'p1',
            rotulo: '7A',
            circulo: BoundingCirculo(x: 10, y: 10, raio: 5),
          ),
        ],
      );
      final ref = Mapa_Referencia(pontosUids: ['p-inexistente', 'p1']);
      expect(extrairRotuloReferencia(mapa, ref), '7A');
    });

    test('extrai início e top de caminho vetorial com múltiplos segmentos (ex: 5-C)', () {
      final mapa = Mapa(
        pontosDeInteresse: [
          Mapa_PontoDeInteresse(
            uid: 'linha_12',
            linha: LinhaTrajeto(
              compilado: DadosCompiladosLinha(
                marcadores: [
                  MarcadorCompilado(
                    tipo: NoTrajeto_TipoNo.CIRCULO_IDENTIFICADOR,
                    rotulo: '5',
                  ),
                ],
              ),
            ),
          ),
          Mapa_PontoDeInteresse(
            uid: 'linha_16',
            linha: LinhaTrajeto(
              compilado: DadosCompiladosLinha(
                marcadores: [
                  MarcadorCompilado(
                    tipo: NoTrajeto_TipoNo.PASSAGEM,
                    rotulo: '',
                  ),
                ],
              ),
            ),
          ),
          Mapa_PontoDeInteresse(
            uid: 'linha_21',
            linha: LinhaTrajeto(
              compilado: DadosCompiladosLinha(
                marcadores: [
                  MarcadorCompilado(
                    tipo: NoTrajeto_TipoNo.FIM_TOP,
                    rotulo: 'C',
                  ),
                ],
              ),
            ),
          ),
        ],
      );

      final ref = Mapa_Referencia(
        pontosUids: ['linha_12', 'linha_16', 'linha_21'],
        alvoUid: 'esc-polydance',
      );

      expect(extrairRotuloReferencia(mapa, ref), '5-C');
    });

    test('extrai múltiplos círculos identificadores intermediários na ordem em que aparecem', () {
      final mapa = Mapa(
        pontosDeInteresse: [
          Mapa_PontoDeInteresse(
            uid: 'linha_boulder',
            linha: LinhaTrajeto(
              compilado: DadosCompiladosLinha(
                marcadores: [
                  MarcadorCompilado(
                    tipo: NoTrajeto_TipoNo.INICIO_AGACHADO,
                    rotulo: 'SS',
                  ),
                  MarcadorCompilado(
                    tipo: NoTrajeto_TipoNo.CIRCULO_IDENTIFICADOR,
                    rotulo: '1',
                  ),
                  MarcadorCompilado(
                    tipo: NoTrajeto_TipoNo.FIM_TOP,
                    rotulo: 'TOP',
                  ),
                ],
              ),
            ),
          ),
        ],
      );

      final ref = Mapa_Referencia(pontosUids: ['linha_boulder']);
      expect(extrairRotuloReferencia(mapa, ref), 'SS-1-TOP');
    });

    test('funciona com linhas em modo de edição (conteudo.nos)', () {
      final mapa = Mapa(
        pontosDeInteresse: [
          Mapa_PontoDeInteresse(
            uid: 'linha_edit',
            linha: LinhaTrajeto(
              conteudo: DadosConteudoLinha(
                nos: [
                  NoTrajeto(
                    tipo: NoTrajeto_TipoNo.CIRCULO_IDENTIFICADOR,
                    rotulo: '7',
                  ),
                  NoTrajeto(
                    tipo: NoTrajeto_TipoNo.PASSAGEM,
                    rotulo: '',
                  ),
                  NoTrajeto(
                    tipo: NoTrajeto_TipoNo.FIM_TOP,
                    rotulo: 'B',
                  ),
                ],
              ),
            ),
          ),
        ],
      );

      final ref = Mapa_Referencia(pontosUids: ['linha_edit']);
      expect(extrairRotuloReferencia(mapa, ref), '7-B');
    });

    test('deduplica rótulos consecutivos idênticos de segmentos adjacentes', () {
      final mapa = Mapa(
        pontosDeInteresse: [
          Mapa_PontoDeInteresse(
            uid: 'seg_1',
            linha: LinhaTrajeto(
              compilado: DadosCompiladosLinha(
                marcadores: [
                  MarcadorCompilado(
                    tipo: NoTrajeto_TipoNo.CIRCULO_IDENTIFICADOR,
                    rotulo: '5',
                  ),
                ],
              ),
            ),
          ),
          Mapa_PontoDeInteresse(
            uid: 'seg_2',
            linha: LinhaTrajeto(
              compilado: DadosCompiladosLinha(
                marcadores: [
                  MarcadorCompilado(
                    tipo: NoTrajeto_TipoNo.CIRCULO_IDENTIFICADOR,
                    rotulo: '5',
                  ),
                  MarcadorCompilado(
                    tipo: NoTrajeto_TipoNo.FIM_TOP,
                    rotulo: 'A',
                  ),
                ],
              ),
            ),
          ),
        ],
      );

      final ref = Mapa_Referencia(pontosUids: ['seg_1', 'seg_2']);
      expect(extrairRotuloReferencia(mapa, ref), '5-A');
    });

    test('retorna vazio para linhas sem círculos identificadores (nunca expõe IDs técnicos)', () {
      final mapa = Mapa(
        pontosDeInteresse: [
          Mapa_PontoDeInteresse(
            uid: 'linha_curva_1',
            linha: LinhaTrajeto(
              compilado: DadosCompiladosLinha(
                marcadores: [
                  MarcadorCompilado(
                    tipo: NoTrajeto_TipoNo.PASSAGEM,
                    rotulo: '',
                  ),
                ],
              ),
            ),
          ),
          Mapa_PontoDeInteresse(
            uid: 'linha_curva_2',
            linha: LinhaTrajeto(
              compilado: DadosCompiladosLinha(
                marcadores: [
                  MarcadorCompilado(
                    tipo: NoTrajeto_TipoNo.PASSAGEM,
                    rotulo: '',
                  ),
                ],
              ),
            ),
          ),
        ],
      );

      final ref = Mapa_Referencia(pontosUids: ['linha_curva_1', 'linha_curva_2']);
      expect(extrairRotuloReferencia(mapa, ref), '');
    });
  });
}
