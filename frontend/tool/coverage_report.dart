import 'dart:io';

void main(List<String> args) {
  final currentDir = Directory.current.path;
  
  // O script pode ser rodado da pasta frontend/ ou da pasta coverage/
  final lcovPath = currentDir.endsWith('coverage') ? 'lcov.info' : 'coverage/lcov.info';
  final outHtmlPath = currentDir.endsWith('coverage') ? 'coverage_report.html' : 'coverage/coverage_report.html';
  
  generateReport(lcovPath, outHtmlPath);
}

void generateReport(String lcovPath, String outHtmlPath) {
  final file = File(lcovPath);
  if (!file.existsSync()) {
    print('Arquivo de coverage não encontrado em: ' + lcovPath);
    return;
  }

  final lines = file.readAsLinesSync();
  
  String currentFile = '';
  int fileFound = 0;
  int fileHit = 0;
  int totalFound = 0;
  int totalHit = 0;
  
  List<Map<String, dynamic>> fileStats = [];

  bool ignoreCurrentFile = false;

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      // Ignora a pasta lib/aresta_api (código gerado)
      if (currentFile.contains('lib/aresta_api') || currentFile.contains('lib\\aresta_api')) {
        ignoreCurrentFile = true;
      } else {
        ignoreCurrentFile = false;
        fileFound = 0;
        fileHit = 0;
      }
    } else if (!ignoreCurrentFile) {
      if (line.startsWith('LF:')) {
        fileFound = int.parse(line.substring(3));
        totalFound += fileFound;
      } else if (line.startsWith('LH:')) {
        fileHit = int.parse(line.substring(3));
        totalHit += fileHit;
      } else if (line == 'end_of_record') {
        if (fileFound > 0) {
          fileStats.add({
            'file': currentFile,
            'found': fileFound,
            'hit': fileHit,
            'percentage': (fileHit / fileFound) * 100,
          });
        }
      }
    }
  }

  // Ordena por porcentagem (crescente)
  fileStats.sort((a, b) => (a['percentage'] as double).compareTo(b['percentage'] as double));

  final double totalPercentage = totalFound > 0 ? (totalHit / totalFound) * 100 : 0;

  final StringBuffer html = StringBuffer();
  html.writeln('<!DOCTYPE html>');
  html.writeln('<html lang="pt-BR">');
  html.writeln('<head>');
  html.writeln('    <meta charset="UTF-8">');
  html.writeln('    <meta name="viewport" content="width=device-width, initial-scale=1.0">');
  html.writeln('    <title>Relatório de Cobertura de Testes</title>');
  html.writeln('    <style>');
  html.writeln('        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; max-width: 1000px; margin: 0 auto; padding: 20px; }');
  html.writeln('        h1 { border-bottom: 2px solid #eee; padding-bottom: 10px; }');
  html.writeln('        .summary { background: #f8f9fa; border-radius: 8px; padding: 20px; margin-bottom: 30px; border-left: 5px solid #007bff; }');
  html.writeln('        .summary h2 { margin-top: 0; }');
  html.writeln('        table { width: 100%; border-collapse: collapse; margin-top: 20px; }');
  html.writeln('        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }');
  html.writeln('        th { background-color: #f2f2f2; font-weight: bold; }');
  html.writeln('        tr:hover { background-color: #f5f5f5; }');
  html.writeln('        .pct-low { color: #d9534f; font-weight: bold; }');
  html.writeln('        .pct-medium { color: #f0ad4e; font-weight: bold; }');
  html.writeln('        .pct-high { color: #5cb85c; font-weight: bold; }');
  html.writeln('    </style>');
  html.writeln('</head>');
  html.writeln('<body>');
  
  html.writeln('    <h1>📊 Relatório Detalhado de Cobertura de Testes</h1>');
  
  html.writeln('    <div class="summary">');
  html.writeln('        <h2>Resumo Geral (Excluindo código gerado)</h2>');
  html.writeln('        <p><strong>Cobertura Total:</strong> ' + totalPercentage.toStringAsFixed(2) + '%</p>');
  html.writeln('        <p><strong>Linhas Cobertas:</strong> ' + totalHit.toString() + ' de ' + totalFound.toString() + '</p>');
  html.writeln('    </div>');
  
  html.writeln('    <h2>Cobertura por Arquivo</h2>');
  html.writeln('    <table>');
  html.writeln('        <thead>');
  html.writeln('            <tr>');
  html.writeln('                <th>Arquivo</th>');
  html.writeln('                <th>Cobertura (%)</th>');
  html.writeln('                <th>Linhas Cobertas</th>');
  html.writeln('                <th>Total de Linhas</th>');
  html.writeln('            </tr>');
  html.writeln('        </thead>');
  html.writeln('        <tbody>');
  
  for (var stat in fileStats) {
    final double pct = stat['percentage'];
    String pctClass = 'pct-high';
    if (pct < 50) {
      pctClass = 'pct-low';
    } else if (pct < 80) {
      pctClass = 'pct-medium';
    }

    final int hit = stat['hit'];
    final int found = stat['found'];
    final String fileStr = stat['file'];
    
    html.writeln('            <tr>');
    html.writeln('                <td>' + fileStr + '</td>');
    html.writeln('                <td class="' + pctClass + '">' + pct.toStringAsFixed(2) + '%</td>');
    html.writeln('                <td>' + hit.toString() + '</td>');
    html.writeln('                <td>' + found.toString() + '</td>');
    html.writeln('            </tr>');
  }
  
  html.writeln('        </tbody>');
  html.writeln('    </table>');
  html.writeln('</body>');
  html.writeln('</html>');

  final outFile = File(outHtmlPath);
  outFile.writeAsStringSync(html.toString());
  print('HTML gerado em: ' + outFile.absolute.path);
}
