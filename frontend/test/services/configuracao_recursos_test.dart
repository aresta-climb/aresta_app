// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/configuracao_recursos.dart';

void main() {
  group('ConfiguracaoRecursos', () {
    tearDown(() {
      ConfiguracaoRecursos.redefinirParaTestes();
    });

    test('por padrão em ambiente de teste, perfilHabilitado deve ser falso', () {
      expect(ConfiguracaoRecursos.perfilHabilitado, isFalse);
    });

    test('permite sobrescrita para testes via definirSobrescritaPerfilParaTestes', () {
      ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);
      expect(ConfiguracaoRecursos.perfilHabilitado, isTrue);

      ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(false);
      expect(ConfiguracaoRecursos.perfilHabilitado, isFalse);

      ConfiguracaoRecursos.redefinirParaTestes();
      expect(ConfiguracaoRecursos.perfilHabilitado, isFalse);
    });

    test('validarChaveAcesso valida chaves secretas autorizadas', () {
      // Chaves autorizadas
      expect(ConfiguracaoRecursos.validarChaveAcesso('my_secret_key'), isTrue);
      expect(ConfiguracaoRecursos.validarChaveAcesso('aresta_segredo_perfil_2026'), isTrue);
      expect(ConfiguracaoRecursos.validarChaveAcesso('minha_chave_secreta'), isTrue);
      expect(ConfiguracaoRecursos.validarChaveAcesso('aresta_dev_secret'), isTrue);

      // Chaves inválidas ou vazias
      expect(ConfiguracaoRecursos.validarChaveAcesso(''), isFalse);
      expect(ConfiguracaoRecursos.validarChaveAcesso('   '), isFalse);
      expect(ConfiguracaoRecursos.validarChaveAcesso(null), isFalse);
      expect(ConfiguracaoRecursos.validarChaveAcesso('chave_qualquer'), isFalse);
      expect(ConfiguracaoRecursos.validarChaveAcesso('123456'), isFalse);
    });

    test('validarChaveAcesso ignora espaços em branco nas extremidades', () {
      expect(ConfiguracaoRecursos.validarChaveAcesso('  my_secret_key  '), isTrue);
      expect(ConfiguracaoRecursos.validarChaveAcesso(' aresta_segredo_perfil_2026 '), isTrue);
    });

    test('chavesSecretasAutorizadas contém as chaves padronizadas de desenvolvimento', () {
      expect(
        ConfiguracaoRecursos.chavesSecretasAutorizadas,
        containsAll([
          'my_secret_key',
          'aresta_segredo_perfil_2026',
          'minha_chave_secreta',
          'aresta_dev_secret',
        ]),
      );
    });

    test('validarChaveAcesso é estritamente sensível a maiúsculas e minúsculas', () {
      expect(ConfiguracaoRecursos.validarChaveAcesso('MY_SECRET_KEY'), isFalse);
      expect(ConfiguracaoRecursos.validarChaveAcesso('Aresta_Segredo_Perfil_2026'), isFalse);
      expect(ConfiguracaoRecursos.validarChaveAcesso('MINHA_CHAVE_SECRETA'), isFalse);
    });

    test('validarChaveAcesso rejeita chaves contendo caracteres extras no prefixo ou sufixo', () {
      expect(ConfiguracaoRecursos.validarChaveAcesso('my_secret_key_adicional'), isFalse);
      expect(ConfiguracaoRecursos.validarChaveAcesso('prefixo_my_secret_key'), isFalse);
      expect(ConfiguracaoRecursos.validarChaveAcesso('my_secret_key;'), isFalse);
    });

    test('validarChaveAcesso aceita tabulações e quebras de linha nas extremidades ao fazer trim', () {
      expect(ConfiguracaoRecursos.validarChaveAcesso('\tmy_secret_key\n'), isTrue);
      expect(ConfiguracaoRecursos.validarChaveAcesso('\n\raresta_dev_secret\t'), isTrue);
      expect(ConfiguracaoRecursos.validarChaveAcesso('\t \n \r'), isFalse);
    });

    test('getters modoApp e chaveAcessoDefinida retornam strings vazias no ambiente padrão de testes', () {
      expect(ConfiguracaoRecursos.modoApp, isEmpty);
      expect(ConfiguracaoRecursos.chaveAcessoDefinida, isEmpty);
    });

    test('redefinirParaTestes restaura o estado padrão mesmo após múltiplas alternâncias', () {
      ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);
      expect(ConfiguracaoRecursos.perfilHabilitado, isTrue);

      ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(false);
      expect(ConfiguracaoRecursos.perfilHabilitado, isFalse);

      ConfiguracaoRecursos.definirSobrescritaPerfilParaTestes(true);
      expect(ConfiguracaoRecursos.perfilHabilitado, isTrue);

      ConfiguracaoRecursos.redefinirParaTestes();
      expect(ConfiguracaoRecursos.perfilHabilitado, isFalse);
    });
  });
}
