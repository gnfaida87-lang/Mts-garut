import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/guru_service.dart';

class WaliKelasPageGuru extends StatefulWidget {
  const WaliKelasPageGuru({super.key});

  @override
  State<WaliKelasPageGuru> createState() => _WaliKelasPageGuruState();
}

class _WaliKelasPageGuruState extends State<WaliKelasPageGuru>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _errorMessage;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  String? _selectedBulan;
  String? _selectedTahun;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _load();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  String? get _bulanTahun {
    if (_selectedBulan != null && _selectedTahun != null) {
      return '$_selectedTahun-${_selectedBulan!.padLeft(2, '0')}';
    }
    return null;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await GuruService.getDataSiswa(bulanTahun: _bulanTahun);
      if (!mounted) return;
      if (data['wali_kelas'] == null && data['kelas'] == null) {
        setState(() {
          _data = data;
          _loading = false;
        });
        return;
      }
      setState(() {
        _data = data;
        _loading = false;
        _errorMessage = null;
      });
      _animCtrl.reset();
      _animCtrl.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Gagal memuat data santri. Periksa koneksi Anda.';
      });
    }
  }

  bool get _isWaliKelas => _data?['kelas'] != null;
  Map<String, dynamic>? get _kelas => _data?['kelas'] as Map<String, dynamic>?;
  Map<String, dynamic>? get _waliGuru =>
      _data?['wali_guru'] as Map<String, dynamic>?;
  Map<String, dynamic>? get _semester =>
      _data?['semester'] as Map<String, dynamic>?;
  List<dynamic> get _siswa => _data?['siswa'] as List<dynamic>? ?? [];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 3),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isWaliKelas) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_outlined, size: 72, color: Colors.orange.shade300),
            const SizedBox(height: 16),
            Text(
              'Anda bukan wali kelas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 768;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: isWide
                ? _buildWideLayout()
                : _buildNarrowLayout(),
          );
        },
      ),
    );
  }

  // ─── LAYOUT WIDE (desktop) ───────────────────────────────
  Widget _buildWideLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildFilterBar(),
        const SizedBox(height: 20),
        _buildSummaryRow(),
        const SizedBox(height: 20),
        _buildActionsRow(),
        const SizedBox(height: 16),
        _buildTable(),
      ],
    );
  }

  // ─── LAYOUT NARROW (tablet/mobile) ───────────────────────
  Widget _buildNarrowLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        _buildFilterBar(),
        const SizedBox(height: 16),
        _buildSummaryRow(),
        const SizedBox(height: 12),
        _buildActionsRow(),
        const SizedBox(height: 12),
        _buildCardList(),
      ],
    );
  }

  // ─── FILTER BAR ─────────────────────────────────────────
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              value: _selectedBulan,
              isDense: true,
              decoration: InputDecoration(
                labelText: 'Bulan',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Semua Bulan', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: '1', child: Text('Januari', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: '2', child: Text('Februari', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: '3', child: Text('Maret', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: '4', child: Text('April', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: '5', child: Text('Mei', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: '6', child: Text('Juni', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: '7', child: Text('Juli', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: '8', child: Text('Agustus', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: '9', child: Text('September', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: '10', child: Text('Oktober', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: '11', child: Text('November', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: '12', child: Text('Desember', style: TextStyle(fontSize: 13))),
              ],
              onChanged: (v) => setState(() => _selectedBulan = v),
            ),
          ),
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<String>(
              value: _selectedTahun,
              isDense: true,
              decoration: InputDecoration(
                labelText: 'Tahun',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.date_range_outlined, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Semua Tahun', style: TextStyle(fontSize: 13))),
                for (int y = DateTime.now().year; y >= DateTime.now().year - 5; y--)
                  DropdownMenuItem(value: '$y', child: Text('$y', style: const TextStyle(fontSize: 13))),
              ],
              onChanged: (v) => setState(() => _selectedTahun = v),
            ),
          ),
          FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Tampilkan'),
          ),
        ],
      ),
    );
  }

  // ─── HEADER GRADIENT ────────────────────────────────────
  Widget _buildHeader() {
    final kelas = _kelas;
    final guru = _waliGuru;
    final sem = _semester;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5D4037), Color(0xFF8D6E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WALI KELAS',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      kelas?['nama'] ?? '-',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (guru != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        guru['nama'] ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (sem != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Semester ${sem['nama'] ?? '-'}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoChip(Icons.people_outlined, '${_siswa.length} Santri'),
              const SizedBox(width: 12),
              _infoChip(
                Icons.check_circle_outline,
                '${_siswa.where((s) => s['status'] == 'baik').length} Baik',
                color: const Color(0xFFB08968),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? Colors.white.withValues(alpha: 0.85)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SUMMARY ROW ────────────────────────────────────────
  Widget _buildSummaryRow() {
    final total = _siswa.length;
    if (total == 0) return const SizedBox.shrink();
    final totalHadir =
        _siswa.fold<int>(0, (s, e) => s + ((e['hadir'] as num?)?.toInt() ?? 0));
    final totalIzin =
        _siswa.fold<int>(0, (s, e) => s + ((e['izin'] as num?)?.toInt() ?? 0));
    final totalSakit =
        _siswa.fold<int>(0, (s, e) => s + ((e['sakit'] as num?)?.toInt() ?? 0));
    final totalAlpa =
        _siswa.fold<int>(0, (s, e) => s + ((e['alpa'] as num?)?.toInt() ?? 0));

    return Row(
      children: [
        _summaryCard('Total Hadir', '$totalHadir', Icons.check_circle, const Color(0xFF9C6644)),
        const SizedBox(width: 8),
        _summaryCard('Izin', '$totalIzin', Icons.info, Colors.orange),
        const SizedBox(width: 8),
        _summaryCard('Sakit', '$totalSakit', Icons.local_hospital, Colors.blue),
        const SizedBox(width: 8),
        _summaryCard('Alpa', '$totalAlpa', Icons.cancel, Colors.red),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ACTION BUTTONS ─────────────────────────────────────
  Widget _buildActionsRow() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _downloadPdf,
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('Download PDF F4'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _printPdf,
            icon: const Icon(Icons.print, size: 18),
            label: const Text('Print'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.teal.shade700,
              side: BorderSide(color: Colors.teal.shade300),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── DATA TABLE (WIDE) ──────────────────────────────────
  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.teal.shade50),
          dataRowMinHeight: 44,
          dataRowMaxHeight: 56,
          columnSpacing: 16,
          horizontalMargin: 16,
          columns: const [
            DataColumn(label: Text('NIS', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('NISN', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Kelas', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('Hadir', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('Izin', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('Sakit', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('Alpa', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _siswa.map((s) {
            final status = s['status']?.toString() ?? 'baik';
            final statusColor = _statusColor(status);
            return DataRow(
              cells: [
                DataCell(Text(s['nis']?.toString() ?? '')),
                DataCell(Text(s['nisn']?.toString() ?? '-')),
                DataCell(Text(s['nama']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w500))),
                DataCell(Text(s['kelas_nama']?.toString() ?? '')),
                DataCell(Text('${s['total_kehadiran'] ?? 0}')),
                DataCell(Text('${s['hadir'] ?? 0}')),
                DataCell(Text('${s['izin'] ?? 0}')),
                DataCell(Text('${s['sakit'] ?? 0}')),
                DataCell(Text('${s['alpa'] ?? 0}')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── CARD LIST (NARROW) ─────────────────────────────────
  Widget _buildCardList() {
    return Column(
      children: _siswa.map((s) {
        final status = s['status']?.toString() ?? 'baik';
        final statusColor = _statusColor(status);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s['nama']?.toString() ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${s['nis'] ?? ''} · ${s['kelas_nama'] ?? ''}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _miniStat(Icons.check_circle, const Color(0xFF9C6644), '${s['hadir'] ?? 0}'),
                    _miniStat(Icons.info, Colors.orange, '${s['izin'] ?? 0}'),
                    _miniStat(Icons.local_hospital, Colors.blue, '${s['sakit'] ?? 0}'),
                    _miniStat(Icons.cancel, Colors.red, '${s['alpa'] ?? 0}'),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _miniStat(IconData icon, Color color, String value) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'baik':
        return const Color(0xFF9C6644);
      case 'cukup':
        return Colors.orange;
      case 'kurang':
        return Colors.deepOrange;
      case 'kritis':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getNamaBulan(String? bulan) {
    switch (bulan) {
      case '1': return 'Januari';
      case '2': return 'Februari';
      case '3': return 'Maret';
      case '4': return 'April';
      case '5': return 'Mei';
      case '6': return 'Juni';
      case '7': return 'Juli';
      case '8': return 'Agustus';
      case '9': return 'September';
      case '10': return 'Oktober';
      case '11': return 'November';
      case '12': return 'Desember';
      default: return '';
    }
  }

  // ─── PDF GENERATION ─────────────────────────────────────
  Future<void> _downloadPdf() async {
    try {
      final pdf = await _generatePdf();
      final bytes = await pdf.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..target = '_blank'
        ..download =
            'Persentase_Kehadiran_${_kelas?['nama'] ?? 'Santri'}_${DateTime.now().millisecondsSinceEpoch}.pdf'
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat PDF')),
        );
      }
    }
  }

  Future<void> _printPdf() async {
    try {
      final pdf = await _generatePdf();
      await Printing.layoutPdf(
        onLayout: (_) => pdf.save(),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mencetak')),
        );
      }
    }
  }

  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();
    final kelas = _kelas;
    final guru = _waliGuru;
    final sem = _semester;
    final siswa = _siswa;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: const PdfPageFormat(215 * PdfPageFormat.mm, 330 * PdfPageFormat.mm, marginAll: 15),
        margin: const pw.EdgeInsets.all(15),
        header: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Column(
            children: [
              pw.Text(
                'PERSENTASE KEHADIRAN SELURUH SANTRI',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (_bulanTahun != null)
                pw.Text(
                  'Periode: ${_getNamaBulan(_selectedBulan)} $_selectedTahun',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
            ],
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Kelas: ${kelas?['nama'] ?? '-'}', style: const pw.TextStyle(fontSize: 11)),
              pw.Text('Wali Kelas: ${guru?['nama'] ?? '-'}', style: const pw.TextStyle(fontSize: 11)),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Semester: ${sem?['nama'] ?? '-'}',
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.grey200,
            ),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.center,
              6: pw.Alignment.center,
              7: pw.Alignment.center,
              8: pw.Alignment.center,
            },
            columnWidths: {
              0: const pw.FixedColumnWidth(24),
              1: const pw.FixedColumnWidth(22),
              2: const pw.FixedColumnWidth(50),
              3: const pw.FixedColumnWidth(22),
              4: const pw.FixedColumnWidth(14),
              5: const pw.FixedColumnWidth(14),
              6: const pw.FixedColumnWidth(14),
              7: const pw.FixedColumnWidth(14),
              8: const pw.FixedColumnWidth(16),
            },
            headers: const [
              'No', 'NIS', 'Nama', 'Kelas', 'Ttl', 'H', 'I', 'S', 'A',
            ],
            data: siswa.asMap().entries.map((entry) {
              final i = entry.key + 1;
              final s = entry.value;
              return [
                '$i',
                s['nis']?.toString() ?? '',
                s['nama']?.toString() ?? '',
                s['kelas_nama']?.toString() ?? '',
                '${s['total_kehadiran'] ?? 0}',
                '${s['hadir'] ?? 0}',
                '${s['izin'] ?? 0}',
                '${s['sakit'] ?? 0}',
                '${s['alpa'] ?? 0}',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('Mengetahui,', style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 40),
                  pw.Text(
                    guru?['nama'] ?? '__________________',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Wali Kelas',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Dicetak: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
        ],
      ),
    );

    return pdf;
  }
}
