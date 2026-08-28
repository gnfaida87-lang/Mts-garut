import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/guru_service.dart';

class RaporPageGuru extends StatefulWidget {
  const RaporPageGuru({super.key});

  @override
  State<RaporPageGuru> createState() => _RaporPageGuruState();
}

class _RaporPageGuruState extends State<RaporPageGuru> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _dataWali;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDataWali();
  }

  Future<void> _loadDataWali() async {
    try {
      _dataWali = await GuruService.getDataWaliRapor();
    } catch (_) { debugPrint('[rapor_page.dart] error caught'); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_dataWali == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('Gagal memuat data', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.grey[600])),
              const SizedBox(height: 6),
              Text('Periksa koneksi dan coba lagi', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () { setState(() => _loading = true); _loadDataWali(); },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C6644), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
        ),
      );
    }

    final waliKelas = _dataWali!['wali_kelas'] as Map<String, dynamic>?;
    if (waliKelas == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('Anda bukan wali kelas', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.grey[600])),
              const SizedBox(height: 6),
              Text('Fitur rapor hanya untuk wali kelas', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ],
          ),
        ),
      );
    }

    final siswa = _dataWali!['siswa'] as List<dynamic>? ?? [];
    final mapel = _dataWali!['mapel'] as List<dynamic>? ?? [];

    return Column(
      children: [
        // ── Header ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF9C6644), Color(0xFFA9764F), Color(0xFF9C6644)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.assignment_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rapor Santri', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('Wali Kelas: ${waliKelas['nama'] ?? ''}', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(width: 6),
                    Text('${siswa.length} Santri  ·  ${mapel.length} Mapel', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ),
            ],
          ),
        ),
        // ── Tab Bar ──
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF9C6644),
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: const Color(0xFF9C6644),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: const [
              Tab(text: 'Lihat Rapor', icon: Icon(Icons.visibility_rounded, size: 18)),
              Tab(text: 'Status Pengiriman', icon: Icon(Icons.history_rounded, size: 18)),
            ],
          ),
        ),
        // ── Tab Content ──
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _LihatRapor(dataWali: _dataWali!),
              _StatusPengiriman(dataWali: _dataWali!),
            ],
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// TAB 1: LIHAT RAPOR
// =====================================================================

class _LihatRapor extends StatefulWidget {
  final Map<String, dynamic> dataWali;
  const _LihatRapor({required this.dataWali});

  @override
  State<_LihatRapor> createState() => _LihatRaporState();
}

class _LihatRaporState extends State<_LihatRapor> {
  List<dynamic> _siswa = [], _semester = [];
  int? _siswaId, _semesterId;
  Map<String, dynamic>? _raporData;
  bool _loadingSemester = true, _loadingRapor = false;

  @override
  void initState() {
    super.initState();
    _siswa = List<dynamic>.from(widget.dataWali['siswa'] as List? ?? []);
    _loadSemester();
  }

  Future<void> _loadSemester() async {
    try {
      _semester = await GuruService.getSemesterList();
      if (_semester.isNotEmpty) _semesterId = _semester[0]['id'] as int?;
    } catch (_) { debugPrint('[rapor_page.dart] error caught'); }
    if (mounted) setState(() => _loadingSemester = false);
  }

  Future<void> _loadRapor() async {
    if (_siswaId == null || _semesterId == null) return;
    setState(() => _loadingRapor = true);
    try {
      _raporData = await GuruService.getRapor(siswaId: '$_siswaId', semesterId: '$_semesterId');
    } catch (_) {
      _raporData = null;
    }
    setState(() => _loadingRapor = false);
  }

  // ── PDF Generation ──

