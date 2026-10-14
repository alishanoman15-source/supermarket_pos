import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/providers.dart';
import '../providers/cart_controller.dart';

/// Camera scanner for EAN-13/8, UPC-A/E, Code128, Code39 (SPEC §33, screen #18).
class CameraScannerScreen extends ConsumerStatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  ConsumerState<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends ConsumerState<CameraScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
    ],
  );
  bool _handling = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final code = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((value) => value != null && value.isNotEmpty, orElse: () => null);
    if (code == null) return;

    _handling = true;
    try {
      final product = await ref.read(productRepositoryProvider).fetchByBarcode(code);
      if (!mounted) return;
      if (product == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.productNotFound)));
        _handling = false;
        return;
      }
      ref.read(cartControllerProvider.notifier).addProduct(product);
      if (mounted) Navigator.pop(context);
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
      _handling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.cameraScanner)),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(l10n.scanBarcodeHint),
            ),
          ),
        ],
      ),
    );
  }
}
