import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../config/env.dart';

class QrAbsensiPage extends StatelessWidget {
  const QrAbsensiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Absensi'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header info
            _buildInfoCard(),
            const SizedBox(height: 24),

            // QR Code
            _buildQrCode(),
            const SizedBox(height: 24),

            // Instructions
            _buildInstructions(),
            const SizedBox(height: 24),

            // Print button
            _buildPrintButton(context),
          ],
        ),
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
          Icon(
            Icons.info_outline,
            color: AppTheme.primary,
            size: 32,
          ),
          SizedBox(height: 12),
          Text(
            'QR Code Absensi Guru',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Cetak QR Code ini dan tempel di pintu masuk.\nGuru scan QR ini menggunakan aplikasi untuk absensi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.grey700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCode() {
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.grey800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          QrImageView(
            data: Env.qrAbsensiToken,
            version: QrVersions.auto,
            size: 250,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppTheme.grey800,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AppTheme.grey800,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'MTs Persis Garut',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.grey600,
            ),
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.grey800,
            ),
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(1, 'Cetak QR Code ini dalam ukuran minimal 10x10 cm'),
          _buildInstructionStep(2, 'Tempel QR Code di pintu masuk atau area yang mudah diakses'),
          _buildInstructionStep(3, 'Guru buka aplikasi → tap icon "Scan" di navigation bar'),
          _buildInstructionStep(4, 'Arahkan kamera ke QR Code'),
          _buildInstructionStep(5, 'Scan pertama = Jam Masuk, Scan kedua = Jam Keluar'),
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
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.grey700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          // Copy token to clipboard for manual printing
          Clipboard.setData(const ClipboardData(text: Env.qrAbsensiToken));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Token QR telah disalin ke clipboard'),
              backgroundColor: AppTheme.primary,
            ),
          );
        },
        icon: const Icon(Icons.print, color: Colors.white),
        label: const Text(
          'Cetak QR Code',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
