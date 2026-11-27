// SPDX-FileCopyrightText: Copyright (C) 2026 Aresta Climb Contributors
// SPDX-License-Identifier: MPL-2.0

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:frontend/aresta_api/proto/generated/indice.pb.dart';

/// Resultado da execução de uma rotina de geração com rotação de cópia de segurança.
class ResultadoGeracaoComSeguranca {
  /// Indica se foi necessário recorrer à cópia de segurança devido à falha da fonte externa.
  final bool usouCopiaSeguranca;

  /// Mensagem descritiva do desfecho da operação para auditoria em terminal/CI.
  final String mensagem;

  const ResultadoGeracaoComSeguranca({
    required this.usouCopiaSeguranca,
    required this.mensagem,
  });
}

/// Gerador e rotacionador das malhas geográficas reais (IBGE API v3 + Natural Earth),
/// textura esférica NASA Blue Marble e altimetria/grade DEM real (NASA SRTM / Copernicus DEM).
///
/// Mantém exatamente uma cópia de segurança validada (`*.seguranca.*`) para cada artefato,
/// promovendo o arquivo atual anterior para cópia de segurança e descartando versões mais
/// antigas sempre que dados novos íntegros são coletados.
abstract final class GeradorMalhaGeograficaOffline {
  /// Limite máximo permitido para o arquivo vetorial de malha geográfica (400 KB).
  static const int limiteMaximoBytesMalha = 400 * 1024;

  /// Dimensão lateral (`N x N`) da grade DEM real amostrada ao redor de cada pico.
  static const int dimensaoGradeDem = 13;

  /// Raio angular (em graus de lat/lon, `~2.7 km`) coberto pela grade DEM local de cada pico.
  static const double raioGradeDemGraus = 0.024;

  static const Map<String, String> _codigoIbgeParaUf = <String, String>{
    '11': 'RO',
    '12': 'AC',
    '13': 'AM',
    '14': 'RR',
    '15': 'PA',
    '16': 'AP',
    '17': 'TO',
    '21': 'MA',
    '22': 'PI',
    '23': 'CE',
    '24': 'RN',
    '25': 'PB',
    '26': 'PE',
    '27': 'AL',
    '28': 'SE',
    '29': 'BA',
    '31': 'MG',
    '32': 'ES',
    '33': 'RJ',
    '35': 'SP',
    '41': 'PR',
    '42': 'SC',
    '43': 'RS',
    '50': 'MS',
    '51': 'MT',
    '52': 'GO',
    '53': 'DF',
  };

  /// Executa a geração e rotação atômica da malha geográfica (`atual` + `seguranca`).
  static Future<ResultadoGeracaoComSeguranca> executarGeracaoMalha({
    required String caminhoSaida,
    required String caminhoSeguranca,
    required Future<Map<String, dynamic>> Function() provedorMalhaExterna,
  }) {
    return _rotacionarJsonComCopiaSeguranca(
      caminhoSaida: caminhoSaida,
      caminhoSeguranca: caminhoSeguranca,
      buscarDados: provedorMalhaExterna,
      validarDados: validarEstruturaMalha,
      nomeRecurso: 'malha geográfica IBGE/Natural Earth',
    );
  }

  /// Executa a geração e rotação atômica do arquivo inicial de altimetria (`atual` + `seguranca`).
  static Future<ResultadoGeracaoComSeguranca> executarGeracaoAltimetria({
    required String caminhoSaida,
    required String caminhoSeguranca,
    required Future<Map<String, dynamic>> Function() provedorAltimetriaExterna,
  }) {
    return _rotacionarJsonComCopiaSeguranca(
      caminhoSaida: caminhoSaida,
      caminhoSeguranca: caminhoSeguranca,
      buscarDados: provedorAltimetriaExterna,
      validarDados: validarEstruturaAltimetria,
      nomeRecurso: 'altimetria real SRTM/Copernicus DEM',
    );
  }

