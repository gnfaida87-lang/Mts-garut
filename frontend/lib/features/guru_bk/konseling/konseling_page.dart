import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_utils.dart';
import '../services/guru_bk_service.dart';

class KonselingPage extends StatefulWidget {
  const KonselingPage({super.key});

  @override
  State<KonselingPage> createState() => _KonselingPageState();
}

class _KonselingPageState extends State<KonselingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // Tab 1 - Jadwal
  List<dynamic> _kelasList = [];
  List<dynamic> _siswaList = [];
  String? _selectedKelasId;
  bool _siswaLoading = false;

  // Tab 2 - History
  List<dynamic> _history = [];
  bool _historyLoading = true;
  int _historyPage = 1;
  int _historyTotalPages = 1;

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
    _loadHistory();
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

  Future<void> _loadSiswa() async {
    if (_selectedKelasId == null) return;
    setState(() => _siswaLoading = true);
    try {
      _siswaList = await GuruBKService.getSiswaByKelas(int.parse(_selectedKelasId!));
    } catch (e) {
      _siswaList = [];
      if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat data santri');
    }
    if (mounted) {
      setState(() => _siswaLoading = false);
      _animCtrl.reset();
      _animCtrl.forward();
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    try {
      final data = await GuruBKService.getHistoryKonseling(page: _historyPage);
      if (!mounted) return;
      _history = data['items'] as List<dynamic>? ?? [];
      final pag = data['pagination'] as Map<String, dynamic>?;
      _historyTotalPages = pag?['total_pages'] as int? ?? 1;
    } catch (e) {
      _history = [];
      if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat riwayat konseling');
    }
    if (mounted) setState(() => _historyLoading = false);
  }

  Future<void> _showJadwalDialog(Map<String, dynamic> siswa) async {
    final tanggalCtl = TextEditingController();
    final jamCtl = TextEditingController();
    final catatanCtl = TextEditingController();
    String jenis = 'individu';

    // Pilih hari dalam seminggu
    String? selectedHari;
    final hariList = ['Sabtu', 'Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis'];

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        String? hari = selectedHari;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.calendar_today, color: AppTheme.primary, size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Jadwal Konseling',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primary,
                          child: Text(
                            ((siswa['nama']?.toString() ?? '').isEmpty
                                    ? '?'
                                    : siswa['nama'].toString())
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(siswa['nama']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              Text('${siswa['nis'] ?? ''} · ${siswa['kelas_nama'] ?? ''}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pilih Hari
                  const Text('Hari', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: hariList.map((h) => ChoiceChip(
                      label: Text(h, style: const TextStyle(fontSize: 12)),
                      selected: hari == h,
                      selectedColor: AppTheme.primary.withValues(alpha: 0.15),
                      onSelected: (v) => setDialogState(() => hari = h),
                      visualDensity: VisualDensity.compact,
                    )).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Tanggal
                  TextField(
                    controller: tanggalCtl,
                    decoration: const InputDecoration(
                      labelText: 'Tanggal (YYYY-MM-DD)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.date_range, size: 20),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),

                  // Jam
                  TextField(
                    controller: jamCtl,
                    decoration: const InputDecoration(
                      labelText: 'Jam (HH:MM)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time, size: 20),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),

                  // Jenis
                  DropdownButtonFormField<String>(
                    value: jenis,
                    decoration: const InputDecoration(
                      labelText: 'Jenis',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    items: ['individu', 'kelompok', 'online'].map((j) =>
                      DropdownMenuItem(value: j, child: Text(j, style: const TextStyle(fontSize: 14)))
                    ).toList(),
                    onChanged: (v) => setDialogState(() => jenis = v!),
                  ),
                  const SizedBox(height: 12),

                  // Catatan
                  TextField(
                    controller: catatanCtl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                      contentPadding: EdgeInsets.all(12),
                    ),
                    style: const TextStyle(fontSize: 14),
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
                  if (tanggalCtl.text.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Tanggal wajib diisi'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  try {
                    await GuruBKService.createJadwalKonseling({
                      'siswa_id': siswa['id'],
                      'tanggal': tanggalCtl.text,
                      'jam': jamCtl.text,
                      'hari': hari,
                      'jenis': jenis,
                      'catatan': catatanCtl.text,
                    });
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } catch (e) {
                    if (ctx.mounted) AppUtils.handleError(ctx, e, message: 'Gagal menyimpan jadwal konseling');
                  }
                },
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Simpan'),
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
      _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jadwal konseling tersimpan'),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _selesaikanJadwal(int id) async {
    try {
      await GuruBKService.updateJadwalKonseling(id, {'status': 'selesai'});
      _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konseling selesai'),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) AppUtils.handleError(context, e, message: 'Gagal menyelesaikan konseling');
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
                    child: const Icon(Icons.support_agent_outlined, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'KONSELING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
                  Tab(icon: Icon(Icons.calendar_month, size: 20), text: 'Jadwal'),
                  Tab(icon: Icon(Icons.history, size: 20), text: 'Catatan'),
                ],
                onTap: (i) => setState(() {}),
              ),
            ],
          ),
        ),
        // Body
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildJadwalTab(),
              _buildCatatanTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ─── TAB 1: JADWAL ──────────────────────────────────────
  Widget _buildJadwalTab() {
    return Column(
      children: [
        // Pilih Kelas
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
        const SizedBox(height: 4),
        // Informasi jumlah siswa
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
                Text(
                  'Klik "Jadwalkan" pada kolom Jadwal',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        // Tabel siswa
        Expanded(
          child: _siswaLoading
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
                            if (isWide) return _buildTabelSiswa();
                            return _buildCardSiswa();
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildTabelSiswa() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.teal.shade50),
          dataRowMinHeight: 44,
          dataRowMaxHeight: 56,
          columnSpacing: 12,
          horizontalMargin: 12,
          columns: const [
            DataColumn(label: Text('NIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('NISN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Nama Santri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Kelas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Jadwal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
          rows: _siswaList.map((s) {
            final sudahDijadwalkan = s['jadwal_id'] != null;
            return DataRow(cells: [
              DataCell(Text(s['nis']?.toString() ?? '', style: const TextStyle(fontSize: 12))),
              DataCell(Text(s['nisn']?.toString() ?? '-', style: const TextStyle(fontSize: 12))),
              DataCell(Text(s['nama']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
              DataCell(Text(s['kelas_nama']?.toString() ?? '', style: const TextStyle(fontSize: 12))),
              DataCell(
                sudahDijadwalkan
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9C6644).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${s['jadwal_tanggal'] ?? ''} ${s['jadwal_jam'] ?? ''}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF9C6644)),
                        ),
                      )
                    : SizedBox(
                        height: 30,
                        child: ElevatedButton.icon(
                          onPressed: () => _showJadwalDialog(s as Map<String, dynamic>),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Jadwalkan', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCardSiswa() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _siswaList.length,
        itemBuilder: (context, i) {
          final s = _siswaList[i];
          final sudahDijadwalkan = s['jadwal_id'] != null;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['nama']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(
                          '${s['nis'] ?? ''} · ${s['kelas_nama'] ?? ''}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        if (sudahDijadwalkan)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Jadwal: ${s['jadwal_tanggal']} ${s['jadwal_jam'] ?? ''}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF9C6644)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  jikaTidak(sudahDijadwalkan,
                    SizedBox(
                      height: 32,
                      child: ElevatedButton.icon(
                        onPressed: () => _showJadwalDialog(s as Map<String, dynamic>),
                        icon: const Icon(Icons.calendar_month, size: 16),
                        label: const Text('Jadwal', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
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

  // ─── TAB 2: CATATAN (HISTORY) ───────────────────────────
  Widget _buildCatatanTab() {
    if (_historyLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 3));
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Belum ada riwayat konseling', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return Column(
          children: [
            if (_historyTotalPages > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Text('Halaman $_historyPage dari $_historyTotalPages',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: _historyPage > 1
                          ? () { _historyPage--; _loadHistory(); }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      onPressed: _historyPage < _historyTotalPages
                          ? () { _historyPage++; _loadHistory(); }
                          : null,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: isWide ? _buildTabelHistory() : _buildCardHistory(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabelHistory() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.indigo.shade50),
        dataRowMinHeight: 44,
        dataRowMaxHeight: 60,
        columnSpacing: 12,
        horizontalMargin: 12,
        columns: const [
          DataColumn(label: Text('NIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('NISN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('Nama Santri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('Kelas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('Catatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
        rows: _history.map((h) {
          final status = h['status']?.toString() ?? 'dijadwalkan';
          final catatan = h['catatan']?.toString() ?? h['konseling_tindak_lanjut']?.toString() ?? '-';
          final statusColor = status == 'selesai' ? const Color(0xFF9C6644) : status == 'dibatalkan' ? Colors.red : Colors.orange;
          final jadwalInfo = [h['hari'], h['tanggal'], h['jam']]
              .where((v) => v != null && v.toString().isNotEmpty)
              .map((v) => v.toString())
              .join(' · ');
          return DataRow(cells: [
            DataCell(Text(h['siswa_nis']?.toString() ?? '', style: const TextStyle(fontSize: 12))),
            DataCell(Text(h['siswa_nisn']?.toString() ?? '-', style: const TextStyle(fontSize: 12))),
            DataCell(Text(h['siswa_nama']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
            DataCell(Text(h['kelas_nama']?.toString() ?? '-', style: const TextStyle(fontSize: 12))),
            DataCell(Text(jadwalInfo, style: const TextStyle(fontSize: 11))),
            DataCell(SizedBox(
              width: 160,
              child: Text(catatan, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
            )),
            DataCell(Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status == 'dijadwalkan' ? 'Terjadwal' : status == 'selesai' ? 'Selesai' : 'Batal',
                style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
              ),
            )),
            DataCell(
              status == 'dijadwalkan'
                  ? SizedBox(
                      height: 30,
                      child: ElevatedButton.icon(
                        onPressed: () => _selesaikanJadwal(h['id']),
                        icon: const Icon(Icons.check, size: 14),
                        label: const Text('Selesai', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildCardHistory() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      itemCount: _history.length,
      itemBuilder: (context, i) {
        final h = _history[i];
        final status = h['status']?.toString() ?? 'dijadwalkan';
        final catatan = h['catatan']?.toString() ?? h['konseling_tindak_lanjut']?.toString() ?? '-';
        final statusColor = status == 'selesai' ? const Color(0xFF9C6644) : status == 'dibatalkan' ? Colors.red : Colors.orange;
        final jadwalInfo = [h['hari'], h['tanggal'], h['jam']]
            .where((v) => v != null && v.toString().isNotEmpty)
            .map((v) => v.toString())
            .join(' · ');
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
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: statusColor.withValues(alpha: 0.15),
                      child: Icon(
                        status == 'selesai' ? Icons.check_circle : Icons.schedule,
                        size: 18,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h['siswa_nama']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text(
                            '${h['siswa_nis'] ?? ''} · ${h['kelas_nama'] ?? ''}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status == 'dijadwalkan' ? 'Terjadwal' : status == 'selesai' ? 'Selesai' : 'Batal',
                        style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(jadwalInfo,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(catatan, style: const TextStyle(fontSize: 12)),
                ),
                if (status == 'dijadwalkan') ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _selesaikanJadwal(h['id']),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Selesai', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
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

  // Helper widget untuk conditional rendering
  Widget jikaTidak(bool kondisi, Widget widget) {
    return kondisi ? const SizedBox.shrink() : widget;
  }
}
