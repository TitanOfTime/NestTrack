import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Controller for the Barcode Scanner.
///
/// Loads [assets/products.json] ONCE during [init()] and caches it
/// in [_productDb]. All SKU lookups are instant, synchronous map reads.
class ScannerController {
  // ── Camera ────────────────────────────────────────────────────
  late final MobileScannerController cameraController;

  // ── State ─────────────────────────────────────────────────────
  /// Guards against duplicate rapid-fire barcode detections.
  bool isProcessing = false;

  /// In-memory product database loaded from assets/products.json.
  Map<String, dynamic> _productDb = {};

  // ── Lifecycle ─────────────────────────────────────────────────

  /// Must be called once (e.g. in [State.initState]) before use.
  Future<void> init() async {
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    await _loadProductDb();
  }

  Future<void> _loadProductDb() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/products.json');
      _productDb = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('ScannerController: failed to load products.json – $e');
      _productDb = {};
    }
  }

  void dispose() {
    cameraController.dispose();
  }

  // ── Flashlight ────────────────────────────────────────────────
  void toggleFlashlight() {
    cameraController.toggleTorch();
  }

  // ── Lookup ────────────────────────────────────────────────────

  /// Instant synchronous lookup against the cached map.
  Map<String, dynamic>? _lookupSku(String code) {
    final entry = _productDb[code];
    if (entry == null) return null;
    return Map<String, dynamic>.from(entry as Map);
  }

  // ── Barcode handling ──────────────────────────────────────────

  /// Main entry point for both camera detections and manual entry.
  /// [onStateChanged] is called so the View can rebuild (e.g. update
  /// isProcessing-dependent UI) without this controller holding a [setState].
  Future<void> handleBarcode({
    required String code,
    required BuildContext context,
    required VoidCallback onStateChanged,
  }) async {
    if (isProcessing) return;

    isProcessing = true;
    onStateChanged();

    final product = _lookupSku(code.trim());

    // ── Guard: widget may have been disposed during any prior await ──
    if (!context.mounted) {
      isProcessing = false;
      return;
    }

    if (product == null) {
      // ── Error state ──
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SKU not found: $code'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (!context.mounted) return;
      isProcessing = false;
      onStateChanged();
    } else {
      // ── Success state ──
      isProcessing = false;
      onStateChanged();

      await Navigator.pushNamed(
        context,
        '/report',
        arguments: {'sku': code, ...product},
      );
    }
  }
}
