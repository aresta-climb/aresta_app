// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../data/modelos/cadena.dart';
import '../../data/modelos/tipo_ascensao.dart';
import '../../data/modelos/tipo_escalada.dart';
import '../../services/caderneta/repositorio_caderneta.dart';
import '../../theme/cores_app.dart';
import '../../view/view_models/registro_cadena_view_model.dart';

/// Exibe o modal de registro de cadena em formato Bottom Sheet.
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

/// Interface gráfica declarativa (Dumb UI) para o registro de ascensões e cadenas.
///
/// Todas as regras de negócio, persistência e estados de formulário são delegados ao
/// [RegistroCadenaViewModel], garantindo uma camada de apresentação desacoplada, elegante
/// e facilmente testável.
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
              _CabecalhoModal(nomeEscalada: _viewModel.nomeEscalada),
              const SizedBox(height: 20),
              _SeletorEstiloEsportivo(
                estiloSelecionado: _viewModel.tipoAscensao,
                onSelecionar: _viewModel.definirTipoAscensao,
              ),
              const SizedBox(height: 20),
              _ContadorTentativas(
                tentativas: _viewModel.tentativas,
                podeDecrementar: _viewModel.podeDecrementarTentativas,
                onIncrementar: _viewModel.incrementarTentativas,
                onDecrementar: _viewModel.decrementarTentativas,
              ),
              const SizedBox(height: 20),
              _SeletorDataAscensao(
                dataTexto: _viewModel.dataAscensaoFormatada,
                onTap: _abrirSeletorData,
              ),
              const SizedBox(height: 20),
              _CampoNotasPrivadas(
                controller: _notasController,
                contadorTexto: _viewModel.contadorNotasTexto,
                atingiuLimite: _viewModel.atingiuLimiteNotas,
              ),
              const SizedBox(height: 24),
              _BotaoSalvarCadena(onPressed: _salvarAscensao),
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
  final String nomeEscalada;

  const _CabecalhoModal({required this.nomeEscalada});

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Registrar Ascensão',
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

/// Seletor em chips para escolha do estilo esportivo da ascensão.
class _SeletorEstiloEsportivo extends StatelessWidget {
  final TipoAscensao estiloSelecionado;
  final ValueChanged<TipoAscensao> onSelecionar;

  const _SeletorEstiloEsportivo({
    required this.estiloSelecionado,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estilo Esportivo',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: cores.chalkWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TipoAscensao.values.map((estilo) {
            final selecionado = estiloSelecionado == estilo;
            return ChoiceChip(
              label: Text(
                estilo.rotulo,
                style: TextStyle(
                  color: selecionado ? cores.chalkWhite : cores.ashGrey,
                  fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: selecionado,
              selectedColor: cores.rustIron,
              backgroundColor: cores.caveShadow,
              side: BorderSide(
                color: selecionado
                    ? cores.rustIron
                    : cores.graniteEdge.withValues(alpha: 0.6),
              ),
              onSelected: (bool ativo) {
                if (ativo) onSelecionar(estilo);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Seletor numérico de tentativas despendidas na ascensão.
class _ContadorTentativas extends StatelessWidget {
  final int tentativas;
  final bool podeDecrementar;
  final VoidCallback onIncrementar;
  final VoidCallback onDecrementar;

  const _ContadorTentativas({
    required this.tentativas,
    required this.podeDecrementar,
    required this.onIncrementar,
    required this.onDecrementar,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Tentativas / Pegas',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: cores.chalkWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cores.caveShadow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cores.graniteEdge),
          ),
          child: Row(
            children: [
              IconButton(
                key: const Key('btn_decrementar_tentativas'),
                icon: const Icon(Icons.remove, size: 18),
                color: podeDecrementar ? cores.chalkWhite : cores.ashGrey,
                onPressed: podeDecrementar ? onDecrementar : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '$tentativas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cores.chalkWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                key: const Key('btn_incrementar_tentativas'),
                icon: const Icon(Icons.add, size: 18),
                color: cores.chalkWhite,
                onPressed: onIncrementar,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Botão de acionamento do diálogo de seleção de data.
class _SeletorDataAscensao extends StatelessWidget {
  final String dataTexto;
  final VoidCallback onTap;

  const _SeletorDataAscensao({required this.dataTexto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Data da Ascensão',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: cores.chalkWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        InkWell(
          key: const Key('btn_selecionar_data'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cores.caveShadow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cores.graniteEdge),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: cores.rustIron,
                ),
                const SizedBox(width: 8),
                Text(dataTexto, style: TextStyle(color: cores.chalkWhite)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Campo de texto para inserção das notas técnicas pessoais do escalador.
class _CampoNotasPrivadas extends StatelessWidget {
  final TextEditingController controller;
  final String contadorTexto;
  final bool atingiuLimite;

  const _CampoNotasPrivadas({
    required this.controller,
    required this.contadorTexto,
    required this.atingiuLimite,
  });

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Notas Privadas (Crux / Métodos)',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: cores.chalkWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              contadorTexto,
              style: TextStyle(
                color: atingiuLimite ? cores.rustIron : cores.ashGrey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('campo_notas_privadas'),
          controller: controller,
          maxLength: RegistroCadenaViewModel.limiteNotasPrivadas,
          maxLines: 3,
          buildCounter:
              (
                context, {
                required currentLength,
                required isFocused,
                maxLength,
              }) => null,
          style: TextStyle(color: cores.chalkWhite),
          decoration: InputDecoration(
            hintText:
                'Ex: Crux no 3º grampo com calcanhar esquerdo, levar costura longa...',
            hintStyle: TextStyle(
              color: cores.ashGrey.withValues(alpha: 0.7),
              fontSize: 13,
            ),
            filled: true,
            fillColor: cores.caveShadow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cores.graniteEdge),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cores.graniteEdge),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cores.rustIron),
            ),
          ),
        ),
      ],
    );
  }
}

/// Botão de submissão do formulário de cadena.
class _BotaoSalvarCadena extends StatelessWidget {
  final VoidCallback onPressed;

  const _BotaoSalvarCadena({required this.onPressed});

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
      child: const Text(
        'Salvar na Caderneta',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
