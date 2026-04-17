import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Controller for the Barcode Scanner.
///
/// Queries the Firestore `products` collection for SKU lookups lock-safely.
class ScannerController {
  // ── Camera ────────────────────────────────────────────────────
  late final MobileScannerController cameraController;

  // ── State ─────────────────────────────────────────────────────
  /// Guards against duplicate rapid-fire barcode detections.
  bool isProcessing = false;

  // ── Lifecycle ─────────────────────────────────────────────────

  /// Must be called once (e.g. in [State.initState]) before use.
  Future<void> init() async {
    cameraController = MobileScannerController(
      // We handle throttling manually via [isProcessing] to prevent the 
      // scanner from ignoring same-barcode re-scans permanently.
      detectionSpeed: DetectionSpeed.normal,
    );
  }

  void dispose() {
    cameraController.dispose();
  }

  // ── Flashlight ────────────────────────────────────────────────
  void toggleFlashlight() {
    cameraController.toggleTorch();
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

    final sku = code.trim();

    try {
      final doc = await FirebaseFirestore.instance.collection('products').doc(sku).get();

      // ── Guard: widget may have been disposed during any prior await ──
      if (!context.mounted) {
        isProcessing = false;
        return;
      }

      if (!doc.exists || doc.data() == null) {
        // ── Error state ──
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SKU not found: $sku'),
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
        final productData = doc.data()!;
        
        // Note: Do NOT set isProcessing = false here! 
        // Keep it true during the route transition to prevent double-pushes.
        onStateChanged();

        // Explicitly stop the camera before leaving the view to free hardware
        await cameraController.stop();

        await Navigator.pushNamed(
          context,
          '/report',
          arguments: {'sku': sku, ...productData},
        );

        // ── Returned from ReportView (e.g. user pressed Re-Scan) ──
        if (!context.mounted) return;
        
        // Explicitly restart the camera safely
        await cameraController.start();
        
        // Minimal delay to prevent instant accidental re-scans
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (!context.mounted) return;
        isProcessing = false;
        onStateChanged();
      }
    } catch (e) {
      if (!context.mounted) {
        isProcessing = false;
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error looking up SKU: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      );
      
      await Future.delayed(const Duration(seconds: 2));
      if (!context.mounted) return;
      isProcessing = false;
      onStateChanged();
    }
  }
}

