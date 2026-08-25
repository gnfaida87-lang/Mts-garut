import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/dauroh_santri_service.dart';

class HasilProgramPage extends StatefulWidget {
  const HasilProgramPage({super.key});

  @override
  State<HasilProgramPage> createState() => _HasilProgramPageState();
}

class _HasilProgramPageState extends State<HasilProgramPage> {
  final _service = DaurohSantriService();
  List<Map<String, dynamic>> _nilai = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _nilai = await _service.getNilai();
      if (mounted) {
        setState(() => _loading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Hasil Program',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
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
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_nilai.isEmpty)
            _buildEmptyCard('Belum ada penilaian')
          else
            ..._nilai.map((n) => _buildNilaiCard(n)),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            style: const TextStyle(color: AppTheme.grey500, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildNilaiCard(Map<String, dynamic> nilai) {
    final program = nilai['nama_program']?.toString() ?? '-';
    final jenisProgram = nilai['jenis_program']?.toString() ?? '-';
    final surat = nilai['surat_nama']?.toString() ?? '-';
    final dariAyat = nilai['dari_ayat']?.toString() ?? '-';
    final sampaiAyat = nilai['sampai_ayat']?.toString() ?? '-';
    final status = nilai['status_hafalan']?.toString() ?? '-';
    final totalNilai = nilai['total_nilai'];

    // Dynamic labels dari backend
    final labelBidang1 = nilai['label_bidang1']?.toString() ?? 'Bidang 1';
    final labelBidang2 = nilai['label_bidang2']?.toString() ?? 'Bidang 2';
    final labelBidang3 = nilai['label_bidang3']?.toString() ?? 'Bidang 3';

    // Dynamic max values dari backend
    final maxBidang1 = _parseInt(nilai['max_bidang1']) ?? 40;
    final maxBidang2 = _parseInt(nilai['max_bidang2']) ?? 30;
    final maxBidang3 = _parseInt(nilai['max_bidang3']) ?? 30;

    final bidang1 = nilai['nilai_bidang1'];
    final bidang2 = nilai['nilai_bidang2'];
    final bidang3 = nilai['nilai_bidang3'];
    final catatan = nilai['catatan_umum']?.toString();
    final rencanaTL = nilai['rencana_tindak_lanjut']?.toString();
    final musyrifah = nilai['musyrifah_nama']?.toString() ?? '-';
    final tanggal = nilai['created_at']?.toString() ?? '-';

    Color statusColor;
    switch (status) {
      case 'mengulang':
        statusColor = AppTheme.orange;
        break;
      case 'melanjutkan':
        statusColor = AppTheme.primary;
        break;
      case 'selesai':
        statusColor = const Color(0xFF9C6644);
        break;
      default:
        statusColor = AppTheme.grey500;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Program + Status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Program: $program',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Jenis: $jenisProgram',
                        style: const TextStyle(fontSize: 12, color: AppTheme.grey500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Surat: $surat (Ayat $dariAyat-$sampaiAyat)',
                        style: const TextStyle(fontSize: 13, color: AppTheme.grey600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            // Nilai per Bidang (dynamic labels & max)
            Row(
              children: [
                _buildNilaiChip(labelBidang1, bidang1, maxBidang1),
                const SizedBox(width: 8),
                _buildNilaiChip(labelBidang2, bidang2, maxBidang2),
                const SizedBox(width: 8),
                _buildNilaiChip(labelBidang3, bidang3, maxBidang3),
                const Spacer(),
                _buildTotalNilai(totalNilai),
              ],
            ),
            const SizedBox(height: 12),
            // Musyrifah + Tanggal
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: AppTheme.grey500),
                const SizedBox(width: 4),
                Text(
                  'Dinilai oleh: $musyrifah',
                  style: const TextStyle(fontSize: 12, color: AppTheme.grey500),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.grey500),
                const SizedBox(width: 4),
                Text(
                  tanggal.length > 10 ? tanggal.substring(0, 10) : tanggal,
                  style: const TextStyle(fontSize: 12, color: AppTheme.grey500),
                ),
              ],
            ),
            // Catatan
            if (catatan != null && catatan.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoBox('Catatan:', catatan),
            ],
            // Rencana Tindak Lanjut
            if (rencanaTL != null && rencanaTL.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoBox('Rencana Tindak Lanjut:', rencanaTL),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.grey50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.grey600),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(fontSize: 12, color: AppTheme.grey700),
          ),
        ],
      ),
    );
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  Widget _buildNilaiChip(String label, dynamic nilai, int max) {
    final nilaiNum = nilai != null ? (nilai as num).toDouble() : null;
    Color color = AppTheme.grey600;
    if (nilaiNum != null) {
      final percentage = (nilaiNum / max) * 100;
      if (percentage >= 80) {
        color = AppTheme.primary;
      } else if (percentage >= 60) {
        color = AppTheme.orange;
      } else {
        color = AppTheme.error;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color),
          ),
          Text(
            nilaiNum?.toStringAsFixed(0) ?? '-',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
          ),
          Text(
            '/ $max',
            style: TextStyle(fontSize: 10, color: color.withAlpha(150)),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalNilai(dynamic nilai) {
    final nilaiNum = nilai != null ? (nilai as num).toDouble() : null;
    Color color = AppTheme.grey600;
    if (nilaiNum != null) {
      if (nilaiNum >= 80) {
        color = AppTheme.primary;
      } else if (nilaiNum >= 60) {
        color = AppTheme.orange;
      } else {
        color = AppTheme.error;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'TOTAL',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          Text(
            nilaiNum?.toStringAsFixed(0) ?? '-',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