  Future<Uint8List> _generatePdf() async {
    if (_raporData == null) return Uint8List(0);
    final s = _raporData!['siswa'] as Map<String, dynamic>? ?? {};
    final sem = _raporData!['semester'] as Map<String, dynamic>? ?? {};
    final mapel = _raporData!['mapel'] as List<dynamic>? ?? [];
    final catatan = _raporData!['catatan_wali'] as String? ?? '';

    final pdf = pw.Document();
    const pageFormat = PdfPageFormat(215 * PdfPageFormat.mm, 330 * PdfPageFormat.mm); // F4

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Column(children: [
            pw.Text('RAPOR HASIL BELAJAR SANTRI', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('Madrasah Tsanawiyah / Aliyah', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            pw.Divider(thickness: 1),
          ]),
        ),
        build: (_) => [
          pw.Text('NILAI HASIL BELAJAR ${(sem['nama'] as String?)?.toUpperCase() ?? ''}',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          _pdfRow('NIS / NISN', '${s['nis'] ?? ''} / ${s['nisn'] ?? '-'}'),
          _pdfRow('Nama Santri', s['nama']?.toString() ?? ''),
          _pdfRow('Kelas', s['kelas_nama']?.toString() ?? ''),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.5),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(0.8),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _pdfCell('No', bold: true, align: pw.Alignment.center),
                  _pdfCell('Mata Pelajaran', bold: true),
                  _pdfCell('Nilai ${mapel.isNotEmpty ? (mapel[0]['jenis_ujian']?.toString().toUpperCase() ?? 'UJIAN') : 'UJIAN'}', bold: true, align: pw.Alignment.center),
                  _pdfCell('Rata-rata Harian', bold: true, align: pw.Alignment.center),
                  _pdfCell('Nilai Akhir', bold: true, align: pw.Alignment.center),
                  _pdfCell('Predikat', bold: true, align: pw.Alignment.center),
                ],
              ),
              ...mapel.asMap().entries.map((e) {
                final m = e.value as Map<String, dynamic>;
                return pw.TableRow(children: [
                  _pdfCell('${e.key + 1}', align: pw.Alignment.center),
                  _pdfCell(m['nama']?.toString() ?? ''),
                  _pdfCell(m['nilai_ujian']?.toString() ?? '-', align: pw.Alignment.center),
                  _pdfCell(m['rata_harian']?.toString() ?? '-', align: pw.Alignment.center),
                  _pdfCell(m['nilai_akhir']?.toString() ?? '-', align: pw.Alignment.center),
                  _pdfCell(m['predikat']?.toString() ?? '-', align: pw.Alignment.center),
                ]);
              }),
            ],
          ),
          if (catatan.isNotEmpty) ...[pw.SizedBox(height: 20), pw.Text('Catatan Wali Kelas:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)), pw.SizedBox(height: 4), pw.Container(padding: const pw.EdgeInsets.all(12), decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)), child: pw.Text(catatan, style: const pw.TextStyle(fontSize: 11)))],
          pw.SizedBox(height: 30),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [
            pw.Column(children: [pw.Text('Mengetahui,', style: const pw.TextStyle(fontSize: 10)), pw.SizedBox(height: 40), pw.Text('Kepala Madrasah', style: const pw.TextStyle(fontSize: 10)), pw.SizedBox(height: 4), pw.Text('( ___________________ )', style: const pw.TextStyle(fontSize: 10))]),
            pw.Column(children: [pw.Text('Wali Kelas,', style: const pw.TextStyle(fontSize: 10)), pw.SizedBox(height: 40), pw.Text('___________________', style: const pw.TextStyle(fontSize: 10)), pw.SizedBox(height: 4), pw.Text('( ___________________ )', style: const pw.TextStyle(fontSize: 10))]),
            pw.Column(children: [pw.Text('Santri,', style: const pw.TextStyle(fontSize: 10)), pw.SizedBox(height: 40), pw.Text('___________________', style: const pw.TextStyle(fontSize: 10)), pw.SizedBox(height: 4), pw.Text('( ___________________ )', style: const pw.TextStyle(fontSize: 10))]),
          ]),
        ],
      ),
    );
    return pdf.save();
  }

  pw.Widget _pdfRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(children: [
          pw.SizedBox(width: 100, child: pw.Text(label, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
          pw.Text(':  $value', style: const pw.TextStyle(fontSize: 11)),
        ]),
      );

  pw.Widget _pdfCell(String text, {bool bold = false, pw.Alignment? align}) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        alignment: align ?? pw.Alignment.centerLeft,
        child: pw.Text(text, style: pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );

  Future<void> _downloadPdf() async {
    if (_raporData == null) return;
    try {
      final pdfBytes = await _generatePdf();
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = 'Rapor_${_raporData!['siswa']?['nama'] ?? 'Santri'}_${_raporData!['semester']?['nama'] ?? ''}.pdf';
      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [Icon(Icons.check_circle, color: Colors.white, size: 18), SizedBox(width: 8), Text('PDF berhasil diunduh')]),
          backgroundColor: const Color(0xFF9C6644), behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal: $e'), backgroundColor: Colors.red[700], behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  Future<void> _printPdf() async {
    if (_raporData == null) return;
    try {
      final pdfBytes = await _generatePdf();
      await Printing.layoutPdf(onLayout: (_) => pdfBytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal print: $e'), backgroundColor: Colors.red[700], behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSemester) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // ── Filter ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF9C6644).withValues(alpha: 0.1)),
            boxShadow: [BoxShadow(color: const Color(0xFF9C6644).withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(title: 'Pilih Santri & Semester'),
              const SizedBox(height: 12),
              Wrap(spacing: 16, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
                SizedBox(width: 250, child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Pilih Santri', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_rounded)),
                  value: _siswaId,
                  items: _siswa.map((s) => DropdownMenuItem(value: s['id'] as int, child: Text('${s['nis']} - ${s['nama']}', overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() => _siswaId = v),
                )),
                SizedBox(width: 200, child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Pilih Semester', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_month_rounded)),
                  value: _semesterId,
                  items: _semester.map((s) => DropdownMenuItem(value: s['id'] as int, child: Text(s['nama']?.toString() ?? ''))).toList(),
                  onChanged: (v) => setState(() => _semesterId = v),
                )),
                SizedBox(height: 50, child: ElevatedButton.icon(
                  onPressed: (_siswaId != null && _semesterId != null && !_loadingRapor) ? _loadRapor : null,
                  icon: _loadingRapor
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search_rounded),
                  label: Text(_loadingRapor ? 'Memuat...' : 'Tampilkan', style: const TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9C6644), foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                )),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Hasil ──
        if (_raporData != null) ...[
          // Tombol Aksi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(children: [
              const Icon(Icons.picture_as_pdf, size: 18, color: Color(0xFF9C6644)),
              const SizedBox(width: 6),
              const Text('F4', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF9C6644))),
              const Spacer(),
              _actionBtn(icon: Icons.download_rounded, label: 'Download PDF', color: const Color(0xFF1565C0), onTap: _downloadPdf),
              const SizedBox(width: 10),
              _actionBtn(icon: Icons.print_rounded, label: 'Print', color: const Color(0xFFE65100), onTap: _printPdf),
            ]),
          ),

          // Header Nilai Hasil Belajar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF9C6644).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF9C6644).withValues(alpha: 0.12)),
            ),
            child: Text(
              'NILAI HASIL BELAJAR ${(_raporData!['semester']?['nama'] as String?)?.toUpperCase() ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF9C6644), letterSpacing: 0.5),
            ),
          ),
          const SizedBox(height: 14),

          // Info Siswa
          _buildSiswaCard(),
          const SizedBox(height: 14),

          // Tabel Nilai
          _buildNilaiTable(),
          const SizedBox(height: 14),

          // Catatan Wali
          _buildCatatanCard(),
        ] else if (_loadingRapor) ...[
          const SizedBox(height: 60), const Center(child: CircularProgressIndicator()),
        ] else ...[
          const SizedBox(height: 60),
          Center(child: Column(children: [
            Icon(Icons.touch_app_rounded, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Pilih santri dan semester', style: TextStyle(fontSize: 15, color: Colors.grey[500])),
            const SizedBox(height: 4),
            Text('lalu klik Tampilkan', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          ])),
        ],
      ]),
    );
  }

  Widget _actionBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Material(
      color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10), onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
          ]),
        ),
      ),
    );
  }

  Widget _buildSiswaCard() {
    final s = _raporData!['siswa'] as Map<String, dynamic>? ?? {};
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF9C6644).withValues(alpha: 0.08)), boxShadow: [BoxShadow(color: const Color(0xFF9C6644).withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF9C6644).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.person_rounded, color: Color(0xFF9C6644), size: 26)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s['nama']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF9C6644))),
          const SizedBox(height: 4),
          Wrap(spacing: 20, runSpacing: 4, children: [
            _infoChip(Icons.badge_rounded, 'NIS/NISN: ${s['nis'] ?? '-'} / ${s['nisn'] ?? '-'}'),
            _infoChip(Icons.book_rounded, '${s['kelas_nama'] ?? '-'}'),
          ]),
        ])),
      ]),
    );
  }

  Widget _infoChip(IconData icon, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ]);

  Widget _buildNilaiTable() {
    final mapel = _raporData!['mapel'] as List<dynamic>? ?? [];
    if (mapel.isEmpty) return Container(padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey[200]!)), child: const Center(child: Text('Belum ada data nilai')));

    final totalAkhir = mapel.fold<double>(0, (sum, m) => sum + ((m['nilai_akhir'] as num?)?.toDouble() ?? 0));
    final rataRata = mapel.isNotEmpty ? (totalAkhir / mapel.length).toStringAsFixed(1) : '0.0';

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF9C6644).withValues(alpha: 0.08)), boxShadow: [BoxShadow(color: const Color(0xFF9C6644).withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF9C6644).withValues(alpha: 0.06), borderRadius: const BorderRadius.vertical(top: Radius.circular(14))),
          child: Row(children: [
            const Icon(Icons.menu_book_rounded, size: 18, color: Color(0xFF9C6644)),
            const SizedBox(width: 8),
            const Text('Daftar Nilai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF9C6644))),
            const Spacer(),
            Text('Rata-rata: $rataRata', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF9C6644))),
          ]),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(const Color(0xFF9C6644).withValues(alpha: 0.04)),
            headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF9C6644)),
            columnSpacing: 20, horizontalMargin: 16, dataRowMinHeight: 40, dataRowMaxHeight: 48,
            columns: const [DataColumn(label: Text('No')), DataColumn(label: Text('Mata Pelajaran')), DataColumn(label: Text('Nilai Ujian'), numeric: true), DataColumn(label: Text('Rata Harian'), numeric: true), DataColumn(label: Text('Nilai Akhir'), numeric: true), DataColumn(label: Text('Predikat'))],
            rows: List.generate(mapel.length, (i) {
              final m = mapel[i] as Map<String, dynamic>;
              final nilaiAkhir = m['nilai_akhir'];
              final predikat = m['predikat']?.toString() ?? '-';
              final color = _predikatColor(predikat);
              return DataRow(cells: [
                DataCell(Text('${i + 1}', style: const TextStyle(fontSize: 13))),
                DataCell(SizedBox(width: 170, child: Text(m['nama']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)))),
                DataCell(Text(m['nilai_ujian']?.toString() ?? '-', style: const TextStyle(fontSize: 13))),
                DataCell(Text(m['rata_harian']?.toString() ?? '-', style: const TextStyle(fontSize: 13))),
                DataCell(Text(nilaiAkhir?.toString() ?? '-', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: nilaiAkhir != null ? const Color(0xFF9C6644) : Colors.grey))),
                DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.3))), child: Text(predikat, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)))),
              ]);
            }),
          ),
        ),
      ]),
    );
  }

  Color _predikatColor(String p) {
    switch (p) { case 'A': return const Color(0xFF9C6644); case 'B': return const Color(0xFF1565C0); case 'C': return const Color(0xFFE65100); case 'D': return const Color(0xFFC62828); default: return Colors.grey; }
  }

  Widget _buildCatatanCard() {
    final catatan = _raporData!['catatan_wali'] as String? ?? '';
    final catatanCtl = TextEditingController(text: catatan);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFF9A825).withValues(alpha: 0.2)), boxShadow: [BoxShadow(color: const Color(0xFFF9A825).withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF9A825).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.note_alt_rounded, color: Color(0xFFF9A825), size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Catatan Wali Kelas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFF9A825))),
          const SizedBox(height: 6),
          Text(catatan.isNotEmpty ? catatan : 'Belum ada catatan. Klik edit untuk menambahkan.', style: TextStyle(fontSize: 13, color: catatan.isNotEmpty ? Colors.grey[700] : Colors.grey[400], height: 1.5, fontStyle: catatan.isNotEmpty ? FontStyle.normal : FontStyle.italic)),
        ])),
        IconButton(
          tooltip: 'Edit Catatan',
          icon: const Icon(Icons.edit_rounded, size: 20, color: Color(0xFFF9A825)),
          onPressed: () => _editCatatan(catatanCtl),
        ),
      ]),
    );
  }

  Future<void> _editCatatan(TextEditingController ctl) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Catatan Wali Kelas'),
        content: TextField(
          controller: ctl,
          maxLines: 4,
          maxLength: 1000,
          decoration: const InputDecoration(
            hintText: 'Tulis catatan wali kelas untuk santri ini...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctl.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result == null || !mounted || _siswaId == null || _semesterId == null) return;
    try {
      await GuruService.saveCatatanWali({
        'siswa_id': _siswaId,
        'semester_id': _semesterId,
        'catatan': result,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Row(children: [Icon(Icons.check_circle, color: Colors.white, size: 18), SizedBox(width: 8), Text('Catatan tersimpan')]),
        backgroundColor: Color(0xFF9C6644), behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))), margin: EdgeInsets.all(16),
      ));
      await _loadRapor();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal menyimpan catatan'), backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(16),
        ));
      }
    }
  }
}

