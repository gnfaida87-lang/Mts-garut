import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../config/env.dart';

class ScanAbsenPage extends StatefulWidget {
  final VoidCallback? onBack;
  const ScanAbsenPage({super.key, this.onBack});

  @override
  State<ScanAbsenPage> createState() => _ScanAbsenPageState();
}

class _ScanAbsenPageState extends State<ScanAbsenPage> {
  MobileScannerController? _cameraController;
  bool _isProcessing = false;
  bool _hasResult = false;
  String? _resultMessage;
  bool? _isSuccess;
  DateTime? _lastScanTime;
  Map<String, dynamic>? _waktu;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadWaktu();
  }

  Future<void> _loadWaktu() async {
    try {
      final res = await ApiClient.get('/absensi/pengaturan-waktu');
      if (mounted) setState(() => _waktu = res['data'] as Map<String, dynamic>);
    } catch (_) {}
  }

  String _fmtJam(String? t) => (t != null && t.length >= 5) ? t.substring(0, 5) : '-';

  void _initCamera() {
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final scannedValue = barcode.rawValue ?? '';

    // Validasi QR token
    if (scannedValue != Env.qrAbsensiToken) {
      _showResult(false, 'QR Code tidak valid');
      return;
    }

    // Debounce: abaikan scan dalam 3 detik dari scan terakhir
    if (_lastScanTime != null) {
      final diff = DateTime.now().difference(_lastScanTime!);
      if (diff.inSeconds < 3) return;
    }

    _processScan();
  }

  Future<void> _processScan() async {
    setState(() {
      _isProcessing = true;
      _hasResult = false;
    });

    _lastScanTime = DateTime.now();

    try {
      final response = await ApiClient.post('/absensi/scan', body: {'token': Env.qrAbsensiToken});
      final data = response['data'] as Map<String, dynamic>;
      final action = data['action'] as String;
      final time = data['time'] as String;

      String displayMessage;
      if (action == 'jam_masuk') {
        displayMessage = 'Absensi Masuk Tercatat\nJam $time';
      } else {
        displayMessage = 'Absensi Keluar Tercatat\nJam $time';
      }

      _showResult(true, displayMessage);
    } on ApiException catch (e) {
      _showResult(false, e.message);
    } catch (e) {
      _showResult(false, 'Gagal mengirim data absensi');
    }
  }

  void _showResult(bool success, String message) {
    setState(() {
      _hasResult = true;
      _isSuccess = success;
      _resultMessage = message;
      _isProcessing = false;
    });

    // Auto-reset setelah 4 detik
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _hasResult = false;
          _resultMessage = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
        title: const Text('Scan Absensi', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.grey900,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Camera preview
          if (_cameraController != null)
            MobileScanner(
              controller: _cameraController!,
              onDetect: _onDetect,
            ),

          // Overlay with scan area
          _buildScanOverlay(),

          // Result overlay
          if (_hasResult) _buildResultOverlay(),

          // Processing indicator
          if (_isProcessing) _buildProcessingOverlay(),

          // Instructions at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildInstructions(),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return CustomPaint(
      painter: _ScanOverlayPainter(),
      size: Size.infinite,
    );
  }

  Widget _buildResultOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isSuccess! ? Icons.check_circle : Icons.error,
                size: 80,
                color: _isSuccess! ? AppTheme.primary : AppTheme.error,
              ),
              const SizedBox(height: 20),
              Text(
                _isSuccess! ? 'Berhasil!' : 'Gagal',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _isSuccess! ? AppTheme.primary : AppTheme.error,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _resultMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.grey700,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primary,
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Arahkan kamera ke QR Code absensi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan pertama = Jam Masuk • Scan kedua = Jam Keluar',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            if (_waktu != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Jam masuk ${_fmtJam(_waktu!['jam_masuk_mulai']?.toString())}–${_fmtJam(_waktu!['jam_masuk_selesai']?.toString())}'
                  '  •  Jam keluar ${_fmtJam(_waktu!['jam_keluar_mulai']?.toString())}–${_fmtJam(_waktu!['jam_keluar_selesai']?.toString())}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final scanAreaSize = size.width * 0.7;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2 - 50;
    final right = left + scanAreaSize;
    final bottom = top + scanAreaSize;

    // Draw overlay with cutout
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize),
        const Radius.circular(20),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw scan area border
    final borderPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final borderPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize),
        const Radius.circular(20),
      ));

    canvas.drawPath(borderPath, borderPaint);

    // Draw corner accents
    final cornerPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;

    // Top-left
    canvas.drawLine(
      Offset(left, top + cornerLength),
      Offset(left, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(right - cornerLength, top),
      Offset(right, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(right, top),
      Offset(right, top + cornerLength),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(left, bottom - cornerLength),
      Offset(left, bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, bottom),
      Offset(left + cornerLength, bottom),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(right - cornerLength, bottom),
      Offset(right, bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(right, bottom - cornerLength),
      Offset(right, bottom),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
