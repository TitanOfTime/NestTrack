import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../controllers/scanner_controller.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  static const Color _cyan = Color(0xFF00E5FF);
  static const Color _darkBg = Color(0xFF121212);

  final ScannerController _controller = ScannerController();
  bool _controllerReady = false;

  @override
  void initState() {
    super.initState();
    _controller.init().then((_) {
      if (mounted) setState(() => _controllerReady = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Barcode detection callback ─────────────────────────────────
  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || !mounted) return;

    _controller.handleBarcode(
      code: code,
      context: context,
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  // ── "Unable to Scan?" dialog ───────────────────────────────────
  void _showManualEntryDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Enter SKU Manually',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g. SKU-100',
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _cyan),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              final code = textController.text.trim();
              Navigator.pop(dialogContext);
              if (code.isNotEmpty && mounted) {
                _controller.handleBarcode(
                  code: code,
                  context: context,
                  onStateChanged: () {
                    if (mounted) setState(() {});
                  },
                );
              }
            },
            child: const Text(
              'Search',
              style: TextStyle(color: _cyan, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    // ── App title ──
                    _buildAppTitle(),
                    const SizedBox(height: 32),

                    // ── Page title ──
                    const Text(
                      'Scan QR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Align the QR within the frame to scan',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // ── Camera viewfinder with flashlight ──
                    _buildViewfinder(),
                    const SizedBox(height: 20),

                    // ── Unable to Scan ──
                    TextButton(
                      onPressed: _showManualEntryDialog,
                      child: const Text(
                        'Unable to Scan?',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Scanner icon badge ──
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: _cyan,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.black,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Bottom nav bar ──
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ── Viewfinder + flashlight ────────────────────────────────────
  Widget _buildViewfinder() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Scanner box ──
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                // Live camera feed
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: _controllerReady
                      ? MobileScanner(
                          controller: _controller.cameraController,
                          onDetect: _onDetect,
                        )
                      : const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00E5FF),
                          ),
                        ),
                ),

                // Cyan corner brackets
                ..._buildCornerBrackets(),

                // Red laser line
                Center(
                  child: Container(
                    width: 2,
                    height: double.infinity,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 16),

        // ── Flashlight button ──
        GestureDetector(
          onTap: () => setState(() => _controller.toggleFlashlight()),
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt, color: Colors.black, size: 28),
          ),
        ),
      ],
    );
  }

  // ── Corner bracket builders ────────────────────────────────────
  List<Widget> _buildCornerBrackets() {
    const double size = 28;
    const double thickness = 3;
    const Color color = Color(0xFF00E5FF);

    Widget corner({
      required AlignmentGeometry alignment,
      required BorderRadius borderRadius,
      required Border border,
    }) {
      return Align(
        alignment: alignment,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(border: border, borderRadius: borderRadius),
        ),
      );
    }

    return [
      // Top-left
      corner(
        alignment: Alignment.topLeft,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(4)),
        border: const Border(
          top: BorderSide(color: color, width: thickness),
          left: BorderSide(color: color, width: thickness),
        ),
      ),
      // Top-right
      corner(
        alignment: Alignment.topRight,
        borderRadius: const BorderRadius.only(topRight: Radius.circular(4)),
        border: const Border(
          top: BorderSide(color: color, width: thickness),
          right: BorderSide(color: color, width: thickness),
        ),
      ),
      // Bottom-left
      corner(
        alignment: Alignment.bottomLeft,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(4)),
        border: const Border(
          bottom: BorderSide(color: color, width: thickness),
          left: BorderSide(color: color, width: thickness),
        ),
      ),
      // Bottom-right
      corner(
        alignment: Alignment.bottomRight,
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(4)),
        border: const Border(
          bottom: BorderSide(color: color, width: thickness),
          right: BorderSide(color: color, width: thickness),
        ),
      ),
    ];
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
              text: 'Nes',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w300,
              ),
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

  // ── Bottom nav bar ─────────────────────────────────────────────
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
              icon: const Icon(
                Icons.home_rounded,
                color: Colors.white54,
                size: 28,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            const Icon(
              Icons.settings_outlined,
              color: Colors.white54,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}