  /// Executa a rotação atômica de um artefato binário (ex.: textura NASA Blue Marble) com 1 cópia de segurança.
  static Future<ResultadoGeracaoComSeguranca> executarGeracaoBinaria({
    required String caminhoSaida,
    required String caminhoSeguranca,
    required Future<List<int>> Function() provedorBytesExternos,
    int tamanhoMinimoBytes = 10240,
    String nomeRecurso = 'textura esférica NASA Blue Marble',
  }) async {
    final arquivoAtual = File(caminhoSaida);
    final arquivoSeguranca = File(caminhoSeguranca);
    arquivoAtual.parent.createSync(recursive: true);
    arquivoSeguranca.parent.createSync(recursive: true);

    bool validarBytes(File f) =>
        f.existsSync() && f.lengthSync() >= tamanhoMinimoBytes;

    try {
      final bytes = await provedorBytesExternos();
      if (bytes.length < tamanhoMinimoBytes) {
        throw FormatException(
          'Payload binário menor que $tamanhoMinimoBytes bytes para $nomeRecurso.',
        );
      }

      final arquivoTmp = File('$caminhoSaida.tmp');
      arquivoTmp.writeAsBytesSync(bytes, flush: true);

      if (validarBytes(arquivoAtual)) {
        arquivoAtual.copySync(caminhoSeguranca);
      } else {
        arquivoTmp.copySync(caminhoSeguranca);
      }

      if (arquivoAtual.existsSync()) {
        arquivoAtual.deleteSync();
      }
      arquivoTmp.renameSync(caminhoSaida);

      return ResultadoGeracaoComSeguranca(
        usouCopiaSeguranca: false,
        mensagem:
            'Atualizado $nomeRecurso (${bytes.length} bytes) e rotacionada cópia única de segurança.',
      );
    } catch (erro) {
      final arquivoTmp = File('$caminhoSaida.tmp');
      if (arquivoTmp.existsSync()) {
        arquivoTmp.deleteSync();
      }
      if (validarBytes(arquivoAtual)) {
        if (!validarBytes(arquivoSeguranca)) {
          arquivoAtual.copySync(caminhoSeguranca);
        }
        return ResultadoGeracaoComSeguranca(
          usouCopiaSeguranca: true,
          mensagem:
              'Falha ao baixar $nomeRecurso ($erro). Mantida versão local íntegra.',
        );
      }
      if (validarBytes(arquivoSeguranca)) {
        arquivoSeguranca.copySync(caminhoSaida);
        return ResultadoGeracaoComSeguranca(
          usouCopiaSeguranca: true,
          mensagem:
              'Falha ao baixar $nomeRecurso ($erro). Restaurado da cópia de segurança.',
        );
      }
      throw StateError(
        'Não foi possível obter $nomeRecurso ($erro) e não há cópia de segurança íntegra.',
      );
    }
  }

  static Future<ResultadoGeracaoComSeguranca> _rotacionarJsonComCopiaSeguranca({
    required String caminhoSaida,
    required String caminhoSeguranca,
    required Future<Map<String, dynamic>> Function() buscarDados,
    required bool Function(Map<String, dynamic> dados) validarDados,
    required String nomeRecurso,
  }) async {
    final arquivoAtual = File(caminhoSaida);
    final arquivoSeguranca = File(caminhoSeguranca);
    arquivoAtual.parent.createSync(recursive: true);
    arquivoSeguranca.parent.createSync(recursive: true);

    try {
      final novosDados = await buscarDados();
      if (!validarDados(novosDados)) {
        throw FormatException('Estrutura inválida recebida para $nomeRecurso.');
      }

      final conteudoJson = jsonEncode(novosDados);
      final arquivoTmp = File('$caminhoSaida.tmp');
      arquivoTmp.writeAsStringSync(conteudoJson, flush: true);

      if (_arquivoJsonIntegro(arquivoAtual, validarDados)) {
        arquivoAtual.copySync(caminhoSeguranca);
      } else {
        arquivoTmp.copySync(caminhoSeguranca);
      }

      if (arquivoAtual.existsSync()) {
        arquivoAtual.deleteSync();
      }
      arquivoTmp.renameSync(caminhoSaida);

      return ResultadoGeracaoComSeguranca(
        usouCopiaSeguranca: false,
        mensagem:
            'Atualizado $nomeRecurso (${utf8.encode(conteudoJson).length} bytes) e rotacionada cópia única de segurança.',
      );
    } catch (erro) {
      final arquivoTmp = File('$caminhoSaida.tmp');
      if (arquivoTmp.existsSync()) {
        arquivoTmp.deleteSync();
      }

      if (_arquivoJsonIntegro(arquivoAtual, validarDados)) {
        if (!_arquivoJsonIntegro(arquivoSeguranca, validarDados)) {
          arquivoAtual.copySync(caminhoSeguranca);
        }
        return ResultadoGeracaoComSeguranca(
          usouCopiaSeguranca: true,
          mensagem:
              'Falha ao consultar $nomeRecurso ($erro). Mantida versão local íntegra.',
        );
      }

      if (_arquivoJsonIntegro(arquivoSeguranca, validarDados)) {
        arquivoSeguranca.copySync(caminhoSaida);
        return ResultadoGeracaoComSeguranca(
          usouCopiaSeguranca: true,
          mensagem:
              'Falha ao consultar $nomeRecurso ($erro). Restaurado a partir da cópia de segurança.',
        );
      }

      throw StateError(
        'Não foi possível obter $nomeRecurso ($erro) e não há cópia de segurança íntegra disponível.',
      );
    }
  }

