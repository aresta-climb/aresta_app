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
import '../widgets/micro_badge_beta.dart';
import '../widgets/modal_beta_aberto.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../aresta_api/proto/generated/croqui.pb.dart';
import '../services/http/servico_croqui_online.dart';

/// Navega para a página de detalhes de um pico selecionado (local ou sob demanda online).
Future<void> handlePicoSelection(
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
      final checksum = pico['checksum']?.toString();
      croqui = await servicoOnline.carregarCroquiRemoto(
        url,
        picoId: id,
        checksumSha256: checksum,
      );
    }
  }

  if (!context.mounted) return;

  Navigator.of(context, rootNavigator: true).pop();

  if (croqui != null && croqui.picos.isNotEmpty) {
    datasetRepo.gerenciadorSessaoOnline.registrarCroquiOnline(id, croqui);
    datasetRepo.indexarMidiasDoCroqui(id, croqui);

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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/logo_app_trace.svg',
                      height: 22,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 7),
                    InkWell(
                      onTap: () => exibirModalBetaAberto(context),
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 7, bottom: 5),
                            child: Text(
                              'ARESTA CLIMB',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                fontSize: 15.5,
                                letterSpacing: 0.5,
                                color: context.colors.chalkWhite,
                              ),
                            ),
                          ),
                          const Positioned(
                            right: 0,
                            bottom: 0,
                            child: MicroBadgeBeta(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'BEM VINDO!',
          style: TextStyle(
            color: context.colors.dryMoss,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'BORA PRA PEDRA?',
          style: TextStyle(
            color: context.colors.chalkWhite,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'O guia definitivo para facilitar a sua escalada. Explore setores, vias e boulders locais e salve os croquis para acessar totalmente offline.',
          style: TextStyle(
            color: context.colors.chalkWhite.withValues(alpha: 0.85),
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
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: context.colors.graniteEdge.withValues(alpha: 0.8),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: context.colors.rustIron.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'COMO FUNCIONA',
              style: TextStyle(
                color: context.colors.rustIron,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'GUIA RÁPIDO DO ARESTA',
            style: TextStyle(
              color: context.colors.chalkWhite,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quatro passos pra você sair do app direto pro paredão.',
            style: TextStyle(
              color: context.colors.ashGrey,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _buildStepItem(
            context,
            num: '01',
            icon: Icons.search,
            title: 'ENCONTRE O PICO',
            desc:
                'Use a busca ou explore os picos próximos no carrossel superior da home.',
            iconColor: const Color(0xFFE25844),
          ),
          _buildStepItem(
            context,
            num: '02',
            icon: Icons.download_outlined,
            title: 'SALVE OFFLINE',
            desc:
                'Baixe os croquis e setores inteiros para continuar navegando sem sinal de internet.',
            iconColor: const Color(0xFF6D9578),
          ),
          _buildStepItem(
            context,
            num: '03',
            icon: Icons.menu_book_outlined,
            title: 'CROQUI INTERATIVO',
            desc:
                'Toque nos pontos da imagem do paredão para consultar graus, altura e proteções.',
            iconColor: const Color(0xFFBCA646),
          ),
          _buildStepItem(
            context,
            num: '04',
            icon: Icons.people_outline,
            title: 'COMPARTILHE',
            desc:
                'Avise outros escaladores sobre restrições de fauna, chuva ou itens perdidos.',
            iconColor: const Color(0xFF5B81A7),
            isLast: true,
          ),
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
  bool isLast = false,
}) {
  return Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: context.colors.deepBasalt,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: iconColor.withValues(alpha: 0.6)),
                ),
                child: Text(
                  num,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.caveShadow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: context.colors.graniteEdge.withValues(alpha: 0.8),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.colors.chalkWhite,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    color: context.colors.ashGrey,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
