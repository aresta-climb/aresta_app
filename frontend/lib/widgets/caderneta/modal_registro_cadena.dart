// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../data/modelos/cadena.dart';
import '../../data/modelos/tipo_escalada.dart';
import '../../services/caderneta/repositorio_caderneta.dart';
import '../../theme/cores_app.dart';
import '../../view/view_models/registro_cadena_view_model.dart';
import 'controles_formulario_cadena.dart';

/// Exibe o modal de registro ou edição de cadena em formato Bottom Sheet.
///
/// Aceita diretamente um [viewModel] ou instancia um automaticamente a partir
/// dos parâmetros fornecidos.
Future<void> exibirModalRegistroCadena(
  BuildContext context, {
  String? escaladaUid,
  String? nomeEscalada,
  TipoEscalada tipoEscaladaPadrao = TipoEscalada.guiado,
  int? grauSugerido,
  RepositorioCaderneta? repositorio,
  RegistroCadenaViewModel? viewModel,
  void Function(Cadena cadenaSalva)? onSalvo,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: context.colors.deepBasalt,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (modalContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(modalContext).viewInsets.bottom,
        ),
        child: ModalRegistroCadena(
          viewModel: viewModel,
          escaladaUid: escaladaUid,
          nomeEscalada: nomeEscalada,
          tipoEscaladaPadrao: tipoEscaladaPadrao,
          grauSugerido: grauSugerido,
          repositorio: repositorio,
          onSalvo: onSalvo,
        ),
      );
    },
  );
}

/// Interface gráfica declarativa (Dumb UI) para o registro e edição de ascensões e cadenas.
///
/// Todas as regras de negócio, persistência e estados de formulário são delegados ao
/// [RegistroCadenaViewModel], enquanto os controles visuais são compostos a partir de
/// [controles_formulario_cadena.dart].
class ModalRegistroCadena extends StatefulWidget {
  /// ViewModel injetado contendo a lógica e o estado da tela.
  final RegistroCadenaViewModel? viewModel;

  /// Identificador NanoID 14c estável da via associada (usado se [viewModel] for omitido).
  final String? escaladaUid;

  /// Nome legível da escalada (usado se [viewModel] for omitido).
  final String? nomeEscalada;

  /// Modalidade padrão da via de escalada (usada se [viewModel] for omitido).
  final TipoEscalada tipoEscaladaPadrao;

  /// Grau sugerido oficial ou pré-calculado.
  final int? grauSugerido;

  /// Repositório opcional de caderneta para testes.
  final RepositorioCaderneta? repositorio;

  /// Callback opcional executado imediatamente após o salvamento.
  final void Function(Cadena cadenaSalva)? onSalvo;

  const ModalRegistroCadena({
    super.key,
    this.viewModel,
    this.escaladaUid,
    this.nomeEscalada,
    this.tipoEscaladaPadrao = TipoEscalada.guiado,
    this.grauSugerido,
    this.repositorio,
    this.onSalvo,
  });

  @override
  State<ModalRegistroCadena> createState() => _ModalRegistroCadenaState();
}

class _ModalRegistroCadenaState extends State<ModalRegistroCadena> {
  late final RegistroCadenaViewModel _viewModel;
  late final TextEditingController _notasController;
  bool _criouViewModelInterno = false;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
    } else {
      _viewModel = RegistroCadenaViewModel(
        escaladaUid: widget.escaladaUid ?? '',
        nomeEscalada: widget.nomeEscalada ?? '',
        tipoEscaladaPadrao: widget.tipoEscaladaPadrao,
        grauSugerido: widget.grauSugerido,
        repositorio: widget.repositorio,
      );
      _criouViewModelInterno = true;
    }

    _notasController = TextEditingController(text: _viewModel.notasPrivadas);
    _notasController.addListener(() {
      _viewModel.definirNotasPrivadas(_notasController.text);
    });
  }

  @override
  void dispose() {
    _notasController.dispose();
    if (_criouViewModelInterno) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  Future<void> _abrirSeletorData() async {
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _viewModel.dataAscensao,
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: context.colors.rustIron,
              surface: context.colors.deepBasalt,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (dataEscolhida != null) {
      _viewModel.definirDataAscensao(dataEscolhida);
    }
  }

  Future<void> _salvarAscensao() async {
    final cadenaSalva = await _viewModel.salvar();
    widget.onSalvo?.call(cadenaSalva);

    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _AlcaArrasteModal(),
              _CabecalhoModal(
                titulo: _viewModel.tituloModal,
                nomeEscalada: _viewModel.nomeEscalada,
              ),
              const SizedBox(height: 20),
              SeletorEstiloAscensao(
                estiloSelecionado: _viewModel.tipoAscensao,
                aoSelecionar: _viewModel.definirTipoAscensao,
              ),
              const SizedBox(height: 20),
              ContadorTentativasAscensao(
                tentativas: _viewModel.tentativas,
                podeDecrementar: _viewModel.podeDecrementarTentativas,
                aoIncrementar: _viewModel.incrementarTentativas,
                aoDecrementar: _viewModel.decrementarTentativas,
              ),
              const SizedBox(height: 20),
              SeletorDataAscensao(
                dataTexto: _viewModel.dataAscensaoFormatada,
                aoTocar: _abrirSeletorData,
              ),
              const SizedBox(height: 20),
              CampoNotasPrivadasAscensao(
                controlador: _notasController,
                contadorTexto: _viewModel.contadorNotasTexto,
                atingiuLimite: _viewModel.atingiuLimiteNotas,
                limiteCaracteres: RegistroCadenaViewModel.limiteNotasPrivadas,
              ),
              const SizedBox(height: 24),
              _BotaoSalvarCadena(
                rotulo: _viewModel.rotuloBotaoSalvar,
                onPressed: _salvarAscensao,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Alça visual superior indicando capacidade de arraste no bottom sheet.
class _AlcaArrasteModal extends StatelessWidget {
  const _AlcaArrasteModal();

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cores.ashGrey.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Cabeçalho textual do modal contendo título da ação e nome da via.
class _CabecalhoModal extends StatelessWidget {
  final String titulo;
  final String nomeEscalada;

  const _CabecalhoModal({
    required this.titulo,
    required this.nomeEscalada,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: cores.chalkWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (nomeEscalada.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            nomeEscalada,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cores.ashGrey),
          ),
        ],
      ],
    );
  }
}

/// Botão de submissão do formulário de cadena.
class _BotaoSalvarCadena extends StatelessWidget {
  final String rotulo;
  final VoidCallback onPressed;

  const _BotaoSalvarCadena({
    required this.rotulo,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return ElevatedButton(
      key: const Key('btn_salvar_cadena'),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: cores.rustIron,
        foregroundColor: cores.chalkWhite,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        rotulo,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
