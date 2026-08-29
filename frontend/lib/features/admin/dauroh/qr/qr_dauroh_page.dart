import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/dauroh_service.dart';

class QrDaurohPage extends StatefulWidget {
  const QrDaurohPage({super.key});

  @override
  State<QrDaurohPage> createState() => _QrDaurohPageState();
}

class _QrDaurohPageState extends State<QrDaurohPage> {
  String? _token;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await DaurohService.getQRInfo();
      if (mounted) {
        setState(() {
          _token = info['token']?.toString() ?? 'PPI_DAUROH_QR_2026';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _printQR() async {
    final token = _token ?? 'PPI_DAUROH_QR_2026';

    final pdf = pw.Document();
    final theme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.nunitoRegular(),
      bold: await PdfGoogleFonts.nunitoBold(),
    );

    final qrImage = await QrPainter(
      data: token,
      version: QrVersions.auto,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Colors.black,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black,
      ),
    ).toImage(300);
    final byteData = await qrImage.toByteData(format: ui.ImageByteFormat.png);
    final qrBytes = byteData!.buffer.asUint8List();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              'ABSENSI AT-TA\'WID',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
'MTs Persis Garut',
              style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
            ),
          ),
          pw.SizedBox(height: 30),
          pw.Center(
            child: pw.Container(
              width: 200,
              height: 200,
              child: pw.Image(pw.MemoryImage(qrBytes)),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text(
              'Token: $token',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          pw.SizedBox(height: 40),
          pw.Center(
            child: pw.Text(
              'Pindai QR Code ini untuk absensi musyrifah.',
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey500, fontStyle: pw.FontStyle.italic),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppTheme.error)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildInfoCard(),
          const SizedBox(height: 24),
          _buildQrCode(),
          const SizedBox(height: 24),
          _buildInstructions(),
          const SizedBox(height: 24),
          _buildPrintButton(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: const Column(
        children: [
          Icon(Icons.qr_code_2, color: AppTheme.primary, size: 32),
          SizedBox(height: 12),
          Text(
            'QR Code Absensi Musyrifah',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
          ),
          SizedBox(height: 8),
          Text(
            'Cetak QR Code ini sekali dan tempel di area kegiatan.\n'
            'QR berlaku untuk semua jadwal at-Ta\'wid.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.grey700),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCode() {
    final token = _token ?? 'PPI_DAUROH_QR_2026';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'SCAN UNTUK ABSENSI',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.grey800, letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          QrImageView(
            data: token,
            version: QrVersions.auto,
            size: 250,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.grey800),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppTheme.grey800),
          ),
          const SizedBox(height: 16),
          const Text(
            'MTs Persis Garut',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.grey600),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cara Penggunaan:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.grey800),
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(1, 'Cetak QR Code ini (ukuran minimal 10x10 cm)'),
          _buildInstructionStep(2, 'Tempel QR Code di pintu masuk atau area yang mudah diakses'),
          _buildInstructionStep(3, 'Musyrifah buka aplikasi → tap icon "Scan" di navigation bar'),
          _buildInstructionStep(4, 'Arahkan kamera ke QR Code untuk absen masuk (06:30-07:00 WIB)'),
          _buildInstructionStep(5, 'Scan kembali untuk absen keluar (08:00-09:00 WIB)'),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(int step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: AppTheme.grey700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _printQR,
        icon: const Icon(Icons.print, color: Colors.white),
        label: const Text(
          'Cetak QR Code',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
