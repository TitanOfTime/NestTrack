import 'package:flutter/material.dart';
import '../../controllers/home_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  // ── Brand colours ──────────────────────────────────────────────
  static const Color _cyan = Color(0xFF00E5FF);
  static const Color _darkBg = Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Body (scrollable) ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── App title ──
                    _buildAppTitle(),
                    const SizedBox(height: 24),

                    // ── Greeting ──
                    _buildGreeting(),
                    const SizedBox(height: 32),

                    // ── SCAN button ──
                    _buildScanButton(context),
                    const SizedBox(height: 36),

                    // ── Recent Scans ──
                    _buildRecentScansHeader(),
                    const SizedBox(height: 12),
                    _buildScanList(),
                  ],
                ),
              ),
            ),

            // ── Bottom nav bar ──
            _buildBottomNav(context, isHomeActive: true),
          ],
        ),
      ),
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

  // ── Greeting ───────────────────────────────────────────────────
  Widget _buildGreeting() {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey.shade700,
          child: const Icon(Icons.person, color: Colors.white54, size: 26),
        ),
        const SizedBox(width: 12),
        const Text(
          'Hello Kamal!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── SCAN button ────────────────────────────────────────────────
  Widget _buildScanButton(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => HomeController.navigateToScanner(context),
        child: Container(
          width: double.infinity,
          height: 90,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00D4E8), Color(0xFF00B4CC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _cyan.withAlpha(80),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SCAN',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.qr_code_scanner, color: Colors.black, size: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────────
  Widget _buildRecentScansHeader() {
    return const Text(
      'Recent Scans',
      style: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // ── Scan list container ────────────────────────────────────────
  Widget _buildScanList() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _cyan, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: HomeController.recentScans
              .map((scan) => _ScanCard(scan: scan))
              .toList(),
        ),
      ),
    );
  }

  // ── Bottom nav bar ─────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context, {required bool isHomeActive}) {
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
              icon: Icon(
                Icons.home_rounded,
                color: isHomeActive ? _cyan : Colors.white54,
                size: 28,
              ),
              onPressed: () {}, // already on Home
            ),
            IconButton(
              icon: Icon(
                Icons.settings_outlined,
                color: isHomeActive ? Colors.white54 : _cyan,
                size: 26,
              ),
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scan card widget ───────────────────────────────────────────────
class _ScanCard extends StatelessWidget {
  final Map<String, dynamic> scan;
  const _ScanCard({required this.scan});

  static const Color _cyan = Color(0xFF00E5FF);
  static const Color _cardBg = Color(0xFF1C1C1E);

  @override
  Widget build(BuildContext context) {
    final statuses = scan['statuses'] as List<String>;

    return Container(
      color: _cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Index ──
          SizedBox(
            width: 24,
            child: Text(
              '${scan['index']}',
              style: const TextStyle(
                color: _cyan,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ── Main content ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SKU + badges
                Row(
                  children: [
                    Text(
                      scan['sku'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    ...statuses.map((s) => _StatusBadge(status: s)),
                  ],
                ),
                const SizedBox(height: 2),

                // Product name
                Text(
                  scan['product'] as String,
                  style: const TextStyle(color: _cyan, fontSize: 12),
                ),
                const SizedBox(height: 8),

                // Route line
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(scan['fromDate'] as String, style: _metaStyle),
                        Text(scan['fromCity'] as String, style: _metaStyle),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.double_arrow, color: _cyan, size: 18),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(scan['toDate'] as String, style: _metaStyle),
                        Text(scan['toCity'] as String, style: _metaStyle),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      scan['time'] as String,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _metaStyle = TextStyle(
    color: Colors.white54,
    fontSize: 11,
  );
}

// ── Status badge ───────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDelivered = status == 'Delivered';
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDelivered ? Colors.green : Colors.redAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
