// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Exceção lançada quando uma string de versão não adere ao formato SemVer esperado.
class SemverInvalidoException implements Exception {
  /// Mensagem explicativa do erro de validação.
  final String mensagem;

  SemverInvalidoException(this.mensagem);

  @override
  String toString() => 'SemverInvalidoException: $mensagem';
}

/// Representa a decomposição estruturada de uma versão semântica (SemVer 2.0.0)
/// com suporte aos metadados de build do Flutter (+build).
class SemverInfo {
  /// Dígito de versão maior (breaking changes).
  final int maior;

  /// Dígito de versão menor (novas funcionalidades compatíveis).
  final int menor;

  /// Dígito de correção ou patch (correções de bugs).
  final int correcao;

  /// Identificador opcional de pré-lançamento (ex: 'dev', 'alpha.1').
  final String? preRelease;

  /// Número de build sequencial do Flutter (ex: 67 em 0.2.4+67).
  final int? build;

  const SemverInfo({
    required this.maior,
    required this.menor,
    required this.correcao,
    this.preRelease,
    this.build,
  });

  /// Indica se a versão representa um ciclo de desenvolvimento ativo.
  bool get ehDev => preRelease != null && preRelease!.isNotEmpty;

  /// Retorna a versão semântica pura no formato `MAJOR.MINOR.PATCH`.
  String get semverBase => '$maior.$menor.$correcao';

  /// Retorna a versão com o pré-release caso exista (ex: `0.1.4-dev`).
  String get versaoComPreRelease =>
      ehDev ? '$semverBase-$preRelease' : semverBase;

  /// Retorna a versão completa com build caso exista (ex: `0.1.4-dev+10`).
  String get versaoCompleta {
    final base = versaoComPreRelease;
    return build != null ? '$base+$build' : base;
  }
}

