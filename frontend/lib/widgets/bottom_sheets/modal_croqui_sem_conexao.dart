// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';

import '../../services/catalogo/repositorio_catalogo.dart';
import '../../theme/cores_app.dart';
import '../../view/function_library/biblioteca_funcoes_comuns.dart';

/// Modal *bottom sheet* exibido quando o usuário tenta abrir (por Deep Link ou Busca Global)
/// uma escalada, setor, grupo ou pico cujo croqui não está salvo em `/downloads` nem
/// no cache volátil `/temp_cache` e o dispositivo está sem conexão à internet.
///
/// Apresenta os metadados da entidade e do croqui obtidos do `catalogo.db` (ou índice local)
/// e oferece um botão **"Tentar novamente"** que reexecuta a resolução *in-place*, fechando
/// o modal automaticamente caso a conexão tenha sido restabelecida ou exibindo um aviso
/// inline caso permaneça offline.
class ModalCroquiSemConexao extends StatefulWidget {
  /// Metadados da entidade e do croqui hospedeiro que o usuário tentou abrir.
  final ItemCatalogoBusca item;

  /// Ação assíncrona que tenta novamente abrir e navegar para o destino.
  /// Deve retornar `true` caso o croqui tenha sido carregado com sucesso.
  final Future<bool> Function() aoTentarNovamente;

  const ModalCroquiSemConexao({
    super.key,
    required this.item,
    required this.aoTentarNovamente,
  });

  /// Exibe o [ModalCroquiSemConexao] utilizando o navegador raiz (`useRootNavigator: true`).
  static Future<bool?> mostrar({
    required BuildContext context,
    required ItemCatalogoBusca item,
    required Future<bool> Function() aoTentarNovamente,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: context.colors.deepBasalt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ModalCroquiSemConexao(
        item: item,
        aoTentarNovamente: aoTentarNovamente,
      ),
    );
  }

  @override
  State<ModalCroquiSemConexao> createState() => _ModalCroquiSemConexaoState();
}

class _ModalCroquiSemConexaoState extends State<ModalCroquiSemConexao> {
  bool _tentandoConectar = false;
  bool _falhaAoTentarNovamente = false;

  String get _tituloEntidade {
    final item = widget.item;
    final grau = item.escaladaGrau ?? '';
    if (item.tipo == 'escalada' && grau.isNotEmpty) {
      return '${item.nome} ($grau)';
    }
    return item.nome;
  }

  String get _subtituloContexto {
    final item = widget.item;
    final partes = <String>[
      if ((item.setorNome ?? '').isNotEmpty) item.setorNome!,
      if ((item.grupoNome ?? '').isNotEmpty) item.grupoNome!,
      'Croqui ${item.picoNome}',
    ];
    final localPartes = <String>[
      if ((item.cidade ?? '').isNotEmpty) item.cidade!,
      if ((item.estado ?? '').isNotEmpty) item.estado!,
    ];
    if (localPartes.isNotEmpty) {
      partes.add(localPartes.join(', '));
    }
    return partes.join(' • ');
  }

  Future<void> _executarTentativa() async {
    setState(() {
      _tentandoConectar = true;
      _falhaAoTentarNovamente = false;
    });
    final sucesso = await widget.aoTentarNovamente();
    if (!mounted) return;
    if (sucesso) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _tentandoConectar = false;
        _falhaAoTentarNovamente = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nomeCroqui = widget.item.picoNome;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.graniteEdge,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC05244).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_off_rounded,
                          color: Color(0xFFC05244),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'VOCÊ ESTÁ SEM CONEXÃO',
                          style: TextStyle(
                            color: context.colors.chalkWhite,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                buildFeedbackButton(context, color: context.colors.chalkWhite),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.colors.caveShadow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.colors.graniteEdge),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tituloEntidade,
                    style: TextStyle(
                      color: context.colors.chalkWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtituloContexto,
                    style: TextStyle(
                      color: context.colors.ashGrey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Este conteúdo faz parte do croqui $nomeCroqui, que ainda não está salvo offline no seu aparelho. Quando voltar a ter conexão com a internet, tente novamente para abri-lo.',
              style: TextStyle(
                color: context.colors.ashGrey,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (_falhaAoTentarNovamente) ...[
              const SizedBox(height: 12),
              Text(
                'Ainda sem conexão com a internet. Verifique sua rede e tente novamente.',
                style: const TextStyle(
                  color: Color(0xFFC05244),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _tentandoConectar ? null : _executarTentativa,
                icon: _tentandoConectar
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                label: Text(
                  _tentandoConectar
                      ? 'Tentando conectar...'
                      : 'Tentar novamente',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B8B6F),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _tentandoConectar
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: Text(
                  'Fechar',
                  style: TextStyle(
                    color: context.colors.ashGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
