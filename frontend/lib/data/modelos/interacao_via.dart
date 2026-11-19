// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

/// Categorias canônicas de alerta de segurança estilo Waze nas vias e setores.
///
/// Espelha exatamente os valores permitidos pela restrição `chk_fila_categoria_alerta`
/// na tabela `public.fila_interacoes` do Supabase, associando a cada categoria o emoji
/// renderizado na bolha vermelha flutuante da `ViaPage`.
enum CategoriaAlertaSeguranca {
  /// Enxame ou colmeia de abelhas, marimbondos ou vespas na linha da via.
  abelhasInsetos(
    codigoBanco: 'ABELHAS_INSETOS',
    emoji: '🐝',
    rotulo: 'Abelhas ou Insetos',
    descricaoCurta: 'Colmeia, marimbondos ou enxame ativo próximo à via.',
  ),

  /// Bloco solto, laca oca ou agarra quebrando na linha de escalada.
  rochaAgarraInstavel(
    codigoBanco: 'ROCHA_AGARRA_INSTAVEL',
    emoji: '🪨',
    rotulo: 'Rocha ou Agarra Instável',
    descricaoCurta: 'Bloco solto, laca perigosa ou agarra prestes a quebrar.',
  ),

  /// Chapeleta girando, grampo oxidado, porca frouxa ou parada comprometida.
  protecaoPrecaria(
    codigoBanco: 'PROTECAO_PRECARIA',
    emoji: '🔩',
    rotulo: 'Proteção Precária',
    descricaoCurta: 'Chapeleta solta, corrosão severa ou ancoragem danificada.',
  ),

  /// Infiltração, ressurgência de água ou agarras escorregadias na via.
  viaMolhada(
    codigoBanco: 'VIA_MOLHADA',
    emoji: '💧',
    rotulo: 'Via Molhada',
    descricaoCurta: 'Infiltração ativa ou parede úmida e escorregadia.',
  ),

  /// Queda potencial no chão, lance exposto sem proteção ou acesso interditado.
  riscoExposicao(
    codigoBanco: 'RISCO_EXPOSICAO',
    emoji: '⚠️',
    rotulo: 'Risco de Exposição',
    descricaoCurta: 'Lance exposto, risco de queda no chão ou acesso restrito.',
  );

  /// Identificador textual persistido em `public.fila_interacoes.categoria_alerta`.
  final String codigoBanco;

  /// Emoji exibido dentro da bolha vermelha de alerta na tela da via.
  final String emoji;

  /// Título legível em português exibido nos modais de confirmação e relato.
  final String rotulo;

  /// Explicação concisa auxiliando o escalador na escolha rápida na base da falésia.
  final String descricaoCurta;

  const CategoriaAlertaSeguranca({
    required this.codigoBanco,
    required this.emoji,
    required this.rotulo,
    required this.descricaoCurta,
  });

  /// Converte o [codigo] proveniente do banco ou YAML na [CategoriaAlertaSeguranca] correspondente.
  static CategoriaAlertaSeguranca deCodigoBanco(String codigo) {
    for (final item in CategoriaAlertaSeguranca.values) {
      if (item.codigoBanco == codigo) {
        return item;
      }
    }
    throw ArgumentError.value(
      codigo,
      'codigo',
      'Categoria de alerta de segurança desconhecida.',
    );
  }
}
