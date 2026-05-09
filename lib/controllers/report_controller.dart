import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller for the Damage Report feature.
///
/// Manages all form state, image picking, voice recording,
/// audio capture, and the Firebase Storage + Firestore submission flow.
class ReportController {
  // ── Form state ────────────────────────────────────────────────
  bool isDamaged = true;
  File? imageFile;
  bool isListening = false;
  String _textBeforeRecording = '';

  // ── Dropdown state ────────────────────────────────────────────
  String? selectedCause;
  String? selectedZone;

  final List<String> causes = ['Transit', 'Handling', 'Environmental', 'Other'];
  final List<String> zones  = ['Loading Dock A', 'Aisle 4', 'Cold Storage', 'Quarantine'];

  // ── Audio recording state ─────────────────────────────────────
  bool isRecording = false;
  String? _audioFilePath;
  final AudioRecorder _recorder = AudioRecorder();

  final TextEditingController damagedUnitsController  = TextEditingController();
  final TextEditingController unusableUnitsController = TextEditingController();
  final TextEditingController descriptionController   = TextEditingController();

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

  // ── Speech-to-Text ────────────────────────────────────────────

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

  // ── Audio Recording (.m4a) ────────────────────────────────────

  /// Toggles start/stop of the .m4a audio recorder.
  /// [onStateChanged] lets the View rebuild when [isRecording] flips.
  Future<void> toggleRecording(VoidCallback onStateChanged) async {
    if (isRecording) {
      // ── Stop ──
      final path = await _recorder.stop();
      isRecording = false;
      _audioFilePath = path;
      onStateChanged();
      return;
    }

    // ── Start ──
    if (await _recorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );
      isRecording = true;
      onStateChanged();
    }
  }

  /// Uploads the recorded .m4a file to Firebase Storage.
  /// Sets MIME type explicitly so web dashboards can stream it.
  Future<String?> _uploadAudioToStorage() async {
    if (_audioFilePath == null) return null;
    final file = File(_audioFilePath!);
    if (!file.existsSync()) return null;

    final fileName =
        'voice_notes/${DateTime.now().millisecondsSinceEpoch}.m4a';
    final ref = FirebaseStorage.instance.ref(fileName);

    // Explicitly set MIME type so the Next.js web dashboard
    // streams the file in an HTML5 <audio> player instead
    // of forcing a raw binary download.
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'audio/m4a'),
    );
    return ref.getDownloadURL();
  }

  // ── Behavioral Personalization ─────────────────────────────────

  /// Reads the cached default zone and updates the selectedZone state.
  Future<void> initializePersonalization(VoidCallback onStateChanged) async {
    final prefs = await SharedPreferences.getInstance();
    final defaultZone = prefs.getString('defaultZone');
    
    // Ensure the cached zone is still a valid option in the list
    if (defaultZone != null && zones.contains(defaultZone)) {
      selectedZone = defaultZone;
      onStateChanged();
    }
  }

  /// Implements the "Streak Rule": tracks a candidateZone and promotes it to defaultZone
  /// if it is selected 3 times in a row.
  Future<void> _learnWorkerHabits(String justSelectedZone) async {
    final prefs = await SharedPreferences.getInstance();
    final currentDefault = prefs.getString('defaultZone');

    if (currentDefault == null) {
      // First time saving a zone
      await prefs.setString('defaultZone', justSelectedZone);
      await prefs.remove('candidateZone');
      await prefs.remove('reassignmentStreak');
      return;
    }

    if (justSelectedZone == currentDefault) {
      // Matches default zone: Reset streak and candidate tracking
      await prefs.remove('candidateZone');
      await prefs.remove('reassignmentStreak');
    } else {
      // Mismatch: Evaluate candidate zone
      final currentCandidate = prefs.getString('candidateZone');
      
      if (justSelectedZone == currentCandidate) {
        // Repeated the same candidate zone
        int currentStreak = prefs.getInt('reassignmentStreak') ?? 1;
        currentStreak++;

        if (currentStreak >= 3) {
          // Promote candidate to default after 3 consecutive selections
          await prefs.setString('defaultZone', justSelectedZone);
          await prefs.remove('candidateZone');
          await prefs.remove('reassignmentStreak');
        } else {
          // Increment streak
          await prefs.setInt('reassignmentStreak', currentStreak);
        }
      } else {
        // A new candidate zone entirely
        await prefs.setString('candidateZone', justSelectedZone);
        await prefs.setInt('reassignmentStreak', 1);
      }
    }
  }

  // ── Firebase Submission ────────────────────────────────────────

  /// Validates form, dual-writes to `damage_reports` and `replenishment_queue`,
  /// and returns a triage action string.
  ///
  /// Guards every UI call with `if (!context.mounted) return null;`.
  Future<String?> submitReport({
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
      return null;
    }

    // 2. Non-numeric unit values
    final damagedInt = int.tryParse(damagedUnitsController.text.trim());
    final unusableInt = int.tryParse(unusableUnitsController.text.trim());
    if (damagedInt == null || unusableInt == null) {
      _showErrorSnackBar(context, 'Unit counts must be valid numbers.');
      return null;
    }

    // 3. Empty description
    if (descriptionController.text.trim().isEmpty) {
      _showErrorSnackBar(
        context,
        'Please provide a brief description of the damage.',
      );
      return null;
    }

    // 4. Dropdown fields — must both be selected
    if (selectedCause == null || selectedZone == null) {
      _showErrorSnackBar(
        context,
        'Please select a damage cause and warehouse zone.',
      );
      return null;
    }

    // ── Show loading overlay ──
    onLoadingChanged();

    try {
      String? imageUrl;

      // ── Upload image only if one was captured ──
      if (imageFile != null) {
        final fileName =
            'damage_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref(fileName);
        await ref.putFile(imageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      // ── Upload audio if recorded ──
      final audioUrl = await _uploadAudioToStorage();

      // ── Safely parse unitPrice (handles int, double, or String from Firestore)
      final rawPrice = productData['unitPrice'];
      int unitPrice = 0;
      if (rawPrice is num) {
        unitPrice = rawPrice.toInt();
      } else if (rawPrice is String) {
        unitPrice = int.tryParse(rawPrice) ?? 0;
      }

      // ── Incident Loss Calculation ──
      final incidentLoss = unitPrice * unusableInt;

      // ── Sanitize hazardType to lowercase for reliable triage matching ──
      final hazardType =
          (productData['hazardType']?.toString() ?? 'dry').toLowerCase().trim();
      final sku         = productData['sku'] ?? '';
      final productName = productData['name'] ?? '';

      // ── The Primary Write: Damage Report ──
      await FirebaseFirestore.instance.collection('damage_reports').add({
        'sku':           sku,
        'productName':   productName,
        'isDamaged':     isDamaged,
        'damagedUnits':  damagedInt,
        'unusableUnits': unusableInt,
        'description':   descriptionController.text.trim(),
        'imageUrl':      imageUrl,
        'audioUrl':      audioUrl,
        'incidentLoss':  incidentLoss,
        'unitPrice':     unitPrice,
        'hazardType':    hazardType,
        'damageCause':   selectedCause,
        'warehouseZone': selectedZone,
        'timestamp':     FieldValue.serverTimestamp(),
      });

      // ── The Auto-Replenishment Write ──
      if (unitPrice < 10000) {
        await FirebaseFirestore.instance.collection('replenishment_queue').add({
          'sku':          sku,
          'productName':  productName,
          'damagedUnits': damagedInt,
          'status':       'Auto-Replacement Approved',
          'timestamp':    FieldValue.serverTimestamp(),
        });
      }

      // ── Behavioral Personalization: Learn Zone Habits ──
      if (selectedZone != null) {
        await _learnWorkerHabits(selectedZone!);
      }

      if (!context.mounted) return null;

      // ── Dismiss loading ──
      onLoadingChanged();

      // ── The Triage Engine (Routing Logic) ──
      if (unitPrice < 1500) {
        return 'DISPOSE';
      } else if (hazardType == 'glass') {
        return 'HAZARD_GLASS';
      } else if (hazardType == 'liquid' || hazardType == 'perishable') {
        return 'HAZARD_LIQUID';
      } else {
        return 'RETURN_STANDARD';
      }
    } catch (e) {
      if (!context.mounted) return null;
      onLoadingChanged(); // hide loading
      _showErrorSnackBar(context, 'Submission failed: $e');
      return null;
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Lifecycle ─────────────────────────────────────────────────
  void dispose() {
    damagedUnitsController.dispose();
    unusableUnitsController.dispose();
    descriptionController.dispose();
    _recorder.dispose();
  }
}
