import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/nilai_model.dart';
import '../services/wakil_kurikulum_service.dart';

class NilaiPageWK extends StatefulWidget {
  const NilaiPageWK({super.key});

  @override
  State<NilaiPageWK> createState() => _NilaiPageWKState();
}

class _NilaiPageWKState extends State<NilaiPageWK> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Bobot Nilai
  List<BobotNilai> _bobot = [];
  List<Map<String, dynamic>> _mapelList = [];
  List<Map<String, dynamic>> _tahunAjaranList = [];
  bool _loadingBobot = true;

  // Monitoring
  List<Map<String, dynamic>> _monitoring = [];
  Map<String, dynamic>? _monitoringStats;
  Map<String, dynamic>? _monitoringPagination;
  bool _loadingMonitoring = true;
  int _monitoringPage = 1;
  List<Map<String, dynamic>> _kelasList = [];
  String? _filterKelasId;
  String? _filterMapelId;
  String? _filterStatus;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  // Status Pengumpulan
  List<Map<String, dynamic>> _status = [];
  bool _loadingStatus = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadBobot(),
      _loadMonitoring(),
      _loadStatus(),
    ]);
  }

  // ═══════════════════════════════════════════════════
  //  BOBOT NILAI
  // ═══════════════════════════════════════════════════

  Future<void> _loadBobot() async {
    setState(() => _loadingBobot = true);
    try {
      final results = await Future.wait([
        WakilKurikulumService.getBobotNilai(),
        _loadReferensi(),
      ]);
      final rawBobot = results[0] as List<dynamic>;
      _bobot = rawBobot.map((e) => BobotNilai.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat bobot nilai: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
    if (mounted) setState(() => _loadingBobot = false);
  }

  Future<void> _loadReferensi() async {
    try {
      final ref = await WakilKurikulumService.getReferensi();
      _kelasList = (ref['kelas'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      _mapelList = (ref['mapel'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      _tahunAjaranList = (ref['semester'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat referensi: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _showFormBobot({BobotNilai? existing}) async {
    final isEdit = existing != null;
    int? selectedMapelId = existing?.mataPelajaranId;
    int? selectedTAId = existing?.tahunAjaranId;
    final harianCtrl = TextEditingController(text: '${existing?.harianPersen ?? 20}');
    final tugasCtrl = TextEditingController(text: '${existing?.tugasPersen ?? 20}');
    final utsCtrl = TextEditingController(text: '${existing?.utsPersen ?? 30}');
    final uasCtrl = TextEditingController(text: '${existing?.uasPersen ?? 30}');

    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final total = (int.tryParse(harianCtrl.text) ?? 0) +
              (int.tryParse(tugasCtrl.text) ?? 0) +
              (int.tryParse(utsCtrl.text) ?? 0) +
              (int.tryParse(uasCtrl.text) ?? 0);
          final totalValid = total == 100;

          return AlertDialog(
            title: Row(
              children: [
                Icon(isEdit ? Icons.edit : Icons.add_circle_outline, color: AppTheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(isEdit ? 'Edit Bobot Nilai' : 'Tambah Bobot Nilai'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dropdown Mapel
                  DropdownButtonFormField<int>(
                    value: selectedMapelId,
                    decoration: const InputDecoration(
                      labelText: 'Mata Pelajaran',
                      hintText: 'Kosongkan untuk default',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.book_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Default (Semua Mapel)'),
                      ),
                      ..._mapelList.map((m) => DropdownMenuItem<int>(
                            value: m['id'] as int,
                            child: Text(m['nama'] ?? '-'),
                          )),
                    ],
                    onChanged: (v) => setDialogState(() => selectedMapelId = v),
                  ),
                  const SizedBox(height: 12),

                  // Dropdown Tahun Ajaran
                  DropdownButtonFormField<int>(
                    value: selectedTAId,
                    decoration: const InputDecoration(
                      labelText: 'Semester / Tahun Ajaran *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    items: _tahunAjaranList.map((t) => DropdownMenuItem<int>(
                          value: t['tahun_ajaran_id'] as int? ?? t['id'] as int,
                          child: Text(t['nama'] ?? '-'),
                        )).toList(),
                    onChanged: (v) => setDialogState(() => selectedTAId = v),
                  ),
                  const SizedBox(height: 16),

                  // Slider Persentase
                  _buildPersenSlider(setDialogState, 'Harian', harianCtrl, AppTheme.primary),
                  const SizedBox(height: 8),
                  _buildPersenSlider(setDialogState, 'Tugas', tugasCtrl, AppTheme.blue),
                  const SizedBox(height: 8),
                  _buildPersenSlider(setDialogState, 'UTS', utsCtrl, AppTheme.orange),
                  const SizedBox(height: 8),
                  _buildPersenSlider(setDialogState, 'UAS', uasCtrl, AppTheme.error),
                  const SizedBox(height: 12),

                  // Total indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: totalValid
                          ? AppTheme.primary.withValues(alpha: 0.1)
                          : AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: totalValid ? AppTheme.primary : AppTheme.error,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          totalValid ? Icons.check_circle : Icons.warning,
                          color: totalValid ? AppTheme.primary : AppTheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Total: $total%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: totalValid ? AppTheme.primary : AppTheme.error,
                          ),
                        ),
                        if (!totalValid) ...[
                          const SizedBox(width: 8),
                          const Text(
                            '(harus 100%)',
                            style: TextStyle(color: AppTheme.error, fontSize: 12),
                          ),
                        ],
                      ],
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
                onPressed: (selectedTAId == null || !totalValid)
                    ? null
                    : () async {
                        try {
                          final body = {
                            'mata_pelajaran_id': selectedMapelId,
                            'tahun_ajaran_id': selectedTAId,
                            'harian_persen': int.tryParse(harianCtrl.text) ?? 20,
                            'tugas_persen': int.tryParse(tugasCtrl.text) ?? 20,
                            'uts_persen': int.tryParse(utsCtrl.text) ?? 30,
                            'uas_persen': int.tryParse(uasCtrl.text) ?? 30,
                          };
                          if (isEdit) {
                            await WakilKurikulumService.updateBobotNilai(existing.id!, body);
                          } else {
                            await WakilKurikulumService.createBobotNilai(body);
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          _loadBobot();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEdit ? 'Bobot nilai berhasil diupdate' : 'Bobot nilai berhasil ditambahkan'),
                                backgroundColor: AppTheme.primary,
                              ),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
                            );
                          }
                        }
                      },
                icon: Icon(isEdit ? Icons.save : Icons.add, size: 18),
                label: Text(isEdit ? 'Simpan' : 'Tambah'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPersenSlider(StateSetter setDialogState, String label, TextEditingController ctrl, Color color) {
    final value = (double.tryParse(ctrl.text) ?? 0).clamp(0, 100);
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: color,
            label: '${value.round()}%',
            onChanged: (v) {
              ctrl.text = v.round().toString();
              setDialogState(() {});
            },
          ),
        ),
        SizedBox(
          width: 50,
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
            decoration: const InputDecoration(
              suffixText: '%',
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setDialogState(() {}),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteBobot(BobotNilai bobot) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Bobot Nilai?'),
        content: Text('Hapus bobot untuk ${bobot.displayName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await WakilKurikulumService.deleteBobotNilai(bobot.id!);
        _loadBobot();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bobot nilai berhasil dihapus'), backgroundColor: AppTheme.primary),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: AppTheme.error),
          );
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════
  //  MONITORING
  // ═══════════════════════════════════════════════════

  Future<void> _loadMonitoring() async {
    setState(() => _loadingMonitoring = true);
    try {
      final result = await WakilKurikulumService.getMonitoringNilai(
        page: _monitoringPage,
        perPage: 20,
        kelasId: _filterKelasId,
        mapelId: _filterMapelId,
        status: _filterStatus,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      _monitoring = List<Map<String, dynamic>>.from(
        (result['data'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>(),
      );
      final statsRaw = result['stats'];
      _monitoringStats = (statsRaw is Map) ? Map<String, dynamic>.from(statsRaw) : null;
      final pagRaw = result['pagination'];
      _monitoringPagination = (pagRaw is Map) ? Map<String, dynamic>.from(pagRaw) : null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat monitoring: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
    if (mounted) setState(() => _loadingMonitoring = false);
  }

  // ═══════════════════════════════════════════════════
  //  STATUS PENGUMPULAN
  // ═══════════════════════════════════════════════════

  Future<void> _loadStatus() async {
    setState(() => _loadingStatus = true);
    try {
      _status = (await WakilKurikulumService.getStatusPengumpulan()).cast<Map<String, dynamic>>();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat status: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
    if (mounted) setState(() => _loadingStatus = false);
  }

  // ═══════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════

  static String _str(Map<String, dynamic> m, String key, {String fallback = '-'}) {
    final v = m[key];
    if (v == null) return fallback;
    if (v is String) return v;
    if (v is num) return v.toString();
    return v.toString();
  }

  static int _int(Map<String, dynamic> m, String key, {int fallback = 0}) {
    final v = m[key];
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static num _num(Map<String, dynamic> m, String key, {num fallback = 0}) {
    final v = m[key];
    if (v == null) return fallback;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          decoration: BoxDecoration(
            color: AppTheme.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabCtrl,
            labelColor: AppTheme.primaryDark,
            unselectedLabelColor: AppTheme.grey500,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            indicatorColor: AppTheme.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 3,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Bobot Nilai'),
              Tab(text: 'Monitoring'),
              Tab(text: 'Status Pengumpulan'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildTabContent(),
        ),
      ],
    );
  }

  Widget _buildTabContent() {
    if (_loadingBobot && _loadingMonitoring && _loadingStatus) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    return TabBarView(
      controller: _tabCtrl,
      children: [
        _buildBobotTab(),
        _buildMonitoringTab(),
        _buildStatusTab(),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  //  TAB: BOBOT NILAI
  // ═══════════════════════════════════════════════════

  Widget _buildBobotTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppTheme.grey500),
              const SizedBox(width: 4),
              Text(
                '${_bobot.length} bobot tersimpan',
                style: const TextStyle(color: AppTheme.grey500, fontSize: 12),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showFormBobot(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Bobot'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingBobot
              ? const Center(child: CircularProgressIndicator())
              : _bobot.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.grading_outlined, size: 64, color: AppTheme.grey300),
                          SizedBox(height: 16),
                          Text('Belum ada bobot nilai', style: TextStyle(color: AppTheme.grey500, fontSize: 16)),
                          SizedBox(height: 8),
                          Text('Tekan tombol "Tambah Bobot" untuk menambah', style: TextStyle(color: AppTheme.grey400, fontSize: 12)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBobot,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _bobot.length,
                        itemBuilder: (_, i) {
                          final b = _bobot[i];
                          return _buildBobotCard(b);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildBobotCard(BobotNilai b) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  b.isDefault ? Icons.all_inclusive : Icons.book_outlined,
                  size: 20,
                  color: b.isDefault ? AppTheme.grey500 : AppTheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    b.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _showFormBobot(existing: b),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                  onPressed: () => _deleteBobot(b),
                  tooltip: 'Hapus',
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPersenChip('Harian', b.harianPersen, AppTheme.primary),
                _buildPersenChip('Tugas', b.tugasPersen, AppTheme.blue),
                _buildPersenChip('UTS', b.utsPersen, AppTheme.orange),
                _buildPersenChip('UAS', b.uasPersen, AppTheme.error),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersenChip(String label, num value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${value.round()}%',
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.grey500)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  //  TAB: MONITORING
  // ═══════════════════════════════════════════════════

  Widget _buildMonitoringTab() {
    return Column(
      children: [
        // Stats Summary
        if (_monitoringStats != null) _buildMonitoringStats(),

        // Search & Filter Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  isDense: true,
                  decoration: const InputDecoration(
                    hintText: 'Semua Kelas',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                  ),
                  value: _filterKelasId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Semua Kelas')),
                    ..._kelasList.map((k) => DropdownMenuItem(
                      value: k['id'].toString(),
                      child: Text('${k['nama']}', overflow: TextOverflow.ellipsis),
                    )),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _filterKelasId = v;
                      _monitoringPage = 1;
                    });
                    _loadMonitoring();
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  isDense: true,
                  decoration: const InputDecoration(
                    hintText: 'Semua Mapel',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                  ),
                  value: _filterMapelId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Semua Mapel')),
                    ..._mapelList.map((m) => DropdownMenuItem(
                      value: m['id'].toString(),
                      child: Text('${m['nama']}', overflow: TextOverflow.ellipsis),
                    )),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _filterMapelId = v;
                      _monitoringPage = 1;
                    });
                    _loadMonitoring();
                  },
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari nama siswa atau mapel...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                _searchQuery = '';
                                _monitoringPage = 1;
                              });
                              _loadMonitoring();
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: (v) {
                    setState(() {
                      _searchQuery = v;
                      _monitoringPage = 1;
                    });
                    _loadMonitoring();
                  },
                ),
              ),
              PopupMenuButton<String>(
                icon: Badge(
                  isLabelVisible: _filterStatus != null,
                  child: const Icon(Icons.filter_list),
                ),
                onSelected: (v) {
                  setState(() {
                    _filterStatus = v == 'all' ? null : v;
                    _monitoringPage = 1;
                  });
                  _loadMonitoring();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'all', child: Text('Semua Status')),
                  const PopupMenuItem(value: 'draft', child: Text('📝 Draft')),
                  const PopupMenuItem(value: 'tervalidasi', child: Text('✅ Tervalidasi')),
                ],
              ),
            ],
          ),
        ),

        // Monitoring List
        Expanded(
          child: _loadingMonitoring
              ? const Center(child: CircularProgressIndicator())
              : _monitoring.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.analytics_outlined, size: 64, color: AppTheme.grey300),
                          SizedBox(height: 16),
                          Text('Belum ada data nilai', style: TextStyle(color: AppTheme.grey500, fontSize: 16)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMonitoring,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _monitoring.length,
                        itemBuilder: (_, i) => _buildMonitoringCard(_monitoring[i]),
                      ),
                    ),
        ),

        // Pagination
        if (_monitoringPagination != null && (_monitoringPagination!['total_pages'] ?? 0) > 1)
          _buildPagination(),
      ],
    );
  }

  Widget _buildMonitoringStats() {
    final stats = _monitoringStats!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary.withValues(alpha: 0.1), AppTheme.primaryLight.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', '${_int(stats, 'total')}', AppTheme.primary),
          _buildStatItem('Draft', '${_int(stats, 'draft')}', AppTheme.orange),
          _buildStatItem('Valid', '${_int(stats, 'tervalidasi')}', AppTheme.primaryDark),
          _buildStatItem('Rata2', '${_num(stats, 'rata_rata')}', AppTheme.blue),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.grey500)),
      ],
    );
  }

  Widget _buildMonitoringCard(Map<String, dynamic> n) {
    final status = _str(n, 'status_validasi', fallback: 'draft');
    final isDraft = status == 'draft';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDraft
              ? AppTheme.orange.withValues(alpha: 0.1)
              : AppTheme.primary.withValues(alpha: 0.1),
          child: Icon(
            isDraft ? Icons.pending_outlined : Icons.check_circle_outline,
            color: isDraft ? AppTheme.orange : AppTheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          _str(n, 'siswa_nama'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${_str(n, 'mapel_nama')} | ${_str(n, 'jenis')}',
          style: const TextStyle(color: AppTheme.grey500, fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDraft
                ? AppTheme.orange.withValues(alpha: 0.1)
                : AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _str(n, 'nilai'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDraft ? AppTheme.orange : AppTheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final totalPages = _monitoringPagination!['total_pages'] ?? 1;
    final currentPage = _monitoringPagination!['page'] ?? 1;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 1
                ? () {
                    setState(() => _monitoringPage = currentPage - 1);
                    _loadMonitoring();
                  }
                : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$currentPage / $totalPages',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages
                ? () {
                    setState(() => _monitoringPage = currentPage + 1);
                    _loadMonitoring();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  TAB: STATUS PENGUMPULAN
  // ═══════════════════════════════════════════════════

  Widget _buildStatusTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.people_outline, size: 16, color: AppTheme.grey500),
              const SizedBox(width: 4),
              Text(
                '${_status.length} guru aktif',
                style: const TextStyle(color: AppTheme.grey500, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingStatus
              ? const Center(child: CircularProgressIndicator())
              : _status.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.school_outlined, size: 64, color: AppTheme.grey300),
                          SizedBox(height: 16),
                          Text('Belum ada data', style: TextStyle(color: AppTheme.grey500, fontSize: 16)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadStatus,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _status.length,
                        itemBuilder: (_, i) => _buildStatusCard(_status[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(Map<String, dynamic> s) {
    final totalInput = s['total_input'] ?? 0;
    final draft = s['draft'] ?? 0;
    final tervalidasi = s['tervalidasi'] ?? 0;
    final progress = totalInput > 0 ? tervalidasi / totalInput : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    (s['guru_nama']?.toString().isNotEmpty == true
                            ? s['guru_nama'].toString()[0]
                            : '?')
                        .toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['guru_nama'] ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$totalInput input | $draft draft | $tervalidasi tervalidasi',
                        style: const TextStyle(color: AppTheme.grey500, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: progress >= 1.0
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : draft > 0
                            ? AppTheme.orange.withValues(alpha: 0.1)
                            : AppTheme.grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: progress >= 1.0
                          ? AppTheme.primary
                          : draft > 0
                              ? AppTheme.orange
                              : AppTheme.grey500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppTheme.grey100,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? AppTheme.primary : AppTheme.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