  static bool _arquivoJsonIntegro(
    File arquivo,
    bool Function(Map<String, dynamic>) validador,
  ) {
    if (!arquivo.existsSync()) return false;
    try {
      final decodificado = jsonDecode(arquivo.readAsStringSync());
      return decodificado is Map<String, dynamic> && validador(decodificado);
    } catch (_) {
      return false;
    }
  }

  /// Valida se o mapa JSON de malha geográfica contém continentes, contorno nacional e todas as 27 UFs.
  static bool validarEstruturaMalha(Map<String, dynamic> dados) {
    final continentes = dados['continentes'];
    final brasil = dados['brasil'];
    final estados = dados['estados_br'];
    if (continentes is! List || continentes.isEmpty) return false;
    if (brasil is! List || brasil.length < 10) return false;
    if (estados is! List || estados.length != 27) return false;

    final bytesEstimados = utf8.encode(jsonEncode(dados)).length;
    if (bytesEstimados > limiteMaximoBytesMalha) return false;

    final ufsEncontradas = <String>{};
    for (final item in estados) {
      if (item is! Map) return false;
      final uf = item['uf'];
      final poligono = item['poligono'];
      if (uf is! String || uf.length != 2) return false;
      if (poligono is! List || poligono.length < 4) return false;
      ufsEncontradas.add(uf);
    }
    return ufsEncontradas.length == 27;
  }

  /// Valida se o mapa JSON de altimetria possui cotas numéricas plausíveis para cada pico listado.
  static bool validarEstruturaAltimetria(Map<String, dynamic> dados) {
    final picos = dados['picos'];
    if (picos is! Map || picos.isEmpty) return false;
    for (final entrada in picos.entries) {
      if (entrada.key is! String || (entrada.key as String).isEmpty) {
        return false;
      }
      final val = entrada.value;
      if (val is! Map) return false;
      final base = val['altitude_base_m'];
      final topo = val['altitude_pico_m'];
      if (base is! num || topo is! num) return false;
      if (base < -50 || topo > 4000 || topo < base) return false;
      final grade = val['grade_dem_m'];
      if (grade != null) {
        if (grade is! List || grade.isEmpty) return false;
      }
    }
    return true;
  }

  /// Coleta online a malha real de massas continentais (Natural Earth 110m) e as 27 UFs oficiais (IBGE v3).
  static Future<Map<String, dynamic>> buscarMalhaRealIbgeENaturalEarth() async {
    final cliente = HttpClient()..connectionTimeout = const Duration(seconds: 25);
    try {
      final textoLand = await _getTextoHttp(
        cliente,
        'https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_110m_land.geojson',
      );
      final textoBrasil = await _getTextoHttp(
        cliente,
        'https://servicodados.ibge.gov.br/api/v3/malhas/paises/BR?formato=application/vnd.geo+json&qualidade=minima',
      );
      final textoUfs = await _getTextoHttp(
        cliente,
        'https://servicodados.ibge.gov.br/api/v3/malhas/paises/BR?intrarregiao=UF&formato=application/vnd.geo+json&qualidade=minima',
      );

      final geoLand = jsonDecode(textoLand) as Map<String, dynamic>;
      final continentes = <Map<String, dynamic>>[];
      var idxCont = 0;
      for (final anel in _extrairAneisGeoJson(geoLand)) {
        final simplificado = simplificarDouglasPeucker(anel, 0.14);
        if (simplificado.length >= 5) {
          continentes.add(<String, dynamic>{
            'id': 'massa_${idxCont++}',
            'poligono': _arredondarVertices(simplificado, casas: 2),
          });
        }
      }

      final geoBr = jsonDecode(textoBrasil) as Map<String, dynamic>;
      final aneisBr = _extrairAneisGeoJson(geoBr);
      aneisBr.sort((a, b) => b.length.compareTo(a.length));
      final contornoBrasil = _arredondarVertices(
        simplificarDouglasPeucker(aneisBr.first, 0.05),
        casas: 3,
      );

      final geoUfs = jsonDecode(textoUfs) as Map<String, dynamic>;
      final featuresUf = geoUfs['features'] as List<dynamic>;
      final estadosBr = <Map<String, dynamic>>[];

      for (final feat in featuresUf) {
        final fMap = feat as Map<String, dynamic>;
        final props = (fMap['properties'] as Map<String, dynamic>?) ?? const {};
        final cod = (props['codarea'] ?? fMap['id'] ?? '').toString();
        final uf = _codigoIbgeParaUf[cod];
        if (uf == null) continue;

        final aneisUf = _extrairAneisDeGeometria(
          fMap['geometry'] as Map<String, dynamic>,
        );
        if (aneisUf.isEmpty) continue;
        aneisUf.sort((a, b) => b.length.compareTo(a.length));
        final simplificado = simplificarDouglasPeucker(aneisUf.first, 0.035);
        estadosBr.add(<String, dynamic>{
          'uf': uf,
          'poligono': _arredondarVertices(simplificado, casas: 3),
        });
      }

      estadosBr.sort(
        (a, b) => (a['uf'] as String).compareTo(b['uf'] as String),
      );

      return <String, dynamic>{
        'versao': '2026.11-ibge-v3-ne110m',
        'fonte': 'IBGE API v3 Malhas Oficiais + Natural Earth 110m Land',
        'continentes': continentes,
        'brasil': contornoBrasil,
        'estados_br': estadosBr,
      };
    } finally {
      cliente.close(force: true);
    }
  }

