import 'package:flutter/material.dart';
import '../views/scanner/scanner_view.dart';

/// Controller for the Home Dashboard.
/// Owns navigation logic and the mock recent-scans dataset.
class HomeController {
  // ── Navigation ─────────────────────────────────────────────────
  static void navigateToScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScannerView()),
    );
  }

  // ── Mock recent-scan data (Sprint 1 placeholder) ───────────────
  static const List<Map<String, dynamic>> recentScans = [
    {
      'index': 1,
      'sku': 'SE-26023',
      'product': 'Maggie Box',
      'fromDate': '27 Jan 2026',
      'fromCity': 'Rathnapura',
      'toDate': '30 Jan 2026',
      'toCity': 'Colombo',
      'time': '19:23:55',
      'statuses': ['Delivered'],
    },
    {
      'index': 2,
      'sku': 'SE-26225',
      'product': 'Milo Box',
      'fromDate': '23 Jan 2026',
      'fromCity': 'Rathnapura',
      'toDate': '28 Jan 2026',
      'toCity': 'Colombo',
      'time': '12:17:05',
      'statuses': ['Damaged', 'Delivered'],
    },
    {
      'index': 3,
      'sku': 'SE-26431',
      'product': 'Milkmaid Box',
      'fromDate': '23 Jan 2026',
      'fromCity': 'Panadura',
      'toDate': '28 Jan 2026',
      'toCity': 'Colombo',
      'time': '10:12:15',
      'statuses': ['Damaged', 'Delivered'],
    },
    {
      'index': 4,
      'sku': 'SE-26431',
      'product': 'Maggie Box',
      'fromDate': '23 Jan 2026',
      'fromCity': 'Panadura',
      'toDate': '25 Jan 2026',
      'toCity': 'Colombo',
      'time': '10:04:11',
      'statuses': ['Delivered'],
    },
    {
      'index': 5,
      'sku': 'SE-26431',
      'product': 'Milo Box',
      'fromDate': '21 Jan 2026',
      'fromCity': 'Panadura',
      'toDate': '24 Jan 2026',
      'toCity': 'Colombo',
      'time': '09:30:00',
      'statuses': ['Delivered'],
    },
  ];
}
