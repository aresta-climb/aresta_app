// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../theme/cores_app.dart';

/// Constrói o cabeçalho centralizado de identidade do atleta no Hub de Perfil.
///
/// Renderiza o avatar circular envolvido pelo anel de acento da marca,
/// o nome esportivo em destaque, o rótulo de função e o botão cápsula de edição.
Widget buildCabecalhoHubPerfil({
  required String nome,
  required String funcao,
  required VoidCallback onEditarPerfil,
  String? avatarUrl,
}) {
  return Builder(
    builder: (context) {
      final cores = context.colors;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar central com anel de acento vibrante
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE05A47), width: 2.5),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: cores.caveShadow,
              child: Icon(
                Icons.person,
                color: cores.chalkWhite,
                size: 42,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Nome do atleta
          Text(
            nome,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: cores.chalkWhite,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          // Subtítulo / Função esportiva
          Text(
            funcao,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          // Botão pílula "Editar perfil"
          InkWell(
            key: const Key('btn_editar_perfil_hub'),
            onTap: onEditarPerfil,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: cores.caveShadow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF3F4248)),
              ),
              child: Text(
                'Editar perfil',
                style: TextStyle(
                  color: cores.chalkWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// Constrói a barra horizontal contendo os 4 cartões de métricas rápidas.
Widget buildBarraMetricasHub({
  required int totalCadenas,
  required int totalTentativas,
  required int totalPicos,
  required int totalVias,
}) {
  return Builder(
    builder: (context) {
      // Cores vibrantes em harmonia com o design oficial
      const corCadenas = Color(0xFF22C55E); // Verde esmeralda vivo
      const corTentativas = Color(0xFFE05A47); // Coral/ferrugem vivo
      const corPicos = Color(0xFF94A3B8); // Slate/cinza límpido
      const corVias = Color(0xFFE05A47); // Coral/laranja vivo

      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: buildCardMetricaHub(
                key: const Key('card_metrica_cadenas'),
                icone: Icons.check_rounded,
                corIcone: corCadenas,
                corBorda: corCadenas.withValues(alpha: 0.28),
                valor: '$totalCadenas',
                rotulo: 'CADENAS',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildCardMetricaHub(
                key: const Key('card_metrica_tentativas'),
                icone: Icons.refresh_rounded,
                corIcone: corTentativas,
                corBorda: corTentativas.withValues(alpha: 0.28),
                valor: '$totalTentativas',
                rotulo: 'TENTATIVAS',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildCardMetricaHub(
                key: const Key('card_metrica_picos'),
                icone: Icons.terrain_rounded,
                corIcone: corPicos,
                corBorda: corPicos.withValues(alpha: 0.22),
                valor: '$totalPicos',
                rotulo: 'PICOS',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildCardMetricaHub(
                key: const Key('card_metrica_vias'),
                icone: Icons.alt_route_rounded,
                corIcone: corVias,
                corBorda: corVias.withValues(alpha: 0.28),
                valor: '$totalVias',
                rotulo: 'VIAS',
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Constrói um cartão individual de métrica rápida esportiva com cantos arredondados.
Widget buildCardMetricaHub({
  Key? key,
  required IconData icone,
  required Color corIcone,
  required String valor,
  required String rotulo,
  Color? corBorda,
}) {
  return Builder(
    builder: (context) {
      final cores = context.colors;
      final bordaEfetiva = corBorda ?? corIcone.withValues(alpha: 0.25);

      return Container(
        key: key,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 3),
        decoration: BoxDecoration(
          color: cores.caveShadow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bordaEfetiva, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Selo circular com ícone temático
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: corIcone.withValues(alpha: 0.18),
              ),
              child: Icon(icone, color: corIcone, size: 18),
            ),
            const SizedBox(height: 10),
            // Valor numérico
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                valor,
                maxLines: 1,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: cores.chalkWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Rótulo da métrica
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                rotulo,
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Constrói o menu de navegação e opções em lista modular vertical.
Widget buildMenuOpcoesHub({
  required VoidCallback onAbrirCaderneta,
  required VoidCallback onAbrirConfiguracoes,
  required VoidCallback onAbrirDadosPrivacidade,
  required VoidCallback onConfirmarSaida,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      buildItemMenuHub(
        key: const Key('item_menu_minha_caderneta'),
        icone: Icons.menu_book_outlined,
        titulo: 'Minha caderneta',
        onTap: onAbrirCaderneta,
      ),
      const SizedBox(height: 10),
      buildItemMenuHub(
        key: const Key('item_menu_configuracoes'),
        icone: Icons.settings_outlined,
        titulo: 'Configurações',
        onTap: onAbrirConfiguracoes,
      ),
      const SizedBox(height: 10),
      buildItemMenuHub(
        key: const Key('item_menu_dados_privacidade'),
        icone: Icons.lock_outline_rounded,
        titulo: 'Dados e privacidade',
        onTap: onAbrirDadosPrivacidade,
      ),
      const SizedBox(height: 10),
      buildItemMenuHub(
        key: const Key('item_menu_sair'),
        icone: Icons.logout_rounded,
        titulo: 'Sair',
        onTap: onConfirmarSaida,
        isPerigo: true,
      ),
    ],
  );
}

/// Constrói um item de menu individual em estilo de cartão arredondado com chevron.
Widget buildItemMenuHub({
  Key? key,
  required IconData icone,
  required String titulo,
  required VoidCallback onTap,
  bool isPerigo = false,
}) {
  return Builder(
    builder: (context) {
      final cores = context.colors;
      const corPerigoVibrante = Color(0xFFEF4444);
      final corDestaque = isPerigo ? corPerigoVibrante : cores.chalkWhite;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          key: key,
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: cores.caveShadow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPerigo
                    ? corPerigoVibrante.withValues(alpha: 0.25)
                    : cores.graniteEdge,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(icone, color: corDestaque, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    titulo,
                    style: TextStyle(
                      color: corDestaque,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!isPerigo)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Exibe o diálogo de edição do nome esportivo do atleta.
Future<String?> exibirDialogoEditarPerfil(
  BuildContext context, {
  required String nomeAtual,
}) {
  final controller = TextEditingController(text: nomeAtual);

  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      final cores = dialogContext.colors;

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
          controller: controller,
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
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            key: const Key('btn_salvar_editar_perfil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE05A47),
              foregroundColor: cores.chalkWhite,
            ),
            onPressed: () {
              final texto = controller.text.trim();
              Navigator.of(dialogContext).pop(texto.isNotEmpty ? texto : null);
            },
            child: const Text('Salvar'),
          ),
        ],
      );
    },
  );
}

/// Exibe modal com detalhes de dados, identificador NanoID 14c e privacidade.
