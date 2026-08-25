import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/guru_bk_service.dart';

class BakatMinatPage extends StatefulWidget {
  const BakatMinatPage({super.key});

  @override
  State<BakatMinatPage> createState() => _BakatMinatPageState();
}

class _BakatMinatPageState extends State<BakatMinatPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> _kelasList = [];
  List<dynamic> _siswaList = [];
  String? _selectedKelasId;
  bool _loading = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _loadKelas();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadKelas() async {
    try {
      final list = await GuruBKService.getKelasList();
      if (mounted) setState(() => _kelasList = list);
    } catch (_) {
      if (mounted) setState(() => _kelasList = []);
    }
  }

  Future<void> _loadSiswa() async {
    if (_selectedKelasId == null) return;
    setState(() => _loading = true);
    try {
      _siswaList = await GuruBKService.getSiswaBakatMinat(int.parse(_selectedKelasId!));
    } catch (_) {
      _siswaList = [];
    }
    if (mounted) {
      setState(() => _loading = false);
      _animCtrl.reset();
      _animCtrl.forward();
    }
  }

  Future<void> _showBMDialog(Map<String, dynamic> siswa) async {
    final hasBm = siswa['bm_id'] != null;
    final deskripsiCtl = TextEditingController(text: siswa['bm_deskripsi']?.toString() ?? '');
    final catatanCtl = TextEditingController(text: siswa['bm_catatan']?.toString() ?? '');
    String jenis = siswa['bm_jenis']?.toString() ?? 'bakat';
    final isEdit = hasBm;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        String selectedJenis = jenis;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  isEdit ? Icons.edit_note : Icons.auto_awesome,
                  color: AppTheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  isEdit ? 'Edit Bakat & Minat' : 'Tambah Bakat & Minat',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info siswa
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.primary,
                          child: Text(
                            ((siswa['nama']?.toString() ?? '?').isNotEmpty
                                    ? siswa['nama'].toString()
                                    : '?')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(siswa['nama']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              Text('${siswa['nis'] ?? ''} · ${siswa['kelas_nama'] ?? ''}',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Jenis
                  DropdownButtonFormField<String>(
                    value: selectedJenis,
                    decoration: const InputDecoration(
                      labelText: 'Jenis',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category, size: 20),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'bakat', child: Text('Bakat', style: TextStyle(fontSize: 14))),
                      DropdownMenuItem(value: 'minat', child: Text('Minat', style: TextStyle(fontSize: 14))),
                    ],
                    onChanged: (v) => setDialogState(() => selectedJenis = v!),
                  ),
                  const SizedBox(height: 12),

                  // Deskripsi
                  TextField(
                    controller: deskripsiCtl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Catatan Pengembangan
                  TextField(
                    controller: catatanCtl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Catatan Pengembangan (opsional)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),

                  if (isEdit)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: ctx,
                            builder: (c) => AlertDialog(
                              title: const Text('Hapus Data'),
                              content: const Text('Yakin ingin menghapus data bakat & minat ini?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal')),
                                TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await GuruBKService.deleteBakatMinat(siswa['bm_id']);
                              if (ctx.mounted) Navigator.pop(ctx, true);
                            } catch (_) {}
                          }
                        },
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  if (deskripsiCtl.text.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Deskripsi wajib diisi'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  try {
                    final body = {
                      'id': siswa['bm_id'],
                      'siswa_id': siswa['id'],
                      'jenis': selectedJenis,
                      'deskripsi': deskripsiCtl.text,
                      'catatan_pengembangan': catatanCtl.text,
                    };
                    await GuruBKService.saveBakatMinat(body);
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.save, size: 18),
                label: Text(isEdit ? 'Simpan' : 'Tambah'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (saved == true) {
      _loadSiswa();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data bakat & minat tersimpan'),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header gradient
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryDark, AppTheme.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'BAKAT & MINAT',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        // Body
        Expanded(
          child: Column(
            children: [
              // Pilih Kelas
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: DropdownButtonFormField<String>(
                  value: _selectedKelasId,
                  decoration: InputDecoration(
                    labelText: 'Pilih Kelas',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.school, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  items: _kelasList.map((k) => DropdownMenuItem(
                    value: k['id'].toString(),
                    child: Text(k['nama']?.toString() ?? '', style: const TextStyle(fontSize: 14)),
                  )).toList(),
                  onChanged: (v) {
                    setState(() => _selectedKelasId = v);
                    _loadSiswa();
                  },
                ),
              ),
              // Action buttons
              if (_siswaList.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.people_outline, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(
                        '${_siswaList.length} santri',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      const Spacer(),
                      _actionChip(Icons.download, 'Template', _downloadTemplate, Colors.blue),
                      const SizedBox(width: 6),
                      _actionChip(Icons.upload_file, 'Upload', _uploadMassal, Colors.deepPurple),
                    ],
                  ),
                ),
              if (_siswaList.isNotEmpty) const SizedBox(height: 6),
              // Tabel siswa
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
                    : _selectedKelasId == null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.touch_app, size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 8),
                                Text('Pilih kelas untuk melihat santri', style: TextStyle(color: Colors.grey.shade500)),
                              ],
                            ),
                          )
                        : _siswaList.isEmpty
                            ? const Center(child: Text('Tidak ada santri di kelas ini'))
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 600;
                                  return isWide ? _buildTable() : _buildCardList();
                                },
                              ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionChip(IconData icon, String label, VoidCallback onPressed, Color color) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.teal.shade50),
          dataRowMinHeight: 48,
          dataRowMaxHeight: 60,
          columnSpacing: 14,
          horizontalMargin: 14,
          columns: const [
            DataColumn(label: Text('NIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('NISN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Nama Santri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Kelas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Bakat & Minat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
          rows: _siswaList.map((s) {
            final hasBm = s['bm_id'] != null;
            final bmJenis = s['bm_jenis']?.toString();
            return DataRow(cells: [
              DataCell(Text(s['nis']?.toString() ?? '', style: const TextStyle(fontSize: 12))),
              DataCell(Text(s['nisn']?.toString() ?? '-', style: const TextStyle(fontSize: 12))),
              DataCell(Text(s['nama']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
              DataCell(Text(s['kelas_nama']?.toString() ?? '', style: const TextStyle(fontSize: 12))),
              DataCell(
                hasBm
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            bmJenis == 'bakat' ? Icons.star : Icons.favorite,
                            color: bmJenis == 'bakat' ? Colors.amber : Colors.pink,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            bmJenis == 'bakat' ? 'Bakat' : 'Minat',
                            style: TextStyle(fontSize: 11, color: bmJenis == 'bakat' ? Colors.amber.shade700 : Colors.pink.shade400),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => _showBMDialog(s as Map<String, dynamic>),
                            child: Icon(Icons.edit, size: 16, color: Colors.grey.shade400),
                          ),
                        ],
                      )
                    : IconButton(
                        onPressed: () => _showBMDialog(s as Map<String, dynamic>),
                        icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 22),
                        tooltip: 'Tambah Bakat & Minat',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCardList() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _siswaList.length,
        itemBuilder: (context, i) {
          final s = _siswaList[i];
          final hasBm = s['bm_id'] != null;
          final bmJenis = s['bm_jenis']?.toString();
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 1,
            child: InkWell(
              onTap: () => _showBMDialog(s as Map<String, dynamic>),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['nama']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text('${s['nis'] ?? ''} · ${s['kelas_nama'] ?? ''}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          if (hasBm)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    bmJenis == 'bakat' ? Icons.star : Icons.favorite,
                                    size: 16,
                                    color: bmJenis == 'bakat' ? Colors.amber : Colors.pink,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    bmJenis == 'bakat' ? 'Bakat' : 'Minat',
                                    style: TextStyle(fontSize: 12, color: bmJenis == 'bakat' ? Colors.amber.shade700 : Colors.pink.shade400),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      hasBm ? Icons.check_circle : Icons.add_circle_outline,
                      color: hasBm ? const Color(0xFF9C6644) : AppTheme.primary,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── TEMPLATE & UPLOAD ────────────────────────────────
  Future<void> _downloadTemplate() async {
    final kelasNama = _kelasList.firstWhere(
      (k) => k['id'].toString() == _selectedKelasId,
      orElse: () => {'nama': 'Kelas'},
    )['nama'];

    // Buat CSV dengan data siswa, kolom Jenis/Deskripsi dikosongkan
    final buffer = StringBuffer('NIS,NISN,Nama,Kelas,Jenis (bakat/minat),Deskripsi,Catatan Pengembangan\n');
    for (final s in _siswaList) {
      buffer.write('${s['nis'] ?? ''},${s['nisn'] ?? ''},${s['nama'] ?? ''},${s['kelas_nama'] ?? ''},,,,\n');
    }
    final csvText = buffer.toString();
    final fileName = 'Template_BakatMinat_$kelasNama.csv';

    try {
      if (kIsWeb) {
        final blob = html.Blob([csvText], 'text/csv');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..target = '_blank'
          ..download = fileName
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        await Share.shareXFiles(
          [XFile.fromData(utf8.encode(csvText), mimeType: 'text/csv', name: fileName)],
          subject: 'Template Bakat & Minat',
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengunduh template'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _uploadMassal() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.first.bytes;
      if (bytes == null) return;
      final csvText = utf8.decode(bytes);

      // Parse CSV
      final lines = csvText.split('\n').where((l) => l.trim().isNotEmpty).toList();
      if (lines.length < 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File CSV kosong (hanya header)'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      int success = 0;
      int failed = 0;
      for (int i = 1; i < lines.length; i++) {
        final cols = lines[i].split(',').map((c) => c.trim()).toList();
        if (cols.length < 6) { failed++; continue; }
        final nis = cols[0];
        final jenis = cols[4].toLowerCase();
        final deskripsi = cols[5];
        final catatan = cols.length > 6 ? cols[6] : '';

        if (nis.isEmpty || jenis.isEmpty || deskripsi.isEmpty) { failed++; continue; }
        if (jenis != 'bakat' && jenis != 'minat') { failed++; continue; }

        // Cari siswa_id dari NIS
        final siswa = _siswaList.cast<Map<String, dynamic>>().firstWhere(
          (s) => s['nis']?.toString() == nis,
          orElse: () => <String, dynamic>{},
        );
        if (siswa.isEmpty) { failed++; continue; }

        try {
          await GuruBKService.saveBakatMinat({
            'id': siswa['bm_id'],
            'siswa_id': siswa['id'],
            'jenis': jenis,
            'deskripsi': deskripsi,
            'catatan_pengembangan': catatan,
          });
          success++;
        } catch (_) {
          failed++;
        }
      }

      if (!mounted) return;
      _loadSiswa();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload selesai: $success berhasil, $failed gagal'),
          backgroundColor: failed > 0 ? Colors.orange : AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memproses file CSV'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
