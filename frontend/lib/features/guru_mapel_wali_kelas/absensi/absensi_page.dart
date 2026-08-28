import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/guru_service.dart';

class AbsensiPageGuru extends StatelessWidget {
  const AbsensiPageGuru({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: const BoxDecoration(
            gradient: AppTheme.headerGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Absensi', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fact_check, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text('Input & monitoring kehadiran santri', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _MenuCard(
                  icon: Icons.edit_note_rounded,
                  title: 'Input Absen',
                  subtitle: 'Isi kehadiran santri per sesi',
                  color: AppTheme.primary,
                  lightColor: AppTheme.primaryLight,
                  onTap: () => Navigator.of(context).push(_bounceRoute(const _InputAbsensiPage())),
                ),
                const SizedBox(height: 20),
                _MenuCard(
                  icon: Icons.history_rounded,
                  title: 'Riwayat Absensi',
                  subtitle: 'Lihat rekap kehadiran santri',
                  color: const Color(0xFF1565C0),
                  lightColor: const Color(0xFFE3F2FD),
                  onTap: () => Navigator.of(context).push(_bounceRoute(const _RiwayatAbsensiPage())),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  PageRouteBuilder _bounceRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color, lightColor;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.lightColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 6)),
          ],
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [lightColor, color.withValues(alpha: 0.25)],
                      ),
                      boxShadow: [
                        BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Icon(icon, size: 34, color: color),
                  ),
                  const SizedBox(height: 18),
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                  const SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Buka', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, size: 12, color: color),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =================================================================
// PAGE: Input Absensi
// =================================================================

class _InputAbsensiPage extends StatefulWidget {
  const _InputAbsensiPage();

  @override
  State<_InputAbsensiPage> createState() => _InputAbsensiPageState();
}

class _InputAbsensiPageState extends State<_InputAbsensiPage> {
  final _tanggalCtl = TextEditingController();
  final _searchCtl = TextEditingController();
  final _jamCtl = TextEditingController();

