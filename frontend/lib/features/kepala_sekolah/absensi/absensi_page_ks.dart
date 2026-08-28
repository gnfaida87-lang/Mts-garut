import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/kepala_sekolah_service.dart';

class AbsensiPageKS extends StatefulWidget {
  const AbsensiPageKS({super.key});

  @override
  State<AbsensiPageKS> createState() => _AbsensiPageKSState();
}

class _AbsensiPageKSState extends State<AbsensiPageKS> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.checklist_outlined, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Monitoring Absensi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.grey800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppTheme.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryDark,
            unselectedLabelColor: AppTheme.grey500,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            indicatorColor: AppTheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Asatidz'),
              Tab(text: 'Santri'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _TabGuru(),
              _TabSiswa(),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabGuru extends StatefulWidget {
  const _TabGuru();

  @override
  State<_TabGuru> createState() => _TabGuruState();
}

class _TabGuruState extends State<_TabGuru> {
  final _tanggalCtl = TextEditingController();
  String? _status;
  List<dynamic> _items = [];
  bool _loading = false;
  int _page = 1, _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _tanggalCtl.text = DateTime.now().toIso8601String().substring(0, 10);
    _load();
  }

  @override
  void dispose() {
    _tanggalCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await KepalaSekolahService.getAbsensiGuru(
        page: _page, tanggal: _tanggalCtl.text, status: _status,
      );
      if (!mounted) return;
      _items = data['items'] as List<dynamic>? ?? [];
      final pag = data['pagination'] as Map<String, dynamic>? ?? {};
      _totalPages = pag['total_pages'] as int? ?? 1;
    } catch (_) { debugPrint('[absensi_page_ks.dart] error caught'); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildFilterBar(),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        else if (_items.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: AppTheme.grey300),
                  SizedBox(height: 12),
                  Text('Tidak ada data', style: TextStyle(color: AppTheme.grey500, fontSize: 14)),
                ],
              ),
            ),
          )
        else ...[
          _buildDataTable(),
          const SizedBox(height: 12),
          _buildPaginationRow(
            page: _page,
            totalPages: _totalPages,
            onPrev: () {
              if (_page > 1) { _page--; _load(); }
            },
            onNext: () {
              if (_page < _totalPages) { _page++; _load(); }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 200,
            child: TextField(
              controller: _tanggalCtl,
              decoration: const InputDecoration(
                labelText: 'Tanggal',
                suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
              ),
              readOnly: true,
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (d != null) _tanggalCtl.text = d.toIso8601String().substring(0, 10);
              },
            ),
          ),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Status'),
              value: _status,
              items: const [
                DropdownMenuItem(value: null, child: Text('Semua')),
                DropdownMenuItem(value: 'hadir', child: Text('Hadir')),
                DropdownMenuItem(value: 'izin', child: Text('Izin')),
                DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                DropdownMenuItem(value: 'alpa', child: Text('Alpa')),
              ],
              onChanged: (v) => setState(() => _status = v),
            ),
          ),
          FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Cari'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('NIP', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Nama Asatidz', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Jam Masuk', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Jam Keluar', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Keterangan', style: TextStyle(fontWeight: FontWeight.w600))),
          ],
          rows: _items.map((item) {
            final s = item as Map<String, dynamic>;
            return DataRow(cells: [
              DataCell(Text(s['guru_nip']?.toString() ?? '')),
              DataCell(Text(s['guru_nama']?.toString() ?? '')),
              DataCell(Text(s['tanggal']?.toString() ?? '')),
              DataCell(Text(s['jam_masuk']?.toString() ?? '-')),
              DataCell(Text(s['jam_keluar']?.toString() ?? '-')),
              DataCell(_statusChipWidget(s['status']?.toString() ?? '')),
              DataCell(Text(s['keterangan']?.toString() ?? '-')),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

class _TabSiswa extends StatefulWidget {
  const _TabSiswa();

  @override
  State<_TabSiswa> createState() => _TabSiswaState();
}

class _TabSiswaState extends State<_TabSiswa> {
  final _tanggalCtl = TextEditingController();
  String? _kelasId, _status;
  List<dynamic> _items = [], _kelas = [];
  bool _loading = false;
  int _page = 1, _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _tanggalCtl.text = DateTime.now().toIso8601String().substring(0, 10);
    _loadKelas();
    _load();
  }

  @override
  void dispose() {
    _tanggalCtl.dispose();
    super.dispose();
  }

  Future<void> _loadKelas() async {
    try {
      final res = await KepalaSekolahService.getReferensi();
      if (!mounted) return;
      setState(() => _kelas = res['kelas'] as List<dynamic>? ?? []);
    } catch (_) { debugPrint('[absensi_page_ks.dart] error caught'); }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await KepalaSekolahService.getAbsensiSiswa(
        page: _page, kelasId: _kelasId, tanggal: _tanggalCtl.text, status: _status,
      );
      if (!mounted) return;
      _items = data['items'] as List<dynamic>? ?? [];
      final pag = data['pagination'] as Map<String, dynamic>? ?? {};
      _totalPages = pag['total_pages'] as int? ?? 1;
    } catch (_) { debugPrint('[absensi_page_ks.dart] error caught'); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildFilterBar(),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        else if (_items.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: AppTheme.grey300),
                  SizedBox(height: 12),
                  Text('Tidak ada data', style: TextStyle(color: AppTheme.grey500, fontSize: 14)),
                ],
              ),
            ),
          )
        else ...[
          _buildDataTable(),
          const SizedBox(height: 12),
          _buildPaginationRow(
            page: _page,
            totalPages: _totalPages,
            onPrev: () {
              if (_page > 1) { _page--; _load(); }
            },
            onNext: () {
              if (_page < _totalPages) { _page++; _load(); }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Kelas'),
              value: _kelasId,
              items: _kelas.map((k) => DropdownMenuItem(
                value: k['id'].toString(),
                child: Text(k['nama'] as String? ?? ''),
              )).toList(),
              onChanged: (v) => setState(() => _kelasId = v),
            ),
          ),
          SizedBox(
            width: 200,
            child: TextField(
              controller: _tanggalCtl,
              decoration: const InputDecoration(
                labelText: 'Tanggal',
                suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
              ),
              readOnly: true,
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (d != null) _tanggalCtl.text = d.toIso8601String().substring(0, 10);
              },
            ),
          ),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Status'),
              value: _status,
              items: const [
                DropdownMenuItem(value: null, child: Text('Semua')),
                DropdownMenuItem(value: 'hadir', child: Text('Hadir')),
                DropdownMenuItem(value: 'izin', child: Text('Izin')),
                DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                DropdownMenuItem(value: 'alpa', child: Text('Alpa')),
              ],
              onChanged: (v) => setState(() => _status = v),
            ),
          ),
          FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Cari'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('NIS', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Nama', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Kelas', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Mapel', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Keterangan', style: TextStyle(fontWeight: FontWeight.w600))),
          ],
          rows: _items.map((item) {
            final s = item as Map<String, dynamic>;
            return DataRow(cells: [
              DataCell(Text(s['siswa_nis']?.toString() ?? '')),
              DataCell(Text(s['siswa_nama']?.toString() ?? '')),
              DataCell(Text(s['kelas_nama']?.toString() ?? '')),
              DataCell(Text(s['mapel_nama']?.toString() ?? '-')),
              DataCell(Text(s['tanggal']?.toString() ?? '')),
              DataCell(_statusChipWidget(s['status']?.toString() ?? '')),
              DataCell(Text(s['keterangan']?.toString() ?? '-')),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

Widget _statusChipWidget(String status) {
  Color color;
  String label;
  switch (status) {
    case 'hadir': color = AppTheme.primary; label = 'Hadir'; break;
    case 'izin': color = AppTheme.orange; label = 'Izin'; break;
    case 'sakit': color = AppTheme.blue; label = 'Sakit'; break;
    case 'alpa': color = AppTheme.error; label = 'Alpa'; break;
    default: color = AppTheme.grey400; label = status; break;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}

Widget _buildPaginationRow({
  required int page,
  required int totalPages,
  required VoidCallback onPrev,
  required VoidCallback onNext,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(
        icon: const Icon(Icons.chevron_left, size: 20),
        onPressed: page > 1 ? onPrev : null,
        color: AppTheme.grey600,
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$page / $totalPages',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryDark),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.chevron_right, size: 20),
        onPressed: page < totalPages ? onNext : null,
        color: AppTheme.grey600,
      ),
    ],
  );
}
