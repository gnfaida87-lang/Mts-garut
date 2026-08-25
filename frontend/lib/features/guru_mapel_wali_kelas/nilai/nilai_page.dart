import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../services/guru_service.dart';

class NilaiPageGuru extends StatelessWidget {
  const NilaiPageGuru({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF9C6644), Color(0xFF6F4E37)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.grading_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Penilaian', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text('Input & kelola nilai santri', style: TextStyle(fontSize: 13, color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _MenuCard(
                        icon: Icons.edit_note_rounded,
                        iconColor: const Color(0xFF9C6644),
                        title: 'Input Nilai',
                        subtitle: 'Input nilai harian, PTS, PAS/PAT langsung atau dari Excel',
                        onTap: () => Navigator.of(context).push(_route(const _InputNilaiPage())),
                      ),
                      const SizedBox(height: 14),
                      _MenuCard(
                        icon: Icons.history_rounded,
                        iconColor: const Color(0xFF1565C0),
                        title: 'Riwayat Nilai',
                        subtitle: 'Lihat & edit nilai yang sudah diinput',
                        onTap: () => Navigator.of(context).push(_route(const _RiwayatNilaiPage())),
                      ),
                      const SizedBox(height: 14),
                      _MenuCard(
                        icon: Icons.bar_chart_rounded,
                        iconColor: const Color(0xFFE65100),
                        title: 'Analisis Nilai',
                        subtitle: 'Statistik dan rekap nilai per kelas',
                        onTap: () => Navigator.of(context).push(_route(const _AnalisisNilaiPage())),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PageRouteBuilder _route(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final VoidCallback onTap;
  const _MenuCard({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [iconColor.withValues(alpha: 0.12), iconColor.withValues(alpha: 0.04)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: iconColor),
            ),
          ],
        ),
      ),
    );
  }
}

Color _nilaiColor(num? n) {
  if (n == null) return Colors.grey[300]!;
  if (n >= 85) return const Color(0xFF9C6644);
  if (n >= 70) return const Color(0xFFE65100);
  return const Color(0xFFC62828);
}

String _jenisLabel(String j) {
  switch (j) {
    case 'harian': return 'Harian';
    case 'pts1': return 'PTS 1';
    case 'pts2': return 'PTS 2';
    case 'pas': return 'PAS';
    case 'pat': return 'PAT';
    default: return j.toUpperCase();
  }
}

void _showNotif(BuildContext context, String msg, {bool isError = false, String? actionLabel, VoidCallback? onAction}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Row(
      children: [
        Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
      ],
    ),
    backgroundColor: isError ? const Color(0xFFC62828) : const Color(0xFF9C6644),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 3),
    action: actionLabel != null && onAction != null
        ? SnackBarAction(label: actionLabel, textColor: Colors.white, onPressed: onAction)
        : null,
  ));
}

// ─── INPUT NILAI ──────────────────────────────────────────────────────

class _InputNilaiPage extends StatefulWidget {
  const _InputNilaiPage();
  @override
  State<_InputNilaiPage> createState() => __InputNilaiPageState();
}

class __InputNilaiPageState extends State<_InputNilaiPage> {
  List<dynamic> _assignments = [];
  List<dynamic> _siswa = [];
  Map<int, TextEditingController> _nilaiCtl = {};
  Map<int, FocusNode> _focusNodes = {};
  int? _kelasId, _mapelId;
  String _jenis = 'harian';
  List<String> _jenisList = ['harian'];
  bool _loadingAssign = true, _loadingSiswa = false, _saving = false, _downloading = false, _uploading = false;

