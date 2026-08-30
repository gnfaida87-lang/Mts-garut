import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/app_utils.dart';
import '../services/kepala_sekolah_service.dart';

class LaporanPageKS extends StatefulWidget {
  const LaporanPageKS({super.key});

  @override
  State<LaporanPageKS> createState() => _LaporanPageKSState();
}

class _LaporanPageKSState extends State<LaporanPageKS> {
  int _tab = 0;
  List<dynamic> _items = [];
  bool _loading = true;
  int? _kelasId;
  int? _semesterId;
  List<dynamic> _kelas = [], _semester = [];

  @override
  void initState() {
    super.initState();
    _loadReferensi();
  }

  Future<void> _loadReferensi() async {
    try {
      final res = await ApiClient.get('/referensi');
      final data = res['data'] as Map<String, dynamic>;
      _kelas = data['kelas'] as List<dynamic>? ?? [];
      _semester = data['semester'] as List<dynamic>? ?? [];
    } catch (e) { if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat referensi laporan'); }
    if (mounted) _loadLaporan();
  }

  Future<void> _loadLaporan() async {
    setState(() => _loading = true);
    final jenis = ['jadwal', 'absensi', 'nilai', 'rapor'][_tab];
    try {
      _items = await KepalaSekolahService.getLaporan(
        jenis,
        kelasId: _kelasId?.toString(),
        semesterId: (_tab == 3) ? _semesterId?.toString() : null,
      );
    } catch (e) {
      _items = [];
      if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat laporan');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Text('Laporan', style: Theme.of(context).textTheme.titleLarge),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 12, runSpacing: 8,
            children: [
              if (_tab != 3)
                SizedBox(width: 180, child: DropdownButtonFormField<int?>(
                  decoration: const InputDecoration(labelText: 'Filter Kelas', border: OutlineInputBorder(), isDense: true),
                  value: _kelasId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Semua')),
                    ..._kelas.map((k) => DropdownMenuItem(value: k['id'] as int, child: Text(k['nama'] as String))),
                  ],
                  onChanged: (v) { setState(() => _kelasId = v); _loadLaporan(); },
                )),
              if (_tab == 3)
                SizedBox(width: 180, child: DropdownButtonFormField<int?>(
                  decoration: const InputDecoration(labelText: 'Semester', border: OutlineInputBorder(), isDense: true),
                  value: _semesterId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Pilih Semester')),
                    ..._semester.map((s) => DropdownMenuItem(value: s['id'] as int, child: Text(s['nama'] as String))),
                  ],
                  onChanged: (v) { setState(() => _semesterId = v); _loadLaporan(); },
                )),
              ElevatedButton.icon(icon: const Icon(Icons.refresh, size: 18), onPressed: _loadLaporan, label: const Text('Refresh')),
            ],
          ),
        ),
        Expanded(
          child: DefaultTabController(
            length: 4,
            child: Column(
              children: [
                TabBar(
                  labelColor: Colors.blue,
                  tabs: const [
                    Tab(icon: Icon(Icons.calendar_month), text: 'Jadwal'),
                    Tab(icon: Icon(Icons.checklist), text: 'Absensi'),
                    Tab(icon: Icon(Icons.grading), text: 'Nilai'),
                    Tab(icon: Icon(Icons.assignment), text: 'Rapor'),
                  ],
                  onTap: (i) { setState(() => _tab = i); _loadLaporan(); },
                ),
                Expanded(child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_items.isEmpty) return const Center(child: Text('Tidak ada data'));

    switch (_tab) {
      case 0: return _buildJadwal();
      case 1: return _buildAbsensi();
      case 2: return _buildNilai();
      case 3: return _buildRapor();
      default: return const SizedBox();
    }
  }

  Widget _buildJadwal() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Mapel')), DataColumn(label: Text('Asatidz')),
              DataColumn(label: Text('Kelas')), DataColumn(label: Text('Hari')),
              DataColumn(label: Text('JP')), DataColumn(label: Text('Ruangan')),
            ],
            rows: _items.map((j) => DataRow(cells: [
              DataCell(Text(j['mapel_nama']?.toString() ?? '')),
              DataCell(Text(j['guru_nama']?.toString() ?? '')),
              DataCell(Text(j['kelas_nama']?.toString() ?? '')),
              DataCell(Text(j['hari']?.toString() ?? '')),
              DataCell(Text('${j['jp_ke'] ?? ''}')),
              DataCell(Text(j['ruangan_nama']?.toString() ?? '')),
            ])).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAbsensi() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Periode')), DataColumn(label: Text('Status')),
              DataColumn(label: Text('Kelas')), DataColumn(label: Text('Jumlah')),
            ],
            rows: _items.map((a) => DataRow(cells: [
              DataCell(Text(a['periode']?.toString() ?? '')),
              DataCell(Text(a['status']?.toString() ?? '')),
              DataCell(Text(a['kelas_nama']?.toString() ?? '')),
              DataCell(Text('${a['jumlah'] ?? 0}')),
            ])).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNilai() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Jenis')), DataColumn(label: Text('Kelas')),
              DataColumn(label: Text('Mapel')), DataColumn(label: Text('Total')),
              DataColumn(label: Text('Rata')), DataColumn(label: Text('Min')),
              DataColumn(label: Text('Max')),
            ],
            rows: _items.map((n) => DataRow(cells: [
              DataCell(Text(n['jenis']?.toString() ?? '')),
              DataCell(Text(n['kelas_nama']?.toString() ?? '')),
              DataCell(Text(n['mapel_nama']?.toString() ?? '')),
              DataCell(Text('${n['total'] ?? 0}')),
              DataCell(Text('${n['rata_rata'] ?? '-'}')),
              DataCell(Text('${n['min'] ?? '-'}')),
              DataCell(Text('${n['max'] ?? '-'}')),
            ])).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRapor() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('NIS')), DataColumn(label: Text('Santri')),
              DataColumn(label: Text('Mapel')), DataColumn(label: Text('Nilai')),
              DataColumn(label: Text('Predikat')), DataColumn(label: Text('Catatan')),
            ],
            rows: _items.map((r) => DataRow(cells: [
              DataCell(Text(r['siswa_nis']?.toString() ?? '')),
              DataCell(Text(r['siswa_nama']?.toString() ?? '')),
              DataCell(Text(r['mapel_nama']?.toString() ?? '')),
              DataCell(Text('${r['nilai_akhir'] ?? '-'}')),
              DataCell(Text(r['predikat']?.toString() ?? '-')),
              DataCell(Text(r['catatan_wali_kelas']?.toString() ?? '-', maxLines: 2)),
            ])).toList(),
          ),
        ),
      ],
    );
  }
}