  int? _mapelId, _kelasId;
  List<dynamic> _assignments = [];
  List<dynamic> _kelasList = [];
  List<dynamic> _siswa = [];
  List<dynamic> _siswaFiltered = [];
  Map<dynamic, String> _statusMap = {};
  Map<dynamic, TextEditingController> _ketCtl = {};
  bool _loading = true, _loadingSiswa = false, _saving = false;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  @override
  void dispose() {
    _tanggalCtl.dispose();
    _searchCtl.dispose();
    _jamCtl.dispose();
    for (final c in _ketCtl.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> _loadAssignments() async {
    setState(() => _loading = true);
    try {
      _assignments = await GuruService.getAssignments();
    } catch (_) { debugPrint('[absensi_page.dart] error caught'); }
    setState(() => _loading = false);
  }

  void _onMapelChanged(int? id) {
    setState(() {
      _mapelId = id;
      _kelasId = null;
      _resetSiswaState();
      if (id != null) {
        final mapel = _assignments.firstWhere((a) => a['id'] == id, orElse: () => null);
        _kelasList = mapel != null ? List<dynamic>.from(mapel['kelas'] ?? []) : [];
      } else {
        _kelasList = [];
      }
    });
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _siswaFiltered = List.from(_siswa);
      } else {
        final q = query.toLowerCase();
        _siswaFiltered = _siswa.where((s) {
          final nama = (s['nama'] as String? ?? '').toLowerCase();
          final nis = (s['nis'] as String? ?? '').toLowerCase();
          return nama.contains(q) || nis.contains(q);
        }).toList();
      }
    });
  }

  void _resetSiswaState() {
    _siswa = [];
    _siswaFiltered = [];
    _statusMap = {};
    for (final c in _ketCtl.values) { c.dispose(); }
    _ketCtl = {};
    _searchCtl.clear();
  }

  Future<void> _loadSiswa() async {
    if (_kelasId == null || _tanggalCtl.text.isEmpty) return;
    setState(() => _loadingSiswa = true);
    try {
      final data = await GuruService.getSiswaPerKelasAbsensi(
        _kelasId.toString(),
        tanggal: _tanggalCtl.text,
        mataPelajaranId: _mapelId?.toString(),
        jam: _jamCtl.text.isNotEmpty ? _jamCtl.text : null,
      );
      final siswa = data['siswa'] as List<dynamic>? ?? [];
      final existing = data['existing'] as Map<dynamic, dynamic>? ?? {};

      for (final c in _ketCtl.values) { c.dispose(); }

      _siswa = siswa;
      _statusMap = {};
      _ketCtl = {};
      for (final s in _siswa) {
        final id = s['id'];
        final ex = existing[id];
        _statusMap[id] = (ex != null ? ex['status'] as String : 'hadir');
        _ketCtl[id] = TextEditingController(text: ex != null ? ex['keterangan'] as String? ?? '' : '');
      }
      _searchCtl.clear();
      _siswaFiltered = List.from(_siswa);
    } catch (_) {
      _siswa = [];
      _siswaFiltered = [];
    }
    setState(() => _loadingSiswa = false);
  }

  Future<void> _simpan() async {
    if (_kelasId == null || _tanggalCtl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      final entries = _siswa.map((s) {
        final id = s['id'];
        return {'siswa_id': id, 'status': _statusMap[id] ?? 'hadir', 'keterangan': _ketCtl[id]?.text.isNotEmpty == true ? _ketCtl[id]!.text : null};
      }).toList();

      await GuruService.inputAbsensiMassal({
        'kelas_id': _kelasId,
        'mata_pelajaran_id': _mapelId,
        'tanggal': _tanggalCtl.text,
        'jam': _jamCtl.text.isNotEmpty ? _jamCtl.text : null,
        'entries': entries,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Absensi berhasil disimpan'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal: $e'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
    setState(() => _saving = false);
  }

  void _setAllStatus(String status) {
    for (final s in _siswa) {
      _statusMap[s['id']] = status;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Absen'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FormCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle(title: 'Pilih Sesi Absensi'),
                        Wrap(
                          spacing: 14, runSpacing: 14,
                          children: [
                            SizedBox(width: 220, child: DropdownButtonFormField<int>(
                              decoration: const InputDecoration(labelText: 'Mata Pelajaran', border: OutlineInputBorder(), prefixIcon: Icon(Icons.book)),
                              value: _mapelId,
                              items: _assignments.map((a) => DropdownMenuItem(value: a['id'] as int, child: Text(a['nama'] as String? ?? ''))).toList(),
                              onChanged: _onMapelChanged,
                            )),
                            SizedBox(width: 180, child: DropdownButtonFormField<int>(
                              decoration: const InputDecoration(labelText: 'Kelas', border: OutlineInputBorder(), prefixIcon: Icon(Icons.school)),
                              value: _kelasId,
                              items: _kelasList.map((k) => DropdownMenuItem(value: k['id'] as int, child: Text(k['nama'] as String? ?? ''))).toList(),
                              onChanged: (v) => setState(() {
                                _kelasId = v;
                                _resetSiswaState();
                              }),
                            )),
                            SizedBox(width: 160, child: TextField(
                              controller: _tanggalCtl,
                              decoration: const InputDecoration(labelText: 'Tanggal', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                              readOnly: true,
                              onTap: () async {
                                final d = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2030));
                                if (d != null) {
                                  setState(() {
                                    _tanggalCtl.text = d.toIso8601String().substring(0, 10);
                                    _resetSiswaState();
                                  });
                                }
                              },
                            )),
                            SizedBox(width: 140, child: TextField(
                              controller: _jamCtl,
                              decoration: const InputDecoration(labelText: 'Jam', border: OutlineInputBorder(), prefixIcon: Icon(Icons.access_time)),
                              readOnly: true,
                              onTap: () async {
                                final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                if (t != null) { if (!context.mounted) return; setState(() {
                                  _jamCtl.text = t.format(context);
                                  _resetSiswaState();
                                }); }
                              },
                            )),
                            SizedBox(
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _kelasId == null || _tanggalCtl.text.isEmpty ? null : _loadSiswa,
                                icon: const Icon(Icons.people),
                                label: const Text('Muat Santri', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 28),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_loadingSiswa)
                    const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                  else if (_siswa.isNotEmpty) ...[
                    _FormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionTitle(title: 'Data Santri'),
                          TextField(
                            controller: _searchCtl,
                            decoration: InputDecoration(
                              hintText: 'Cari santri...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              isDense: true, filled: true, fillColor: Colors.grey[50],
                            ),
                            onChanged: _onSearch,
                          ),
                          const SizedBox(height: 14),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                const Text('Status Cepat: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(width: 6),
                                _quickChip('Hadir Semua', 'hadir', const Color(0xFF9C6644)),
                                const SizedBox(width: 6),
                                _quickChip('Izin', 'izin', Colors.orange),
                                const SizedBox(width: 6),
                                _quickChip('Sakit', 'sakit', Colors.blue),
                                const SizedBox(width: 6),
                                _quickChip('Alpa', 'alpa', Colors.red),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (_, constraints) {
                              if (constraints.maxWidth > 700) {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    headingRowColor: WidgetStatePropertyAll(AppTheme.primary.withValues(alpha: 0.06)),
                                    headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary),
                                    columnSpacing: 10, horizontalMargin: 12, dataRowMinHeight: 48, dataRowMaxHeight: 56,
                                    columns: const [
                                      DataColumn(label: Text('No')),
                                      DataColumn(label: Text('NIS')),
                                      DataColumn(label: Text('Nama Santri')),
                                      DataColumn(label: Text('Hadir')),
                                      DataColumn(label: Text('Izin')),
                                      DataColumn(label: Text('Sakit')),
                                      DataColumn(label: Text('Alpa')),
                                      DataColumn(label: Text('Keterangan')),
                                    ],
                                    rows: List.generate(_siswaFiltered.length, (i) {
                                      final s = _siswaFiltered[i];
                                      final id = s['id'];
                                      return DataRow(cells: [
                                        DataCell(Text('${i + 1}', style: const TextStyle(fontSize: 13))),
                                        DataCell(Text(s['nis']?.toString() ?? '', style: const TextStyle(fontSize: 13))),
                                        DataCell(SizedBox(width: 170, child: Text(s['nama']?.toString() ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)))),
                                        DataCell(_radioChip(id, 'hadir', const Color(0xFF9C6644))),
                                        DataCell(_radioChip(id, 'izin', Colors.orange)),
                                        DataCell(_radioChip(id, 'sakit', Colors.blue)),
                                        DataCell(_radioChip(id, 'alpa', Colors.red)),
                                        DataCell(SizedBox(width: 120, child: TextField(
                                          controller: _ketCtl[id],
                                          decoration: InputDecoration(hintText: 'Ket.', isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: Colors.grey[50]),
                                          style: const TextStyle(fontSize: 13),
                                        ))),
                                      ]);
                                    }),
                                  ),
                                );
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _siswaFiltered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (_, i) {
                                  final s = _siswaFiltered[i];
                                  final id = s['id'];
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.grey[200]!),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 26, height: 26,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                                                child: Text('${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(s['nama']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                                    Text('NIS: ${s['nis']?.toString() ?? '-'}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 14),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              _mobileStatusBtn(id, 'hadir', 'Hadir', const Color(0xFF9C6644)),
                                              _mobileStatusBtn(id, 'izin', 'Izin', Colors.orange),
                                              _mobileStatusBtn(id, 'sakit', 'Sakit', Colors.blue),
                                              _mobileStatusBtn(id, 'alpa', 'Alpa', Colors.red),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          TextField(
                                            controller: _ketCtl[id],
                                            decoration: InputDecoration(
                                              hintText: 'Keterangan (opsional)',
                                              isDense: true,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                              filled: true, fillColor: Colors.grey[50],
                                            ),
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _simpan,
                        icon: _saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_rounded),
                        label: Text(_saving ? 'Menyimpan...' : 'Simpan Absensi', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _quickChip(String label, String val, Color color) {
    final isSelected = _siswa.every((s) => _statusMap[s['id']] == val);
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : color)),
      selected: isSelected, selectedColor: color, backgroundColor: color.withValues(alpha: 0.1),
      checkmarkColor: Colors.white, showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      onSelected: (_) => _setAllStatus(val),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? color : color.withValues(alpha: 0.4))),
    );
  }

  Widget _radioChip(dynamic siswaId, String value, Color color) {
    final isSelected = _statusMap[siswaId] == value;
    return InkWell(
      onTap: () => setState(() => _statusMap[siswaId] = value),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : Colors.grey[300]!, width: isSelected ? 1.5 : 1),
        ),
        child: Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? color : Colors.grey[400], size: 18),
      ),
    );
  }

  Widget _mobileStatusBtn(dynamic siswaId, String value, String label, Color color) {
    final isSelected = _statusMap[siswaId] == value;
    return GestureDetector(
      onTap: () => setState(() => _statusMap[siswaId] = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : Colors.grey[300]!, width: isSelected ? 1.5 : 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? color : Colors.grey[400], size: 22),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? color : Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// PAGE: Riwayat Absensi
// =================================================================

class _RiwayatAbsensiPage extends StatefulWidget {
  const _RiwayatAbsensiPage();

  @override
  State<_RiwayatAbsensiPage> createState() => _RiwayatAbsensiPageState();
}

class _RiwayatAbsensiPageState extends State<_RiwayatAbsensiPage> {
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
      final data = await GuruService.getRiwayatSesi(page: _page);
      _items = data['items'] as List<dynamic>? ?? [];
      final pag = data['pagination'] as Map<String, dynamic>? ?? {};
      _totalPages = pag['total_pages'] as int? ?? 1;
    } catch (_) { debugPrint('[absensi_page.dart] error caught'); }
    setState(() => _loading = false);
  }

  void _openDetail(Map<String, dynamic> sesi) {
    Navigator.of(context).push(_DetailRoute(sesi));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Absensi'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
          else if (_items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(Icons.history_rounded, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('Belum ada riwayat absensi', style: TextStyle(fontSize: 15, color: Colors.grey[500])),
                  ],
                ),
              ),
            )
          else ...[
            ...List.generate(_items.length, (i) {
              final s = _items[i] as Map<String, dynamic>;
              final hadir = s['hadir'] ?? 0;
              final izin = s['izin'] ?? 0;
              final sakit = s['sakit'] ?? 0;
              final alpa = s['alpa'] ?? 0;
              final totalSiswa = s['total_siswa'] ?? 0;
              final sudah = (hadir as int) + (izin as int) + (sakit as int) + (alpa as int);

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
                  border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.08)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openDetail(s),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.calendar_today, size: 20, color: Color(0xFF1565C0)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${s['hari'] ?? ''}, ${s['tanggal_label'] ?? ''}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 2),
                                  Text('${s['kelas_nama'] ?? ''}  ·  ${s['mapel_nama'] ?? '-'}',
                                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time, size: 14, color: Color(0xFF1565C0)),
                                  const SizedBox(width: 4),
                                  Text(s['jam'] ?? '-',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1565C0))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (_, constraints) {
                            final isNarrow = constraints.maxWidth < 420;
                            return Wrap(
                              spacing: 6, runSpacing: 8,
                              alignment: WrapAlignment.start,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _SesiBadge(label: 'Hadir', value: hadir, color: const Color(0xFF9C6644)),
                                _SesiBadge(label: 'Izin', value: izin, color: Colors.orange),
                                _SesiBadge(label: 'Sakit', value: sakit, color: Colors.blue),
                                _SesiBadge(label: 'Alpa', value: alpa, color: Colors.red),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: sudah == (totalSiswa as int) ? const Color(0xFF9C6644).withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(isNarrow ? '$sudah/$totalSiswa' : 'Tercatat $sudah/$totalSiswa', style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600,
                                    color: sudah == totalSiswa ? const Color(0xFF9C6644) : Colors.orange[700],
                                  )),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Lihat Detail', style: TextStyle(fontSize: 13, color: Colors.blue[700], fontWeight: FontWeight.w600)),
                              Icon(Icons.chevron_right, size: 18, color: Colors.blue[700]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (_totalPages > 1) ...[
              const SizedBox(height: 8),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _page > 1 ? () { setState(() => _page--); _load(); } : null,
                      style: IconButton.styleFrom(backgroundColor: Colors.grey[100], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                    const SizedBox(width: 12),
                    Text('Halaman $_page dari $_totalPages', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _page < _totalPages ? () { setState(() => _page++); _load(); } : null,
                      style: IconButton.styleFrom(backgroundColor: Colors.grey[100], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SesiBadge extends StatelessWidget {
  final String label;
  final dynamic value;
  final Color color;
  const _SesiBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(width: 4),
          Text('$value', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

// =================================================================
// COMPONENTS
// =================================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFFF9A825), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;
  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

// =================================================================
// DETAIL ROUTE
// =================================================================

class _DetailRoute extends MaterialPageRoute<void> {
  _DetailRoute(Map<String, dynamic> sesi) : super(builder: (_) => _DetailSesiPage(sesi: sesi));
}

class _DetailSesiPage extends StatefulWidget {
  final Map<String, dynamic> sesi;
  const _DetailSesiPage({required this.sesi});

  @override
  State<_DetailSesiPage> createState() => _DetailSesiPageState();
}

class _DetailSesiPageState extends State<_DetailSesiPage> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = widget.sesi;
      _items = await GuruService.getDetailSesi(
        s['tanggal_label'] ?? s['tanggal'] ?? '',
        '${s['kelas_id'] ?? ''}',
        mapelId: s['mata_pelajaran_id'] != null ? '${s['mata_pelajaran_id']}' : null,
        jam: s['jam'] as String?,
      );
    } catch (_) { debugPrint('[absensi_page.dart] error caught'); }
    setState(() => _loading = false);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'hadir': return const Color(0xFF9C6644);
      case 'izin': return Colors.orange;
      case 'sakit': return Colors.blue;
      case 'alpa': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'hadir': return 'Hadir';
      case 'izin': return 'Izin';
      case 'sakit': return 'Sakit';
      case 'alpa': return 'Alpa';
      default: return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sesi;
    return Scaffold(
      appBar: AppBar(
        title: Text('${s['hari'] ?? ''}, ${s['tanggal_label'] ?? s['tanggal'] ?? ''}'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              border: Border(bottom: BorderSide(color: const Color(0xFF1565C0).withValues(alpha: 0.1))),
            ),
            child: Wrap(
              spacing: 20, runSpacing: 8,
              children: [
                _infoPill(Icons.access_time, s['jam'] ?? '-'),
                _infoPill(Icons.school, s['kelas_nama'] ?? ''),
                _infoPill(Icons.book, s['mapel_nama'] ?? '-'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('Tidak ada data'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final r = _items[i] as Map<String, dynamic>;
                          final status = r['status'] as String? ?? '';
                          final color = _statusColor(status);
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: color.withValues(alpha: 0.15)),
                              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: color.withValues(alpha: 0.12), radius: 18,
                                child: Text('${i + 1}', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(r['siswa_nama'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text('NIS: ${r['nis'] ?? '-'}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: color.withValues(alpha: 0.3)),
                                ),
                                child: Text(_statusLabel(status), style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _infoPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1565C0)),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1565C0))),
        ],
      ),
    );
  }
}
