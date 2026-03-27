import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Controller for the Damage Report feature.
///
/// Manages all form state, image picking, voice recording,
/// and the Firebase Storage + Firestore submission flow.
class ReportController {
  // ── Form state ────────────────────────────────────────────────
  bool isDamaged = true;
  File? imageFile;
  bool isListening = false;
  String _textBeforeRecording = '';

  final TextEditingController damagedUnitsController = TextEditingController();
  final TextEditingController unusableUnitsController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // ── Private singletons ────────────────────────────────────────
  final _picker = ImagePicker();
  final _speech = stt.SpeechToText();

  // ── Image Picker ──────────────────────────────────────────────

  /// Opens the device camera and stores the captured image.
  /// Returns the picked [File], or null if cancelled.
  Future<File?> pickDamageImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked == null) return null;
    imageFile = File(picked.path);
    return imageFile;
  }

  // ── Voice Recording ───────────────────────────────────────────

  /// Toggles the speech-to-text session.
  /// [onStateChanged] lets the View rebuild when [isListening] flips.
  Future<void> toggleVoiceRecording(VoidCallback onStateChanged) async {
    if (isListening) {
      await _speech.stop();
      isListening = false;
      onStateChanged();
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          isListening = false;
          onStateChanged();
        }
      },
      onError: (error) {
        isListening = false;
        onStateChanged();
      },
    );

    if (!available) return;

    // Snapshot current text BEFORE the session starts.
    // The onResult callback will overwrite (not append) using this baseline.
    _textBeforeRecording = descriptionController.text;

    isListening = true;
    onStateChanged();

    _speech.listen(
      localeId: 'en_US',
      onResult: (result) {
        final recognized = result.recognizedWords;
        if (recognized.isNotEmpty) {
          // OVERWRITE with baseline + latest recognised words (no duplication).
          descriptionController.text =
              '$_textBeforeRecording $recognized'.trim();
          descriptionController.selection = TextSelection.fromPosition(
            TextPosition(offset: descriptionController.text.length),
          );
        }
      },
    );
  }

  // ── Firebase Submission ────────────────────────────────────────

  /// Uploads image (if any) to Firebase Storage, then writes a
  /// Firestore document to `damage_reports`.
  ///
  /// Guards every UI call with `if (!context.mounted) return;`.
  Future<void> submitReport({
    required Map<String, dynamic> productData,
    required BuildContext context,
    required VoidCallback onLoadingChanged,
  }) async {
    // ── Validation (runs before any loading or Firebase calls) ────

    // 1. Empty unit fields
    if (damagedUnitsController.text.trim().isEmpty ||
        unusableUnitsController.text.trim().isEmpty) {
      _showErrorSnackBar(
        context,
        'Please enter the number of damaged and unusable units.',
      );
      return;
    }

    // 2. Non-numeric unit values
    final damagedInt = int.tryParse(damagedUnitsController.text.trim());
    final unusableInt = int.tryParse(unusableUnitsController.text.trim());
    if (damagedInt == null || unusableInt == null) {
      _showErrorSnackBar(context, 'Unit counts must be valid numbers.');
      return;
    }

    // 3. Empty description
    if (descriptionController.text.trim().isEmpty) {
      _showErrorSnackBar(
        context,
        'Please provide a brief description of the damage.',
      );
      return;
    }

    // ── Show loading overlay ──
    onLoadingChanged();

    try {
      String? imageUrl;

      // ── Upload image only if one was captured ──
      if (imageFile != null) {
        final fileName = 'damage_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref(fileName);
        await ref.putFile(imageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      // ── Write Firestore document ──
      await FirebaseFirestore.instance.collection('damage_reports').add({
        'sku': productData['sku'] ?? '',
        'productName': productData['name'] ?? '',
        'isDamaged': isDamaged,
        'damagedUnits': damagedUnitsController.text.trim(),
        'unusableUnits': unusableUnitsController.text.trim(),
        'description': descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      // ── Dismiss loading ──
      onLoadingChanged();

      // ── Success: green SnackBar then pop to Home ──
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Report submitted successfully!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.popUntil(context, ModalRoute.withName('/home'));
    } catch (e) {
      if (!context.mounted) return;
      onLoadingChanged(); // hide loading
      _showErrorSnackBar(context, 'Submission failed: $e');
    }
  }

  // ── Private helpers ───────────────────────────────────────────

  /// Shows a floating red [SnackBar] with [message].
  /// Centralises all error-SnackBar boilerplate in one place.
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Lifecycle ─────────────────────────────────────────────────
  void dispose() {
    damagedUnitsController.dispose();
    unusableUnitsController.dispose();
    descriptionController.dispose();
  }
}
