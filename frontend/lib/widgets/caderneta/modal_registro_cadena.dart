// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import '../../data/modelos/cadena.dart';
import '../../data/modelos/tipo_ascensao.dart';
import '../../data/modelos/tipo_escalada.dart';
import '../../services/caderneta/repositorio_caderneta.dart';
import '../../theme/cores_app.dart';

/// Exibe o modal de registro de cadena em formato Bottom Sheet.
Future<void> exibirModalRegistroCadena(
  BuildContext context, {
  required String escaladaUid,
  required String nomeEscalada,
  TipoEscalada tipoEscaladaPadrao = TipoEscalada.guiado,
  int? grauSugerido,
  RepositorioCaderneta? repositorio,
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

/// Modal interativo para registro de ascensão esportiva ou tentativa na caderneta.
///
/// Permite selecionar o estilo esportivo ([TipoAscensao]), ajustar o contador de tentativas,
/// definir a data de realização e redigir notas técnicas privadas limitadas a 200 caracteres.
class ModalRegistroCadena extends StatefulWidget {
  /// Identificador NanoID 14c estável da via associada.
  final String escaladaUid;

  /// Nome legível da escalada para exibição no cabeçalho.
  final String nomeEscalada;

  /// Modalidade padrão da via de escalada.
  final TipoEscalada tipoEscaladaPadrao;

  /// Grau sugerido oficial ou pré-calculado.
  final int? grauSugerido;

  /// Instância opcional do repositório de caderneta (injetável em testes).
  final RepositorioCaderneta? repositorio;

  /// Callback opcional executado imediatamente após o salvamento.
  final void Function(Cadena cadenaSalva)? onSalvo;

  const ModalRegistroCadena({
    super.key,
    required this.escaladaUid,
    required this.nomeEscalada,
    this.tipoEscaladaPadrao = TipoEscalada.guiado,
    this.grauSugerido,
    this.repositorio,
    this.onSalvo,
  });

  @override
  State<ModalRegistroCadena> createState() => _ModalRegistroCadenaState();
}

class _ModalRegistroCadenaState extends State<ModalRegistroCadena> {
  late TipoAscensao _tipoAscensao;
  late TipoEscalada _tipoEscalada;
  int _tentativas = 1;
  late DateTime _dataAscensao;
  late final TextEditingController _notasController;

  @override
  void initState() {
    super.initState();
    _tipoAscensao = TipoAscensao.trabalhado;
    _tipoEscalada = widget.tipoEscaladaPadrao;
    _dataAscensao = DateTime.now();
    _notasController = TextEditingController();
    _notasController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  void _incrementarTentativas() {
    setState(() {
      _tentativas++;
    });
  }

  void _decrementarTentativas() {
    if (_tentativas > 1) {
      setState(() {
        _tentativas--;
      });
    }
  }

  Future<void> _selecionarData() async {
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataAscensao,
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
      setState(() {
        _dataAscensao = dataEscolhida;
      });
    }
  }

  Future<void> _salvar() async {
    final repo = widget.repositorio ?? RepositorioCadernetaLocal.instancia;

    final cadena = Cadena.criar(
      escaladaUid: widget.escaladaUid,
      dataAscensao: _dataAscensao,
      tipoAscensao: _tipoAscensao,
      tipoEscalada: _tipoEscalada,
      tentativas: _tentativas,
      grauSugerido: widget.grauSugerido,
      notasPrivadas: _notasController.text.trim(),
    );

    await repo.salvarCadena(cadena);
    widget.onSalvo?.call(cadena);

    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Alça de arraste superior
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cores.ashGrey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Título e identificador da via
          Text(
            'Registrar Ascensão',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: cores.chalkWhite,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.nomeEscalada,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cores.ashGrey,
                ),
          ),
          const SizedBox(height: 20),

          // Seção 1: Estilo Esportivo
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
              final selecionado = _tipoAscensao == estilo;
              return ChoiceChip(
                label: Text(
                  estilo.rotulo,
                  style: TextStyle(
                    color: selecionado ? cores.chalkWhite : cores.ashGrey,
                    fontWeight:
                        selecionado ? FontWeight.bold : FontWeight.normal,
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
                onSelected: (bool selected) {
                  if (selected) {
                    setState(() {
                      _tipoAscensao = estilo;
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Seção 2: Quantidade de Tentativas
          Row(
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
                      color: _tentativas > 1 ? cores.chalkWhite : cores.ashGrey,
                      onPressed: _decrementarTentativas,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$_tentativas',
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
                      onPressed: _incrementarTentativas,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Seção 3: Data da Ascensão
          Row(
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
                onTap: _selecionarData,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cores.caveShadow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cores.graniteEdge),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 16, color: cores.rustIron),
                      const SizedBox(width: 8),
                      Text(
                        '${_dataAscensao.day.toString().padLeft(2, '0')}/${_dataAscensao.month.toString().padLeft(2, '0')}/${_dataAscensao.year}',
                        style: TextStyle(color: cores.chalkWhite),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Seção 4: Notas Privadas (Máximo 200 caracteres)
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
                '${_notasController.text.length}/200',
                style: TextStyle(
                  color: _notasController.text.length >= 200
                      ? cores.rustIron
                      : cores.ashGrey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('campo_notas_privadas'),
            controller: _notasController,
            maxLength: 200,
            maxLines: 3,
            buildCounter: (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) =>
                null, // Esconde contador nativo inferior
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
          const SizedBox(height: 24),

          // Botão de Confirmação
          ElevatedButton(
            key: const Key('btn_salvar_cadena'),
            onPressed: _salvar,
            style: ElevatedButton.styleFrom(
              backgroundColor: cores.rustIron,
              foregroundColor: cores.chalkWhite,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Salvar na Caderneta',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