/// Biblioteca utilitária para validação, comparação e cálculo de versões
/// semânticas no pipeline de lançamento do aplicativo Aresta.
class GerenciadorSemver {
  /// Expressão regular em conformidade com o padrão SemVer 2.0.0 e sufixo +build do Flutter.
  static final RegExp _padraoSemver = RegExp(
    r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([a-zA-Z0-9.-]+))?(?:\+([0-9]+))?$',
  );

  /// Decompõe uma string de versão em um objeto [SemverInfo].
  ///
  /// Lança [SemverInvalidoException] se a versão informada for inválida.
  static SemverInfo decompor(String versao) {
    final versaoLimpa = versao.trim();
    final match = _padraoSemver.firstMatch(versaoLimpa);

    if (match == null) {
      throw SemverInvalidoException(
        'A versão "$versao" não é uma versão SemVer válida. '
        'Formato esperado: MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD].',
      );
    }

    final maior = int.parse(match.group(1)!);
    final menor = int.parse(match.group(2)!);
    final correcao = int.parse(match.group(3)!);
    final preRelease = match.group(4);
    final buildStr = match.group(5);
    final build = buildStr != null ? int.parse(buildStr) : null;

    return SemverInfo(
      maior: maior,
      menor: menor,
      correcao: correcao,
      preRelease: preRelease,
      build: build,
    );
  }

  /// Valida se uma versão atende às regras de formato SemVer.
  ///
  /// Lança [SemverInvalidoException] em caso de formato inválido.
  static void validarSemver(String versao) {
    decompor(versao);
  }

  /// Compara duas versões semânticas segundo as regras de precedência da SemVer 2.0.0.
  ///
  /// Retorna um valor negativo se [v1] < [v2], zero se [v1] == [v2], ou positivo se [v1] > [v2].
  /// Metadados de build (+build) são intencionalmente ignorados conforme especificação SemVer.
  static int compararSemver(String v1, String v2) {
    final info1 = decompor(v1);
    final info2 = decompor(v2);

    if (info1.maior != info2.maior) {
      return info1.maior.compareTo(info2.maior);
    }
    if (info1.menor != info2.menor) {
      return info1.menor.compareTo(info2.menor);
    }
    if (info1.correcao != info2.correcao) {
      return info1.correcao.compareTo(info2.correcao);
    }

    // Regra SemVer: versão sem pré-release possui maior precedência que com pré-release.
    final pre1 = info1.preRelease;
    final pre2 = info2.preRelease;

    if (pre1 == pre2) return 0;
    if (pre1 == null && pre2 != null) return 1;
    if (pre1 != null && pre2 == null) return -1;

    // Se ambos têm pré-release, comparar identificadores
    return _compararPreReleases(pre1!, pre2!);
  }

  /// Compara dois identificadores de pré-release separados por ponto.
  static int _compararPreReleases(String pre1, String pre2) {
    final partes1 = pre1.split('.');
    final partes2 = pre2.split('.');
    final minLen = partes1.length < partes2.length ? partes1.length : partes2.length;

    for (var i = 0; i < minLen; i++) {
      final p1 = partes1[i];
      final p2 = partes2[i];
      if (p1 == p2) continue;

      final n1 = int.tryParse(p1);
      final n2 = int.tryParse(p2);

      if (n1 != null && n2 != null) {
        return n1.compareTo(n2);
      }
      if (n1 != null && n2 == null) {
        return -1; // numérico tem menor precedência que textual
      }
      if (n1 == null && n2 != null) {
        return 1;
      }
      return p1.compareTo(p2);
    }

    return partes1.length.compareTo(partes2.length);
  }

  /// Calcula a versão oficial estável de release baseando-se na versão atual
  /// e no tipo de incremento solicitado ('patch', 'minor', 'major', 'custom').
  ///
  /// Se [tipo] for 'patch' e a versão atual já estiver em modo `-dev` (ex: `0.1.4-dev`),
  /// a versão de lançamento será a versão estável correspondente (`0.1.4`), pois
  /// o patch já havia sido incrementado no início do ciclo de desenvolvimento.
  static String calcularVersaoRelease({
    required String versaoAtual,
    required String tipo,
    String? custom,
  }) {
    final info = decompor(versaoAtual);
    final tipoNormalizado = tipo.trim().toLowerCase();

    switch (tipoNormalizado) {
      case 'patch':
        if (info.ehDev) {
          return info.semverBase;
        }
        return '${info.maior}.${info.menor}.${info.correcao + 1}';

      case 'minor':
        return '${info.maior}.${info.menor + 1}.0';

      case 'major':
        return '${info.maior + 1}.0.0';

      case 'custom':
        if (custom == null || custom.trim().isEmpty) {
          throw ArgumentError(
            'A versão customizada é obrigatória quando o tipo for "custom".',
          );
        }
        final versaoCustom = custom.trim();
        validarSemver(versaoCustom);

        // A versão customizada deve ser estritamente maior que a versão base atual
        if (compararSemver(versaoCustom, info.semverBase) <= 0 ||
            compararSemver(versaoCustom, info.versaoComPreRelease) <= 0) {
          throw ArgumentError(
            'A versão customizada ($versaoCustom) deve ser estritamente maior '
            'que a versão atual (${info.versaoComPreRelease}).',
          );
        }
        return decompor(versaoCustom).semverBase;

      default:
        throw ArgumentError(
          'Tipo de incremento inválido: "$tipo". Opções válidas: patch, minor, major, custom.',
        );
    }
  }

  /// Calcula a próxima versão de desenvolvimento contínuo (-dev) a partir de uma
  /// versão estável recém-lançada.
  ///
  /// Exemplo: para um release `0.1.4`, o próximo ciclo em `main` será `0.1.5-dev`.
  static String calcularProximoDev(String versaoLancada) {
    final info = decompor(versaoLancada);
    final proximoPatch = info.correcao + 1;
    return '${info.maior}.${info.menor}.$proximoPatch-dev';
  }
}
