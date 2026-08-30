import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/app_utils.dart';
import '../services/wakil_kurikulum_service.dart';

class KenaikanKelasPage extends StatefulWidget {
  const KenaikanKelasPage({super.key});

  @override
  State<KenaikanKelasPage> createState() => _KenaikanKelasPageState();
}

class _KenaikanKelasPageState extends State<KenaikanKelasPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Data
  List<Map<String, dynamic>> _kenaikan = [];
  List<Map<String, dynamic>> _alumni = [];
  List<Map<String, dynamic>> _kelasList = [];
  List<Map<String, dynamic>> _tahunAjaranList = [];
  bool _loading = true;

  // Pagination
  int _kenaikanPage = 1;
  int _kenaikanTotalPages = 1;
  int _alumniPage = 1;
  int _alumniTotalPages = 1;
  final _searchKenaikanCtrl = TextEditingController();
  final _searchAlumniCtrl = TextEditingController();

  // Batch processing state
  int _wizardStep = 0; // 0=riwayat, 1=pilih kelas, 2=centang siswa, 3=pilih kelas tujuan, 4=review
  String? _selectedKelasId;
  String? _selectedTahunAjaranId;
  List<Map<String, dynamic>> _calonSiswa = [];
  List<Map<String, dynamic>> _kelasTujuan = [];
  Map<String, dynamic>? _pengaturan;
  bool _loadingBatch = false;
  Set<int> _selectedSiswaIds = {};
  Map<int, int> _siswaKelasTujuan = {}; // siswa_id -> kelas_id tujuan
  bool _isLastLevel = false;

  // Pengaturan
  final _minAbsensiCtrl = TextEditingController(text: '75');
  final _minNilaiCtrl = TextEditingController(text: '60');

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _minAbsensiCtrl.dispose();
    _minNilaiCtrl.dispose();
    _searchKenaikanCtrl.dispose();
    _searchAlumniCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        WakilKurikulumService.getKenaikanKelas(page: _kenaikanPage, search: _searchKenaikanCtrl.text),
        WakilKurikulumService.getAlumni(page: _alumniPage, search: _searchAlumniCtrl.text),
      ]);
      final kenaikanData = results[0];
      final alumniData = results[1];
      _kenaikan = List<Map<String, dynamic>>.from(kenaikanData['items'] ?? []);
      _kenaikanTotalPages = kenaikanData['pagination']?['total_pages'] ?? 1;
      _alumni = List<Map<String, dynamic>>.from(alumniData['items'] ?? []);
      _alumniTotalPages = alumniData['pagination']?['total_pages'] ?? 1;
    } catch (e) {
      if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat data');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadReferensi() async {
    try {
      final ref = await WakilKurikulumService.getReferensi();
      _kelasList = (ref['kelas'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      _tahunAjaranList = (ref['tahun_ajaran'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    } catch (e) {
      if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat referensi');
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  WIZARD: Step 1 - Pilih Kelas Asal
  // ═══════════════════════════════════════════════════════════
  Future<void> _startBatchProses() async {
    await _loadReferensi();
    setState(() {
      _wizardStep = 1;
      _selectedKelasId = null;
      _selectedTahunAjaranId = null;
      _calonSiswa = [];
      _kelasTujuan = [];
      _selectedSiswaIds = {};
      _siswaKelasTujuan = {};
      _isLastLevel = false;
    });
  }

  Future<void> _loadCalonSiswa() async {
    if (_selectedKelasId == null || _selectedTahunAjaranId == null) return;
    setState(() => _loadingBatch = true);
    try {
      final data = await WakilKurikulumService.getCalonBatch(_selectedKelasId!, _selectedTahunAjaranId!);
      _calonSiswa = (data['siswa'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      _pengaturan = data['pengaturan'] as Map<String, dynamic>?;
      if (_pengaturan != null) {
        _minAbsensiCtrl.text = (_pengaturan!['min_absensi_persen'] ?? 75).toString();
        _minNilaiCtrl.text = (_pengaturan!['min_nilai_akhir'] ?? 60).toString();
      }
      // Load kelas tujuan
      final kelasTujuanData = await WakilKurikulumService.getKelasTujuan(_selectedKelasId!, _selectedTahunAjaranId!);
      _kelasTujuan = (kelasTujuanData['kelas'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      _isLastLevel = kelasTujuanData['is_last_level'] ?? false;
    } catch (e) {
      if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat data');
    }
    if (mounted) setState(() => _loadingBatch = false);
  }

  void _proceedToStep2() {
    if (_selectedKelasId == null || _selectedTahunAjaranId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih kelas dan tahun ajaran')));
      return;
    }
    _loadCalonSiswa().then((_) {
      if (mounted) setState(() => _wizardStep = 2);
    });
  }

  void _proceedToStep3() {
    if (_selectedSiswaIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih minimal satu siswa')));
      return;
    }
    setState(() => _wizardStep = 3);
  }

  void _proceedToStep4() {
    // Validasi semua siswa yang dipilih sudah punya kelas tujuan
    if (!_isLastLevel) {
      for (final siswaId in _selectedSiswaIds) {
        if (!_siswaKelasTujuan.containsKey(siswaId)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Siswa ID $siswaId belum dipilih kelas tujuan')),
          );
          return;
        }
      }
    }
    setState(() => _wizardStep = 4);
  }

  Future<void> _submitBatch() async {
    if (_loadingBatch) return;

    // Konfirmasi sebelum proses
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: AppTheme.orange, size: 40),
        title: const Text('Konfirmasi Kenaikan Kelas'),
        content: Text(
          'Proses kenaikan kelas untuk ${_selectedSiswaIds.length} siswa?\n\n'
          '${_isLastLevel ? "Semua siswa yang dipilih akan menjadi ALUMNI." : "Siswa tidak dipilih akan TIDAK NAIK kelas."}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Ya, Proses'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loadingBatch = true);
    try {
      final siswaNaik = <Map<String, dynamic>>[];
      final siswaTidakNaik = <int>[];

      for (final siswaId in _selectedSiswaIds) {
        if (_isLastLevel) {
          siswaNaik.add({'siswa_id': siswaId, 'ke_kelas_id': 0});
        } else {
          final kelasId = _siswaKelasTujuan[siswaId];
          if (kelasId != null) {
            siswaNaik.add({'siswa_id': siswaId, 'ke_kelas_id': kelasId});
          }
        }
      }

      for (final s in _calonSiswa) {
        final id = s['id'] as int;
        if (!_selectedSiswaIds.contains(id)) {
          siswaTidakNaik.add(id);
        }
      }

      final result = await WakilKurikulumService.prosesBatch({
        'dari_kelas_id': int.tryParse(_selectedKelasId!),
        'tahun_ajaran_id': int.tryParse(_selectedTahunAjaranId!),
        'siswa_naik': siswaNaik,
        'siswa_tidak_naik': siswaTidakNaik,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Berhasil memproses ${result['processed']} siswa')),
        );
        setState(() => _wizardStep = 0);
        _load();
      }
    } catch (e) {
      if (mounted) AppUtils.handleError(context, e, message: 'Gagal memproses kenaikan kelas');
    } finally {
      if (mounted) setState(() => _loadingBatch = false);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
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
                child: const Icon(Icons.trending_up, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Kenaikan Kelas & Alumni',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.grey800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tab Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppTheme.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabCtrl,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.grey500,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Kenaikan Kelas'),
              Tab(text: 'Alumni'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tab Content
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildKenaikanTab(),
                    _buildAlumniTab(),
                  ],
                ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  TAB: KENAIKAN KELAS
  // ═══════════════════════════════════════════════════════════
  Widget _buildKenaikanTab() {
    if (_wizardStep > 0) {
      return _buildWizard();
    }

    return Column(
      children: [
        // Action Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _startBatchProses,
                  icon: const Icon(Icons.batch_prediction, size: 18),
                  label: const Text('Proses Batch'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _showPengaturanDialog,
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('Pengaturan'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.grey600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _searchKenaikanCtrl,
            decoration: InputDecoration(
              hintText: 'Cari nama atau NIS...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchKenaikanCtrl.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchKenaikanCtrl.clear(); _load(); })
                : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              isDense: true,
            ),
            onSubmitted: (_) => _load(),
          ),
        ),
        const SizedBox(height: 12),

        // Riwayat List
        Expanded(
          child: _kenaikan.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 48, color: AppTheme.grey300),
                      SizedBox(height: 12),
                      Text('Belum ada data kenaikan kelas', style: TextStyle(color: AppTheme.grey500, fontSize: 14)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _kenaikan.length,
                  itemBuilder: (_, i) => _buildRiwayatCard(_kenaikan[i]),
                ),
        ),

        // Pagination
        if (_kenaikanTotalPages > 1)
          _buildPagination(
            currentPage: _kenaikanPage,
            totalPages: _kenaikanTotalPages,
            onPageChanged: (page) { _kenaikanPage = page; _load(); },
          ),
      ],
    );
  }

  Widget _buildRiwayatCard(Map<String, dynamic> k) {
    final status = k['status']?.toString() ?? '';
    final statusColor = status == 'naik'
        ? AppTheme.primary
        : status == 'lulus'
            ? AppTheme.blue
            : AppTheme.error;
    final statusIcon = status == 'naik'
        ? Icons.arrow_upward
        : status == 'lulus'
            ? Icons.school
            : Icons.remove_circle_outline;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.grey200),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(statusIcon, color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(k['siswa_nama']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    '${k['dari_kelas'] ?? '-'} → ${status == 'lulus' ? 'LULUS' : (k['ke_kelas'] ?? '-')}',
                    style: const TextStyle(color: AppTheme.grey500, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  WIZARD
  // ═══════════════════════════════════════════════════════════
  Widget _buildWizard() {
    return Column(
      children: [
        // Step Indicator
        _buildStepIndicator(),

        // Step Content
        Expanded(
          child: _wizardStep == 1
              ? _buildStep1()
              : _wizardStep == 2
                  ? _buildStep2()
                  : _wizardStep == 3
                      ? _buildStep3()
                      : _buildStep4(),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    final steps = _isLastLevel
      ? ['Pilih Kelas', 'Centang Siswa', 'Review']
      : ['Pilih Kelas', 'Centang Siswa', 'Pilih Tujuan', 'Review'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = _wizardStep - 1 == i;
          final isDone = _wizardStep - 1 > i;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone ? AppTheme.primary : AppTheme.grey200,
                    ),
                  ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppTheme.primary
                        : isActive
                            ? AppTheme.primary
                            : AppTheme.grey200,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : AppTheme.grey500,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    steps[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? AppTheme.primary : AppTheme.grey500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (i < steps.length - 1) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Step 1: Pilih Kelas Asal ──
  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Langkah 1: Pilih Kelas Asal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Pilih kelas yang siswanya akan diproses kenaikan kelas.', style: TextStyle(color: AppTheme.grey500, fontSize: 13)),
          const SizedBox(height: 20),

          // Tahun Ajaran
          DropdownButtonFormField<String>(
            value: _selectedTahunAjaranId,
            decoration: InputDecoration(
              labelText: 'Tahun Ajaran',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: _tahunAjaranList.map((t) => DropdownMenuItem(
              value: t['id'].toString(),
              child: Text(t['nama']?.toString() ?? '-'),
            )).toList(),
            onChanged: (v) => setState(() => _selectedTahunAjaranId = v),
          ),
          const SizedBox(height: 16),

          // Kelas
          DropdownButtonFormField<String>(
            value: _selectedKelasId,
            decoration: InputDecoration(
              labelText: 'Kelas Asal',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: _kelasList.map((k) => DropdownMenuItem(
              value: k['id'].toString(),
              child: Text(k['nama']?.toString() ?? '-'),
            )).toList(),
            onChanged: (v) => setState(() => _selectedKelasId = v),
          ),
          const Spacer(),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _wizardStep = 0),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _loadingBatch ? null : _proceedToStep2,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _loadingBatch
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Lihat Siswa'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Step 2: Centang Siswa ──
  Widget _buildStep2() {
    final minAbsensi = double.tryParse(_minAbsensiCtrl.text) ?? 75;
    final minNilai = double.tryParse(_minNilaiCtrl.text) ?? 60;

    return Column(
      children: [
        // Info Bar
        Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.blueLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.blue, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Batas minimum: Absensi ≥ ${minAbsensi.toInt()}% | Nilai ≥ ${minNilai.toInt()} | Dipilih: ${_selectedSiswaIds.length} dari ${_calonSiswa.length}',
                  style: const TextStyle(color: AppTheme.grey700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        // Select All
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Checkbox(
                value: _selectedSiswaIds.length == _calonSiswa.length && _calonSiswa.isNotEmpty,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedSiswaIds = _calonSiswa.map((s) => s['id'] as int).toSet();
                    } else {
                      _selectedSiswaIds.clear();
                    }
                  });
                },
                activeColor: AppTheme.primary,
              ),
              const Text('Pilih Semua', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),

        // Table
        Expanded(
          child: _loadingBatch
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : _calonSiswa.isEmpty
                  ? const Center(child: Text('Tidak ada siswa aktif di kelas ini'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(AppTheme.grey50),
                          headingTextStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.grey700),
                          dataTextStyle: const TextStyle(fontSize: 12, color: AppTheme.grey800),
                          horizontalMargin: 20,
                          columns: const [
                            DataColumn(label: Text('☐')),
                            DataColumn(label: Text('Nama')),
                            DataColumn(label: Text('A%')),
                            DataColumn(label: Text('B%')),
                            DataColumn(label: Text('C%')),
                            DataColumn(label: Text('D%')),
                            DataColumn(label: Text('Rata2')),
                            DataColumn(label: Text('Absen%')),
                          ],
                          rows: _calonSiswa.map((s) {
                            final id = s['id'] as int;
                            final nilai = s['nilai'] as Map<String, dynamic>? ?? {};
                            final absensi = s['absensi'] as Map<String, dynamic>? ?? {};
                            final isSelected = _selectedSiswaIds.contains(id);
                            final persenHadir = (absensi['persen_hadir'] ?? 0) as num;
                            final rataNilai = (nilai['rata_rata_nilai'] ?? 0) as num;
                            final memenuhi = persenHadir >= minAbsensi && rataNilai >= minNilai;

                            return DataRow(
                              selected: isSelected,
                              color: WidgetStateProperty.all(
                                !memenuhi ? AppTheme.redLight.withValues(alpha: 0.3) : null,
                              ),
                              cells: [
                                DataCell(
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true) {
                                          _selectedSiswaIds.add(id);
                                        } else {
                                          _selectedSiswaIds.remove(id);
                                          _siswaKelasTujuan.remove(id);
                                        }
                                      });
                                    },
                                    activeColor: AppTheme.primary,
                                  ),
                                ),
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s['nama']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                      Text('NIS: ${s['nis'] ?? '-'}', style: const TextStyle(color: AppTheme.grey500, fontSize: 10)),
                                    ],
                                  ),
                                ),
                                DataCell(_buildPersenChip(nilai['persen_a'] ?? 0, AppTheme.primary)),
                                DataCell(_buildPersenChip(nilai['persen_b'] ?? 0, AppTheme.blue)),
                                DataCell(_buildPersenChip(nilai['persen_c'] ?? 0, AppTheme.orange)),
                                DataCell(_buildPersenChip(nilai['persen_d'] ?? 0, AppTheme.error)),
                                DataCell(Text('$rataNilai', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: persenHadir >= minAbsensi ? AppTheme.primaryLight : AppTheme.redLight,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text('$persenHadir%', style: TextStyle(
                                      color: persenHadir >= minAbsensi ? AppTheme.primaryDark : AppTheme.error,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    )),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
        ),

        // Buttons
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _wizardStep = 1),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Kembali'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _selectedSiswaIds.isEmpty ? null : (_isLastLevel ? _proceedToStep4 : _proceedToStep3),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(_isLastLevel ? 'Review & Proses' : 'Pilih Kelas Tujuan'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersenChip(dynamic value, Color color) {
    final v = (value as num?) ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$v%', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  // ── Step 3: Pilih Kelas Tujuan ──
  Widget _buildStep3() {
    final selectedList = _calonSiswa.where((s) => _selectedSiswaIds.contains(s['id'] as int)).toList();

    return Column(
      children: [
        // Header
        Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.school, color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pilih kelas tujuan untuk ${selectedList.length} siswa yang dipilih',
                  style: const TextStyle(color: AppTheme.grey700, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),

        // Siswa List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: selectedList.length,
            itemBuilder: (_, i) {
              final s = selectedList[i];
              final siswaId = s['id'] as int;
              final nilai = s['nilai'] as Map<String, dynamic>? ?? {};

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.grey200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Info Siswa
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['nama']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildMiniChip('A: ${nilai['persen_a'] ?? 0}%', AppTheme.primary),
                                const SizedBox(width: 4),
                                _buildMiniChip('B: ${nilai['persen_b'] ?? 0}%', AppTheme.blue),
                                const SizedBox(width: 4),
                                _buildMiniChip('Rata2: ${nilai['rata_rata_nilai'] ?? 0}', AppTheme.grey600),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Dropdown Kelas Tujuan
                      SizedBox(
                        width: 140,
                        child: DropdownButtonFormField<int>(
                          value: _siswaKelasTujuan[siswaId],
                          decoration: InputDecoration(
                            hintText: 'Pilih kelas',
                            hintStyle: const TextStyle(color: AppTheme.grey400, fontSize: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 12, color: AppTheme.grey800),
                          items: _kelasTujuan.map((k) => DropdownMenuItem(
                            value: k['id'] as int,
                            child: Text(k['nama']?.toString() ?? '-', style: const TextStyle(fontSize: 12)),
                          )).toList(),
                          onChanged: (v) {
                            setState(() {
                              if (v != null) {
                                _siswaKelasTujuan[siswaId] = v;
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Buttons
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _wizardStep = 2),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Kembali'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _siswaKelasTujuan.length == selectedList.length ? _proceedToStep4 : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Review & Proses'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  // ── Step 4: Review ──
  Widget _buildStep4() {
    final selectedList = _calonSiswa.where((s) => _selectedSiswaIds.contains(s['id'] as int)).toList();
    final notSelectedList = _calonSiswa.where((s) => !_selectedSiswaIds.contains(s['id'] as int)).toList();

    // Group by kelas tujuan
    final Map<String, List<Map<String, dynamic>>> groupedByKelas = {};
    for (final s in selectedList) {
      final siswaId = s['id'] as int;
      final kelasId = _siswaKelasTujuan[siswaId];
      final kelasNama = _kelasTujuan.firstWhere(
        (k) => k['id'] == kelasId,
        orElse: () => {'nama': _isLastLevel ? 'ALUMNI' : '???'},
      )['nama']?.toString() ?? '???';
      groupedByKelas.putIfAbsent(kelasNama, () => []).add(s);
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _buildSummaryItem('Dipilih', '${selectedList.length}', Icons.check_circle, Colors.white),
                      const SizedBox(width: 24),
                      _buildSummaryItem('Tidak Naik', '${notSelectedList.length}', Icons.cancel, Colors.white),
                      const SizedBox(width: 24),
                      _buildSummaryItem('Kelas', '${groupedByKelas.length}', Icons.school, Colors.white),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Per Kelas Tujuan
                if (!_isLastLevel) ...[
                  const Text('Distribusi per Kelas Tujuan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  ...groupedByKelas.entries.map((e) {
                    final avg = e.value.isEmpty
                        ? 0.0
                        : e.value.map((s) => ((s['nilai'] as Map?)?['rata_rata_nilai'] ?? 0) as num).reduce((a, b) => a + b) / e.value.length;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.school, color: AppTheme.primary, size: 20),
                        ),
                        title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${e.value.length} siswa | Rata-rata: ${avg.toStringAsFixed(1)}'),
                      ),
                    );
                  }),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.blueLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.school, color: AppTheme.blue, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Kelas XII → Semua siswa yang dipilih akan menjadi ALUMNI',
                            style: TextStyle(color: AppTheme.grey700, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Siswa Tidak Naik
                if (notSelectedList.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Siswa Tidak Naik Kelas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: notSelectedList.map((s) => Chip(
                      label: Text(s['nama']?.toString() ?? '-', style: const TextStyle(fontSize: 11)),
                      backgroundColor: AppTheme.redLight,
                      labelStyle: const TextStyle(color: AppTheme.error),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Buttons
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _wizardStep = _isLastLevel ? 2 : 3),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Kembali'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _loadingBatch ? null : _submitBatch,
                  icon: _loadingBatch
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle, size: 18),
                  label: Text(_loadingBatch ? 'Memproses...' : 'Proses Kenaikan Kelas'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 11)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  TAB: ALUMNI
  // ═══════════════════════════════════════════════════════════
  Widget _buildAlumniTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _showFormAlumni,
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Tambah Alumni'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _searchAlumniCtrl,
            decoration: InputDecoration(
              hintText: 'Cari nama atau NIS...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchAlumniCtrl.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchAlumniCtrl.clear(); _load(); })
                : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              isDense: true,
            ),
            onSubmitted: (_) => _load(),
          ),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: _alumni.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school, size: 48, color: AppTheme.grey300),
                      SizedBox(height: 12),
                      Text('Belum ada data alumni', style: TextStyle(color: AppTheme.grey500, fontSize: 14)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _alumni.length,
                  itemBuilder: (_, i) {
                    final a = _alumni[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.grey200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppTheme.blueLight, borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.school, color: AppTheme.blue, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a['siswa_nama']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text('NIS: ${a['nis'] ?? '-'} | Lulus: ${a['tahun_lulus'] ?? '-'}', style: const TextStyle(color: AppTheme.grey500, fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                              onPressed: () => _confirmDeleteAlumni(a),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Pagination
        if (_alumniTotalPages > 1)
          _buildPagination(
            currentPage: _alumniPage,
            totalPages: _alumniTotalPages,
            onPageChanged: (page) { _alumniPage = page; _load(); },
          ),
      ],
    );
  }

  Future<void> _showFormAlumni() async {
    final tahunLulusCtrl = TextEditingController();
    final kontakCtrl = TextEditingController();
    int? selectedSiswaId;
    List<Map<String, dynamic>> calonAlumniList = [];

    try {
      final result = await WakilKurikulumService.getCalonAlumni();
      calonAlumniList = List<Map<String, dynamic>>.from(result);
    } catch (e) {
      if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat data siswa');
      return;
    }

    if (!mounted) return;
    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Tambah Alumni'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<int>(
              value: selectedSiswaId,
              decoration: InputDecoration(
                labelText: 'Pilih Siswa',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: calonAlumniList.map((s) => DropdownMenuItem(
                value: s['id'] as int,
                child: Text('${s['nama']} (${s['nis'] ?? '-'})', style: const TextStyle(fontSize: 13)),
              )).toList(),
              onChanged: (v) => setD(() => selectedSiswaId = v),
            ),
            const SizedBox(height: 12),
            TextField(controller: tahunLulusCtrl,
                decoration: InputDecoration(labelText: 'Tahun Lulus', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 12),
            TextField(controller: kontakCtrl,
                decoration: InputDecoration(labelText: 'Kontak', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: selectedSiswaId == null ? null : () async {
                try {
                  await WakilKurikulumService.createAlumni({
                    'siswa_id': selectedSiswaId,
                    'tahun_lulus': tahunLulusCtrl.text,
                    'kontak': kontakCtrl.text,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } catch (e) { if (ctx.mounted) AppUtils.handleError(ctx, e, message: 'Gagal menyimpan alumni'); }
              },
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAlumni(Map<String, dynamic> a) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Alumni'),
        content: Text('Hapus data alumni ${a['siswa_nama']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              try {
                await ApiClient.delete('/wakil-kurikulum/alumni/${a['id']}');
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              } catch (e) { if (ctx.mounted) AppUtils.handleError(ctx, e, message: 'Gagal menghapus alumni'); }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  PENGATURAN DIALOG
  // ═══════════════════════════════════════════════════════════
  Future<void> _showPengaturanDialog() async {
    await _loadReferensi();
    String? selectedTaId;

    if (!mounted) return;
    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Pengaturan Kenaikan Kelas'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            // Tahun Ajaran
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Tahun Ajaran',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: _tahunAjaranList.map((t) => DropdownMenuItem(
                value: t['id'].toString(),
                child: Text(t['nama']?.toString() ?? '-'),
              )).toList(),
              onChanged: (v) async {
                selectedTaId = v;
                if (v != null) {
                  try {
                    final data = await WakilKurikulumService.getPengaturanKenaikan(int.parse(v));
                    setD(() {
                      _minAbsensiCtrl.text = (data['min_absensi_persen'] ?? 75).toString();
                      _minNilaiCtrl.text = (data['min_nilai_akhir'] ?? 60).toString();
                    });
                  } catch (e) {
                    if (ctx.mounted) AppUtils.handleError(ctx, e, message: 'Gagal memuat pengaturan kenaikan');
                  }
                }
              },
            ),
            const SizedBox(height: 16),

            // Min Absensi
            TextField(
              controller: _minAbsensiCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Minimum Absensi (%)',
                hintText: '75',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixText: '%',
              ),
            ),
            const SizedBox(height: 12),

            // Min Nilai
            TextField(
              controller: _minNilaiCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Minimum Rata-rata Nilai',
                hintText: '60',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: selectedTaId == null
                  ? null
                  : () async {
                      try {
                        await WakilKurikulumService.savePengaturanKenaikan({
                          'tahun_ajaran_id': int.parse(selectedTaId!),
                          'min_absensi_persen': double.tryParse(_minAbsensiCtrl.text) ?? 75,
                          'min_nilai_akhir': double.tryParse(_minNilaiCtrl.text) ?? 60,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan berhasil disimpan')));
                      } catch (e) {
                        if (ctx.mounted) AppUtils.handleError(ctx, e, message: 'Gagal menyimpan pengaturan');
                      }
                    },
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination({required int currentPage, required int totalPages, required Function(int) onPageChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
          ),
          ...List.generate(totalPages > 5 ? 5 : totalPages, (i) {
            int pageNum;
            if (totalPages <= 5) {
              pageNum = i + 1;
            } else if (currentPage <= 3) {
              pageNum = i + 1;
            } else if (currentPage >= totalPages - 2) {
              pageNum = totalPages - 4 + i;
            } else {
              pageNum = currentPage - 2 + i;
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                onTap: () => onPageChanged(pageNum),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: pageNum == currentPage ? AppTheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$pageNum',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: pageNum == currentPage ? FontWeight.w600 : FontWeight.normal,
                      color: pageNum == currentPage ? Colors.white : AppTheme.grey600,
                    ),
                  ),
                ),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
          ),
        ],
      ),
    );
  }
}
