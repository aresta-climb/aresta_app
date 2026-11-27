// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../data/modelos/interacao_via.dart';
import '../../idioma/tradutor_app.dart';
import '../../theme/cores_app.dart';

const Color _corDestaqueCriado = Color(0xFFD93829);

/// Seção declarativa (Dumb UI) da `CadernetaPage` exibindo os alertas de segurança criados
/// (`CRIADO POR VOCÊ`) e confirmados (`CONFIRMADO (+1)`) pelo escalador para acesso rápido.
class SecaoMeusAlertasCaderneta extends StatelessWidget {
  /// Título formatado da seção (ex.: `'Meus Alertas na Rocha (2)'`).
  final String tituloSecao;

  /// Lista de alertas criados ou confirmados pelo usuário (ativos primeiro).
  final List<AlertaContribuidoCaderneta> alertas;

  /// Resolvedor do nome legível da escalada a partir de seu `escaladaUid`.
  final String Function(String escaladaUid) obterNomeVia;

  /// Resolvedor opcional do grau da escalada a partir de seu `escaladaUid`.
  final String? Function(String escaladaUid) obterGrauVia;

  /// Formatador de data curta (`DD/MM/AAAA`).
  final String Function(DateTime data) formatarData;

  /// Callback acionado ao tocar no cartão para abrir a página da via.
  final ValueChanged<String> aoTocarVia;

  /// Callback acionado ao marcar rapidamente um alerta ativo como resolvido.
  final ValueChanged<AlertaContribuidoCaderneta> aoResolverAlerta;

  /// Callback opcional acionado pelo autor para editar categoria/detalhe de um alerta ativo criado por ele.
  final ValueChanged<AlertaContribuidoCaderneta>? aoEditarAlerta;

  /// Callback opcional acionado pelo autor para excluir permanentemente um alerta ativo criado por ele.
  final ValueChanged<AlertaContribuidoCaderneta>? aoExcluirAlerta;

  /// Cria uma instância de [SecaoMeusAlertasCaderneta].
  const SecaoMeusAlertasCaderneta({
    super.key,
    required this.tituloSecao,
    required this.alertas,
    required this.obterNomeVia,
    required this.obterGrauVia,
    required this.formatarData,
    required this.aoTocarVia,
    required this.aoResolverAlerta,
    this.aoEditarAlerta,
    this.aoExcluirAlerta,
  });

  @override
  Widget build(BuildContext context) {
    if (alertas.isEmpty) {
      return const SizedBox.shrink();
    }
    final cores = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tituloSecao,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: cores.chalkWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: alertas.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = alertas[index];
              final ehMeuAtivo =
                  item.ativo &&
                  item.papel == PapelContribuicaoAlerta.criadoPorMim;
              return _CartaoMeuAlertaCaderneta(
                item: item,
                nomeVia: obterNomeVia(item.alerta.escaladaUid),
                grauVia: obterGrauVia(item.alerta.escaladaUid),
                dataFormatada: formatarData(item.ultimaInteracaoEm),
                aoTocar: () => aoTocarVia(item.alerta.escaladaUid),
                aoResolver: item.ativo ? () => aoResolverAlerta(item) : null,
                aoEditar: ehMeuAtivo && aoEditarAlerta != null
                    ? () => aoEditarAlerta!(item)
                    : null,
                aoExcluir: ehMeuAtivo && aoExcluirAlerta != null
                    ? () => aoExcluirAlerta!(item)
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CartaoMeuAlertaCaderneta extends StatelessWidget {
  final AlertaContribuidoCaderneta item;
  final String nomeVia;
  final String? grauVia;
  final String dataFormatada;
  final VoidCallback aoTocar;
  final VoidCallback? aoResolver;
  final VoidCallback? aoEditar;
  final VoidCallback? aoExcluir;

  const _CartaoMeuAlertaCaderneta({
    required this.item,
    required this.nomeVia,
    required this.grauVia,
    required this.dataFormatada,
    required this.aoTocar,
    required this.aoResolver,
    this.aoEditar,
    this.aoExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    final alerta = item.alerta;
    final criadoPorMim = item.papel == PapelContribuicaoAlerta.criadoPorMim;
    final corPapel = criadoPorMim ? _corDestaqueCriado : cores.mossRock;
    final textoStatus = item.ativo
        ? (alerta.confirmacoesAtivas == 1
              ? context.tr(ChaveTexto.alertaAtivoUmConfirmacao)
              : context.tr(ChaveTexto.alertaAtivoVariasConfirmacoes, {
                  'n': '${alerta.confirmacoesAtivas}',
                }))
        : context.tr(ChaveTexto.alertaResolvidoStatus);

    return Opacity(
      opacity: item.ativo ? 1.0 : 0.68,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('item_meu_alerta_${alerta.uid}'),
          onTap: aoTocar,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cores.caveShadow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: item.ativo
                    ? corPapel.withValues(alpha: 0.45)
                    : cores.graniteEdge,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: corPapel.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: corPapel.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            criadoPorMim
                                ? Icons.flag_rounded
                                : Icons.verified_outlined,
                            size: 12,
                            color: criadoPorMim
                                ? const Color(0xFFFCA5A5)
                                : cores.mossRock,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              item.papel.rotuloSelo,
                              style: TextStyle(
                                color: criadoPorMim
                                    ? const Color(0xFFFCA5A5)
                                    : cores.mossRock,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      textoStatus,
                      style: TextStyle(
                        color: item.ativo ? cores.chalkWhite : cores.ashGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alerta.categoria.emoji,
                      style: const TextStyle(fontSize: 20, height: 1.1),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                nomeVia,
                                style: TextStyle(
                                  color: cores.chalkWhite,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (grauVia != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cores.deepBasalt,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    grauVia!,
                                    style: TextStyle(
                                      color: cores.rustIron,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${alerta.categoria.rotulo} • $dataFormatada',
                            style: TextStyle(
                              color: cores.ashGrey,
                              fontSize: 12,
                            ),
                          ),
                          if (alerta.detalhe != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '“${alerta.detalhe}”',
                              style: TextStyle(
                                color: cores.chalkWhite,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (aoResolver != null ||
                    aoEditar != null ||
                    aoExcluir != null) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (aoEditar != null)
                        IconButton(
                          key: Key('btn_editar_meu_alerta_${alerta.uid}'),
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 17,
                            color: cores.ashGrey,
                          ),
                          tooltip: context.tr(ChaveTexto.alertaEditarBtn),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          visualDensity: VisualDensity.compact,
                          onPressed: aoEditar,
                        ),
                      if (aoExcluir != null)
                        IconButton(
                          key: Key('btn_excluir_meu_alerta_${alerta.uid}'),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 17,
                            color: _corDestaqueCriado,
                          ),
                          tooltip: context.tr(ChaveTexto.alertaExcluirBtn),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          visualDensity: VisualDensity.compact,
                          onPressed: aoExcluir,
                        ),
                      if (aoResolver != null)
                        OutlinedButton.icon(
                          key: Key('btn_resolver_meu_alerta_${alerta.uid}'),
                          onPressed: aoResolver,
                          icon: Icon(
                            Icons.check_circle_outline_rounded,
                            size: 15,
                            color: cores.fernGreen,
                          ),
                          label: Text(
                            context.tr(ChaveTexto.alertaMarcarResolvido),
                            style: TextStyle(
                              color: cores.chalkWhite,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: cores.graniteEdge),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
