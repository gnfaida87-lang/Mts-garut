import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_utils.dart';
import '../services/guru_bk_service.dart';

class MonitoringAkademikPage extends StatefulWidget {
  const MonitoringAkademikPage({super.key});

  @override
  State<MonitoringAkademikPage> createState() => _MonitoringAkademikPageState();
}

class _MonitoringAkademikPageState extends State<MonitoringAkademikPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  List<dynamic> _kelasList = [];
  String? _selectedKelasId;

  List<dynamic> _absensi = [];
  List<dynamic> _pelanggaran = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _loadKelas();
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadKelas() async {
    try {
      final list = await GuruBKService.getKelasList();
      if (mounted) setState(() => _kelasList = list);
    } catch (e) {
      if (mounted) {
        setState(() => _kelasList = []);
        AppUtils.handleError(context, e, message: 'Gagal memuat daftar kelas');
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final kelasId = _selectedKelasId != null ? int.parse(_selectedKelasId!) : null;
      final results = await Future.wait([
        GuruBKService.getMonitoringAbsensi(kelasId: kelasId),
        GuruBKService.getMonitoringPelanggaran(kelasId: kelasId),
      ]);
      if (!mounted) return;
      _absensi = results[0];
      _pelanggaran = results[1];
    } catch (e) {
      _absensi = [];
      _pelanggaran = [];
      if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat data monitoring');
    }
    if (mounted) {
      setState(() => _loading = false);
      _animCtrl.reset();
      _animCtrl.forward();
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.trending_up_outlined, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'MONITORING SANTRI',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabCtrl,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: const [
                  Tab(icon: Icon(Icons.event_busy, size: 20), text: 'Absensi'),
                  Tab(icon: Icon(Icons.warning_amber, size: 20), text: 'Pelanggaran'),
                ],
                onTap: (i) => setState(() {}),
              ),
            ],
          ),
        ),
        // Filter kelas
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: DropdownButtonFormField<String>(
            value: _selectedKelasId,
            decoration: InputDecoration(
              labelText: 'Filter Kelas',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.filter_alt_outlined, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Semua Kelas', style: TextStyle(fontSize: 13))),
              ..._kelasList.map((k) => DropdownMenuItem(
                value: k['id'].toString(),
                child: Text(k['nama']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
              )),
            ],
            onChanged: (v) {
              setState(() => _selectedKelasId = v);
              _loadData();
            },
          ),
        ),
        const SizedBox(height: 2),
        // Body
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildAbsensiTab(),
                    _buildPelanggaranTab(),
                  ],
                ),
        ),
      ],
    );
  }

  // ─── TAB ABSENSI ────────────────────────────────────────
  Widget _buildAbsensiTab() {
    if (_absensi.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Belum ada data absensi', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    // Summary
    final total = _absensi.length;
    final totalHadir = _absensi.fold<int>(0, (s, e) => s + ((e['hadir'] as num?)?.toInt() ?? 0));
    final totalAlpa = _absensi.fold<int>(0, (s, e) => s + ((e['alpa'] as num?)?.toInt() ?? 0));

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _miniCard('Santri', '$total', Icons.people, Colors.teal),
                const SizedBox(width: 6),
                _miniCard('Hadir', '$totalHadir', Icons.check_circle, const Color(0xFF9C6644)),
                const SizedBox(width: 6),
                _miniCard('Alpa', '$totalAlpa', Icons.cancel, Colors.red),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return constraints.maxWidth > 600
                    ? _buildAbsensiTable()
                    : _buildAbsensiCards();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsensiTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.teal.shade50),
        dataRowMinHeight: 44,
        dataRowMaxHeight: 56,
        columnSpacing: 14,
        horizontalMargin: 14,
        columns: const [
          DataColumn(label: Text('NIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('Nama Santri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('Kelas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
          DataColumn(label: Text('Hadir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
          DataColumn(label: Text('Izin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
          DataColumn(label: Text('Sakit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
          DataColumn(label: Text('Alpa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
        ],
        rows: _absensi.map((a) {
          final total = ((a['hadir'] as num?)?.toInt() ?? 0) +
              ((a['izin'] as num?)?.toInt() ?? 0) +
              ((a['sakit'] as num?)?.toInt() ?? 0) +
              ((a['alpa'] as num?)?.toInt() ?? 0);
          return DataRow(cells: [
            DataCell(Text(a['nis']?.toString() ?? '', style: const TextStyle(fontSize: 12))),
            DataCell(Text(a['siswa_nama']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
            DataCell(Text(a['kelas_nama']?.toString() ?? '', style: const TextStyle(fontSize: 12))),
            DataCell(Text('$total', style: const TextStyle(fontSize: 12))),
            DataCell(Text('${a['hadir'] ?? 0}', style: const TextStyle(fontSize: 12, color: Color(0xFF7F5539)))),
            DataCell(Text('${a['izin'] ?? 0}', style: TextStyle(fontSize: 12, color: Colors.orange.shade700))),
            DataCell(Text('${a['sakit'] ?? 0}', style: TextStyle(fontSize: 12, color: Colors.blue.shade700))),
            DataCell(Text('${a['alpa'] ?? 0}', style: TextStyle(fontSize: 12, color: Colors.red.shade700))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildAbsensiCards() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _absensi.length,
      itemBuilder: (context, i) {
        final a = _absensi[i];
        final total = ((a['hadir'] as num?)?.toInt() ?? 0) +
            ((a['izin'] as num?)?.toInt() ?? 0) +
            ((a['sakit'] as num?)?.toInt() ?? 0) +
            ((a['alpa'] as num?)?.toInt() ?? 0);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(a['siswa_nama']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: ((a['alpa'] as num?)?.toInt() ?? 0) > 3 ? Colors.red.withValues(alpha: 0.1) : const Color(0xFF9C6644).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Total: $total',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: ((a['alpa'] as num?)?.toInt() ?? 0) > 3 ? Colors.red : const Color(0xFF9C6644),
                        ),
                      ),
                    ),
                  ],
                ),
                Text('${a['nis'] ?? ''} · ${a['kelas_nama'] ?? ''}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _miniStatAbsen(Icons.check_circle, const Color(0xFF9C6644), '${a['hadir'] ?? 0}', 'Hadir'),
                    _miniStatAbsen(Icons.info, Colors.orange, '${a['izin'] ?? 0}', 'Izin'),
                    _miniStatAbsen(Icons.local_hospital, Colors.blue, '${a['sakit'] ?? 0}', 'Sakit'),
                    _miniStatAbsen(Icons.cancel, Colors.red, '${a['alpa'] ?? 0}', 'Alpa'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _miniStatAbsen(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.7))),
      ],
    );
  }

  // ─── TAB PELANGGARAN ────────────────────────────────────
  Widget _buildPelanggaranTab() {
    if (_pelanggaran.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Color(0xFFB08968)),
            const SizedBox(height: 12),
            Text('Tidak ada pelanggaran', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    // Summary
    final total = _pelanggaran.length;
    final totalPelanggaran = _pelanggaran.fold<int>(0, (s, e) => s + ((e['total_pelanggaran'] as num?)?.toInt() ?? 0));

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _miniCard('Santri', '$total', Icons.people, Colors.deepOrange),
                const SizedBox(width: 6),
                _miniCard('Total', '$totalPelanggaran', Icons.gavel, Colors.red),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return constraints.maxWidth > 600
                    ? _buildPelanggaranTable()
                    : _buildPelanggaranCards();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPelanggaranTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.red.shade50),
        dataRowMinHeight: 44,
        dataRowMaxHeight: 56,
        columnSpacing: 14,
        horizontalMargin: 14,
        columns: const [
          DataColumn(label: Text('NIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('Nama Santri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('Kelas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
          DataColumn(label: Text('Terakhir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('Detail', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
        rows: _pelanggaran.map((p) {
          final lastDate = p['terakhir_dilaporkan']?.toString() ?? '';
          final shortDate = lastDate.length >= 10 ? lastDate.substring(0, 10) : lastDate;
          final daftar = p['daftar_pelanggaran']?.toString() ?? '';
          return DataRow(cells: [
            DataCell(Text(p['nis']?.toString() ?? '', style: const TextStyle(fontSize: 12))),
            DataCell(Text(p['siswa_nama']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
            DataCell(Text(p['kelas_nama']?.toString() ?? '', style: const TextStyle(fontSize: 12))),
            DataCell(Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${p['total_pelanggaran'] ?? 0}x',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
            )),
            DataCell(Text(shortDate, style: const TextStyle(fontSize: 11))),
            DataCell(daftar.isNotEmpty
                ? Tooltip(
                    message: daftar,
                    child: const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                  )
                : const SizedBox.shrink()),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildPelanggaranCards() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _pelanggaran.length,
      itemBuilder: (context, i) {
        final p = _pelanggaran[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.gavel, color: Colors.red, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['siswa_nama']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text('${p['nis'] ?? ''} · ${p['kelas_nama'] ?? ''}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${p['total_pelanggaran'] ?? 0}x',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
                if (p['daftar_pelanggaran'] != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p['daftar_pelanggaran'].toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── SHARED WIDGETS ─────────────────────────────────────
  Widget _miniCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
}
