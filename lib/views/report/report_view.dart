import 'dart:io';
import 'package:flutter/material.dart';
import '../../controllers/report_controller.dart';

class ReportView extends StatefulWidget {
  const ReportView({super.key});

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  // ── Palette ───────────────────────────────────────────────────
  static const Color _darkBg   = Color(0xFF121212);
  static const Color _cardBg   = Color(0xFF1E1E1E);
  static const Color _fieldBg  = Color(0xFF2A2A2A);
  static const Color _cyan     = Color(0xFF00E5FF);
  static const Color _orange   = Colors.orange;

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

  // ── ST-09 Evidence Enforcer ───────────────────────────────────
  bool get _isSubmitLocked {
    final rawPrice = _productData['unitPrice'];
    int unitPrice = 0;
    if (rawPrice is num) {
      unitPrice = rawPrice.toInt();
    } else if (rawPrice is String) {
      unitPrice = int.tryParse(rawPrice) ?? 0;
    }
    return unitPrice > 10000 && _controller.imageFile == null;
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── App title ──
                        _buildAppTitle(),
                        const SizedBox(height: 20),

                        // ── Product card ──
                        _buildProductCard(),
                        const SizedBox(height: 20),

                        // ── Damage form card ──
                        _buildDamageCard(),
                        const SizedBox(height: 20),

                        // ── Description field (outside card, matching screenshot) ──
                        _buildDescriptionField(),
                        const SizedBox(height: 24),

                        // ── Action buttons ──
                        _buildActionButtons(),
                        const SizedBox(height: 8),
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
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300),
            ),
            TextSpan(
              text: 'Track.',
              style: TextStyle(color: _cyan, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ── Product card ───────────────────────────────────────────────
  Widget _buildProductCard() {
    final sku  = _productData['sku']?.toString()  ?? 'SE-000000';
    final name = _productData['name']?.toString() ?? 'Unknown Product';
    final rawPrice = _productData['unitPrice'];
    int unitPrice = 0;
    if (rawPrice is num) {
      unitPrice = rawPrice.toInt();
    } else if (rawPrice is String) {
      unitPrice = int.tryParse(rawPrice) ?? 0;
    }

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: _orange, width: 4),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // SKU + name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sku,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Price badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$unitPrice LKR',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Inventory Value',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ],
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
          // ── Inventory Damaged toggle ──
          _buildDamagedToggleRow(),
          const SizedBox(height: 16),

          // ── Units: Damaged + Unusable side-by-side ──
          Row(
            children: [
              Expanded(
                child: _buildNumberInput(
                  label: 'No of Units Damaged',
                  controller: _controller.damagedUnitsController,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildNumberInput(
                  label: 'No of Unusable Units',
                  controller: _controller.unusableUnitsController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Dropdowns: Zone + Cause side-by-side ──
          Row(
            children: [
              Expanded(child: _buildZoneDropdown()),
              const SizedBox(width: 8),
              Expanded(child: _buildCauseDropdown()),
            ],
          ),
          const SizedBox(height: 16),

          // ── Image upload ──
          const Text(
            'Upload an Image of the Damaged Inventory',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 10),
          _buildImagePicker(),
        ],
      ),
    );
  }

  // ── Yes / No toggle ───────────────────────────────────────────
  Widget _buildDamagedToggleRow() {
    return Row(
      children: [
        const Text(
          'Inventory Damaged :',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        _buildTogglePill(label: 'Yes', active: _controller.isDamaged),
        const SizedBox(width: 8),
        _buildTogglePill(label: 'No',  active: !_controller.isDamaged),
      ],
    );
  }

  Widget _buildTogglePill({required String label, required bool active}) {
    final isYes = label == 'Yes';
    final Color bg = active
        ? (isYes ? Colors.red : Colors.black)
        : Colors.grey.shade800;

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
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ── Number input ──────────────────────────────────────────────
  Widget _buildNumberInput({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.orange,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  // ── Warehouse Zone dropdown ────────────────────────────────────
  Widget _buildZoneDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _controller.selectedZone,
      dropdownColor: const Color(0xFF2A2A2A),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      iconEnabledColor: Colors.white70,
      isExpanded: true,
      hint: const Text(
        'Select Warehouse Zone',
        style: TextStyle(color: Colors.white54, fontSize: 12),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: _fieldBg,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.orange, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.orange, width: 1.5),
        ),
      ),
      items: _controller.zones
          .map((z) => DropdownMenuItem(value: z, child: Text(z)))
          .toList(),
      onChanged: (val) => setState(() => _controller.selectedZone = val),
    );
  }

  // ── Damage Cause dropdown ─────────────────────────────────────
  Widget _buildCauseDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _controller.selectedCause,
      dropdownColor: const Color(0xFF2A2A2A),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      iconEnabledColor: Colors.white70,
      isExpanded: true,
      hint: const Text(
        'Select Damage Cause',
        style: TextStyle(color: Colors.white54, fontSize: 12),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: _fieldBg,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.orange, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.orange, width: 1.5),
        ),
      ),
      items: _controller.causes
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (val) => setState(() => _controller.selectedCause = val),
    );
  }

  // ── Image picker ──────────────────────────────────────────────
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
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white30),
        ),
        child: _controller.imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
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
            fillColor: _cardBg,
            contentPadding: const EdgeInsets.fromLTRB(12, 12, 52, 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        // Mic button – bottom-right inside the field
        Positioned(
          right: 10,
          bottom: 10,
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
    return Column(
      children: [
        // Re-Scan button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'Re-Scan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ST-09 Evidence Enforcer Submit button — full-width, orange
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading || _isSubmitLocked
                ? null
                : () async {
                    final triageAction = await _controller.submitReport(
                      productData: _productData,
                      context: context,
                      onLoadingChanged: _toggleLoading,
                    );
                    if (triageAction != null && context.mounted) {
                      _showTriageScreen(triageAction);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSubmitLocked ? Colors.grey.shade700 : Colors.orange,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade700,
              disabledForegroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              _isSubmitLocked ? 'Photo Required' : 'Submit Report',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Triage Screen ──────────────────────────────────────────────
  void _showTriageScreen(String action) {
    Color bgColor;
    String displayText;

    switch (action) {
      case 'DISPOSE':
        bgColor     = Colors.green.shade800;
        displayText = 'DISPOSE:\nMove Item to Scrap Bin';
        break;
      case 'HAZARD_GLASS':
        bgColor     = Colors.red.shade800;
        displayText = 'HAZARD:\nDeposit in Shatter Bin 4';
        break;
      case 'HAZARD_LIQUID':
        bgColor     = Colors.blue.shade800;
        displayText = 'HAZARD:\nMove to Spill Station';
        break;
      case 'RETURN_STANDARD':
      default:
        bgColor     = Colors.orange.shade800;
        displayText = 'STANDARD DAMAGE:\nPlace on Return Pallet 12';
        break;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: bgColor,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 60),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.popUntil(ctx, ModalRoute.withName('/home')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text(
                    'DONE',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
