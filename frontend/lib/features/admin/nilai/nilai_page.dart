import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../services/admin_service.dart';

class NilaiPage extends StatefulWidget {
  const NilaiPage({super.key});

  @override
  State<NilaiPage> createState() => _NilaiPageState();
}

class _NilaiPageState extends State<NilaiPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int? _selectedTahunAjaranId;
  int? _selectedSemesterId;
  int? _selectedTingkatId;
  String _jenis = '';
  List<Map<String, dynamic>> _tahunAjaranOptions = [];
  List<Map<String, dynamic>> _semesterOptions = [];
  List<Map<String, dynamic>> _tingkatOptions = [];
  List<Map<String, dynamic>> _mapelList = [];
  bool _loadingMapel = false;
  int? _publishingId;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); _loadReferensi().then((_) => _applyFilter()); }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _loadReferensi() async {
    try {
      final res = await AdminService.getReferensi();
      if (!mounted) return;
      setState(() {
        _tahunAjaranOptions = (res['tahun_ajaran'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        _semesterOptions = (res['semester_all'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        _tingkatOptions = (res['tingkat'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        if (_selectedTahunAjaranId == null && _tahunAjaranOptions.isNotEmpty) {
          _selectedTahunAjaranId = _tahunAjaranOptions.first['id'] as int;
        }
        if (_selectedTingkatId == null && _tingkatOptions.isNotEmpty) {
          _selectedTingkatId = _tingkatOptions.first['id'] as int;
        }
        final semesters = _semestersInTA(_selectedTahunAjaranId);
        if (_selectedSemesterId == null && semesters.isNotEmpty) {
          _selectedSemesterId = semesters.first['id'] as int;
        }
      });
    } catch (_) { debugPrint('[nilai_page.dart] error caught'); }
  }

  List<Map<String, dynamic>> _semestersInTA(int? taId) {
    if (taId == null) return _semesterOptions;
    return _semesterOptions.where((s) => s['tahun_ajaran_id'] == taId).toList();
  }

  void _selectTahunAjaran(int? taId) {
    setState(() {
      _selectedTahunAjaranId = taId;
      final sems = _semestersInTA(taId);
      if (!sems.any((s) => s['id'] == _selectedSemesterId)) {
        _selectedSemesterId = sems.isNotEmpty ? sems.first['id'] as int : null;
      }
    });
  }

  String get _jenisValue {
    if (_jenis.isEmpty) return '';
    return _jenis.toLowerCase();
  }

  bool get _filterReady =>
      _selectedSemesterId != null && _selectedTingkatId != null && _jenis.isNotEmpty;

  Future<void> _applyFilter() async {
    if (!_filterReady) return;
    setState(() => _loadingMapel = true);
    try {
      final res = await AdminService.komplitPerMapel(
        semesterId: '$_selectedSemesterId',
        tingkatId: '$_selectedTingkatId',
        jenis: _jenisValue,
      );
      if (mounted) {
        setState(() => _mapelList = (res['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? []);
      }
    } catch (_) {
      if (mounted) setState(() => _mapelList = []);
    }
    if (mounted) setState(() => _loadingMapel = false);
  }

  Color _completenessColor(String status) {
    switch (status) {
      case 'komplit': return AppTheme.primary;
      case 'sebagian': return AppTheme.orange;
      default: return AppTheme.error;
    }
  }

  String _completenessLabel(String status) {
    switch (status) {
      case 'komplit': return 'Komplit';
      case 'sebagian': return 'Belum lengkap';
      default: return 'Belum upload';
    }
  }

  IconData _completenessIcon(String status) {
    switch (status) {
      case 'komplit': return Icons.check_circle;
      case 'sebagian': return Icons.pending;
      default: return Icons.cancel;
    }
  }

  String _jenisLabel(String jenis) {
    const labels = {
      'harian': 'Harian', 'tugas': 'Tugas', 'pts1': 'PTS 1', 'pts2': 'PTS 2',
      'pas': 'PAS', 'uts': 'UTS', 'pat': 'PAT', 'uas': 'UAS', 'akhir': 'Akhir',
    };
    return labels[jenis] ?? jenis;
  }

  Future<void> _toggleMapelPublish(Map<String, dynamic> m) async {
    if (_selectedSemesterId == null || _publishingId != null) return;
    final mapelId = m['mata_pelajaran_id'] as int;
    final target = (m['is_published'] == true) ? false : true;
    setState(() => _publishingId = mapelId);
    try {
      await AdminService.togglePublikasiMapel(
        semesterId: _selectedSemesterId!,
        mataPelajaranId: mapelId,
        jenis: _jenisValue,
        published: target,
      );
      if (mounted) {
        setState(() {
          final m2 = _mapelList.firstWhere((x) => x['mata_pelajaran_id'] == mapelId, orElse: () => {});
          if (m2.isNotEmpty) m2['is_published'] = target;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${m['mapel_nama']}: ${target ? 'Dipublikasikan' : 'Publikasi ditutup'}'),
          backgroundColor: target ? AppTheme.primary : AppTheme.orange,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.error));
    }
    if (mounted) setState(() => _publishingId = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nilai'), automaticallyImplyLeading: false,
        bottom: TabBar(controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Monitoring Nilai', icon: Icon(Icons.visibility_outlined, size: 18)),
            Tab(text: 'Analisis', icon: Icon(Icons.analytics_outlined, size: 18)),
            Tab(text: 'Audit', icon: Icon(Icons.history, size: 18)),
          ],
        ),
      ),
      body: IndexedStack(index: _tabCtrl.index, children: [
        _buildMonitoringTab(),
        const _AnalisisNilaiTab(),
        const _AuditNilaiTab(),
      ]),
    );
  }

  Widget _buildMonitoringTab() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      DataCard(
        padding: const EdgeInsets.all(16),
        header: const Row(children: [
          Icon(Icons.filter_list, size: 20, color: AppTheme.primary),
          SizedBox(width: 8),
          Text('Filter Monitoring', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: DropdownButtonFormField<int>(
              value: _selectedTahunAjaranId,
              isDense: true,
              decoration: inputDecoration('Tahun Ajaran', Icons.calendar_today_outlined),
              items: _tahunAjaranOptions.map((t) => DropdownMenuItem(
                  value: t['id'] as int,
                  child: Text('TA ${t['nama']}', style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: _selectTahunAjaran,
            )),
            const SizedBox(width: 12),
            Expanded(child: DropdownButtonFormField<int>(
              value: _selectedSemesterId,
              isDense: true,
              decoration: inputDecoration('Semester', Icons.menu_book_outlined),
              items: _semestersInTA(_selectedTahunAjaranId).map((s) => DropdownMenuItem(
                  value: s['id'] as int,
                  child: Text('${s['nama']}', style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _selectedSemesterId = v),
            )),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: DropdownButtonFormField<int>(
              value: _selectedTingkatId,
              isDense: true,
              decoration: inputDecoration('Tingkat', Icons.school_outlined),
              items: _tingkatOptions.map((t) => DropdownMenuItem(
                  value: t['id'] as int,
                  child: Text('${t['nama']}', style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _selectedTingkatId = v),
            )),
            const SizedBox(width: 12),
            Expanded(child: DropdownButtonFormField<String>(
              value: _jenis.isEmpty ? null : _jenis,
              isDense: true,
              decoration: inputDecoration('Jenis Ujian', Icons.category_outlined),
              items: ['harian', 'tugas', 'pts1', 'pts2', 'pas', 'uts', 'pat', 'uas', 'akhir'].map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(_jenisLabel(s), style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _jenis = v ?? ''),
            )),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Expanded(child: Text(
              'Pilih kombinasi untuk menampilkan status kelengkapan nilai per mata pelajaran.',
              style: TextStyle(fontSize: 11, color: AppTheme.grey400),
            )),
            FilledButton.icon(
              onPressed: _filterReady ? _applyFilter : null,
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Terapkan'),
            ),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
      DataCard(
        padding: const EdgeInsets.all(16),
        header: const Row(children: [
          Icon(Icons.book_outlined, size: 20, color: AppTheme.primary),
          SizedBox(width: 8),
          Text('List Mata Pelajaran', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Wrap(spacing: 16, runSpacing: 6, children: [
            _LegendDot(color: AppTheme.primary, label: 'Komplit'),
            _LegendDot(color: AppTheme.orange, label: 'Belum lengkap'),
            _LegendDot(color: AppTheme.error, label: 'Belum upload'),
          ]),
          const SizedBox(height: 12),
          if (_loadingMapel)
            const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_mapelList.isEmpty)
            EmptyState(icon: Icons.book_outlined, message: _filterReady
                ? 'Belum ada data mata pelajaran untuk kombinasi ini.'
                : 'Pilih Tahun Ajaran, Semester, Tingkat, dan Jenis Ujian, lalu klik Terapkan.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mapelList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final m = _mapelList[i];
                final status = m['status'] as String? ?? 'kosong';
                final color = _completenessColor(status);
                final isPublished = m['is_published'] == true;
                final canPublish = status == 'komplit';
                final publishing = _publishingId == m['mata_pelajaran_id'];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  child: Row(children: [
                    Icon(_completenessIcon(status), size: 22, color: color),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${m['mapel_nama'] ?? '-'}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('Tingkat ${m['tingkat_nama'] ?? '-'} · Nilai ${m['nilai_terisi'] ?? 0}/${m['total_santri'] ?? 0} santri',
                          style: const TextStyle(fontSize: 11, color: AppTheme.grey600)),
                    ])),
                    StatusBadge(label: _completenessLabel(status), color: color, small: true),
                    const SizedBox(width: 10),
                    if (canPublish)
                      SizedBox(
                        height: 32,
                        child: OutlinedButton.icon(
                          onPressed: publishing ? null : () => _toggleMapelPublish(m),
                          icon: publishing
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : Icon(isPublished ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 15),
                          label: Text(isPublished ? 'Tutup Publikasi' : 'Publikasi',
                              style: const TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            foregroundColor: isPublished ? AppTheme.orange : AppTheme.primary,
                          ),
                        ),
                      )
                    else
                      const Text('Belum dapat dipublikasi', style: TextStyle(fontSize: 11, color: AppTheme.grey400)),
                  ]),
                );
              },
            ),
        ]),
      ),
    ]));
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.grey700)),
    ]);
  }
}

// ── Analisis Nilai Tab ──
class _AnalisisNilaiTab extends StatefulWidget {
  const _AnalisisNilaiTab();
  @override
  State<_AnalisisNilaiTab> createState() => _AnalisisNilaiTabState();
}

class _AnalisisNilaiTabState extends State<_AnalisisNilaiTab> {
  List<Map<String, dynamic>> _semesterList = [];
  List<Map<String, dynamic>> _kelasList = [];
  String? _semesterId;
  String? _kelasId;
  String _jenis = '';
  Map<String, dynamic>? _analisis;
  bool _loading = false;

  @override
  void initState() { super.initState(); _loadRef(); }

  Future<void> _loadRef() async {
    try {
      final res = await AdminService.getReferensi();
      setState(() {
        _semesterList = (res['semester'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        _kelasList = (res['kelas'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
      });
    } catch (_) { debugPrint('[nilai_page.dart] error caught'); }
  }

  Future<void> _loadAnalisis() async {
    if (_semesterId == null) return;
    setState(() => _loading = true);
    try {
      _analisis = await AdminService.getAnalisisNilai(
        semesterId: _semesterId!,
        kelasId: _kelasId,
        jenis: _jenis.isEmpty ? null : _jenis,
      );
    } catch (_) { _analisis = null; }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      DataCard(
        padding: const EdgeInsets.all(16),
        header: const Row(children: [
          Icon(Icons.analytics_outlined, size: 20, color: AppTheme.primary),
          SizedBox(width: 8),
          Text('Filter Analisis', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(
              value: _semesterId,
              isDense: true,
              decoration: inputDecoration('Semester', Icons.calendar_month_outlined),
              items: _semesterList.map((s) => DropdownMenuItem(value: '${s['id']}', child: Text('${s['nama']}', style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _semesterId = v),
            )),
            const SizedBox(width: 12),
            Expanded(child: DropdownButtonFormField<String>(
              value: _kelasId,
              isDense: true,
              decoration: inputDecoration('Kelas', Icons.school_outlined, optional: true),
              items: [const DropdownMenuItem<String>(value: null, child: Text('Semua Kelas', style: TextStyle(fontSize: 13))),
                ..._kelasList.map((k) => DropdownMenuItem(value: '${k['id']}', child: Text('${k['nama']}', style: const TextStyle(fontSize: 13))))],
              onChanged: (v) => setState(() => _kelasId = v),
            )),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(
              value: _jenis.isEmpty ? null : _jenis,
              isDense: true,
              decoration: inputDecoration('Jenis Nilai', Icons.category_outlined, optional: true),
              items: ['', 'harian', 'tugas', 'uts', 'uas', 'akhir', 'pts1', 'pas', 'pts2', 'pat'].map((s) => DropdownMenuItem(value: s.isEmpty ? null : s,
                  child: Text(s.isEmpty ? 'Semua' : s, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _jenis = v ?? ''),
            )),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _loadAnalisis,
              icon: const Icon(Icons.analytics, size: 18),
              label: const Text('Analisis'),
            ),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
      if (_loading)
        const Center(child: CircularProgressIndicator())
      else if (_analisis != null) ...[
        _buildOverview(theme),
        const SizedBox(height: 16),
        _buildPerMapel(theme),
        const SizedBox(height: 16),
        _buildPerKelas(theme),
        const SizedBox(height: 16),
        _buildPerJenis(theme),
      ] else if (_semesterId != null)
        const EmptyState(icon: Icons.analytics_outlined, message: 'Pilih semester dan klik Analisis.')
      else
        const EmptyState(icon: Icons.calendar_month_outlined, message: 'Pilih semester untuk memulai.'),
    ]));
  }

  Widget _buildOverview(ThemeData theme) {
    final o = _analisis!['overview'] as Map<String, dynamic>? ?? {};
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.grey200)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.summarize_outlined, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Ringkasan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ]),
        const SizedBox(height: 16),
        Wrap(spacing: 16, runSpacing: 16, children: [
          _statChip(Icons.people_outline, 'Santri', '${o['total_siswa'] ?? 0}', AppTheme.blue),
          _statChip(Icons.book_outlined, 'Mapel', '${o['total_mapel'] ?? 0}', AppTheme.teal),
          _statChip(Icons.trending_up, 'Rata-rata', '${o['rata_rata'] ?? '-'}', AppTheme.primary),
          _statChip(Icons.arrow_upward, 'Tertinggi', '${o['nilai_tertinggi'] ?? '-'}', AppTheme.orange),
          _statChip(Icons.arrow_downward, 'Terendah', '${o['nilai_terendah'] ?? '-'}', AppTheme.error),
          _statChip(Icons.list, 'Total Entry', '${o['total_entries'] ?? 0}', AppTheme.grey400),
        ]),
      ])),
    );
  }

  Widget _statChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.grey600)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ]),
      ]),
    );
  }

  Widget _buildPerMapel(ThemeData theme) {
    final list = (_analisis!['per_mapel'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    if (list.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.grey200)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.book_outlined, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Per Mata Pelajaran', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ]),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.grey50),
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('Mapel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Rata-rata', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
            DataColumn(label: Text('Entry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
          ],
          rows: list.map((m) => DataRow(cells: [
            DataCell(Text('${m['mapel_nama'] ?? '-'}', style: const TextStyle(fontSize: 12))),
            DataCell(Text('${m['avg_nilai'] ?? '-'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            DataCell(Text('${m['count'] ?? 0}', style: const TextStyle(fontSize: 12))),
          ])).toList(),
        ),
        ),
      ])),
    );
  }

  Widget _buildPerKelas(ThemeData theme) {
    final list = (_analisis!['per_kelas'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    if (list.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.grey200)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.school_outlined, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Per Kelas', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ]),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.grey50),
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('Kelas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Rata-rata', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
            DataColumn(label: Text('Santri', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
            DataColumn(label: Text('Entry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
          ],
          rows: list.map((k) => DataRow(cells: [
            DataCell(Text('${k['kelas_nama'] ?? '-'}', style: const TextStyle(fontSize: 12))),
            DataCell(Text('${k['avg_nilai'] ?? '-'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            DataCell(Text('${k['jumlah_siswa'] ?? 0}', style: const TextStyle(fontSize: 12))),
            DataCell(Text('${k['count'] ?? 0}', style: const TextStyle(fontSize: 12))),
          ])).toList(),
        ),
        ),
      ])),
    );
  }

  Widget _buildPerJenis(ThemeData theme) {
    final list = (_analisis!['per_jenis'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    if (list.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.grey200)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.category_outlined, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Per Jenis Nilai', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ]),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.grey50),
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('Jenis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Rata-rata', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
            DataColumn(label: Text('Entry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), numeric: true),
          ],
          rows: list.map((j) => DataRow(cells: [
            DataCell(Text('${j['jenis'] ?? '-'}', style: const TextStyle(fontSize: 12))),
            DataCell(Text('${j['avg_nilai'] ?? '-'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            DataCell(Text('${j['count'] ?? 0}', style: const TextStyle(fontSize: 12))),
          ])).toList(),
        ),
        ),
      ])),
    );
  }
}

// ── Audit Nilai Tab ──
class _AuditNilaiTab extends StatefulWidget {
  const _AuditNilaiTab();
  @override
  State<_AuditNilaiTab> createState() => _AuditNilaiTabState();
}

class _AuditNilaiTabState extends State<_AuditNilaiTab> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = false;
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await AdminService.getAuditNilai(page: _page);
      _items = (res['items'] as List<dynamic>).cast<Map<String, dynamic>>();
      _totalPages = res['pagination']?['total_pages'] ?? 1;
    } catch (_) { _items = []; }
    if (mounted) setState(() => _loading = false);
  }

  IconData _iconForAksi(String aksi) {
    switch (aksi) {
      case 'create': return Icons.add_circle_outline;
      case 'update': return Icons.edit_outlined;
      case 'delete': return Icons.delete_outline;
      case 'validate': return Icons.check_circle_outline;
      default: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : _items.isEmpty
            ? const EmptyState(icon: Icons.history, message: 'Belum ada aktivitas nilai.')
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _items.length + 1,
                itemBuilder: (_, i) {
                  if (i == _items.length) {
                    if (_page >= _totalPages) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: OutlinedButton.icon(
                        onPressed: () { _page++; _load(); },
                        icon: const Icon(Icons.expand_more, size: 18),
                        label: const Text('Muat lebih banyak'),
                      )),
                    );
                  }
                  final d = _items[i];
                  final aksi = d['aksi'] as String? ?? '';
                  final c = AuditAction.colorFor(aksi);
                  return Card(
                    margin: const EdgeInsets.only(top: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.grey200)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        CircleAvatar(radius: 22, backgroundColor: c.withValues(alpha: 0.12),
                          child: Icon(_iconForAksi(aksi), size: 20, color: c)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            StatusBadge(label: aksi, color: c, small: true),
                            const SizedBox(width: 8),
                            Expanded(child: Text(d['detail'] as String? ?? '', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.person_outline, size: 12, color: AppTheme.grey500),
                            const SizedBox(width: 4),
                            Text('${d['username'] ?? '-'}', style: const TextStyle(fontSize: 11, color: AppTheme.grey600)),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time, size: 12, color: AppTheme.grey500),
                            const SizedBox(width: 4),
                            Text('${d['created_at'] ?? '-'}', style: const TextStyle(fontSize: 11, color: AppTheme.grey600)),
                          ]),
                        ])),
                      ]),
                    ),
                  );
                },
              );
  }
}

// ── Shared Helpers ──

InputDecoration inputDecoration(String label, IconData icon, {bool optional = false}) {
  return AppInputDecoration.standard(label, icon, optional: optional);
}
