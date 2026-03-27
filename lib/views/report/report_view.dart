import 'dart:io';
import 'package:flutter/material.dart';
import '../../controllers/report_controller.dart';

class ReportView extends StatefulWidget {
  const ReportView({super.key});

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  // ── Colours ───────────────────────────────────────────────────
  static const Color _darkBg = Color(0xFF121212);
  static const Color _cyan = Color(0xFF00E5FF);
  static const Color _cardBg = Color(0xFF1C1C1C);
  static const Color _fieldBg = Color(0xFF2A2A2A);

  // ── State ─────────────────────────────────────────────────────
  final _controller = ReportController();
  bool _isLoading = false;
  late Map<String, dynamic> _productData;
  bool _argsExtracted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsExtracted) {
      _productData =
          (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)
              ?? {};
      _argsExtracted = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────
  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _toggleLoading() {
    if (mounted) setState(() => _isLoading = !_isLoading);
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: _darkBg,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── App title ──
                        _buildAppTitle(),
                        const SizedBox(height: 24),

                        // ── SKU (orange) ──
                        Text(
                          _productData['sku']?.toString() ?? 'SE-000000',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // ── Product name (white) ──
                        Text(
                          _productData['name']?.toString() ?? 'Unknown Product',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Damage form card ──
                        _buildDamageCard(),

                        const SizedBox(height: 28),

                        // ── Action buttons ──
                        _buildActionButtons(),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // ── Bottom nav ──
                _buildBottomNav(),
              ],
            ),
          ),
        ),

        // ── Loading overlay ──
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: _cyan),
            ),
          ),
      ],
    );
  }

  // ── App title ──────────────────────────────────────────────────
  Widget _buildAppTitle() {
    return Align(
      alignment: Alignment.topRight,
      child: RichText(
        text: const TextSpan(
          style: TextStyle(fontSize: 22, fontStyle: FontStyle.italic),
          children: [
            TextSpan(
                text: 'Nest',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w300)),
            TextSpan(
                text: 'Track.',
                style: TextStyle(
                    color: _cyan, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ── Damage form card ──────────────────────────────────────────
  Widget _buildDamageCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1 – Inventory Damaged toggle
          _buildDamagedToggleRow(),
          const SizedBox(height: 16),

          // Row 2 – Units Damaged
          _buildLabeledInput(
            label: 'No of Units Damaged :',
            controller: _controller.damagedUnitsController,
          ),
          const SizedBox(height: 12),

          // Row 3 – Unusable Units
          _buildLabeledInput(
            label: 'No of Unusable Units :',
            controller: _controller.unusableUnitsController,
          ),
          const SizedBox(height: 20),

          // Row 4 – Image upload
          const Text(
            'Upload an Image of the Damaged Inventory',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 10),
          _buildImagePicker(),

          const SizedBox(height: 16),

          // Row 5 – Description + mic
          _buildDescriptionField(),
        ],
      ),
    );
  }

  // ── Toggle: Yes / No ──────────────────────────────────────────
  Widget _buildDamagedToggleRow() {
    return Row(
      children: [
        const Text(
          'Inventory Damaged :',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const Spacer(),
        _buildTogglePill(label: 'Yes', active: _controller.isDamaged),
        const SizedBox(width: 8),
        _buildTogglePill(label: 'No', active: !_controller.isDamaged),
      ],
    );
  }

  Widget _buildTogglePill({required String label, required bool active}) {
    final isYes = label == 'Yes';
    Color bg;
    if (active) {
      bg = isYes ? Colors.red : Colors.black;
    } else {
      bg = Colors.grey.shade800;
    }

    return GestureDetector(
      onTap: () => setState(() => _controller.isDamaged = isYes),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: active ? null : Border.all(color: Colors.white30),
        ),
        child: Text(
          label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ── Labeled orange input ───────────────────────────────────────
  Widget _buildLabeledInput({
    required String label,
    required TextEditingController controller,
  }) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 13)),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          height: 34,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.orange,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Image picker square ───────────────────────────────────────
  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: () async {
        final file = await _controller.pickDamageImage();
        if (file != null) setState(() {});
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: _fieldBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white30),
        ),
        child: _controller.imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(_controller.imageFile!.path),
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // ── Description + mic ────────────────────────────────────────
  Widget _buildDescriptionField() {
    return Stack(
      children: [
        TextField(
          controller: _controller.descriptionController,
          maxLines: 5,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter Description...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: _fieldBg,
            contentPadding: const EdgeInsets.fromLTRB(12, 12, 52, 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        // Mic button – bottom-right inside the field
        Positioned(
          right: 8,
          bottom: 8,
          child: GestureDetector(
            onTap: () => _controller.toggleVoiceRecording(_rebuild),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _controller.isListening
                    ? Colors.redAccent
                    : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _controller.isListening ? Icons.mic : Icons.mic_none,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Action buttons ────────────────────────────────────────────
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Re-Scan
        ElevatedButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/scanner'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
          ),
          child: const Text('Re-Scan',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 16),

        // Submit Report
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () => _controller.submitReport(
                    productData: _productData,
                    context: context,
                    onLoadingChanged: _toggleLoading,
                  ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
          ),
          child: const Text('Submit Report',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // ── Bottom nav ────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.home_rounded,
                  color: Colors.white54, size: 28),
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/home'),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined,
                  color: Colors.white54, size: 26),
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/settings'),
            ),
          ],
        ),
      ),
    );
  }
}
