import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../view_functions/common_functions.dart';

/// Página para escanear QR Codes
class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _isScanned = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: nobleBlack,
      appBar: buildCommonAppBar(context, 'Escanear QR Code'),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (BarcodeCapture capture) {
              if (_isScanned) return;
              
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? rawValue = barcode.rawValue;
                if (rawValue != null && rawValue.isNotEmpty) {
                  _isScanned = true;
                  Navigator.pop(context, rawValue);
                  break;
                }
              }
            },
          ),
          // Um overlay simples para indicar a área de leitura
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: beastHide, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Aponte a câmera para o QR Code\ndo repositório',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: fishBone,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2))],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