  /// Coleta online a altimetria real NASA SRTM 30m (AWS Open Data Terrarium `z=12`, `~35m/px`)
  /// e extrai a grade `13x13` de relevo real ao redor das coordenadas de cada pico em `indice.binarypb`.
  static Future<Map<String, dynamic>> buscarAltimetriaRealDemParaIndice({
    required String caminhoIndiceBinaryPb,
    String urlBaseTerrarium =
        'https://s3.amazonaws.com/elevation-tiles-prod/terrarium',
  }) async {
    final arquivo = File(caminhoIndiceBinaryPb);
    if (!arquivo.existsSync()) {
      throw ArgumentError(
        'Arquivo de índice não encontrado: $caminhoIndiceBinaryPb',
      );
    }

    final indice = Indice.fromBuffer(arquivo.readAsBytesSync());
    final picos = <({String id, double lat, double lon})>[];
    for (final c in indice.croquis) {
      if (c.id.isEmpty || !c.hasLocalizacao()) continue;
      final lat = c.localizacao.latitude / 10000000.0;
      final lon = c.localizacao.longitude / 10000000.0;
      if (lat == 0 && lon == 0) continue;
      picos.add((id: c.id, lat: lat, lon: lon));
    }

    const zoom = 12;
    const n = dimensaoGradeDem;
    const span = raioGradeDemGraus;
    final cacheTiles = <String, List<double>>{};

    final cliente = HttpClient()
      ..connectionTimeout = const Duration(seconds: 25);
    try {
      Future<double> amostrarSrtm30m(double lat, double lon) async {
        final escalaMundo = 256.0 * (1 << zoom);
        final pxGlobal = ((lon + 180.0) / 360.0) * escalaMundo;
        final latRad = lat * math.pi / 180.0;
        final pyGlobal =
            ((1.0 -
                    math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) /
                        math.pi) *
                0.5) *
            escalaMundo;

        final tx = (pxGlobal ~/ 256).clamp(0, (1 << zoom) - 1);
        final ty = (pyGlobal ~/ 256).clamp(0, (1 << zoom) - 1);
        final chave = '$zoom/$tx/$ty';

        var gradeTile = cacheTiles[chave];
        if (gradeTile == null) {
          final bytesPng = await _getBytesHttp(
            cliente,
            '$urlBaseTerrarium/$chave.png',
          );
          gradeTile = decodificarPngTerrarium256(bytesPng);
          cacheTiles[chave] = gradeTile;
        }

        final lx = (pxGlobal - tx * 256).clamp(0.0, 255.0);
        final ly = (pyGlobal - ty * 256).clamp(0.0, 255.0);
        final x0 = lx.floor().clamp(0, 255);
        final y0 = ly.floor().clamp(0, 255);
        final x1 = math.min(255, x0 + 1);
        final y1 = math.min(255, y0 + 1);
        final fx = lx - x0;
        final fy = ly - y0;

        final e00 = gradeTile[y0 * 256 + x0];
        final e10 = gradeTile[y0 * 256 + x1];
        final e01 = gradeTile[y1 * 256 + x0];
        final e11 = gradeTile[y1 * 256 + x1];
        final topo = e00 + (e10 - e00) * fx;
        final base = e01 + (e11 - e01) * fx;
        return topo + (base - topo) * fy;
      }

      final mapaPicos = <String, Map<String, dynamic>>{};
      for (final p in picos) {
        final gradeInt = <int>[];
        for (var j = 0; j < n; j++) {
          final v = -1.0 + (2.0 * j) / (n - 1);
          final lat = p.lat + v * span;
          for (var i = 0; i < n; i++) {
            final u = -1.0 + (2.0 * i) / (n - 1);
            final lon = p.lon + u * span;
            final cota = await amostrarSrtm30m(lat, lon);
            gradeInt.add(cota.round());
          }
        }

        // Varredura fina de 35m em raio de ~600m (cume/parede) e ~1.2km (base/vale)
        var minBase = 99999;
        var maxMacico = -99999;
        for (var sj = -8; sj <= 8; sj++) {
          final dLat = sj * 0.0014; // ~155m por passo -> ±1.24 km
          for (var si = -8; si <= 8; si++) {
            final dLon = si * 0.0014;
            final dist = math.sqrt(dLat * dLat + dLon * dLon);
            if (dist > 0.0115) continue;
            final v = (await amostrarSrtm30m(p.lat + dLat, p.lon + dLon)).round();
            if (v < minBase) minBase = v;
            if (dist <= 0.0055 && v > maxMacico) {
              maxMacico = v;
            }
          }
        }

        final cotaExataPino = (await amostrarSrtm30m(p.lat, p.lon)).round();
        if (cotaExataPino > maxMacico) maxMacico = cotaExataPino;
        if (cotaExataPino < minBase) minBase = cotaExataPino;

        mapaPicos[p.id] = <String, dynamic>{
          'altitude_ponto_m': cotaExataPino,
          'altitude_base_m': minBase,
          'altitude_pico_m': math.max(minBase, maxMacico),
          'dimensao_grade': n,
          'raio_grade_graus': span,
          'grade_dem_m': gradeInt,
        };
      }

      return <String, dynamic>{
        'versao': '2026.11-nasa-srtm30m-terrarium-real',
        'fonte': 'NASA SRTM 30m / NASADEM (AWS Open Data Terrarium Tiles z=12)',
        'picos': mapaPicos,
      };
    } finally {
      cliente.close(force: true);
    }
  }

  /// Decodifica um tile PNG `256x256` (RGB ou RGBA 8-bit) codificado em formato Terrarium
  /// (`elevacao_m = R * 256 + G + B / 256 - 32768`) usando apenas `dart:io` (`zlib`).
  static List<double> decodificarPngTerrarium256(List<int> bytesPng) {
    if (bytesPng.length < 33 ||
        bytesPng[0] != 0x89 ||
        bytesPng[1] != 0x50 ||
        bytesPng[2] != 0x4E ||
        bytesPng[3] != 0x47) {
      throw const FormatException('Assinatura PNG inválida em tile Terrarium.');
    }

    int lerUint32(int pos) =>
        (bytesPng[pos] << 24) |
        (bytesPng[pos + 1] << 16) |
        (bytesPng[pos + 2] << 8) |
        bytesPng[pos + 3];

    var offset = 8;
    var largura = 0;
    var altura = 0;
    var tipoCor = 0;
    final idatBuffer = BytesBuilder(copy: false);

    while (offset + 8 <= bytesPng.length) {
      final tam = lerUint32(offset);
      final tipo = String.fromCharCodes(bytesPng.sublist(offset + 4, offset + 8));
      final dadosIni = offset + 8;
      if (dadosIni + tam + 4 > bytesPng.length) break;

      if (tipo == 'IHDR') {
        largura = lerUint32(dadosIni);
        altura = lerUint32(dadosIni + 4);
        final bits = bytesPng[dadosIni + 8];
        tipoCor = bytesPng[dadosIni + 9];
        if (bits != 8 || (tipoCor != 2 && tipoCor != 6)) {
          throw FormatException(
            'Formato PNG Terrarium não suportado (bits=$bits, cor=$tipoCor).',
          );
        }
      } else if (tipo == 'IDAT') {
        idatBuffer.add(bytesPng.sublist(dadosIni, dadosIni + tam));
      } else if (tipo == 'IEND') {
        break;
      }
      offset = dadosIni + tam + 4;
    }

    if (largura != 256 || altura != 256) {
      throw FormatException('Dimensão inesperada de tile ($largura x $altura).');
    }

    final bpp = tipoCor == 6 ? 4 : 3;
    final stride = largura * bpp;
    final descomprimido = zlib.decode(idatBuffer.takeBytes());
    if (descomprimido.length < altura * (1 + stride)) {
      throw const FormatException('Dados IDAT truncados em tile Terrarium.');
    }

    final linhaAtual = List<int>.filled(stride, 0);
    final linhaAnterior = List<int>.filled(stride, 0);
    final elevacoes = List<double>.filled(largura * altura, 0.0);

    int paeth(int a, int b, int c) {
      final p = a + b - c;
      final pa = (p - a).abs();
      final pb = (p - b).abs();
      final pc = (p - c).abs();
      if (pa <= pb && pa <= pc) return a;
      if (pb <= pc) return b;
      return c;
    }

    var src = 0;
    for (var y = 0; y < altura; y++) {
      final filtro = descomprimido[src++];
      for (var i = 0; i < stride; i++) {
        final bruto = descomprimido[src++];
        final esq = i >= bpp ? linhaAtual[i - bpp] : 0;
        final cima = linhaAnterior[i];
        final diag = i >= bpp ? linhaAnterior[i - bpp] : 0;
        int rec;
        switch (filtro) {
          case 0:
            rec = bruto;
          case 1:
            rec = (bruto + esq) & 0xFF;
          case 2:
            rec = (bruto + cima) & 0xFF;
          case 3:
            rec = (bruto + ((esq + cima) >> 1)) & 0xFF;
          case 4:
            rec = (bruto + paeth(esq, cima, diag)) & 0xFF;
          default:
            throw FormatException('Filtro PNG desconhecido: $filtro');
        }
        linhaAtual[i] = rec;
      }

      for (var x = 0; x < largura; x++) {
        final baseIdx = x * bpp;
        final r = linhaAtual[baseIdx];
        final g = linhaAtual[baseIdx + 1];
        final b = linhaAtual[baseIdx + 2];
        elevacoes[y * largura + x] = (r * 256.0 + g + b / 256.0) - 32768.0;
      }

      for (var i = 0; i < stride; i++) {
        linhaAnterior[i] = linhaAtual[i];
      }
    }

    return elevacoes;
  }

  /// Baixa a textura equiretangular pública NASA Blue Marble (`2048x1024`).
  static Future<List<int>> baixarTexturaNasaBlueMarble() async {
    final cliente = HttpClient()..connectionTimeout = const Duration(seconds: 25);
    try {
      const urls = <String>[
        'https://cdn.jsdelivr.net/npm/three-globe/example/img/earth-blue-marble.jpg',
        'https://unpkg.com/three-globe/example/img/earth-blue-marble.jpg',
      ];
      Object? ultimoErro;
      for (final url in urls) {
        try {
          return await _getBytesHttp(cliente, url);
        } catch (e) {
          ultimoErro = e;
        }
      }
      throw StateError('Falha em todos os mirrors NASA Blue Marble: $ultimoErro');
    } finally {
      cliente.close(force: true);
    }
  }

  /// Simplificação geométrica Ramer-Douglas-Peucker preservando extremos de anéis fechados.
  static List<List<double>> simplificarDouglasPeucker(
    List<List<double>> pontos,
    double toleranciaGraus,
  ) {
    if (pontos.length <= 5) return pontos;
    final usados = List<bool>.filled(pontos.length, false);
    usados[0] = true;
    usados[pontos.length - 1] = true;
    // Garante ao menos o ponto médio oposto em anéis fechados onde início == fim
    final meio = pontos.length ~/ 2;
    usados[meio] = true;

    void subdividir(int ini, int fim) {
      if (fim - ini <= 1) return;
      var maiorDist = -1.0;
      var melhorIdx = -1;
      final ax = pontos[ini][0];
      final ay = pontos[ini][1];
      final bx = pontos[fim][0];
      final by = pontos[fim][1];
      final dx = bx - ax;
      final dy = by - ay;
      final norm2 = dx * dx + dy * dy;

      for (var i = ini + 1; i < fim; i++) {
        final px = pontos[i][0];
        final py = pontos[i][1];
        double d2;
        if (norm2 < 1e-12) {
          d2 = (px - ax) * (px - ax) + (py - ay) * (py - ay);
        } else {
          final t = (((px - ax) * dx + (py - ay) * dy) / norm2).clamp(0.0, 1.0);
          final projX = ax + t * dx;
          final projY = ay + t * dy;
          d2 = (px - projX) * (px - projX) + (py - projY) * (py - projY);
        }
        if (d2 > maiorDist) {
          maiorDist = d2;
          melhorIdx = i;
        }
      }

      if (melhorIdx != -1 && maiorDist > toleranciaGraus * toleranciaGraus) {
        usados[melhorIdx] = true;
        subdividir(ini, melhorIdx);
        subdividir(melhorIdx, fim);
      }
    }

    subdividir(0, meio);
    subdividir(meio, pontos.length - 1);

    final saida = <List<double>>[];
    for (var i = 0; i < pontos.length; i++) {
      if (usados[i]) saida.add(pontos[i]);
    }
    return saida;
  }

  static List<List<List<double>>> _extrairAneisGeoJson(
    Map<String, dynamic> geoJson,
  ) {
    final tipo = geoJson['type'];
    if (tipo == 'FeatureCollection') {
      final aneis = <List<List<double>>>[];
      for (final f in (geoJson['features'] as List<dynamic>)) {
        final geom = (f as Map<String, dynamic>)['geometry'];
        if (geom is Map<String, dynamic>) {
          aneis.addAll(_extrairAneisDeGeometria(geom));
        }
      }
      return aneis;
    }
    if (tipo == 'Feature') {
      return _extrairAneisDeGeometria(
        geoJson['geometry'] as Map<String, dynamic>,
      );
    }
    return _extrairAneisDeGeometria(geoJson);
  }

  static List<List<List<double>>> _extrairAneisDeGeometria(
    Map<String, dynamic> geom,
  ) {
    final tipo = geom['type'];
    final coords = geom['coordinates'] as List<dynamic>;
    final aneis = <List<List<double>>>[];
    if (tipo == 'Polygon') {
      if (coords.isNotEmpty) {
        aneis.add(_converterAnelBruto(coords.first as List<dynamic>));
      }
    } else if (tipo == 'MultiPolygon') {
      for (final pol in coords) {
        final anelLista = pol as List<dynamic>;
        if (anelLista.isNotEmpty) {
          aneis.add(_converterAnelBruto(anelLista.first as List<dynamic>));
        }
      }
    }
    return aneis;
  }

  static List<List<double>> _converterAnelBruto(List<dynamic> bruto) {
    return bruto
        .map((c) {
          final par = c as List<dynamic>;
          return <double>[
            (par[0] as num).toDouble(),
            (par[1] as num).toDouble(),
          ];
        })
        .toList(growable: false);
  }

  static List<List<double>> _arredondarVertices(
    List<List<double>> vertices, {
    required int casas,
  }) {
    final fator = math.pow(10, casas).toDouble();
    return vertices
        .map(
          (v) => <double>[
            (v[0] * fator).round() / fator,
            (v[1] * fator).round() / fator,
          ],
        )
        .toList(growable: false);
  }

  static Future<String> _getTextoHttp(HttpClient cliente, String url) async {
    final bytes = await _getBytesHttp(cliente, url);
    return utf8.decode(bytes);
  }

  static Future<List<int>> _getBytesHttp(HttpClient cliente, String url) async {
    for (var tentativa = 1; tentativa <= 4; tentativa++) {
      final req = await cliente.getUrl(Uri.parse(url));
      req.headers.set(HttpHeaders.userAgentHeader, 'ArestaClimbOfflineTool/1.0');
      final resp = await req.close();
      if (resp.statusCode == 200) {
        final builder = BytesBuilder(copy: false);
        await for (final chunk in resp) {
          builder.add(chunk);
        }
        return builder.takeBytes();
      }
      await resp.drain<void>();
      if ((resp.statusCode == 429 || resp.statusCode >= 500) && tentativa < 4) {
        await Future<void>.delayed(Duration(milliseconds: 1600 * tentativa));
        continue;
      }
      throw HttpException('HTTP ${resp.statusCode} em $url');
    }
    throw HttpException('Falha após retentativas em $url');
  }

  /// Malha sintética mínima exclusiva para testes unitários determinísticos sem rede.
  static Map<String, dynamic> construirMalhaPadraoEmbutida({
    String versao = '2026.11-sintetica-teste',
  }) {
    const ufs = <String>[
      'AC', 'AL', 'AM', 'AP', 'BA', 'CE', 'DF', 'ES', 'GO',
      'MA', 'MG', 'MS', 'MT', 'PA', 'PB', 'PE', 'PI', 'PR',
      'RJ', 'RN', 'RO', 'RR', 'RS', 'SC', 'SE', 'SP', 'TO',
    ];
    return <String, dynamic>{
      'versao': versao,
      'fonte': 'Malha sintética para testes unitários offline',
      'continentes': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'america_do_sul',
          'poligono': const <List<double>>[
            [-79.5, 9.2], [-35.0, -5.8], [-53.6, -33.6], [-71.0, -53.0], [-79.5, 9.2],
          ],
        },
      ],
      'brasil': const <List<double>>[
        [-70.0, -4.2], [-60.2, 4.2], [-49.5, 1.8], [-38.5, -3.8],
        [-34.8, -8.2], [-39.1, -16.8], [-43.2, -23.0], [-48.5, -26.5],
        [-53.6, -33.6], [-58.2, -16.2], [-70.0, -4.2],
      ],
      'estados_br': [
        for (var i = 0; i < ufs.length; i++)
          <String, dynamic>{
            'uf': ufs[i],
            'poligono': <List<double>>[
              [-50.0 + (i % 5), -22.0 + (i ~/ 5)],
              [-49.0 + (i % 5), -22.0 + (i ~/ 5)],
              [-49.0 + (i % 5), -21.0 + (i ~/ 5)],
              [-50.0 + (i % 5), -21.0 + (i ~/ 5)],
              [-50.0 + (i % 5), -22.0 + (i ~/ 5)],
            ],
          },
      ],
    };
  }

  /// Altimetria sintética mínima exclusiva para testes unitários determinísticos sem rede.
  static Map<String, dynamic> construirAltimetriaDoIndiceLocal({
    required String caminhoIndiceBinaryPb,
    String versao = '2026.11-sintetica-teste',
  }) {
    final arquivo = File(caminhoIndiceBinaryPb);
    final picosMapa = <String, Map<String, dynamic>>{};
    if (arquivo.existsSync()) {
      final indice = Indice.fromBuffer(arquivo.readAsBytesSync());
      for (final c in indice.croquis) {
        if (c.id.isEmpty) continue;
        picosMapa[c.id] = const <String, dynamic>{
          'altitude_base_m': 700,
          'altitude_pico_m': 980,
        };
      }
    }
    if (picosMapa.isEmpty) {
      picosMapa['br_mg_igarape_pedra_grande'] = const <String, dynamic>{
        'altitude_base_m': 950,
        'altitude_pico_m': 1425,
      };
    }
    return <String, dynamic>{
      'versao': versao,
      'fonte': 'Altimetria sintética para testes unitários offline',
      'picos': picosMapa,
    };
  }
}

