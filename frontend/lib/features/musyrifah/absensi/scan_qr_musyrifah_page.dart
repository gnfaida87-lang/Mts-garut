import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../services/musyrifah_service.dart';

class ScanQrMusyrifahPage extends StatefulWidget {
  final VoidCallback? onBack;
  const ScanQrMusyrifahPage({super.key, this.onBack});

  @override
  State<ScanQrMusyrifahPage> createState() => _ScanQrMusyrifahPageState();
}

class _ScanQrMusyrifahPageState extends State<ScanQrMusyrifahPage> {
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
      final waktu = await MusyrifahService.getPengaturanWaktuAbsensi();
      if (mounted) setState(() => _waktu = waktu);
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

    if (scannedValue.isEmpty) {
      _showResult(false, 'QR Code tidak valid');
      return;
    }

    if (_lastScanTime != null) {
      final diff = DateTime.now().difference(_lastScanTime!);
      if (diff.inSeconds < 3) return;
    }

    _processScan(token: scannedValue);
  }

  Future<void> _processScan({required String token, int? jadwalId}) async {
    setState(() {
      _isProcessing = true;
      _hasResult = false;
    });

    _lastScanTime = DateTime.now();

    try {
      final data = await MusyrifahService.scanAbsensi(token: token, jadwalId: jadwalId);

      if (data['action'] == 'pilih_jadwal') {
        final options = (data['jadwal'] as List? ?? []).cast<Map<String, dynamic>>();
        setState(() {
          _isProcessing = false;
          _hasResult = false;
        });
        if (options.isEmpty) {
          _showResult(false, 'Tidak ada jadwal untuk dipilih');
          return;
        }
        final selected = await _pickJadwal(options: options);
        if (selected == null) return;
        await _processScan(token: token, jadwalId: selected);
        return;
      }

      final jadwal = data['jadwal'] as Map<String, dynamic>?;
      final time = data['time']?.toString() ?? '';
      final message = data['message']?.toString();

      String displayMessage = message ?? 'Absensi Tercatat\nJam $time';
      if (jadwal != null) {
        displayMessage += '\n\n${jadwal['program'] ?? ''}';
        displayMessage += '\n${jadwal['hari'] ?? ''}, ${jadwal['jam_mulai'] ?? ''} - ${jadwal['jam_selesai'] ?? ''}';
      }

      _showResult(true, displayMessage);
    } on ApiException catch (e) {
      _showResult(false, e.message);
    } catch (e) {
      _showResult(false, 'Gagal mengirim data absensi');
    }
  }

  Future<int?> _pickJadwal({required List<Map<String, dynamic>> options}) async {
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Pilih Jadwal'),
        children: [
          for (final j in options)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, j),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      j['program']?.toString() ?? 'Program',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${j['hari'] ?? ''}, ${j['jam_mulai'] ?? ''} - ${j['jam_selesai'] ?? ''}',
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
    if (selected == null) return null;
    return (selected['id'] as num).toInt();
  }

  void _showResult(bool success, String message) {
    setState(() {
      _hasResult = true;
      _isSuccess = success;
      _resultMessage = message;
      _isProcessing = false;
    });

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
        title: const Text('Scan QR at-Ta\'wid', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.grey900,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          if (_cameraController != null)
            MobileScanner(
              controller: _cameraController!,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) {
                return Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.no_photography_outlined,
                          color: Colors.white, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Kamera tidak dapat diakses',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pastikan izin kamera diberikan pada pengaturan aplikasi.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          _buildScanOverlay(),

          if (_hasResult) _buildResultOverlay(),

          if (_isProcessing) _buildProcessingOverlay(),

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
                  fontSize: 14,
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
        child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 3),
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
            const Icon(Icons.qr_code_scanner, color: Colors.white, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Arahkan kamera ke QR Code at-Ta\'wid',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'QR Code berlaku untuk absensi harian',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
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

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize),
        const Radius.circular(20),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize),
        const Radius.circular(20),
      ),
      borderPaint,
    );

    final cornerPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;

    canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(right - cornerLength, top), Offset(right, top), cornerPaint);
    canvas.drawLine(Offset(right, top), Offset(right, top + cornerLength), cornerPaint);
    canvas.drawLine(Offset(left, bottom - cornerLength), Offset(left, bottom), cornerPaint);
    canvas.drawLine(Offset(left, bottom), Offset(left + cornerLength, bottom), cornerPaint);
    canvas.drawLine(Offset(right - cornerLength, bottom), Offset(right, bottom), cornerPaint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
