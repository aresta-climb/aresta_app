// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../main.dart';
import '../services/dataset_repository.dart';
import '../navigation/navigation_tree.dart';
import '../navigation/navigation_functions.dart';
import '../services/firebase/telemetry_service.dart';
import '../theme/app_colors.dart';
import '../view_functions/common_functions.dart';
import '../widgets/nearby_crags_carousel.dart';
import '../widgets/global_search.dart';
import '../services/http/sync_service.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';

import '../services/http/servico_croqui_online.dart';

/// Navega para a página de detalhes de um pico selecionado (local ou sob demanda online).
void handlePicoSelection(
  BuildContext context,
  DatasetRepository datasetRepo,
  dynamic pico, {
  String source = 'home',
}) async {
  final String? id = pico is ResumoPico ? pico.id : pico['id']?.toString();
  if (id == null) return;

  TelemetryService.instance.logAcaoCroqui(id, 'abrir_croqui', origem: source);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(
      child: CircularProgressIndicator(color: context.colors.beastHide),
    ),
  );

  Croqui? croqui = await datasetRepo.getCroqui(id);

  // Se não estiver salvo localmente, busca sob demanda para sessão online
  if (croqui == null) {
    final url = pico is ResumoPico ? pico.url : pico['url']?.toString();
    if (url != null && url.isNotEmpty) {
      final servicoOnline = ServicoCroquiOnline(
        sessaoOnline: datasetRepo.gerenciadorSessaoOnline,
      );
      croqui = await servicoOnline.carregarCroquiRemoto(url, picoId: id);
    }
  }

  if (!context.mounted) return;

  Navigator.of(context, rootNavigator: true).pop();

  if (croqui != null && croqui.picos.isNotEmpty) {
    AppNav.toPico(
      context,
      pico: croqui.picos.first,
      croqui: croqui,
      cragId: id,
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      datasetRepo.updatePriorityAfterNavigation(id);
      datasetRepo.triggerHomeReset();
    });
  } else {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Erro ao abrir o guia. Verifique sua conexão.')));
  }
}

/// Constrói o corpo principal da página inicial refatorada.
Widget buildHomeBody(
  BuildContext context,
  DatasetRepository datasetRepo,
  SyncService syncService, [
  Function(int)? onSwitchTab,
]) {
  return SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(
      parent: BouncingScrollPhysics(),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, datasetRepo, syncService),
        _buildSearchBar(context, datasetRepo),
        NearbyCragsCarousel(syncService: syncService),
        _buildGuiaRapido(context),
        _buildConservacao(context),
        const SizedBox(height: 30),
      ],
    ),
  );
}

Widget _buildHeader(
  BuildContext context,
  DatasetRepository datasetRepo,
  SyncService syncService,
) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                'assets/logo_app.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade800, // Darker grey background
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'ARESTA',
                style: TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 26,
                  letterSpacing: 1.5,
                  height: 1.2,
                  color: Colors.black,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.sync, color: context.colors.ashGrey),
              tooltip: 'Sincronizar catálogo e croquis',
              onPressed: () async {
                await handleManualSync(
                  context,
                  datasetRepo,
                  syncService,
                );
              },
            ),
            buildFeedbackButton(context, color: context.colors.ashGrey),
            IconButton(
              icon: Icon(Icons.settings, color: context.colors.ashGrey),
              onPressed: () {
                TreeNavigationWrapper.of(
                  context,
                ).treeController.navigateTo(SettingsNode(const HomeNode()));
              },
            ),
          ],
        ),
        const SizedBox(height: 30),
        Text(
          'BEM VINDO!',
          style: TextStyle(
            color: context.colors.dryMoss,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'O guia definitivo para facilitar a sua escalada. Explore setores, vias e boulders locais e salve os croquis para acessar totalmente offline.',
          style: TextStyle(
            color: context.colors.ashGrey,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

Widget _buildSearchBar(BuildContext context, DatasetRepository datasetRepo) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
    child: GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: context.colors.deepBasalt,
              appBar: AppBar(
                backgroundColor: context.colors.deepBasalt,
                elevation: 0,
                iconTheme: IconThemeData(
                  color: context.colors.chalkWhite,
                ),
              ),
              body: GlobalSearch(
                datasetRepo: datasetRepo,
                downloadedPicos:
                    datasetRepo.activeDataset.value?.downloadedPicos ??
                        const <ResumoPico>[],
              ),
            ),
          ),
        );
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: context.colors.caveShadow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.graniteEdge),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.search, color: context.colors.ashGrey, size: 20),
            const SizedBox(width: 12),
            Text(
              'Buscar picos, setores ou vias...',
              style: TextStyle(color: context.colors.ashGrey, fontSize: 15),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildGuiaRapido(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.chalkWhite,
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.colors.clayDust,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'COMO FUNCIONA',
              style: TextStyle(
                color: context.colors.rustIron,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'GUIA RÁPIDO DO ARESTA',
            style: TextStyle(
              color: context.colors.slateBlue,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Três passos pra você sair do app direto pro paredão.',
            style: TextStyle(
              color: context.colors.slateBlue.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          _buildStepItem(
            context,
            num: '01',
            icon: Icons.search,
            title: 'ENCONTRE O PICO',
            desc:
                'Use a busca ou explore os picos próximos no carrossel superior da home.',
            iconColor: const Color(0xFFC05244),
            bgColor: const Color(0xFFFBECE9),
          ),
          _buildStepItem(
            context,
            num: '02',
            icon: Icons.download_outlined,
            title: 'SALVE OFFLINE',
            desc:
                'Baixe os croquis e setores inteiros para continuar navegando sem sinal de internet.',
            iconColor: const Color(0xFF6D9578),
            bgColor: const Color(0xFFEAF2ED),
          ),
          _buildStepItem(
            context,
            num: '03',
            icon: Icons.menu_book_outlined,
            title: 'CROQUI INTERATIVO',
            desc:
                'Toque nos pontos da imagem do paredão para consultar graus, altura e proteções.',
            iconColor: const Color(0xFFBCA646),
            bgColor: const Color(0xFFF9F5DE),
            isLast: true,
          ),
          /*
          _buildStepItem(
            context,
            num: '04',
            icon: Icons.people_outline,
            title: 'COMPARTILHE',
            desc:
                'Avise outros escaladores sobre restrições de fauna, chuva ou itens perdidos.',
            iconColor: const Color(0xFF5B81A7),
            bgColor: const Color(0xFFEAF1F8),
            isLast: true,
          ),
          */
        ],
      ),
    ),
  );
}

Widget _buildStepItem(
  BuildContext context, {
  required String num,
  required IconData icon,
  required String title,
  required String desc,
  required Color iconColor,
  required Color bgColor,
  bool isLast = false,
}) {
  return Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: iconColor.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: iconColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    num,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.brandColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(
                    color: context.colors.slateBlue.withValues(alpha: 0.6),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildConservacao(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.darkPine,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.graniteEdge),
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shield_outlined, color: context.colors.fernGreen),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONSERVAÇÃO E ACESSO',
                  style: TextStyle(
                    color: context.colors.fernGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'O acesso aos picos depende de cuidado, ética e envolvimento com as comunidades locais. Cada local tem suas regras, seus guardiões e sua história. Escalar com responsabilidade é garantir que os picos continuem abertos.',
                  style: TextStyle(
                    color: context.colors.fernGreen.withValues(alpha: 0.7),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