Future<void> main(List<String> args) async {
  final raizFrontend = Directory.current.path;
  final modoOfflineSintetico = args.contains('--sintetico-teste');

  final resMalha = await GeradorMalhaGeograficaOffline.executarGeracaoMalha(
    caminhoSaida: '$raizFrontend/assets/geometria/malha_globo_brasil.json',
    caminhoSeguranca:
        '$raizFrontend/assets/geometria/malha_globo_brasil.seguranca.json',
    provedorMalhaExterna: modoOfflineSintetico
        ? () async => GeradorMalhaGeograficaOffline.construirMalhaPadraoEmbutida()
        : GeradorMalhaGeograficaOffline.buscarMalhaRealIbgeENaturalEarth,
  );
  print(
    '[GeradorMalha] ${resMalha.mensagem} '
    '(copiaSeguranca=${resMalha.usouCopiaSeguranca})',
  );

  final resAlt = await GeradorMalhaGeograficaOffline.executarGeracaoAltimetria(
    caminhoSaida: '$raizFrontend/assets/dados/altimetria_picos_inicial.json',
    caminhoSeguranca:
        '$raizFrontend/assets/dados/altimetria_picos_inicial.seguranca.json',
    provedorAltimetriaExterna: () => modoOfflineSintetico
        ? Future.value(
            GeradorMalhaGeograficaOffline.construirAltimetriaDoIndiceLocal(
              caminhoIndiceBinaryPb:
                  '$raizFrontend/assets/preload/indice.binarypb',
            ),
          )
        : GeradorMalhaGeograficaOffline.buscarAltimetriaRealDemParaIndice(
            caminhoIndiceBinaryPb:
                '$raizFrontend/assets/preload/indice.binarypb',
          ),
  );
  print(
    '[GeradorAltimetria] ${resAlt.mensagem} '
    '(copiaSeguranca=${resAlt.usouCopiaSeguranca})',
  );

  if (!modoOfflineSintetico) {
    final resTex = await GeradorMalhaGeograficaOffline.executarGeracaoBinaria(
      caminhoSaida: '$raizFrontend/assets/geometria/textura_globo_nasa.jpg',
      caminhoSeguranca:
          '$raizFrontend/assets/geometria/textura_globo_nasa.seguranca.jpg',
      provedorBytesExternos:
          GeradorMalhaGeograficaOffline.baixarTexturaNasaBlueMarble,
    );
    print(
      '[GeradorTexturaNasa] ${resTex.mensagem} '
      '(copiaSeguranca=${resTex.usouCopiaSeguranca})',
    );
  }
}
