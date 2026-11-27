// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:frontend/services/compartilhamento/servico_compartilhamento.dart';

/// Registro determinístico de uma imagem compartilhada pelo [ServicoCompartilhamentoFake].
class RegistroImagemCompartilhada {
  /// Bytes PNG exportados para o menu nativo.
  final Uint8List bytesPng;

  /// Nome de arquivo atribuído à imagem exportada.
  final String nomeArquivo;

  /// Cria um registro de imagem compartilhada.
  const RegistroImagemCompartilhada({
    required this.bytesPng,
    required this.nomeArquivo,
  });
}

/// Biblioteca Fake determinística em memória para [ServicoCompartilhamento] em testes.
///
/// Registra chamadas de texto, imagens PNG e cópias para a área de transferência,
/// além de permitir simulação determinística de falhas e captura de cartão em memória.
class ServicoCompartilhamentoFake extends ServicoCompartilhamento {
  /// Mensagens de link enviadas pelo fluxo de compartilhamento rápido.
  final List<String> textosCompartilhados;

  /// Imagens PNG enviadas pelo fluxo de compartilhamento para Stories.
  final List<RegistroImagemCompartilhada> imagensCompartilhadas;

  /// Links copiados automaticamente para a área de transferência.
  final List<String> textosCopiadosClipboard;

  /// Quando `true`, lança [StateError] determinístico ao tentar compartilhar texto ou imagem.
  bool simularErroCompartilhamento;

  /// PNG 1x1 válido usado como retorno padrão pelo [capturarCartaoFake].
  static final Uint8List pngMinimoValido = Uint8List.fromList(const [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  ServicoCompartilhamentoFake._({
    required this.textosCompartilhados,
    required this.imagensCompartilhadas,
    required this.textosCopiadosClipboard,
    required this.simularErroCompartilhamento,
    required super.executorCompartilhamento,
    required super.executorImagem,
    required super.copiadorAreaTransferencia,
    required super.capturadorCartao,
  });

  /// Cria uma instância determinística de [ServicoCompartilhamentoFake].
  factory ServicoCompartilhamentoFake({
    bool simularErroCompartilhamento = false,
  }) {
    final textos = <String>[];
    final imagens = <RegistroImagemCompartilhada>[];
    final clipboard = <String>[];
    late final ServicoCompartilhamentoFake fake;

    fake = ServicoCompartilhamentoFake._(
      textosCompartilhados: textos,
      imagensCompartilhadas: imagens,
      textosCopiadosClipboard: clipboard,
      simularErroCompartilhamento: simularErroCompartilhamento,
      capturadorCartao: (_) async => pngMinimoValido,
      executorCompartilhamento: (texto) async {
        if (fake.simularErroCompartilhamento) {
          throw StateError('Falha determinística ao compartilhar link.');
        }
        textos.add(texto);
      },
      executorImagem: (bytesPng, nomeArquivo) async {
        if (fake.simularErroCompartilhamento) {
          throw StateError('Falha determinística ao compartilhar imagem.');
        }
        imagens.add(
          RegistroImagemCompartilhada(
            bytesPng: bytesPng,
            nomeArquivo: nomeArquivo,
          ),
        );
      },
      copiadorAreaTransferencia: (texto) async {
        clipboard.add(texto);
      },
    );
    return fake;
  }

  /// Capturador rápido em memória compatível com [CapturadorBytesCartao] para testes de UI.
  Future<Uint8List> capturarCartaoFake(GlobalKey _) async => pngMinimoValido;
}
