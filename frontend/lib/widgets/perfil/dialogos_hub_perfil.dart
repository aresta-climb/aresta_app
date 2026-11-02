// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../theme/cores_app.dart';

/// Exibe o diálogo de edição do nome esportivo do atleta.
///
/// Retorna o novo nome normalizado (`trim()`) ou `null` quando cancelado ou vazio.
Future<String?> exibirDialogoEditarPerfil(
  BuildContext context, {
  required String nomeAtual,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => DialogoEditarPerfil(nomeAtual: nomeAtual),
  );
}

/// Diálogo com ciclo de vida gerenciado (`StatefulWidget`) para edição do nome do atleta.
///
/// Encapsula e descarta apropriadamente seu [TextEditingController] em [State.dispose],
/// evitando vazamentos de memória após o fechamento do modal.
class DialogoEditarPerfil extends StatefulWidget {
  /// Nome atual exibido inicialmente no campo de texto.
  final String nomeAtual;

  const DialogoEditarPerfil({
    super.key,
    required this.nomeAtual,
  });

  @override
  State<DialogoEditarPerfil> createState() => _DialogoEditarPerfilState();
}

class _DialogoEditarPerfilState extends State<DialogoEditarPerfil> {
  late final TextEditingController _controladorNome;

  @override
  void initState() {
    super.initState();
    _controladorNome = TextEditingController(text: widget.nomeAtual);
  }

  @override
  void dispose() {
    _controladorNome.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return AlertDialog(
      backgroundColor: cores.deepBasalt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cores.graniteEdge),
      ),
      title: Text(
        'Editar Perfil',
        style: TextStyle(
          color: cores.chalkWhite,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: TextField(
        key: const Key('campo_editar_perfil_nome'),
        controller: _controladorNome,
        autofocus: true,
        style: TextStyle(color: cores.chalkWhite),
        decoration: InputDecoration(
          labelText: 'Nome do atleta',
          labelStyle: TextStyle(color: cores.ashGrey),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: cores.graniteEdge),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE05A47)),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
        ElevatedButton(
          key: const Key('btn_salvar_editar_perfil'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE05A47),
            foregroundColor: cores.chalkWhite,
          ),
          onPressed: () {
            final texto = _controladorNome.text.trim();
            Navigator.of(context).pop(texto.isNotEmpty ? texto : null);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

/// Exibe o modal inferior com detalhes de soberania de dados, identificador NanoID 14c e privacidade.
Future<void> exibirModalDadosPrivacidade(
  BuildContext context, {
  required String autorIdPublico,
  required VoidCallback aoCopiarId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.colors.deepBasalt,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ModalDadosPrivacidade(
      autorIdPublico: autorIdPublico,
      aoCopiarId: aoCopiarId,
    ),
  );
}

/// Conteúdo declarativo (Dumb UI) do modal de Dados e Privacidade do atleta.
class ModalDadosPrivacidade extends StatelessWidget {
  /// Identificador NanoID público de 14 caracteres do escalador.
  final String autorIdPublico;

  /// Callback acionado quando o usuário toca no botão de cópia do ID público.
  final VoidCallback aoCopiarId;

  const ModalDadosPrivacidade({
    super.key,
    required this.autorIdPublico,
    required this.aoCopiarId,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dados e Privacidade',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: cores.chalkWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'O Aresta Climb respeita a soberania e a privacidade dos seus dados. '
              'Sua caderneta é estritamente privada. Contribuições públicas de graduação '
              'e alertas utilizam exclusivamente seu ID de Autor público, sem expor dados pessoais.',
              style: TextStyle(
                color: cores.ashGrey,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cores.caveShadow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cores.graniteEdge),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ID DE AUTOR PÚBLICO (NANOID)',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        autorIdPublico,
                        style: TextStyle(
                          color: cores.chalkWhite,
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    key: const Key('btn_copiar_id_privacidade'),
                    icon: const Icon(
                      Icons.copy_rounded,
                      color: Color(0xFFE05A47),
                    ),
                    tooltip: 'Copiar ID público',
                    onPressed: () {
                      aoCopiarId();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Exibe o diálogo de confirmação de saída do Hub de Perfil.
Future<bool?> exibirDialogoConfirmarSaida(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (_) => const DialogoConfirmarSaida(),
  );
}

/// Diálogo declarativo de confirmação de saída do Hub de Perfil.
class DialogoConfirmarSaida extends StatelessWidget {
  const DialogoConfirmarSaida({super.key});

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return AlertDialog(
      backgroundColor: cores.deepBasalt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cores.graniteEdge),
      ),
      title: Text(
        'Deseja realmente sair?',
        style: TextStyle(
          color: cores.chalkWhite,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        'Sua caderneta pessoal e histórico permanecem preservados com segurança no dispositivo.',
        style: TextStyle(color: cores.ashGrey, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
        ElevatedButton(
          key: const Key('btn_confirmar_saida'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: cores.chalkWhite,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sair'),
        ),
      ],
    );
  }
}
