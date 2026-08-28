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
  List<Map<String, dynamic>> _data = [];
  bool _loading = false;
  int _page = 1;
  int _totalPages = 1;
  String _statusFilter = '';
  String _jenisFilter = '';
  bool _nilaiPublished = false;
  int? _selectedSemesterId;
  int? _selectedTahunAjaranId;
  List<Map<String, dynamic>> _semesterOptions = [];
  List<Map<String, dynamic>> _tahunAjaranOptions = [];
  bool _loadingPublikasi = false;
  List<Map<String, dynamic>> _jenisList = [];
  bool _loadingJenis = false;
  List<Map<String, dynamic>> _kelasList = [];
  bool _loadingKelas = false;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); _load(); _initPublikasi(); }

  Future<void> _initPublikasi() async {
    await _loadSemesterOptions();
    await _loadPublikasi();
    await _loadJenisPublikasi();
    await _loadKelasPublikasi();
  }

  Future<void> _loadSemesterOptions() async {
    try {
      final res = await AdminService.getReferensi();
      if (!mounted) return;
      setState(() {
        _semesterOptions = (res['semester'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        _tahunAjaranOptions = (res['tahun_ajaran'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
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
        _selectedSemesterId = sems.isNotEmpty ? sems.first['id'] as int : _selectedSemesterId;
      }
    });
    _reloadPublikasiForSemester(_selectedSemesterId);
  }

  void _selectSemester(int? id) {
    setState(() => _selectedSemesterId = id);
    _reloadPublikasiForSemester(id);
  }

  Future<void> _reloadPublikasiForSemester(int? id) async {
    await _loadPublikasi();
    await _loadJenisPublikasi();
    await _loadKelasPublikasi();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _loadPublikasi() async {
    try {
      final res = await AdminService.getPublikasiStatus(_selectedSemesterId);
      if (mounted) {
        setState(() {
          _nilaiPublished = res['nilai_published'] == true;
          _selectedSemesterId = res['semester_id'] as int? ?? _selectedSemesterId;
        });
      }
    } catch (_) { debugPrint('[nilai_page.dart] error caught'); }
  }

  Future<void> _togglePublikasi() async {
    if (_selectedSemesterId == null) return;
    setState(() => _loadingPublikasi = true);
    try {
      await AdminService.togglePublikasiNilai(_selectedSemesterId!, !_nilaiPublished);
      if (mounted) {
        setState(() => _nilaiPublished = !_nilaiPublished);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_nilaiPublished ? 'Nilai dipublikasikan ke siswa' : 'Nilai disembunyikan dari siswa'),
          backgroundColor: _nilaiPublished ? AppTheme.primary : AppTheme.orange,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.error));
    }
    if (mounted) setState(() => _loadingPublikasi = false);
  }

  Future<void> _loadJenisPublikasi() async {
    setState(() => _loadingJenis = true);
    try {
      final res = await AdminService.getPublikasiJenis(_selectedSemesterId);
      if (mounted) {
        setState(() {
          _jenisList = (res['jenis'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        });
      }
    } catch (_) { debugPrint('[nilai_page.dart] error caught'); }
    if (mounted) setState(() => _loadingJenis = false);
  }

  Future<void> _toggleJenisPublikasi(String jenis, bool current) async {
    if (_selectedSemesterId == null) return;
    try {
      await AdminService.togglePublikasiJenis(_selectedSemesterId!, jenis, !current);
      if (mounted) {
        setState(() {
          final idx = _jenisList.indexWhere((j) => j['jenis'] == jenis);
          if (idx >= 0) _jenisList[idx]['is_published'] = !current;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$jenis ${!current ? 'dipublikasikan' : 'disembunyikan'}'),
          backgroundColor: !current ? AppTheme.primary : AppTheme.orange,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.error));
    }
  }

  Future<void> _setAllJenis(bool newVal) async {
    if (_selectedSemesterId == null || _jenisList.isEmpty) return;
    try {
      for (final j in _jenisList) {
        final jenis = j['jenis'] as String;
        if ((j['is_published'] == true) != newVal) {
          await AdminService.togglePublikasiJenis(_selectedSemesterId!, jenis, newVal);
        }
      }
      if (mounted) {
        setState(() {
          for (final j in _jenisList) { j['is_published'] = newVal; }
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(newVal ? 'Semua jenis dipublikasikan' : 'Semua jenis disembunyikan'),
          backgroundColor: newVal ? AppTheme.primary : AppTheme.orange,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.error));
    }
  }

  Future<void> _loadKelasPublikasi() async {
    setState(() => _loadingKelas = true);
    try {
      final res = await AdminService.getPublikasiKelas(_selectedSemesterId);
      if (mounted) {
        setState(() {
          _kelasList = (res['kelass'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        });
      }
    } catch (_) { debugPrint('[nilai_page.dart] error caught'); }
    if (mounted) setState(() => _loadingKelas = false);
  }

  Future<void> _toggleKelasPublikasi(int kelasId, bool current) async {
    if (_selectedSemesterId == null) return;
    final nama = _kelasList
        .where((k) => k['kelas_id'] == kelasId)
        .map((k) => k['kelas_nama'] ?? 'Kelas')
        .firstOrNull;
    try {
      await AdminService.togglePublikasiKelas(_selectedSemesterId!, kelasId, !current);
      if (mounted) {
        setState(() {
          final idx = _kelasList.indexWhere((k) => k['kelas_id'] == kelasId);
          if (idx >= 0) _kelasList[idx]['is_published'] = !current;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$nama ${!current ? 'dipublikasikan' : 'disembunyikan'}'),
          backgroundColor: !current ? AppTheme.primary : AppTheme.orange,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.error));
    }
  }

  Future<void> _setAllKelas(bool newVal) async {
    if (_selectedSemesterId == null || _kelasList.isEmpty) return;
    try {
      for (final kk in _kelasList) {
        final kelasId = kk['kelas_id'] as int;
        if ((kk['is_published'] == true) != newVal) {
          await AdminService.togglePublikasiKelas(_selectedSemesterId!, kelasId, newVal);
        }
      }
      if (mounted) {
        setState(() {
          for (final kk in _kelasList) { kk['is_published'] = newVal; }
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(newVal ? 'Semua kelas diaktifkan' : 'Semua kelas disembunyikan'),
          backgroundColor: newVal ? AppTheme.primary : AppTheme.orange,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.error));
    }
  }

  String get _jenisValue {
    if (_jenisFilter.isEmpty) return '';
    return _jenisFilter.toLowerCase();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await AdminService.getNilai(page: _page, jenis: _jenisValue.isEmpty ? null : _jenisValue,
          statusValidasi: _statusFilter.isEmpty ? null : _statusFilter);
      _data = (res['items'] as List<dynamic>).cast<Map<String, dynamic>>();
      _totalPages = res['pagination']?['total_pages'] ?? 1;
    } catch (_) { _data = []; }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _validasi(int id) async {
    try {
      await AdminService.validasiNilai(id);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal validasi: $e'), backgroundColor: AppTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nilai'), automaticallyImplyLeading: false,
        bottom: TabBar(controller: _tabCtrl, onTap: (i) { _page = 1; _load(); }, isScrollable: true,
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

  Widget _buildPagination() {
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

  Color _statusColor(String s) => s == 'tervalidasi' ? AppTheme.primary : AppTheme.orange;

  String _jenisLabel(String jenis) {
    const labels = {
      'harian': 'Harian', 'tugas': 'Tugas', 'pts1': 'PTS 1', 'pts2': 'PTS 2',
      'pas': 'PAS', 'uts': 'UTS', 'pat': 'PAT', 'uas': 'UAS', 'akhir': 'Akhir',
    };
    return labels[jenis] ?? jenis;
  }

  Widget _buildCheckItem({required String label, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withValues(alpha: 0.08) : AppTheme.grey50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.grey300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? Icons.check_box : Icons.check_box_outline_blank, size: 18,
                color: selected ? AppTheme.primary : AppTheme.grey400),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: selected ? AppTheme.primary : AppTheme.grey700)),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectAllButton({required bool allSelected, required bool enabled, required VoidCallback onPressed}) {
    return TextButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(allSelected ? Icons.deselect : Icons.select_all, size: 16),
      label: Text(allSelected ? 'Bersihkan semua' : 'Pilih semua', style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(0, 32)),
    );
  }

  Widget _buildMonitoringTab() {
    return Column(children: [
      DataCard(
        padding: const EdgeInsets.all(16),
        header: Row(children: [
          const Icon(Icons.visibility_outlined, size: 20, color: AppTheme.primary),
          const SizedBox(width: 8),
          const Expanded(child: Text('Publikasi Nilai ke Siswa', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
          if (_loadingPublikasi)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          else
            Switch(
              value: _nilaiPublished,
              onChanged: (_) => _togglePublikasi(),
              activeColor: AppTheme.primary,
            ),
        ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(_nilaiPublished ? Icons.check_circle : Icons.cancel,
                size: 16, color: _nilaiPublished ? AppTheme.primary : AppTheme.orange),
            const SizedBox(width: 8),
            Text(
              _nilaiPublished ? 'Semua nilai terlihat oleh siswa' : 'Semua nilai tidak terlihat oleh siswa',
              style: TextStyle(fontSize: 12, color: _nilaiPublished ? AppTheme.primary : AppTheme.orange),
            ),
          ]),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          const Row(children: [
            Icon(Icons.calendar_month_outlined, size: 16, color: AppTheme.grey500),
            SizedBox(width: 8),
            Text('Pilih Semester & Tahun Ajaran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.grey700)),
          ]),
          const SizedBox(height: 4),
          const Text('Kelola kategori publikasi untuk semester tertentu', style: TextStyle(fontSize: 11, color: AppTheme.grey400)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: DropdownButtonFormField<int>(
              value: _selectedTahunAjaranId,
              isDense: true,
              decoration: inputDecoration('Tahun Ajaran', Icons.calendar_today_outlined, optional: true),
              items: [
                const DropdownMenuItem<int>(value: null, child: Text('Semua TA', style: TextStyle(fontSize: 13))),
                ..._tahunAjaranOptions.map((t) => DropdownMenuItem(
                    value: t['id'] as int,
                    child: Text('TA ${t['nama']}', style: const TextStyle(fontSize: 13)))),
              ],
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
              onChanged: _selectSemester,
            )),
          ]),
          if (!_nilaiPublished) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.filter_list, size: 16, color: AppTheme.grey500),
              const SizedBox(width: 8),
              const Expanded(child: Text('Publikasi per Jenis Ujian', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.grey700))),
              if (_jenisList.isNotEmpty)
                _buildSelectAllButton(
                  allSelected: _jenisList.every((j) => j['is_published'] == true),
                  enabled: true,
                  onPressed: () => _setAllJenis(!_jenisList.every((j) => j['is_published'] == true)),
                ),
            ]),
            const SizedBox(height: 4),
            const Text('Centang jenis yang boleh dilihat siswa (bisa lebih dari satu)', style: TextStyle(fontSize: 11, color: AppTheme.grey400)),
            const SizedBox(height: 10),
            if (_loadingJenis)
              const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _jenisList.map((j) {
                  final jenis = j['jenis'] as String;
                  final isPub = j['is_published'] as bool;
                  return _buildCheckItem(
                    label: _jenisLabel(jenis),
                    selected: isPub,
                    onTap: () => _toggleJenisPublikasi(jenis, isPub),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.school_outlined, size: 16, color: AppTheme.grey500),
              const SizedBox(width: 8),
              const Expanded(child: Text('Publikasi per Kelas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.grey700))),
              if (_kelasList.isNotEmpty)
                _buildSelectAllButton(
                  allSelected: _kelasList.every((k) => k['is_published'] == true),
                  enabled: true,
                  onPressed: () => _setAllKelas(!_kelasList.every((k) => k['is_published'] == true)),
                ),
            ]),
            const SizedBox(height: 4),
            const Text('Centang kelas yang boleh melihat nilai (bisa lebih dari satu)', style: TextStyle(fontSize: 11, color: AppTheme.grey400)),
            const SizedBox(height: 10),
            if (_loadingKelas)
              const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            else if (_kelasList.isEmpty)
              const Text('Belum ada data kelas', style: TextStyle(fontSize: 12, color: AppTheme.grey400))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kelasList.map((k) {
                  final kelasId = k['kelas_id'] as int;
                  final nama = k['kelas_nama'] as String? ?? 'Kelas';
                  final isPub = k['is_published'] as bool;
                  return _buildCheckItem(
                    label: nama,
                    selected: isPub,
                    onTap: () => _toggleKelasPublikasi(kelasId, isPub),
                  );
                }).toList(),
              ),
          ],
        ]),
      ),
      DataCard(
        padding: const EdgeInsets.all(16),
        header: const Row(children: [
          Icon(Icons.filter_list, size: 20, color: AppTheme.primary),
          SizedBox(width: 8),
          Text('Filter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(
              value: _statusFilter.isEmpty ? null : _statusFilter,
              isDense: true,
              decoration: inputDecoration('Status', Icons.verified_outlined),
              items: ['', 'draft', 'tervalidasi'].map((s) => DropdownMenuItem(value: s.isEmpty ? null : s,
                  child: Text(s.isEmpty ? 'Semua' : s, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) { _statusFilter = v ?? ''; },
            )),
            const SizedBox(width: 12),
            Expanded(child: DropdownButtonFormField<String>(
              value: _jenisFilter.isEmpty ? null : _jenisFilter,
              isDense: true,
              decoration: inputDecoration('Jenis', Icons.category_outlined),
              items: ['', 'harian', 'tugas', 'uts', 'uas', 'akhir', 'pts1', 'pas', 'pts2', 'pat'].map((s) => DropdownMenuItem(value: s.isEmpty ? null : s,
                  child: Text(s.isEmpty ? 'Semua' : s, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) { _jenisFilter = v ?? ''; },
            )),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () { _page = 1; _load(); },
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Cari'),
            ),
          ]),
        ]),
      ),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data.isEmpty
              ? const EmptyState(icon: Icons.inbox_outlined, message: 'Tidak ada data nilai.')
              : ListView.builder(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), itemCount: _data.length + 1,
                  itemBuilder: (_, i) {
                    if (i == _data.length) return _buildPagination();
                    final d = _data[i];
                    final st = d['status_validasi'] as String? ?? 'draft';
                    final isDraft = st == 'draft';
                    return Card(
                      margin: const EdgeInsets.only(top: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.grey200)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          CircleAvatar(radius: 22, backgroundColor: _statusColor(st).withValues(alpha: 0.12),
                            child: Text((d['siswa_nama'] as String? ?? '?')[0], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _statusColor(st)))),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${d['siswa_nama'] ?? '-'}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.book_outlined, size: 12, color: AppTheme.grey500),
                              const SizedBox(width: 4),
                              Text('${d['mapel_nama'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppTheme.grey600)),
                              const SizedBox(width: 12),
                              const Icon(Icons.category_outlined, size: 12, color: AppTheme.grey500),
                              const SizedBox(width: 4),
                              Text('${d['jenis'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppTheme.grey600)),
                            ]),
                            const SizedBox(height: 2),
                            Row(children: [
                              Text('Nilai: ${d['nilai'] ?? '-'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.grey700)),
                              const SizedBox(width: 12),
                              Text('${d['kelas_nama'] ?? '-'} | ${d['semester_nama'] ?? '-'}', style: const TextStyle(fontSize: 11, color: AppTheme.grey400)),
                            ]),
                            if ((d['tahun_ajaran'] ?? '') != '') ...[
                              const SizedBox(height: 2),
                              Row(children: [
                                const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.grey500),
                                const SizedBox(width: 4),
                                Text('TA ${d['tahun_ajaran'] ?? '-'}', style: const TextStyle(fontSize: 11, color: AppTheme.grey500)),
                                const SizedBox(width: 12),
                                const Icon(Icons.menu_book_outlined, size: 12, color: AppTheme.grey500),
                                const SizedBox(width: 4),
                                Text('Tingkat ${d['tingkat_nama'] ?? '-'}', style: const TextStyle(fontSize: 11, color: AppTheme.grey500)),
                              ]),
                            ],
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            StatusBadge(label: st, color: _statusColor(st), small: true),
                            if (isDraft) ...[
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 32,
                                child: OutlinedButton.icon(
                                  onPressed: () => _validasi(d['id'] as int),
                                  icon: const Icon(Icons.check_circle_outline, size: 14),
                                  label: const Text('Validasi', style: TextStyle(fontSize: 11)),
                                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
                                ),
                              ),
                            ],
                          ]),
                        ]),
                      ),
                    );
                  },
                )),
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
