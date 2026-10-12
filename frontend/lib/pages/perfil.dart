// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/modelos/cadena.dart';
import '../services/caderneta/repositorio_caderneta.dart';
import '../theme/cores_app.dart';
import '../view/function_library/biblioteca_funcoes_comuns.dart';
import '../view/view_models/perfil_view_model.dart';
import '../widgets/caderneta/card_estatistica.dart';
import '../widgets/caderneta/grafico_piramide_graus.dart';

/// Página de exibição do Perfil do Escalador e Caderneta Esportiva pessoal.
///
/// Apresenta o cabeçalho esportivo com identificador público permanente ([autorIdPublico]),
/// apelido customizável, cartões de métricas agregadas, pirâmide de graduação interativa
/// e o histórico cronológico de ascensões com suporte a exclusão segura.
class PerfilPage extends StatefulWidget {
  /// ViewModel injetado (ou inicializado por padrão).
  final PerfilViewModel? viewModel;

  const PerfilPage({super.key, this.viewModel});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  late final PerfilViewModel _viewModel;
  bool _criouViewModelInterno = false;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
    } else {
      _viewModel = PerfilViewModel(
        repositorio: RepositorioCadernetaLocal.instancia,
      );
      _criouViewModelInterno = true;
    }
  }

  @override
  void dispose() {
    if (_criouViewModelInterno) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  Future<void> _copiarIdPublico(String id) async {
    await Clipboard.setData(ClipboardData(text: id));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID público copiado!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _editarApelido() async {
    final controller = TextEditingController(
      text: _viewModel.perfil.autorNomePublico,
    );

    final novoNome = await showDialog<String>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: dialogCtx.colors.deepBasalt,
          title: Text(
            'Editar Apelido',
            style: TextStyle(color: dialogCtx.colors.chalkWhite),
          ),
          content: TextField(
            key: const Key('campo_novo_nome_atleta'),
            controller: controller,
            maxLength: 50,
            style: TextStyle(color: dialogCtx.colors.chalkWhite),
            decoration: InputDecoration(
              hintText: 'Digite seu apelido esportivo...',
              hintStyle: TextStyle(color: dialogCtx.colors.ashGrey),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: dialogCtx.colors.rustIron),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: dialogCtx.colors.ashGrey),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogCtx).pop(controller.text.trim()),
              child: Text(
                'Salvar',
                style: TextStyle(
                  color: dialogCtx.colors.rustIron,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (novoNome != null && novoNome.isNotEmpty) {
      await _viewModel.atualizarNome(novoNome);
    }
  }

  Future<void> _confirmarExclusaoCadena(Cadena cadena) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: dialogCtx.colors.deepBasalt,
          title: Text(
            'Excluir Ascensão?',
            style: TextStyle(color: dialogCtx.colors.chalkWhite),
          ),
          content: Text(
            'Tem certeza de que deseja remover esta ascensão da sua caderneta esportiva?',
            style: TextStyle(color: dialogCtx.colors.ashGrey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(
                'Cancelar',
                style: TextStyle(color: dialogCtx.colors.ashGrey),
              ),
            ),
            TextButton(
              key: const Key('btn_confirmar_exclusao'),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(
                'Excluir',
                style: TextStyle(
                  color: dialogCtx.colors.rustIron,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmado == true) {
      await _viewModel.excluirCadena(cadena.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final perfil = _viewModel.perfil;
        final stats = _viewModel.estatisticas;
        final historico = _viewModel.historicoCadenas;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: buildCommonAppBar(context, 'MEU PERFIL'),
          body: SafeArea(
            bottom: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Cabeçalho do Perfil
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cores.caveShadow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cores.graniteEdge),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: cores.deepBasalt,
                          child: Icon(
                            Icons.terrain_rounded,
                            color: cores.rustIron,
                            size: 34,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      perfil.autorNomePublico,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: cores.chalkWhite,
                                            fontWeight: FontWeight.bold,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    key: const Key('btn_editar_nome_atleta'),
                                    icon: Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: cores.ashGrey,
                                    ),
                                    onPressed: _editarApelido,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                key: const Key('chip_autor_id_publico'),
                                onTap: () =>
                                    _copiarIdPublico(perfil.autorIdPublico),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cores.deepBasalt,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: cores.graniteEdge,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'ID: ${perfil.autorIdPublico}',
                                        style: TextStyle(
                                          color: cores.ashGrey,
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.copy_rounded,
                                        size: 13,
                                        color: cores.rustIron,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Painel de Métricas (2x2)
                  Row(
                    children: [
                      Expanded(
                        child: CardEstatistica(
                          titulo: 'Total de Cadenas',
                          valor: '${stats.totalCadenas}',
                          icone: Icons.emoji_events_outlined,
                          subtitulo: '${stats.totalAscensoes} registros',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CardEstatistica(
                          titulo: 'À Vista / Flash',
                          valor: '${stats.taxaAVistaFlash.toStringAsFixed(0)}%',
                          icone: Icons.bolt,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CardEstatistica(
                          titulo: 'Maior Grau (Via)',
                          valor: stats.maiorGrauVia ?? '-',
                          icone: Icons.vertical_align_top_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CardEstatistica(
                          titulo: 'Maior Grau (Boulder)',
                          valor: stats.maiorGrauBoulder ?? '-',
                          icone: Icons.crop_square_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3. Pirâmide de Graduação
                  GraficoPiramideGraus(
                    piramide: _viewModel.piramideAtiva,
                    modoVias: _viewModel.modoVias,
                    onAlternarModo: _viewModel.alternarModoModalidade,
                  ),
                  const SizedBox(height: 24),

                  // 4. Histórico Cronológico de Ascensões
                  Text(
                    'Histórico de Ascensões (${historico.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: cores.chalkWhite,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),

                  if (historico.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      alignment: Alignment.center,
                      child: Text(
                        'Nenhuma ascensão registrada ainda.\nSuas cadenas salvas nas páginas das vias aparecerão aqui.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cores.ashGrey, fontSize: 13),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: historico.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final cadena = historico[index];
                        final dataStr =
                            '${cadena.dataAscensao.day.toString().padLeft(2, '0')}/${cadena.dataAscensao.month.toString().padLeft(2, '0')}/${cadena.dataAscensao.year}';
                        final nomeVia =
                            _viewModel.obterNomeEscalada(cadena.escaladaUid);
                        final grauVia =
                            _viewModel.obterGrauEscalada(cadena.escaladaUid);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cores.caveShadow,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: cores.graniteEdge),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: cadena.isCadena
                                      ? cores.fernGreen.withValues(alpha: 0.2)
                                      : cores.rustIron.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  cadena.tipoAscensao.rotulo,
                                  style: TextStyle(
                                    color: cadena.isCadena
                                        ? cores.fernGreen
                                        : cores.rustIron,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            nomeVia,
                                            style: TextStyle(
                                              color: cores.chalkWhite,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        if (grauVia != null &&
                                            grauVia.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: cores.deepBasalt,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              grauVia,
                                              style: TextStyle(
                                                color: cores.chalkWhite,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dataStr,
                                      style: TextStyle(
                                        color: cores.ashGrey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (cadena.notasPrivadas.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        '“${cadena.notasPrivadas}”',
                                        style: TextStyle(
                                          color: cores.ashGrey,
                                          fontStyle: FontStyle.italic,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                key: Key('btn_excluir_cadena_${cadena.id}'),
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: cores.ashGrey,
                                ),
                                onPressed: () =>
                                    _confirmarExclusaoCadena(cadena),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
