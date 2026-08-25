import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DaurohPdfExport {
  static final PdfColor _green = PdfColor.fromHex('#9C6644');
  static final PdfColor _orange = PdfColor.fromHex('#FF8F00');
  static final PdfColor _red = PdfColor.fromHex('#C62828');
  static final PdfColor _headerBg = PdfColor.fromHex('#1565C0');
  static final PdfColor _tableHeader = PdfColor.fromHex('#1976D2');
  static final PdfColor _altRow = PdfColor.fromHex('#F5F5F5');
  static final PdfColor _grey300 = PdfColor.fromHex('#E0E0E0');
  static final PdfColor _grey600 = PdfColor.fromHex('#757575');
  static final PdfColor _lightGreenBg = PdfColor.fromHex('#F5EBE0');
  static final PdfColor _lightOrangeBg = PdfColor.fromHex('#FFF3E0');
  static final PdfColor _lightRedBg = PdfColor.fromHex('#FFEBEE');

  static PdfColor _scoreColor(double percent) {
    if (percent >= 80) return _green;
    if (percent >= 60) return _orange;
    return _red;
  }

  static PdfColor _scoreBg(double percent) {
    if (percent >= 80) return _lightGreenBg;
    if (percent >= 60) return _lightOrangeBg;
    return _lightRedBg;
  }

  static double _n(dynamic v) => v != null ? (v as num).toDouble() : 0;

  static int? _maxInt(dynamic v) {
    if (v == null) return null;
    final n = int.tryParse(v.toString());
    return (n == null || n <= 0) ? null : n;
  }

  // ─── EXPORT NILAI PER SANTRI ──────────────────────────────
  static Future<void> exportNilaiPerSantri(Map<String, dynamic> n) async {
    final pdf = pw.Document();
    final theme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.nunitoRegular(),
      bold: await PdfGoogleFonts.nunitoBold(),
    );

    final bidang1Max = _maxInt(n['max_bidang1']) ?? 40;
    final bidang2Max = _maxInt(n['max_bidang2']) ?? 30;
    final bidang3Max = _maxInt(n['max_bidang3']) ?? 30;
    final b1 = _n(n['nilai_bidang1']);
    final b2 = _n(n['nilai_bidang2']);
    final b3 = _n(n['nilai_bidang3']);
    final total = _n(n['total_nilai']);
    final totalMax = bidang1Max + bidang2Max + bidang3Max;
    final percent = totalMax > 0 ? (total / totalMax) * 100 : 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          // ── HEADER ──
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: _headerBg,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'LAPORAN PENILAIAN AT-TA\'WID',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'MA Persis Garut',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.white),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // ── INFO SANTRI ──
          _sectionTitle('Data Santri'),
          pw.SizedBox(height: 8),
          _infoTable([
            ['Nama', '${n['santri_nama'] ?? '-'}'],
            ['NIS', '${n['nis'] ?? '-'}'],
            ['Kelas', '${n['kelas_nama'] ?? '-'}'],
            ['Program', '${n['nama_program'] ?? '-'}'],
            ['Surat', '${n['surat_nama'] ?? '-'} (Ayat ${n['dari_ayat'] ?? '-'}-${n['sampai_ayat'] ?? '-'})'],
            ['Status', '${n['status_hafalan'] ?? '-'}'],
          ]),
          pw.SizedBox(height: 20),

          // ── BIDANG 1 ──
          _bidangSection(
            'Bidang 1: ${n['label_bidang1'] ?? 'Kelancaran Hafalan'} (Max $bidang1Max)',
            [
              ['Kelancaran', _n(n['kelancaran'])],
              ['Ketepatan Ayat', _n(n['ketepatan_ayat'])],
              ['Murojaah Sambung', _n(n['murojaah_sambung'])],
              ['Konsistensi Hafalan', _n(n['konsistensi_hafalan'])],
            ],
            bidang1Max,
            b1,
            n['catatan_bidang1']?.toString(),
          ),
          pw.SizedBox(height: 12),

          // ── BIDANG 2 ──
          _bidangSection(
            'Bidang 2: ${n['label_bidang2'] ?? 'Tajwid'} (Max $bidang2Max)',
            [
              ['Makhorijul Huruf', _n(n['makhorijul_huruf'])],
              ['Sifatul Huruf', _n(n['sifatul_huruf'])],
              ['Ahkamul Huruf', _n(n['ahkamul_huruf'])],
              ['Ahkamul Madd', _n(n['ahkamul_madd'])],
            ],
            bidang2Max,
            b2,
            n['catatan_bidang2']?.toString(),
          ),
          pw.SizedBox(height: 12),

          // ── BIDANG 3 ──
          _bidangSection(
            'Bidang 3: ${n['label_bidang3'] ?? 'Fashohah dan Adab'} (Max $bidang3Max)',
            [
              ['Ahkamul Waqfi', _n(n['ahkamul_waqfi'])],
              ['Adabut Tilawah', _n(n['adabut_tilawah'])],
              ['Kerapihan Bacaan', _n(n['kerapihan_bacaan'])],
              ['Ketepatan Tempo', _n(n['ketepatan_tempo'])],
            ],
            bidang3Max,
            b3,
            n['catatan_bidang3']?.toString(),
          ),
          pw.SizedBox(height: 20),

          // ── TOTAL ──
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _scoreBg(percent),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: _scoreColor(percent), width: 1.5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _totalColumn('Bidang 1', b1, bidang1Max),
                _totalColumn('Bidang 2', b2, bidang2Max),
                _totalColumn('Bidang 3', b3, bidang3Max),
                pw.Container(width: 1, height: 40, color: _grey300),
                pw.Column(
                  children: [
                    pw.Text('TOTAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${total.toStringAsFixed(0)}/$totalMax',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: _scoreColor(percent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // ── CATATAN ──
          if (n['catatan_umum']?.toString().isNotEmpty == true) ...[
            _sectionTitle('Catatan'),
            pw.SizedBox(height: 8),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: _altRow,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(n['catatan_umum'].toString(), style: const pw.TextStyle(fontSize: 11)),
            ),
            pw.SizedBox(height: 12),
          ],
          if (n['rencana_tindak_lanjut']?.toString().isNotEmpty == true) ...[
            _sectionTitle('Rencana Tindak Lanjut'),
            pw.SizedBox(height: 8),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: _altRow,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(n['rencana_tindak_lanjut'].toString(), style: const pw.TextStyle(fontSize: 11)),
            ),
            pw.SizedBox(height: 20),
          ],

          // ── TANDA TANGAN ──
          pw.SizedBox(height: 30),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                children: [
                  pw.Text('Mengetahui,', style: const pw.TextStyle(fontSize: 11)),
                  pw.SizedBox(height: 30),
                  pw.Container(
                    width: 150,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('${n['musyrifah_nama'] ?? 'Musyrifah'}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  // ─── EXPORT BATCH ─────────────────────────────────────────
  static Future<void> exportBatch(List<Map<String, dynamic>> data, {String? title}) async {
    final pdf = pw.Document();
    final theme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.nunitoRegular(),
      bold: await PdfGoogleFonts.nunitoBold(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: theme,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          // ── HEADER ──
          pw.Center(
            child: pw.Text(
              title ?? 'Laporan Penilaian at-Ta\'wid',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'Dicetak: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: pw.TextStyle(fontSize: 10, color: _grey600),
            ),
          ),
          pw.SizedBox(height: 12),

          // ── TABLE ──
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: _tableHeader),
            headerAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            cellHeight: 24,
            cellAlignments: {
              0: pw.Alignment.center,
              5: pw.Alignment.center,
              6: pw.Alignment.center,
              7: pw.Alignment.center,
              8: pw.Alignment.center,
              9: pw.Alignment.center,
            },
            headerAlignments: {
              0: pw.Alignment.center,
              5: pw.Alignment.center,
              6: pw.Alignment.center,
              7: pw.Alignment.center,
              8: pw.Alignment.center,
              9: pw.Alignment.center,
            },
            oddRowDecoration: pw.BoxDecoration(color: _altRow),
            headers: ['No', 'Nama', 'NIS', 'Kelas', 'Surat', 'Status', 'B1', 'B2', 'B3', 'Total'],
            data: data.asMap().entries.map((entry) {
              final i = entry.key;
              final n = entry.value;
              final total = _n(n['total_nilai']);
              return [
                '${i + 1}',
                '${n['santri_nama'] ?? '-'}',
                '${n['nis'] ?? '-'}',
                '${n['kelas_nama'] ?? '-'}',
                '${n['surat_nama'] ?? '-'}',
                '${n['status_hafalan'] ?? '-'}',
                _n(n['nilai_bidang1']).toStringAsFixed(0),
                _n(n['nilai_bidang2']).toStringAsFixed(0),
                _n(n['nilai_bidang3']).toStringAsFixed(0),
                total.toStringAsFixed(0),
              ];
            }).toList(),
          ),

          // ── SUMMARY ──
          if (data.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: _altRow,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _summaryItem('Total Data', '${data.length}'),
                  _summaryItem('Rata-rata B1', _avg(data, 'nilai_bidang1')),
                  _summaryItem('Rata-rata B2', _avg(data, 'nilai_bidang2')),
                  _summaryItem('Rata-rata B3', _avg(data, 'nilai_bidang3')),
                  _summaryItem('Rata-rata Total', _avg(data, 'total_nilai')),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  // ─── HELPER WIDGETS ──────────────────────────────────────
  static pw.Widget _sectionTitle(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue, width: 1.5)),
      ),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
    );
  }

  static pw.Widget _infoTable(List<List<String>> rows) {
    return pw.TableHelper.fromTextArray(
      cellStyle: const pw.TextStyle(fontSize: 11),
      cellHeight: 22,
      cellAlignment: pw.Alignment.centerLeft,
      data: rows,
    );
  }

  static pw.Widget _bidangSection(
    String title,
    List<List<dynamic>> criteria,
    int max,
    double score,
    String? catatan,
  ) {
    final percent = max > 0 ? (score / max) * 100 : 0.0;
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _scoreBg(percent),
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _scoreColor(percent)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(width: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: _scoreColor(percent),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Text(
                  '${score.toStringAsFixed(0)}/$max',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: _grey600),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellHeight: 20,
            headerAlignment: pw.Alignment.centerLeft,
            data: [
              ['Kriteria', 'Potongan (1-5)'],
              ...criteria.map((c) => [
                '${c[0]}',
                (c[1] as double).toStringAsFixed(0),
              ]),
              [
                'Total Potongan',
                criteria.fold(0.0, (sum, c) => sum + (c[1] as double)).toStringAsFixed(0),
              ],
            ],
          ),
          if (catatan != null && catatan.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text('Catatan: $catatan', style: pw.TextStyle(fontSize: 10, color: _grey600, fontStyle: pw.FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  static pw.Widget _totalColumn(String label, double value, int max) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: _grey600)),
        pw.SizedBox(height: 4),
        pw.Text(
          '${value.toStringAsFixed(0)}/$max',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static pw.Widget _summaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 9, color: _grey600)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static String _avg(List<Map<String, dynamic>> data, String field) {
    if (data.isEmpty) return '-';
    double sum = 0;
    int count = 0;
    for (final n in data) {
      final v = n[field];
      if (v != null) {
        sum += (v as num).toDouble();
        count++;
      }
    }
    return count > 0 ? (sum / count).toStringAsFixed(1) : '-';
  }
}
