// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

export 'package:http/http.dart'
    show
        Response,
        Request,
        StreamedResponse,
        MultipartRequest,
        MultipartFile,
        ClientException,
        BaseRequest,
        ByteStream;

/// Cliente HTTP encapsulado e centralizado do ecossistema Aresta Climb.
///
/// Existe para garantir que todas as operações de rede do aplicativo compartilhem
/// um único pool de conexões TCP/TLS persistentes (*HTTP Keep-Alive*), evitando o
/// custo de múltiplos handshakes TLS consecutivos ao carregar croquis e imagens da CDN.
///
/// Regras de design e arquitetura:
/// 1. **Apenas duas formas de instanciação**:
///    - [ClienteHttpAresta.instancia]: singleton global por Isolate para uso em produção;
///    - [ClienteHttpAresta.paraTestes]: fábrica exclusiva para injeção de clientes simulados em testes.
/// 2. **Imutabilidade do ciclo de vida (Sem método `.close()`)**:
///    - A interface pública omite propositalmente o método `.close()`, tornando impossível
///      em tempo de compilação que um ViewModel ou serviço encerre acidentalmente o cliente
///      compartilhado durante o descarte de uma tela.
/// 3. **Isolamento do pacote `http`**:
///    - Nenhum outro arquivo em `lib/` deve importar `package:http/http.dart` ou referenciar
///      `http.Client` diretamente; tipos auxiliares de requisição e resposta são re-exportados
///      por este módulo.
class ClienteHttpAresta {
  /// Tempo máximo em que uma conexão ociosa permanece viva no pool (*Keep-Alive*)
  /// aguardando novas requisições para o mesmo servidor antes de ser liberada pelo SO.
  static const Duration tempoOciosidadeKeepAlive = Duration(seconds: 120);

  /// Tempo limite máximo para o estabelecimento inicial do socket TCP/TLS.
  static const Duration tempoLimiteConexao = Duration(seconds: 10);

  final http.Client _clienteInterno;

  /// Construtor privado para impedir instanciações avulsas fora do controle arquitetural.
  const ClienteHttpAresta._(this._clienteInterno);

  /// Instância singleton global compartilhada por todo o aplicativo no Isolate atual.
  static final ClienteHttpAresta instancia =
      ClienteHttpAresta._(_criarClienteNativo());

  /// Fábrica exclusiva para testes automatizados que permite encapsular um `MockClient`
  /// ou cliente falso sem expor `http.Client` nas assinaturas de produção.
  @visibleForTesting
  factory ClienteHttpAresta.paraTestes(http.Client clienteMock) {
    return ClienteHttpAresta._(clienteMock);
  }

  /// Constrói o cliente nativo baseado em `dart:io` com pool Keep-Alive de 120 segundos.
  static http.Client _criarClienteNativo() {
    final clienteIo = HttpClient()
      ..idleTimeout = tempoOciosidadeKeepAlive
      ..connectionTimeout = tempoLimiteConexao;
    return IOClient(clienteIo);
  }

  /// Executa uma requisição HTTP GET para a [url] informada reutilizando conexões ativas do pool.
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return _clienteInterno.get(url, headers: headers);
  }

  /// Executa uma requisição HTTP POST para a [url] informada reutilizando conexões ativas do pool.
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return _clienteInterno.post(
      url,
      headers: headers,
      body: body,
      encoding: encoding,
    );
  }

  /// Executa uma requisição HTTP HEAD para a [url] informada reutilizando conexões ativas do pool.
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) {
    return _clienteInterno.head(url, headers: headers);
  }

  /// Envia uma requisição HTTP genérica ou em streaming ([http.BaseRequest], [http.MultipartRequest])
  /// reutilizando conexões ativas do pool.
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _clienteInterno.send(request);
  }
}
