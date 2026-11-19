// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/foundation.dart';
import '../../utils/gerador_uid.dart';
import 'perfil_escalador.dart';

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

/// Representa um alerta ativo de segurança estilo Waze vinculado a uma escalada.
///
/// Projetado para ser exibido como uma bolha vermelha compacta no canto superior
/// direito do croqui/cartão de grau e confirmado rapidamente via *"Ainda está lá?"*.
@immutable
class AlertaSegurancaVia {
  /// Limite máximo de caracteres para detalhes opcionais do alerta (`chk_fila_interacoes_payload_por_tipo`).
  static const int limiteCaracteresDetalhe = 100;

  /// Identificador único NanoID 14c do alerta.
  final String uid;

  /// Identificador único NanoID 14c da escalada associada.
  final String escaladaUid;

  /// Categoria semântica do risco reportado.
  final CategoriaAlertaSeguranca categoria;

  /// Observação complementar opcional (máximo de 100 caracteres).
  final String? detalhe;

  /// Apelido público do escalador que reportou o alerta.
  final String autorNomePublico;

  /// Instante em que o alerta foi registrado.
  final DateTime criadoEm;

  /// Total acumulado de confirmações *"Ainda está lá?"* positivas.
  final int confirmacoesAtivas;

  /// Cria uma instância imutável de [AlertaSegurancaVia].
  const AlertaSegurancaVia({
    required this.uid,
    required this.escaladaUid,
    required this.categoria,
    this.detalhe,
    required this.autorNomePublico,
    required this.criadoEm,
    this.confirmacoesAtivas = 1,
  });

  /// Fábrica validada que gera um NanoID 14c e normaliza os campos textuais sob filosofia Fail-Fast.
  factory AlertaSegurancaVia.criar({
    String? uid,
    required String escaladaUid,
    required CategoriaAlertaSeguranca categoria,
    String? detalhe,
    String? autorNomePublico,
    DateTime? criadoEm,
    int confirmacoesAtivas = 1,
  }) {
    final detalheLimpo = detalhe?.trim();
    if (detalheLimpo != null && detalheLimpo.length > limiteCaracteresDetalhe) {
      throw ArgumentError.value(
        detalheLimpo.length,
        'detalhe',
        'O detalhe do alerta deve ter no máximo $limiteCaracteresDetalhe caracteres.',
      );
    }
    final nomeLimpo = autorNomePublico?.trim();

    return AlertaSegurancaVia(
      uid: uid ?? gerarUid(),
      escaladaUid: escaladaUid,
      categoria: categoria,
      detalhe: (detalheLimpo != null && detalheLimpo.isNotEmpty)
          ? detalheLimpo
          : null,
      autorNomePublico: (nomeLimpo != null && nomeLimpo.isNotEmpty)
          ? nomeLimpo
          : PerfilEscalador.apelidoPadrao,
      criadoEm: criadoEm ?? DateTime.now(),
      confirmacoesAtivas: confirmacoesAtivas,
    );
  }

  /// Retorna uma nova cópia com os campos informados atualizados.
  AlertaSegurancaVia copyWith({
    String? detalhe,
    int? confirmacoesAtivas,
  }) {
    return AlertaSegurancaVia(
      uid: uid,
      escaladaUid: escaladaUid,
      categoria: categoria,
      detalhe: detalhe ?? this.detalhe,
      autorNomePublico: autorNomePublico,
      criadoEm: criadoEm,
      confirmacoesAtivas: confirmacoesAtivas ?? this.confirmacoesAtivas,
    );
  }
}