  String? _semesterInfo;
  int? _semesterId;
  String? _kelasNama;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() => _loadingAssign = true);
    try {
      _assignments = await GuruService.getAssignmentsNilai();
      final sem = await GuruService.getSemesterAktif();
      if (sem != null) {
        _semesterInfo = sem['nama'] as String?;
        _semesterId = sem['id'] as int?;
        _jenisList = (sem['jenis_list'] as List<dynamic>?)?.cast<String>() ?? ['harian'];
        _jenis = _jenisList.first;
      }
    } catch (_) {}
    setState(() => _loadingAssign = false);
  }

  Future<void> _loadSiswa() async {
    if (_kelasId == null || _mapelId == null || _semesterId == null) return;
      setState(() { _loadingSiswa = true; _siswa = []; });
    try {
      final data = await GuruService.getSiswaPerKelasNilai(
        _kelasId.toString(), _mapelId.toString(), _semesterId.toString(), jenis: _jenis,
      );
      final loaded = data['siswa'] as List<dynamic>? ?? [];
      final existing = data['existing'] as Map<dynamic, dynamic>? ?? {};
      for (final c in _nilaiCtl.values) { c.dispose(); }
      for (final f in _focusNodes.values) { f.dispose(); }
      _nilaiCtl = {};
      _focusNodes = {};
      for (int i = 0; i < loaded.length; i++) {
        final id = loaded[i]['id'] as int;
        final ex = existing[id];
        _nilaiCtl[id] = TextEditingController(text: ex != null ? _fmt(ex['nilai']) : '');
        _focusNodes[id] = FocusNode();
        _nilaiCtl[id]!.addListener(() => setState(() {}));
      }
      if (loaded.isNotEmpty) _focusNodes[loaded[0]['id'] as int]?.requestFocus();
      _siswa = loaded;
    } catch (_) {}
    setState(() => _loadingSiswa = false);
  }

  String _fmt(dynamic v) {
    if (v == null) return '';
    if (v is num) return v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(1);
    return v.toString();
  }

  int _filledCount() => _siswa.where((s) {
        final t = _nilaiCtl[s['id'] as int]?.text ?? '';
        return t.isNotEmpty && double.tryParse(t) != null;
      }).length;

  void _quickFill(num? val) {
    for (final s in _siswa) {
      _nilaiCtl[s['id'] as int]?.text = val != null ? _fmt(val) : '';
    }
  }

  Future<void> _simpan() async {
    if (_kelasId == null || _mapelId == null || _semesterId == null || _siswa.isEmpty) return;
    setState(() => _saving = true);
    try {
      final entries = _siswa.map((s) {
        final id = s['id'] as int;
        final raw = _nilaiCtl[id]?.text.trim() ?? '';
        final nilai = double.tryParse(raw);
        return {'siswa_id': id, 'nilai': nilai, '_filled': nilai != null};
      }).where((e) => e['_filled'] as bool).toList();

      if (entries.isEmpty) {
        if (mounted) _showNotif(context, 'Belum ada nilai yang diisi', isError: true);
        setState(() => _saving = false);
        return;
      }

      final payload = entries.map((e) {
        e.remove('_filled');
        return e;
      }).toList();

      await GuruService.inputNilaiMassal({
        'kelas_id': _kelasId,
        'mata_pelajaran_id': _mapelId,
        'semester_id': _semesterId,
        'jenis': _jenis,
        'entries': payload,
      });
      if (mounted) {
        final skipped = _siswa.length - entries.length;
        _showNotif(context, skipped > 0
            ? '${entries.length} nilai tersimpan, $skipped sel kosong dilewati'
            : '${entries.length} nilai $_jenisLabel($_jenis) tersimpan');
        _loadSiswa();
      }
    } catch (e) {
      if (mounted) _showNotif(context, 'Gagal menyimpan: $e', isError: true);
    }
    setState(() => _saving = false);
  }

  // ── Download Excel Template ────────────────────────────────────────

  Future<void> _downloadTemplate() async {
    if (_kelasId == null || _mapelId == null || _semesterId == null || _kelasNama == null) return;
    setState(() => _downloading = true);
    try {
      final data = await GuruService.getTemplateNilai(
        _kelasId.toString(), _mapelId.toString(), _semesterId.toString(),
      );
      final rows = data['rows'] as List<dynamic>? ?? [];
      final jenisList = (data['jenis_list'] as List<dynamic>?)?.cast<String>() ?? _jenisList;
      final kelasNama = data['kelas_nama'] as String? ?? _kelasNama;

      final excel = Excel.createExcel();
      final sheet = excel['Nilai'];

      sheet.appendRow([
        TextCellValue('NIS'),
        TextCellValue('NISN'),
        TextCellValue('NAMA SANTRI'),
        TextCellValue('KELAS'),
        ...jenisList.map((j) => TextCellValue(_jenisLabel(j).toUpperCase())),
      ]);

      for (final r in rows) {
        final row = r as Map<String, dynamic>;
        final vals = <CellValue>[
          TextCellValue(row['nis']?.toString() ?? ''),
          TextCellValue(row['nisn']?.toString() ?? ''),
          TextCellValue(row['nama']?.toString() ?? ''),
          TextCellValue(kelasNama ?? ''),
        ];
        for (final j in jenisList) {
          final v = row[j];
          vals.add(v != null ? TextCellValue(_fmt(v)) : TextCellValue(''));
        }
        sheet.appendRow(vals);
      }

      for (int c = 0; c < 4 + jenisList.length; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
        cell.cellStyle = CellStyle(bold: true);
      }

      final fileBytes = excel.encode();
      if (fileBytes == null) throw Exception('Gagal encode Excel');

      final fileName = 'Nilai_${kelasNama!.replaceAll(' ', '_')}_${_jenisLabel(_jenisList.first)}.xlsx';
      final xfile = XFile.fromData(Uint8List.fromList(fileBytes), name: fileName, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

      await Share.shareXFiles([xfile], text: 'Template Nilai $kelasNama');

      if (mounted) _showNotif(context, 'Template Excel $kelasNama siap diunduh');
    } catch (e) {
      if (mounted) _showNotif(context, 'Gagal unduh template: $e', isError: true);
    }
    setState(() => _downloading = false);
  }

  // ── Upload Excel ───────────────────────────────────────────────────

  Future<void> _uploadExcel() async {
    if (_kelasId == null || _mapelId == null || _semesterId == null) return;
    setState(() => _uploading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );
      if (result == null || result.files.isEmpty || result.files.first.bytes == null) {
        setState(() => _uploading = false);
        return;
      }

      final bytes = result.files.first.bytes!;

      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables.values.first;
      if (sheet.rows.isEmpty) throw Exception('Sheet kosong');

      final headerRow = sheet.rows[0];
      final colMap = <String, int>{};
      for (int c = 0; c < headerRow.length; c++) {
        final val = headerRow[c]?.value?.toString().trim().toUpperCase() ?? '';
        colMap[val] = c;
      }

      final nisCol = colMap['NIS'] ?? colMap['NISN'];
      if (nisCol == null) throw Exception('Kolom NIS atau NISN tidak ditemukan');

      final jenisUpload = <String>[];
      for (final j in _jenisList) {
        final label = _jenisLabel(j).toUpperCase();
        if (colMap.containsKey(label)) jenisUpload.add(j);
      }

      final entries = <Map<String, dynamic>>[];
      final siswaMap = <String, int>{};
      for (final s in _siswa) {
        siswaMap[s['nis']?.toString() ?? ''] = s['id'] as int;
        if (s['nisn'] != null) siswaMap[s['nisn']?.toString() ?? ''] = s['id'] as int;
      }

      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;
        final nisVal = row[nisCol]?.value?.toString().trim() ?? '';
        if (nisVal.isEmpty) continue;
        final siswaId = siswaMap[nisVal];
        if (siswaId == null) continue;

        for (final j in jenisUpload) {
          final colIdx = colMap[_jenisLabel(j).toUpperCase()]!;
          if (colIdx >= row.length) continue;
          final raw = row[colIdx]?.value;
          if (raw == null) continue;
          final numVal = num.tryParse(raw.toString().trim());
          if (numVal == null) continue;
          entries.add({'siswa_id': siswaId, 'jenis': j, 'nilai': numVal.toDouble()});
        }
      }

      if (entries.isEmpty) throw Exception('Tidak ada data nilai valid ditemukan di Excel');

      await GuruService.uploadNilaiMassal({
        'kelas_id': _kelasId,
        'mata_pelajaran_id': _mapelId,
        'semester_id': _semesterId,
        'entries': entries,
      });

      if (mounted) {
        _showNotif(context, '${entries.length} nilai berhasil diupload dari Excel');
        _loadSiswa();
      }
    } catch (e) {
      if (mounted) _showNotif(context, 'Gagal upload Excel: $e', isError: true);
    }
    setState(() => _uploading = false);
  }

  @override
  void dispose() {
    for (final c in _nilaiCtl.values) { c.dispose(); }
    for (final f in _focusNodes.values) { f.dispose(); }
    super.dispose();
  }

  List<dynamic> _getFilteredKelasAll() {
    final seen = <String>{};
    final result = <dynamic>[];
    for (final a in _assignments) {
      final kelasId = a['kelas_id'] as int;
      final mapelId = a['mata_pelajaran_id'] as int;
      final key = '$kelasId-$mapelId';
      if (seen.add(key)) {
        result.add({'id': kelasId, 'nama': a['kelas_nama'], 'mapel_id': mapelId});
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Nilai'),
        backgroundColor: const Color(0xFF9C6644),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loadingAssign
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_semesterInfo != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    color: const Color(0xFF9C6644).withValues(alpha: 0.06),
                    child: Row(
                      children: [
                        const Icon(Icons.school_rounded, size: 16, color: Color(0xFF9C6644)),
                        const SizedBox(width: 8),
                        Text('Semester: $_semesterInfo  •  ${_jenisLabel(_jenis)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF9C6644))),
                      ],
                    ),
                  ),
                Expanded(
                  child: _loadingSiswa
                      ? const Center(child: CircularProgressIndicator())
                      : _siswa.isNotEmpty ? _buildStudentBody() : _buildFilterBody(),
                ),
                if (_siswa.isNotEmpty && !_loadingSiswa) _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildFilterBody() {
    final allKelas = _getFilteredKelasAll();
    return ListView(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
      children: [
        _FormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(icon: Icons.filter_list_rounded, title: 'Pilih Kelas & Mata Pelajaran'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Kelas',
                  hintText: 'Pilih kelas...',
                  prefixIcon: Icon(Icons.school_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                value: (_kelasId != null && _mapelId != null) ? '$_kelasId-$_mapelId' : null,
                items: allKelas.map((k) {
                  final mapelNama = _assignmentsMapelNama(k['mapel_id'] as int);
                  final comboKey = '${k['id']}-${k['mapel_id']}';
                  return DropdownMenuItem(
                    value: comboKey,
                    child: Text('${k['nama']} — ${mapelNama ?? ''}'),
                  );
                }).toList(),
                onChanged: (v) {
                  final k = allKelas.firstWhere((x) => '${x['id']}-${x['mapel_id']}' == v);
                  for (final c in _nilaiCtl.values) { c.dispose(); }
                  for (final f in _focusNodes.values) { f.dispose(); }
                  setState(() {
                    _kelasId = k['id'] as int;
                    _mapelId = k['mapel_id'] as int;
                    _kelasNama = k['nama'] as String;
                    _siswa = [];
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Jenis Ujian',
                  prefixIcon: Icon(Icons.quiz_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                value: _jenis,
                items: _jenisList.map((j) => DropdownMenuItem(value: j, child: Text(_jenisLabel(j)))).toList(),
                onChanged: (v) => setState(() => _jenis = v!),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (_kelasId != null && _mapelId != null) ? _loadSiswa : null,
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Muat Santri'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C6644),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _assignmentsMapelNama(int mapelId) {
    for (final a in _assignments) {
      if (a['mata_pelajaran_id'] as int == mapelId) return a['mapel_nama'] as String?;
    }
    return null;
  }

  Widget _buildStudentBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 700) return _buildTableBody();
        return _buildMobileBody();
      },
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip('Kosongkan', null, Colors.grey[600]!),
                      const SizedBox(width: 6),
                      _chip('Semua 100', 100, const Color(0xFF9C6644)),
                      const SizedBox(width: 6),
                      _chip('Semua 80', 80, const Color(0xFF1565C0)),
                      const SizedBox(width: 6),
                      _chip('Semua 75', 75, const Color(0xFFE65100)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildCounterBadge(),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _toolBtn(Icons.download_rounded, 'Download Excel', _downloadTemplate, _downloading, const Color(0xFF9C6644)),
              const SizedBox(width: 8),
              _toolBtn(Icons.upload_file_rounded, 'Upload Excel', _uploadExcel, _uploading, const Color(0xFF1565C0)),
              const Spacer(),
              Text(_kelasNama ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toolBtn(IconData icon, String label, VoidCallback onTap, bool loading, Color color) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: color))
            else
              Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, num? val, Color color) {
    return GestureDetector(
      onTap: () => _quickFill(val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }

  Widget _buildCounterBadge() {
    final filled = _filledCount();
    final total = _siswa.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled == total ? const Color(0xFF9C6644).withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: filled == total ? const Color(0xFF9C6644).withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Text('$filled/$total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: filled == total ? const Color(0xFF9C6644) : Colors.orange[800])),
    );
  }

  Widget _buildTableBody() {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              child: _FormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _SectionTitle(icon: Icons.people_rounded, title: 'Daftar Santri'),
                        const Spacer(),
                        _buildCounterBar(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFF9C6644).withValues(alpha: 0.06)),
                      columnSpacing: 20,
                      headingTextStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      columns: const [
                        DataColumn(label: Text('#')),
                        DataColumn(label: Text('NIS')),
                        DataColumn(label: Text('NISN')),
                        DataColumn(label: Text('Nama')),
                        DataColumn(label: Text('Nilai'), numeric: true),
                      ],
                      rows: List.generate(_siswa.length, (i) {
                        final s = _siswa[i];
                        final id = s['id'] as int;
                        final val = double.tryParse(_nilaiCtl[id]?.text ?? '');
                        final color = _nilaiColor(val);
                        final invalid = val != null && (val < 0 || val > 100);
                        return DataRow(
                          color: WidgetStateProperty.all(i.isEven ? Colors.transparent : Colors.grey.withValues(alpha: 0.02)),
                          cells: [
                            DataCell(Text('${i + 1}', style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
                            DataCell(Text(s['nis']?.toString() ?? '-', style: TextStyle(fontSize: 13, color: Colors.grey[600]))),
                            DataCell(Text(s['nisn']?.toString() ?? '-', style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
                            DataCell(Text(s['nama']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w500))),
                            DataCell(
                              SizedBox(
                                width: 100,
                                child: TextField(
                                  controller: _nilaiCtl[id],
                                  focusNode: _focusNodes[id],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    hintText: '0-100',
                                    hintStyle: TextStyle(color: Colors.grey[300], fontSize: 13),
                                    filled: true,
                                    fillColor: color.withValues(alpha: 0.08),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: invalid ? Colors.red : color.withValues(alpha: 0.3)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: invalid ? Colors.red : Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: color, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    isDense: true,
                                  ),
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: color),
                                  onSubmitted: (_) {
                                    final next = i + 1;
                                    if (next < _siswa.length) _focusNodes[_siswa[next]['id'] as int]?.requestFocus();
                                  },
                                  onChanged: (v) {
                                    final n = double.tryParse(v);
                                    if (n != null && n > 100) {
                                      _nilaiCtl[id]?.text = '100';
                                      _nilaiCtl[id]?.selection = TextSelection.fromPosition(const TextPosition(offset: 3));
                                    }
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileBody() {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            children: [
              _FormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _SectionTitle(icon: Icons.people_rounded, title: 'Santri'),
                        const Spacer(),
                        _buildCounterBadge(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._siswa.asMap().entries.map((e) {
                      final i = e.key;
                      final s = e.value;
                      final id = s['id'] as int;
                      final val = double.tryParse(_nilaiCtl[id]?.text ?? '');
                      final color = _nilaiColor(val);
                      final invalid = val != null && (val < 0 || val > 100);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: color.withValues(alpha: 0.12),
                              child: Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s['nama']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                                  Text('NIS: ${s['nis']?.toString() ?? '-'}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 76,
                              child: TextField(
                                controller: _nilaiCtl[id],
                                focusNode: _focusNodes[id],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: TextStyle(color: Colors.grey[300], fontSize: 13),
                                  filled: true,
                                  fillColor: color.withValues(alpha: 0.08),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: invalid ? Colors.red : color.withValues(alpha: 0.3)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: invalid ? Colors.red : Colors.grey[300]!),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                  isDense: true,
                                ),
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: color),
                                onSubmitted: (_) {
                                  final next = i + 1;
                                  if (next < _siswa.length) _focusNodes[_siswa[next]['id'] as int]?.requestFocus();
                                },
                                onChanged: (v) {
                                  final n = double.tryParse(v);
                                  if (n != null && n > 100) {
                                    _nilaiCtl[id]?.text = '100';
                                    _nilaiCtl[id]?.selection = TextSelection.fromPosition(const TextPosition(offset: 3));
                                  }
                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCounterBar() {
    final filled = _filledCount();
    final total = _siswa.length;
    final pct = total > 0 ? filled / total : 0.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$filled/$total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: pct >= 1 ? const Color(0xFF9C6644) : Colors.orange[800])),
        const SizedBox(width: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            width: 60, height: 6,
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(pct >= 1 ? const Color(0xFF9C6644) : Colors.orange),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final filled = _filledCount();
    final total = _siswa.length;
    final allFilled = filled == total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$filled dari $total terisi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: allFilled ? const Color(0xFF9C6644) : Colors.orange[800])),
                  const SizedBox(height: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: SizedBox(
                      width: double.infinity, height: 4,
                      child: LinearProgressIndicator(
                        value: total > 0 ? filled / total : 0.0,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(allFilled ? const Color(0xFF9C6644) : Colors.orange),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 140,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _simpan,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C6644),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── RIWAYAT NILAI ────────────────────────────────────────────────────

class _RiwayatNilaiPage extends StatefulWidget {
  const _RiwayatNilaiPage();
  @override
  State<_RiwayatNilaiPage> createState() => __RiwayatNilaiPageState();
}

class __RiwayatNilaiPageState extends State<_RiwayatNilaiPage> {
  List<dynamic> _items = [];
  bool _loading = true;
  int _page = 1, _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await GuruService.getNilai(page: _page, perPage: 20);
      _items = data['items'] as List<dynamic>? ?? [];
      final pag = data['pagination'] as Map<String, dynamic>?;
      _totalPages = pag?['total_pages'] as int? ?? 1;
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Nilai'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('Belum ada nilai', style: TextStyle(fontSize: 15, color: Colors.grey[500])),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final n = _items[i] as Map<String, dynamic>;
                          final nilai = (n['nilai'] as num?)?.toDouble() ?? 0;
                          final color = _nilaiColor(nilai);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey[200]!),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                  child: Center(child: Text('${nilai.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(n['siswa_nama'] as String? ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text('${n['mapel_nama']} • ${n['kelas_nama']}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(_jenisLabel(n['jenis'] as String? ?? ''), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1565C0))),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(n['created_at'] as String? ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                                          if (n['status_validasi'] == 'tervalidasi') ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: const Color(0xFF9C6644).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                              child: const Text('Tervalidasi', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9C6644))),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (n['status_validasi'] != 'tervalidasi')
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Hapus Nilai'),
                                          content: Text('Hapus nilai ${n['siswa_nama']}?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        try {
                                          await GuruService.deleteNilai(n['id'] as int);
                                          if (!mounted) return;
                                          if (mounted) {
                                            ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Nilai dihapus')));
                                          }
                                          _load();
                                        } catch (e) {
                                          if (!mounted) return;
                                          if (mounted) {
                                            ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                                          }
                                        }
                                      }
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (_totalPages > 1)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded),
                              onPressed: _page > 1 ? () => setState(() { _page--; _load(); }) : null,
                            ),
                            const SizedBox(width: 8),
                            Text('$_page / $_totalPages', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded),
                              onPressed: _page < _totalPages ? () => setState(() { _page++; _load(); }) : null,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}

// ─── ANALISIS NILAI ───────────────────────────────────────────────────

class _AnalisisNilaiPage extends StatefulWidget {
  const _AnalisisNilaiPage();
  @override
  State<_AnalisisNilaiPage> createState() => __AnalisisNilaiPageState();
}

class __AnalisisNilaiPageState extends State<_AnalisisNilaiPage> {
  bool _loading = true;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Load semua data untuk analisis yang akurat
      final data = await GuruService.getNilai(page: 1, perPage: 1000);
      final items = data['items'] as List<dynamic>? ?? [];
      final total = data['pagination'] is Map ? (data['pagination'] as Map)['total'] as int? ?? 0 : 0;
      double avg = 0;
      if (items.isNotEmpty) {
        final sum = items.fold<double>(0.0, (s, e) => s + (((e as Map)['nilai'] as num?) ?? 0).toDouble());
        avg = sum / items.length;
      }
      _stats = {'total': total, 'rata_rata': avg};
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisis Nilai'),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(color: const Color(0xFFE65100).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.bar_chart_rounded, color: Color(0xFFE65100), size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Text('Statistik Nilai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _statCard('Total Input', '${_stats?['total'] ?? 0}', Icons.grading_rounded, const Color(0xFF1565C0)),
                          const SizedBox(width: 12),
                          _statCard('Rata-rata', (_stats?['rata_rata'] as double?)?.toStringAsFixed(1) ?? '0', Icons.trending_up_rounded, const Color(0xFF9C6644)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

// ─── SHARED WIDGETS ───────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF9C6644)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;
  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}
