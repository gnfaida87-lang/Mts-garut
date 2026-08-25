import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/guru_bk_service.dart';

class LaporanPageBK extends StatefulWidget {
  const LaporanPageBK({super.key});

  @override
  State<LaporanPageBK> createState() => _LaporanPageBKState();
}

class _LaporanPageBKState extends State<LaporanPageBK>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  Map<String, dynamic>? _bulanan;
  List<dynamic> _rekap = [];
  List<dynamic> _laporanKonseling = [];
  List<dynamic> _laporanBakatMinat = [];
  Map<String, dynamic>? _monitoring;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        GuruBKService.getLaporanBulanan(),
        GuruBKService.getRekapKasus(),
        GuruBKService.getLaporanKonseling(),
        GuruBKService.getLaporanBakatMinat(),
        GuruBKService.getLaporanMonitoring(),
      ]);
      if (!mounted) return;
      _bulanan = results[0] as Map<String, dynamic>?;
      _rekap = results[1] as List<dynamic>;
      _laporanKonseling = results[2] as List<dynamic>;
      _laporanBakatMinat = results[3] as List<dynamic>;
      _monitoring = results[4] as Map<String, dynamic>?;
    } catch (e) {
      if (!mounted) return;
      _errorMessage = 'Gagal memuat laporan. Periksa koneksi Anda.';
    }
    if (mounted) {
      setState(() => _loading = false);
      _animCtrl.reset();
      _animCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 3));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

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
                    child: const Icon(Icons.description_outlined, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'LAPORAN BK',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                    onPressed: _load,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              // Summary row
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: _buildSummaryRow(),
              ),
              TabBar(
                controller: _tabCtrl,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Bulanan'),
                  Tab(text: 'Kasus'),
                  Tab(text: 'Konseling'),
                  Tab(text: 'Bakat-Minat'),
                  Tab(text: 'Monitoring'),
                ],
                onTap: (i) => setState(() {}),
              ),
            ],
          ),
        ),
        // Body
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildBulanan(),
                _buildRekap(),
                _buildLaporanKonseling(),
                _buildLaporanBakatMinat(),
                _buildMonitoring(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow() {
    final bulananItems = _bulanan?['items'] as List<dynamic>? ?? [];
    final totalBulanan = bulananItems.fold<int>(0, (s, e) => s + ((e['total'] as num?)?.toInt() ?? 0));
    final totalKasus = _rekap.fold<int>(0, (s, e) => s + ((e['total'] as num?)?.toInt() ?? 0));
    final totalKonseling = _laporanKonseling.fold<int>(0, (s, e) => s + ((e['total'] as num?)?.toInt() ?? 0));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _sumChip(Icons.calendar_month, 'Laporan', '$totalBulanan'),
          const SizedBox(width: 8),
          _sumChip(Icons.gavel, 'Kasus', '$totalKasus'),
          const SizedBox(width: 8),
          _sumChip(Icons.support_agent, 'Konseling', '$totalKonseling'),
        ],
      ),
    );
  }

  Widget _sumChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(color: Colors.white60, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ─── TAB 1: BULANAN ─────────────────────────────────────
  Widget _buildBulanan() {
    final items = _bulanan?['items'] as List<dynamic>? ?? [];
    return _pageContainer(
      items: items,
      emptyIcon: Icons.calendar_month,
      emptyText: 'Belum ada data laporan bulanan',
      builder: () => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) return _buildBulananTable(items);
          return _buildBulananCards(items);
        },
      ),
    );
  }

  Widget _buildBulananTable(List<dynamic> items) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.teal.shade50),
        dataRowMinHeight: 44,
        columnSpacing: 14,
        horizontalMargin: 14,
        columns: const [
          DataColumn(label: Text('Periode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
          DataColumn(label: Text('Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
          DataColumn(label: Text('Diproses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
          DataColumn(label: Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
        ],
        rows: items.map((r) => DataRow(cells: [
          DataCell(Text(r['periode']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12))),
          DataCell(Text('${r['total'] ?? 0}', style: const TextStyle(fontSize: 12))),
          DataCell(Text('${r['baru'] ?? 0}', style: TextStyle(fontSize: 12, color: Colors.red.shade700))),
          DataCell(Text('${r['diproses'] ?? 0}', style: TextStyle(fontSize: 12, color: Colors.orange.shade700))),
          DataCell(Text('${r['selesai'] ?? 0}', style: const TextStyle(fontSize: 12, color: Color(0xFF7F5539)))),
        ])).toList(),
      ),
    );
  }

  Widget _buildBulananCards(List<dynamic> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final r = items[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(r['periode']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const Spacer(),
                    Text('${r['total'] ?? 0} laporan', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _itemStat('Baru', '${r['baru'] ?? 0}', Colors.red),
                    const SizedBox(width: 12),
                    _itemStat('Diproses', '${r['diproses'] ?? 0}', Colors.orange),
                    const SizedBox(width: 12),
                    _itemStat('Selesai', '${r['selesai'] ?? 0}', const Color(0xFF9C6644)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _itemStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }

  // ─── TAB 2: REKAP KASUS ─────────────────────────────────
  Widget _buildRekap() {
    return _pageContainer(
      items: _rekap,
      emptyIcon: Icons.gavel,
      emptyText: 'Belum ada data kasus',
      builder: () => ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _rekap.length,
        itemBuilder: (context, i) {
          final r = _rekap[i];
          final kategori = r['kategori']?.toString() ?? '';
          final isKasus = kategori == 'kasus';
          final color = isKasus ? Colors.deepPurple : Colors.orange;
          final icon = isKasus ? Icons.gavel : Icons.warning_amber;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kategori.toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${r['siswa_terlibat'] ?? 0} santri terlibat',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${r['total'] ?? 0}',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── TAB 3: LAPORAN KONSELING ───────────────────────────
  Widget _buildLaporanKonseling() {
    return _pageContainer(
      items: _laporanKonseling,
      emptyIcon: Icons.support_agent,
      emptyText: 'Belum ada data konseling',
      builder: () => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) return _buildKonselingTable();
          return _buildKonselingCards();
        },
      ),
    );
  }

  Widget _buildKonselingTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.indigo.shade50),
        dataRowMinHeight: 44,
        columnSpacing: 14,
        horizontalMargin: 14,
        columns: const [
          DataColumn(label: Text('Periode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('Total Sesi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
          DataColumn(label: Text('Santri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
        ],
        rows: _laporanKonseling.map((l) => DataRow(cells: [
          DataCell(Text(l['periode']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12))),
          DataCell(Text('${l['total'] ?? 0}', style: const TextStyle(fontSize: 12))),
          DataCell(Text('${l['siswa'] ?? 0}', style: const TextStyle(fontSize: 12))),
        ])).toList(),
      ),
    );
  }

  Widget _buildKonselingCards() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _laporanKonseling.length,
      itemBuilder: (context, i) {
        final l = _laporanKonseling[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 1,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.support_agent, color: Colors.indigo, size: 22),
            ),
            title: Text(l['periode']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${l['siswa'] ?? 0} santri'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${l['total'] ?? 0} sesi', style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  // ─── TAB 4: BAKAT & MINAT ──────────────────────────────
  Widget _buildLaporanBakatMinat() {
    return _pageContainer(
      items: _laporanBakatMinat,
      emptyIcon: Icons.psychology,
      emptyText: 'Belum ada data bakat & minat',
      builder: () => ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _laporanBakatMinat.length,
        itemBuilder: (context, i) {
          final l = _laporanBakatMinat[i];
          final jenis = l['jenis']?.toString() ?? '';
          final isBakat = jenis == 'bakat';
          final color = isBakat ? Colors.amber : Colors.pink;
          final icon = isBakat ? Icons.star : Icons.favorite;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          jenis == 'bakat' ? 'BAKAT' : 'MINAT',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                        ),
                        Text('${l['siswa'] ?? 0} santri', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${l['total'] ?? 0}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── TAB 5: MONITORING ──────────────────────────────────
  Widget _buildMonitoring() {
    final nilai = _monitoring?['nilai'] as List<dynamic>? ?? [];
    final absensi = _monitoring?['absensi'] as List<dynamic>? ?? [];
    final pengaduan = _monitoring?['pengaduan'] as List<dynamic>? ?? [];

    if (nilai.isEmpty && absensi.isEmpty && pengaduan.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.trending_up, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Belum ada data monitoring', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Absensi
          if (absensi.isNotEmpty) ...[
            _sectionHeader(Icons.event_busy, 'Absensi', Colors.teal),
            const SizedBox(height: 8),
            _buildMiniGrid(absensi, Icons.check_circle, (item) {
              final s = item['status']?.toString() ?? '';
              final color = s == 'hadir' ? const Color(0xFF9C6644) : s == 'izin' ? Colors.orange : s == 'sakit' ? Colors.blue : Colors.red;
              return _miniStatCard(
                s.toUpperCase(),
                '${item['jumlah'] ?? 0}',
                color,
                Icons.check_circle,
              );
            }),
            const SizedBox(height: 16),
          ],
          // Pengaduan
          if (pengaduan.isNotEmpty) ...[
            _sectionHeader(Icons.warning_amber, 'Pengaduan', Colors.deepOrange),
            const SizedBox(height: 8),
            _buildMiniGrid(pengaduan, Icons.gavel, (item) {
              final k = item['kategori']?.toString() ?? '';
              final color = k == 'kasus' ? Colors.deepPurple : Colors.orange;
              return _miniStatCard(
                k.toUpperCase(),
                '${item['jumlah'] ?? 0}',
                color,
                k == 'kasus' ? Icons.gavel : Icons.warning_amber,
              );
            }),
            const SizedBox(height: 16),
          ],
          // Nilai rata-rata
          if (nilai.isNotEmpty) ...[
            _sectionHeader(Icons.grade, 'Rata-rata Nilai', Colors.indigo),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: nilai.map((n) => _miniStatCard(
                n['jenis']?.toString().toUpperCase() ?? '',
                '${n['rata_rata'] ?? 0}',
                Colors.indigo,
                Icons.grade,
                width: 100,
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildMiniGrid(List<dynamic> items, IconData fallbackIcon, Widget Function(dynamic) builder) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) => builder(item)).toList(),
    );
  }

  Widget _miniStatCard(String label, String value, Color color, IconData icon, {double width = 140}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  // ─── SHARED ─────────────────────────────────────────────
  Widget _pageContainer({
    required List<dynamic> items,
    required IconData emptyIcon,
    required String emptyText,
    required Widget Function() builder,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(emptyText, style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    return builder();
  }
}