// =====================================================================
// TAB 2: STATUS PENGIRIMAN (Historis input PAS/PAT oleh guru_mapel)
// =====================================================================

class _StatusPengiriman extends StatefulWidget {
  final Map<String, dynamic> dataWali;
  const _StatusPengiriman({required this.dataWali});

  @override
  State<_StatusPengiriman> createState() => _StatusPengirimanState();
}

class _StatusPengirimanState extends State<_StatusPengiriman> {
  List<dynamic> _semester = [];
  int? _semesterId;
  List<dynamic> _statusList = [];
  bool _loadingSemester = true, _loadingData = false;

  @override
  void initState() {
    super.initState();
    _loadSemester();
  }

  Future<void> _loadSemester() async {
    try {
      _semester = await GuruService.getSemesterList();
      if (_semester.isNotEmpty) _semesterId = _semester[0]['id'] as int?;
    } catch (_) { debugPrint('[rapor_page.dart] error caught'); }
    if (mounted) setState(() => _loadingSemester = false);
  }

  Future<void> _loadStatus() async {
    if (_semesterId == null) return;
    setState(() => _loadingData = true);
    try {
      _statusList = await GuruService.getStatusPengiriman('$_semesterId');
    } catch (_) {
      _statusList = [];
    }
    setState(() => _loadingData = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSemester) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Filter
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF9C6644).withValues(alpha: 0.1)), boxShadow: [BoxShadow(color: const Color(0xFF9C6644).withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _SectionTitle(title: 'Pilih Semester'),
            const SizedBox(height: 12),
            Wrap(spacing: 16, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
              SizedBox(width: 250, child: DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Pilih Semester', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_month_rounded)),
                value: _semesterId,
                items: _semester.map((s) => DropdownMenuItem(value: s['id'] as int, child: Text(s['nama']?.toString() ?? ''))).toList(),
                onChanged: (v) => setState(() => _semesterId = v),
              )),
              SizedBox(height: 50, child: ElevatedButton.icon(
                onPressed: (_semesterId != null && !_loadingData) ? _loadStatus : null,
                icon: _loadingData ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.search_rounded),
                label: Text(_loadingData ? 'Memuat...' : 'Tampilkan', style: const TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C6644), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24)),
              )),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // Status list
        if (_loadingData) ...[
          const SizedBox(height: 40), const Center(child: CircularProgressIndicator()),
        ] else if (_statusList.isEmpty) ...[
          const SizedBox(height: 40),
          Center(child: Column(children: [
            Icon(Icons.inbox_rounded, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Pilih semester dan klik Tampilkan', style: TextStyle(color: Colors.grey[500])),
          ])),
        ] else ...[
          // Summary
          _buildSummary(),
          const SizedBox(height: 14),
          // Detail list
          ..._statusList.map((item) => _buildStatusCard(item as Map<String, dynamic>)),
        ],
      ]),
    );
  }

  Widget _buildSummary() {
    final sudah = _statusList.where((s) => (s as Map<String, dynamic>)['nilai_id'] != null).length;
    final total = _statusList.length;
    final belum = total - sudah;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF9C6644).withValues(alpha: 0.08)),
        boxShadow: [BoxShadow(color: const Color(0xFF9C6644).withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Expanded(child: _summaryItem(Icons.check_circle_rounded, 'Sudah Input', '$sudah', const Color(0xFF9C6644))),
        Container(height: 40, width: 1, color: Colors.grey[200]),
        Expanded(child: _summaryItem(Icons.pending_rounded, 'Belum Input', '$belum', Colors.orange[700]!)),
        Container(height: 40, width: 1, color: Colors.grey[200]),
        Expanded(child: _summaryItem(Icons.book_rounded, 'Total Mapel', '$total', const Color(0xFF1565C0))),
      ]),
    );
  }

  Widget _summaryItem(IconData icon, String label, String value, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
    ]);
  }

  Widget _buildStatusCard(Map<String, dynamic> item) {
    final sudahInput = item['nilai_id'] != null;
    final tglInput = item['tgl_input'] as String?;
    final jumlahSantri = item['jumlah_santri'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sudahInput ? const Color(0xFF9C6644).withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: (sudahInput ? const Color(0xFF9C6644) : Colors.orange).withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: sudahInput ? const Color(0xFF9C6644).withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(sudahInput ? Icons.check_circle : Icons.hourglass_empty_rounded,
              color: sudahInput ? const Color(0xFF9C6644) : Colors.orange[700], size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['mapel_nama']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.person_outlined, size: 13, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text('Guru: ${item['guru_nama'] ?? '-'}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(width: 16),
            Icon(Icons.people_outlined, size: 13, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text('$jumlahSantri santri', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ]),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: sudahInput ? const Color(0xFF9C6644).withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sudahInput ? const Color(0xFF9C6644).withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(sudahInput ? Icons.check : Icons.close, size: 14, color: sudahInput ? const Color(0xFF9C6644) : Colors.orange[700]),
              const SizedBox(width: 4),
              Text(sudahInput ? 'Sudah' : 'Belum', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sudahInput ? const Color(0xFF9C6644) : Colors.orange[700])),
            ]),
          ),
          if (sudahInput && tglInput != null) ...[
            const SizedBox(height: 6),
            Text(tglInput.length >= 10 ? tglInput.substring(0, 10) : tglInput, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ]),
      ]),
    );
  }
}

// =====================================================================
// SHARED WIDGET
// =====================================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFFF9A825), borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF9C6644))),
    ]);
  }
}
