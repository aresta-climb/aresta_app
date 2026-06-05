import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/services/firebase/telemetry_service.dart';
import 'package:frontend/services/firebase/app_logger.dart';

class TermsOfUsePage extends StatefulWidget {
  final VoidCallback onAccepted;

  const TermsOfUsePage({super.key, required this.onAccepted});

  @override
  State<TermsOfUsePage> createState() => _TermsOfUsePageState();
}

class _TermsOfUsePageState extends State<TermsOfUsePage> {
  bool _isChecked = false;

  final String _termsMarkdown = '''
### TERMO DE RESPONSABILIDADE E ACEITAÇÃO DE RISCOS

Bem-vindo à Aresta Climb. A Aresta Climb é um aplicativo colaborativo que cataloga picos de escalada para facilitar o acesso à informação, centralizando croquis e dados úteis para a comunidade.

Antes de prosseguir, é obrigatório ler e concordar com os termos abaixo:

**1. A Escalada é um Esporte de Alto Risco:** A escalada em rocha, montanhismo e atividades relacionadas envolvem riscos inerentes, graves e imprevisíveis que podem resultar em lesões severas ou fatalidade. O uso deste aplicativo não substitui o treinamento formal, o julgamento técnico em campo e a responsabilidade pessoal.

**2. Precisão e Atualização dos Croquis:** As informações sobre as vias, graduações e beta são fornecidas "no estado em que se encontram". Como o aplicativo opera com sincronização de dados que podem ser acessados offline, atualizações críticas sobre o estado de uma via podem não refletir a realidade atual no momento da sua escalada.

**3. Integridade das Ancoragens e Proteções:** A presença de uma via no croqui do aplicativo não atesta a segurança das proteções fixas. A condição da rocha e dos equipamentos (chapeletas, grampos, ancoragens químicas ou paradas) sofre desgaste natural e intemperismo. A avaliação da integridade de cada ponto de segurança, bem como a ciência sobre o histórico de regrampeações do local, é de responsabilidade exclusiva do escalador antes de iniciar a via.

**4. Uso da Informação:** O usuário reconhece que a interpretação e a navegação baseadas nos dados da Aresta Climb são feitas por sua própria conta e risco. Os desenvolvedores e mantenedores do aplicativo estão isentos de qualquer responsabilidade civil ou criminal por acidentes, danos a equipamentos ou resgates decorrentes do uso destas informações.

**5. Política de Privacidade:** Ao utilizar a Aresta Climb, você também concorda com a nossa Política de Privacidade, que detalha a forma como lidamos com a coleta anônima de dados de uso e permissões locais. Você pode acessá-la integralmente lendo a nossa [Política de Privacidade](https://aresta-climb.github.io/POLITICA_DE_PRIVACIDADE_ARESTA_CLIMB.html).
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos de Uso'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: _termsMarkdown,
              onTapLink: (text, href, title) async {
                if (href != null) {
                  TelemetryService.instance.logLinkExterno(href, 'termos_uso');
                  final url = Uri.parse(href);
                  try {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    AppLogger.instance.logError('abrir_link_termos', error: e.toString());
                    debugPrint('Erro ao abrir link: $e');
                  }
                }
              },
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 16),
                h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
              child: CheckboxListTile(
                title: const Text(
                  'Ao clicar em "Aceitar", confirmo que li, compreendi e assumo integralmente todos os riscos associados à prática da escalada ao utilizar as informações contidas neste aplicativo.',
                  style: TextStyle(fontSize: 14),
                ),
                value: _isChecked,
                onChanged: (bool? value) {
                  setState(() {
                    _isChecked = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 16.0, 0.0, 24.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isChecked ? () {
                    TelemetryService.instance.logAcaoConfiguracoes('aceitar_termos_uso');
                    widget.onAccepted();
                  } : null,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Aceitar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
