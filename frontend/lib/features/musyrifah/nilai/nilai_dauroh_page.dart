import 'package:flutter/material.dart';
import '../../../core/utils/dauroh_pdf_export.dart';
import '../services/musyrifah_service.dart';

class NilaiDaurohPage extends StatefulWidget {
  const NilaiDaurohPage({super.key});

  @override
  State<NilaiDaurohPage> createState() => _NilaiDaurohPageState();
}

class _NilaiDaurohPageState extends State<NilaiDaurohPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  // Filters
  final _searchCtrl = TextEditingController();
  String? _filterStatus;
  String? _filterProgram;
  List<Map<String, dynamic>> _programs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await MusyrifahService.listNilai(
        programId: _filterProgram,
        search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
        status: _filterStatus,
      );
      // Build unique program list: gabungkan dengan daftar lama agar
      // tidak hilang saat filter aktif
      final Map<String, Map<String, dynamic>> progMap = {};
      for (final p in _programs) {
        progMap[p['id']?.toString() ?? ''] = p;
      }
      for (final item in data) {
        final pid = item['program_id']?.toString() ?? '';
        if (pid.isNotEmpty && !progMap.containsKey(pid)) {
          progMap[pid] = {
            'id': pid,
            'nama': item['nama_program'] ?? 'Program',
          };
        }
      }
      setState(() {
        _items = data;
        _programs = progMap.values.toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openDialog({Map<String, dynamic>? existing}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _InputNilaiDialog(
        existing: existing,
      ),
    );
    if (result == true) {
      _load();
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'selesai':
        return const Color(0xFF9C6644);
      case 'melanjutkan':
        return Colors.blue;
      case 'mengulang':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'selesai':
        return 'Selesai';
      case 'melanjutkan':
        return 'Melanjutkan';
      case 'mengulang':
        return 'Mengulang';
      default:
        return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nilai at-Ta\'wid'),
        automaticallyImplyLeading: false,
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Export Semua ke PDF',
              onPressed: () => DaurohPdfExport.exportBatch(
                _items,
                title: 'Laporan Penilaian at-Ta\'wid',
              ),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Input Nilai Baru',
            onPressed: () => _openDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(
                bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Cari nama santri...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    _load();
                                  },
                                )
                              : null,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onSubmitted: (_) => _load(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        value: _filterStatus,
                        isDense: true,
                        decoration: InputDecoration(
                          hintText: 'Status',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('Semua Status'),
                          ),
                          DropdownMenuItem(
                            value: 'mengulang',
                            child: Text('Mengulang'),
                          ),
                          DropdownMenuItem(
                            value: 'melanjutkan',
                            child: Text('Melanjutkan'),
                          ),
                          DropdownMenuItem(
                            value: 'selesai',
                            child: Text('Selesai'),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _filterStatus = v);
                          _load();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        value: _filterProgram,
                        isDense: true,
                        decoration: InputDecoration(
                          hintText: 'Program',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Semua Program'),
                          ),
                          ..._programs.map(
                            (p) => DropdownMenuItem(
                              value: p['id']?.toString(),
                              child: Text(p['nama'] ?? ''),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _filterProgram = v);
                          _load();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!,
                                style: TextStyle(color: theme.colorScheme.error)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _load,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    : _items.isEmpty
                        ? const Center(child: Text('Tidak ada data nilai'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _items.length,
                              itemBuilder: (ctx, i) =>
                                  _buildCard(_items[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final status = item['status_hafalan']?.toString();
    final totalNilai = (item['total_nilai'] as num?)?.toDouble() ?? 0;
    final b1 = (item['nilai_bidang1'] as num?)?.toDouble() ?? 0;
    final b2 = (item['nilai_bidang2'] as num?)?.toDouble() ?? 0;
    final b3 = (item['nilai_bidang3'] as num?)?.toDouble() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openDialog(existing: item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['santri_nama'] ?? '-',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'NIS: ${item['nis'] ?? '-'}  •  ${item['kelas_nama'] ?? '-'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildStatChip('Program', item['nama_program'] ?? '-'),
                  const SizedBox(width: 8),
                  _buildStatChip(
                      'Surat', '${item['surat_nama'] ?? '-'} (${item['dari_ayat'] ?? '-'}-${item['sampai_ayat'] ?? '-'})'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _scoreCircle('B1', b1, _maxOf(item, 'max_bidang1', 40), theme),
                  const SizedBox(width: 8),
                  _scoreCircle('B2', b2, _maxOf(item, 'max_bidang2', 30), theme),
                  const SizedBox(width: 8),
                  _scoreCircle('B3', b3, _maxOf(item, 'max_bidang3', 30), theme),
                  const Spacer(),
                  _totalBadge(totalNilai, theme),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    tooltip: 'Export PDF',
                    onPressed: () => DaurohPdfExport.exportNilaiPerSantri(item),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
              if (item['musyrifah_nama'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Oleh: ${item['musyrifah_nama']}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _scoreCircle(String label, double value, double max, ThemeData theme) {
    final pct = max > 0 ? value / max : 0.0;
    final color = pct >= 0.8
        ? const Color(0xFF9C6644)
        : pct >= 0.6
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w600),
          ),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  double _maxOf(Map<String, dynamic> item, String key, double fallback) {
    final v = item[key];
    if (v == null) return fallback;
    final n = double.tryParse(v.toString());
    return (n == null || n <= 0) ? fallback : n;
  }

  Widget _totalBadge(double total, ThemeData theme) {
    final color = total >= 80
        ? const Color(0xFF9C6644)
        : total >= 60
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'TOTAL',
            style: TextStyle(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600),
          ),
          Text(
            total.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Input Dialog
// ---------------------------------------------------------------------------

class _InputNilaiDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;

  const _InputNilaiDialog({this.existing});

  @override
  State<_InputNilaiDialog> createState() => _InputNilaiDialogState();
}

class _InputNilaiDialogState extends State<_InputNilaiDialog> {
  bool _saving = false;
  bool _loadingDetail = false;
  String? _detailError;

  // Surat
  List<Map<String, dynamic>> _suratList = [];
  int? _selectedSuratNomor;
  String? _selectedSuratNama;
  int _jumlahAyat = 0;

  // Program list for new input
  List<Map<String, dynamic>> _programList = [];
  String? _selectedProgramId;

  // Santri list for new input
  List<Map<String, dynamic>> _santriList = [];
  String? _selectedSantriId;

  // Jadwal list for new input
  List<Map<String, dynamic>> _jadwalList = [];
  String? _selectedJadwalId;

  // Form fields
  String? _statusHafalan;
  int _dariAyat = 1;
  int _sampaiAyat = 1;

  // Bidang 1: Kelancaran Hafalan (deductions 1-5)
  int _kelancaran = 1;
  int _ketepatanAyat = 1;
  int _murojaahSambung = 1;
  int _konsistensiHafalan = 1;
  String _catatanBidang1 = '';

  // Bidang 2: Tajwid (deductions 1-5)
  int _makhorijulHuruf = 1;
  int _sifatulHuruf = 1;
  int _ahkamulHuruf = 1;
  int _ahkamulMadd = 1;
  String _catatanBidang2 = '';

  // Bidang 3: Fashohah dan Adab (deductions 1-5)
  int _ahkamulWaqfi = 1;
  int _adabutTilawah = 1;
  int _kerapihanBacaan = 1;
  int _ketepatanTempo = 1;
  String _catatanBidang3 = '';

  // General
  String _catatanUmum = '';
  String _rencanaTindakLanjut = '';

  // Konfigurasi program (label & max per bidang)
  int _maxBidang1 = 40;
  int _maxBidang2 = 30;
  int _maxBidang3 = 30;
  String _labelBidang1 = 'Kelancaran Hafalan';
  String _labelBidang2 = 'Tajwid';
  String _labelBidang3 = 'Fashohah dan Adab';

  // Controllers
  final _dariAyatCtrl = TextEditingController(text: '1');
  final _sampaiAyatCtrl = TextEditingController(text: '1');
  final _catatan1Ctrl = TextEditingController();
  final _catatan2Ctrl = TextEditingController();
  final _catatan3Ctrl = TextEditingController();
  final _catatanUmumCtrl = TextEditingController();
  final _rtlCtrl = TextEditingController();

  // Surat search
  final _suratSearchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filteredSurat = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _dariAyatCtrl.dispose();
    _sampaiAyatCtrl.dispose();
    _catatan1Ctrl.dispose();
    _catatan2Ctrl.dispose();
    _catatan3Ctrl.dispose();
    _catatanUmumCtrl.dispose();
    _rtlCtrl.dispose();
    _suratSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    // Load surat list
    try {
      final surat = await MusyrifahService.listSurat();
      setState(() {
        _suratList = surat;
        _filteredSurat = surat;
      });
    } catch (_) {}

    // Load programs for new input (dari jadwal yang diampu, agar nilai pertama bisa diinput)
    if (widget.existing == null) {
      try {
        final jadwalData = await MusyrifahService.getJadwal();
        final Map<String, Map<String, dynamic>> progMap = {};
        for (final item in jadwalData) {
          final pid = item['program_id']?.toString() ?? '';
          if (pid.isNotEmpty && !progMap.containsKey(pid)) {
            progMap[pid] = {
              'id': pid,
              'nama': item['nama_program'] ?? 'Program',
              'max_bidang1': item['max_bidang1'],
              'max_bidang2': item['max_bidang2'],
              'max_bidang3': item['max_bidang3'],
              'label_bidang1': item['label_bidang1'],
              'label_bidang2': item['label_bidang2'],
              'label_bidang3': item['label_bidang3'],
            };
          }
        }
        setState(() {
          _jadwalList = jadwalData;
          _programList = progMap.values.toList();
        });
      } catch (_) {}
    }

    // If editing, load detail
    if (widget.existing != null) {
      _applyProgramConfig(widget.existing!);
      await _loadDetail();
    }
  }

  int _configMax(dynamic v, int fallback) {
    if (v == null) return fallback;
    final n = int.tryParse(v.toString());
    return (n == null || n <= 0) ? fallback : n;
  }

  void _applyProgramConfig(Map<String, dynamic> p) {
    setState(() {
      _maxBidang1 = _configMax(p['max_bidang1'], 40);
      _maxBidang2 = _configMax(p['max_bidang2'], 30);
      _maxBidang3 = _configMax(p['max_bidang3'], 30);
      _labelBidang1 = p['label_bidang1']?.toString() ?? 'Kelancaran Hafalan';
      _labelBidang2 = p['label_bidang2']?.toString() ?? 'Tajwid';
      _labelBidang3 = p['label_bidang3']?.toString() ?? 'Fashohah dan Adab';
    });
  }

  Future<void> _loadDetail() async {
    final id = widget.existing!['id'];
    if (id == null) return;
    setState(() {
      _loadingDetail = true;
      _detailError = null;
    });
    try {
      final detail = await MusyrifahService.getNilaiDetail(id);
      setState(() {
        _selectedSuratNomor = detail['surat_nomor'] as int?;
        _selectedSuratNama = detail['surat_nama']?.toString();
        _jumlahAyat = detail['jumlah_ayat'] as int? ?? 0;
        _statusHafalan = detail['status_hafalan']?.toString();
        _dariAyat = detail['dari_ayat'] as int? ?? 1;
        _sampaiAyat = detail['sampai_ayat'] as int? ?? 1;
        _dariAyatCtrl.text = _dariAyat.toString();
        _sampaiAyatCtrl.text = _sampaiAyat.toString();

        _kelancaran = detail['kelancaran'] as int? ?? 1;
        _ketepatanAyat = detail['ketepatan_ayat'] as int? ?? 1;
        _murojaahSambung = detail['murojaah_sambung'] as int? ?? 1;
        _konsistensiHafalan = detail['konsistensi_hafalan'] as int? ?? 1;
        _catatanBidang1 = detail['catatan_bidang1']?.toString() ?? '';
        _catatan1Ctrl.text = _catatanBidang1;

        _makhorijulHuruf = detail['makhorijul_huruf'] as int? ?? 1;
        _sifatulHuruf = detail['sifatul_huruf'] as int? ?? 1;
        _ahkamulHuruf = detail['ahkamul_huruf'] as int? ?? 1;
        _ahkamulMadd = detail['ahkamul_madd'] as int? ?? 1;
        _catatanBidang2 = detail['catatan_bidang2']?.toString() ?? '';
        _catatan2Ctrl.text = _catatanBidang2;

        _ahkamulWaqfi = detail['ahkamul_waqfi'] as int? ?? 1;
        _adabutTilawah = detail['adabut_tilawah'] as int? ?? 1;
        _kerapihanBacaan = detail['kerapihan_bacaan'] as int? ?? 1;
        _ketepatanTempo = detail['ketepatan_tempo'] as int? ?? 1;
        _catatanBidang3 = detail['catatan_bidang3']?.toString() ?? '';
        _catatan3Ctrl.text = _catatanBidang3;

        _catatanUmum = detail['catatan_umum']?.toString() ?? '';
        _catatanUmumCtrl.text = _catatanUmum;
        _rencanaTindakLanjut = detail['rencana_tindak_lanjut']?.toString() ?? '';
        _rtlCtrl.text = _rencanaTindakLanjut;

        _selectedJadwalId = detail['jadwal_id']?.toString();
      });
    } catch (e) {
      setState(() => _detailError = e.toString());
    }
    setState(() => _loadingDetail = false);
  }

  void _filterSurat(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSurat = _suratList;
      } else {
        _filteredSurat = _suratList
            .where((s) =>
                (s['nama']?.toString().toLowerCase() ?? '')
                    .contains(query.toLowerCase()) ||
                (s['nomor']?.toString() ?? '').contains(query))
            .toList();
      }
    });
  }

  double get _totalBidang1 =>
      (_kelancaran + _ketepatanAyat + _murojaahSambung + _konsistensiHafalan)
          .toDouble();

  double get _totalBidang2 =>
      (_makhorijulHuruf + _sifatulHuruf + _ahkamulHuruf + _ahkamulMadd)
          .toDouble();

  double get _totalBidang3 =>
      (_ahkamulWaqfi + _adabutTilawah + _kerapihanBacaan + _ketepatanTempo)
          .toDouble();

  double get _nilaiBidang1 => 40.0 - (_totalBidang1 - 4);
  double get _nilaiBidang2 => 30.0 - (_totalBidang2 - 4);
  double get _nilaiBidang3 => 30.0 - (_totalBidang3 - 4);
  double get _totalNilai => _nilaiBidang1 + _nilaiBidang2 + _nilaiBidang3;

  Future<void> _save() async {
    if (_selectedSuratNomor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih surat terlebih dahulu')),
      );
      return;
    }
    if (_statusHafalan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih status hafalan')),
      );
      return;
    }
    if (widget.existing == null && _selectedSantriId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih santri terlebih dahulu')),
      );
      return;
    }
    if (widget.existing == null && _selectedProgramId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih program terlebih dahulu')),
      );
      return;
    }

    final dariAyat = int.tryParse(_dariAyatCtrl.text) ?? 1;
    final sampaiAyat = int.tryParse(_sampaiAyatCtrl.text) ?? 1;

    if (sampaiAyat < dariAyat) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sampai ayat harus >= dari ayat')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final params = {
        'suratNomor': _selectedSuratNomor,
        'statusHafalan': _statusHafalan,
        'jadwalId': _selectedJadwalId,
        'dariAyat': dariAyat,
        'sampaiAyat': sampaiAyat,
        'kelancaran': _kelancaran,
        'ketepatanAyat': _ketepatanAyat,
        'murojaahSambung': _murojaahSambung,
        'konsistensiHafalan': _konsistensiHafalan,
        'catatanBidang1': _catatan1Ctrl.text,
        'makhorijulHuruf': _makhorijulHuruf,
        'sifatulHuruf': _sifatulHuruf,
        'ahkamulHuruf': _ahkamulHuruf,
        'ahkamulMadd': _ahkamulMadd,
        'catatanBidang2': _catatan2Ctrl.text,
        'ahkamulWaqfi': _ahkamulWaqfi,
        'adabutTilawah': _adabutTilawah,
        'kerapihanBacaan': _kerapihanBacaan,
        'ketepatanTempo': _ketepatanTempo,
        'catatanBidang3': _catatan3Ctrl.text,
        'catatanUmum': _catatanUmumCtrl.text,
        'rencanaTindakLanjut': _rtlCtrl.text,
      };

      if (widget.existing != null) {
        final id = widget.existing!['id'] as int;
        await MusyrifahService.updateNilai(
          id: id,
          suratNomor: params['suratNomor'] as int?,
          statusHafalan: params['statusHafalan'] as String?,
          jadwalId: params['jadwalId'] as int?,
          dariAyat: params['dariAyat'] as int?,
          sampaiAyat: params['sampaiAyat'] as int?,
          kelancaran: params['kelancaran'] as int?,
          ketepatanAyat: params['ketepatanAyat'] as int?,
          murojaahSambung: params['murojaahSambung'] as int?,
          konsistensiHafalan: params['konsistensiHafalan'] as int?,
          catatanBidang1: params['catatanBidang1'] as String?,
          makhorijulHuruf: params['makhorijulHuruf'] as int?,
          sifatulHuruf: params['sifatulHuruf'] as int?,
          ahkamulHuruf: params['ahkamulHuruf'] as int?,
          ahkamulMadd: params['ahkamulMadd'] as int?,
          catatanBidang2: params['catatanBidang2'] as String?,
          ahkamulWaqfi: params['ahkamulWaqfi'] as int?,
          adabutTilawah: params['adabutTilawah'] as int?,
          kerapihanBacaan: params['kerapihanBacaan'] as int?,
          ketepatanTempo: params['ketepatanTempo'] as int?,
          catatanBidang3: params['catatanBidang3'] as String?,
          catatanUmum: params['catatanUmum'] as String?,
          rencanaTindakLanjut: params['rencanaTindakLanjut'] as String?,
        );
      } else {
        await MusyrifahService.inputNilai(
          programId: int.parse(_selectedProgramId!),
          santriId: int.parse(_selectedSantriId!),
          suratNomor: params['suratNomor'] as int? ?? 0,
          statusHafalan: params['statusHafalan'] as String? ?? 'melanjutkan',
          jadwalId: _selectedJadwalId != null ? int.parse(_selectedJadwalId!) : null,
          dariAyat: params['dariAyat'] as int?,
          sampaiAyat: params['sampaiAyat'] as int?,
          kelancaran: params['kelancaran'] as int?,
          ketepatanAyat: params['ketepatanAyat'] as int?,
          murojaahSambung: params['murojaahSambung'] as int?,
          konsistensiHafalan: params['konsistensiHafalan'] as int?,
          catatanBidang1: params['catatanBidang1'] as String?,
          makhorijulHuruf: params['makhorijulHuruf'] as int?,
          sifatulHuruf: params['sifatulHuruf'] as int?,
          ahkamulHuruf: params['ahkamulHuruf'] as int?,
          ahkamulMadd: params['ahkamulMadd'] as int?,
          catatanBidang2: params['catatanBidang2'] as String?,
          ahkamulWaqfi: params['ahkamulWaqfi'] as int?,
          adabutTilawah: params['adabutTilawah'] as int?,
          kerapihanBacaan: params['kerapihanBacaan'] as int?,
          ketepatanTempo: params['ketepatanTempo'] as int?,
          catatanBidang3: params['catatanBidang3'] as String?,
          catatanUmum: params['catatanUmum'] as String?,
          rencanaTindakLanjut: params['rencanaTindakLanjut'] as String?,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existing != null
                  ? 'Nilai berhasil diperbarui'
                  : 'Nilai berhasil disimpan',
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existing != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.95;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
          horizontal: (screenWidth - dialogWidth) / 2, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.add_circle_outline,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Nilai at-Ta\'wid' : 'Input Nilai at-Ta\'wid',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),

            // Live total banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: theme.primaryColor.withValues(alpha: 0.06),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Nilai',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(
                    _totalNilai.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _totalNilai >= 80
                          ? const Color(0xFF7F5539)
                          : _totalNilai >= 60
                              ? Colors.orange[700]
                              : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),

            // Form content
            Expanded(
              child: _loadingDetail
                  ? const Center(child: CircularProgressIndicator())
                  : _detailError != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 40),
                                const SizedBox(height: 12),
                                Text(
                                  _detailError!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _loadDetail,
                                  child: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      children: [
                        // --- Program Selector (new input only) ---
                        if (!isEditing) ...[
                          DropdownButtonFormField<String>(
                            value: _selectedProgramId,
                            isDense: true,
                            decoration: _inputDecoration('Program *'),
                            items: _programList
                                .map((p) => DropdownMenuItem(
                                      value: p['id']?.toString(),
                                      child: Text(p['nama'] ?? ''),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedProgramId = v;
                                _selectedJadwalId = null;
                                _selectedSantriId = null;
                                _santriList = [];
                              });
                              if (v != null) {
                                final matches = _programList
                                    .where((e) => e['id']?.toString() == v)
                                    .toList();
                                if (matches.isNotEmpty) {
                                  _applyProgramConfig(matches.first);
                                }
                              }
                            },
                          ),
                          const SizedBox(height: 14),

                          // --- Jadwal Selector ---
                          DropdownButtonFormField<String>(
                            value: _selectedJadwalId,
                            isDense: true,
                            decoration: _inputDecoration('Jadwal *'),
                            items: _jadwalList
                                .where((j) => _selectedProgramId == null ||
                                    j['program_id']?.toString() ==
                                        _selectedProgramId)
                                .map((j) {
                              final hari = j['hari'] ?? '';
                              final jam = j['jam_mulai'] ?? '';
                              final namaKelas = j['kelas_nama'] ?? j['nama_kelas'] ?? '';
                              return DropdownMenuItem(
                                value: j['id']?.toString(),
                                child: Text('$hari $jam - $namaKelas'),
                              );
                            }).toList(),
                            onChanged: (v) async {
                              setState(() {
                                _selectedJadwalId = v;
                                _selectedSantriId = null;
                                _santriList = [];
                              });
                              if (v != null) {
                                try {
                                  final santri =
                                      await MusyrifahService.listSantriByJadwal(
                                          int.parse(v));
                                  setState(() => _santriList = santri);
                                } catch (_) {}
                              }
                            },
                          ),
                          const SizedBox(height: 14),

                          // --- Santri Selector ---
                          DropdownButtonFormField<String>(
                            value: _selectedSantriId,
                            isDense: true,
                            decoration: _inputDecoration('Santri *'),
                            items: _santriList
                                .map((s) => DropdownMenuItem(
                                      value: s['id']?.toString(),
                                      child: Text(s['nama'] ?? ''),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedSantriId = v),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // --- Surat Selector ---
                        if (isEditing)
                          _buildInfoRow(
                              'Surat', _selectedSuratNama ?? '-', theme)
                        else
                          _buildSuratDropdown(theme),
                        const SizedBox(height: 14),

                        // --- Status Hafalan ---
                        DropdownButtonFormField<String>(
                          value: _statusHafalan,
                          isDense: true,
                          decoration: _inputDecoration('Status Hafalan *'),
                          items: const [
                            DropdownMenuItem(
                                value: 'mengulang',
                                child: Text('Mengulang')),
                            DropdownMenuItem(
                                value: 'melanjutkan',
                                child: Text('Melanjutkan')),
                            DropdownMenuItem(
                                value: 'selesai', child: Text('Selesai')),
                          ],
                          onChanged: (v) =>
                              setState(() => _statusHafalan = v),
                        ),
                        const SizedBox(height: 14),

                        // --- Ayat Range ---
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _dariAyatCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration('Dari Ayat'),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('—', style: TextStyle(fontSize: 18)),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _sampaiAyatCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration('Sampai Ayat'),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // --- Bidang 1 ---
                        _buildExpansionBidang(
                          title: 'Bidang 1: $_labelBidang1',
                          subtitle:
                              'Nilai: ${_nilaiBidang1.toStringAsFixed(1)} / $_maxBidang1',
                          icon: Icons.auto_stories,
                          color: Colors.blue,
                          children: [
                            _buildDeductionField('Kelancaran', _kelancaran,
                                (v) => setState(() => _kelancaran = v)),
                            _buildDeductionField(
                                'Ketepatan Ayat',
                                _ketepatanAyat,
                                (v) => setState(() => _ketepatanAyat = v)),
                            _buildDeductionField(
                                'Muroja\'ah Sambung',
                                _murojaahSambung,
                                (v) => setState(() => _murojaahSambung = v)),
                            _buildDeductionField(
                                'Konsistensi Hafalan',
                                _konsistensiHafalan,
                                (v) =>
                                    setState(() => _konsistensiHafalan = v)),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _catatan1Ctrl,
                              maxLines: 2,
                              decoration:
                                  _inputDecoration('Catatan Bidang 1'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // --- Bidang 2 ---
                        _buildExpansionBidang(
                          title: 'Bidang 2: $_labelBidang2',
                          subtitle:
                              'Nilai: ${_nilaiBidang2.toStringAsFixed(1)} / $_maxBidang2',
                          icon: Icons.record_voice_over,
                          color: Colors.teal,
                          children: [
                            _buildDeductionField(
                                'Makhorijul Huruf',
                                _makhorijulHuruf,
                                (v) =>
                                    setState(() => _makhorijulHuruf = v)),
                            _buildDeductionField('Sifatul Huruf',
                                _sifatulHuruf, (v) {
                              setState(() => _sifatulHuruf = v);
                            }),
                            _buildDeductionField('Ahkamul Huruf',
                                _ahkamulHuruf, (v) {
                              setState(() => _ahkamulHuruf = v);
                            }),
                            _buildDeductionField(
                                'Ahkamul Madd',
                                _ahkamulMadd,
                                (v) => setState(() => _ahkamulMadd = v)),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _catatan2Ctrl,
                              maxLines: 2,
                              decoration:
                                  _inputDecoration('Catatan Bidang 2'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // --- Bidang 3 ---
                        _buildExpansionBidang(
                          title: 'Bidang 3: $_labelBidang3',
                          subtitle:
                              'Nilai: ${_nilaiBidang3.toStringAsFixed(1)} / $_maxBidang3',
                          icon: Icons.menu_book,
                          color: Colors.deepPurple,
                          children: [
                            _buildDeductionField('Ahkamul Waqfi',
                                _ahkamulWaqfi, (v) {
                              setState(() => _ahkamulWaqfi = v);
                            }),
                            _buildDeductionField('Adabut Tilawah',
                                _adabutTilawah, (v) {
                              setState(() => _adabutTilawah = v);
                            }),
                            _buildDeductionField('Kerapihan Bacaan',
                                _kerapihanBacaan, (v) {
                              setState(() => _kerapihanBacaan = v);
                            }),
                            _buildDeductionField(
                                'Ketepatan Tempo',
                                _ketepatanTempo,
                                (v) =>
                                    setState(() => _ketepatanTempo = v)),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _catatan3Ctrl,
                              maxLines: 2,
                              decoration:
                                  _inputDecoration('Catatan Bidang 3'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // --- General ---
                        TextField(
                          controller: _catatanUmumCtrl,
                          maxLines: 3,
                          decoration: _inputDecoration('Catatan Umum'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _rtlCtrl,
                          maxLines: 3,
                          decoration:
                              _inputDecoration('Rencana Tindak Lanjut'),
                        ),
                        const SizedBox(height: 20),

                        // --- Save Button ---
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isEditing ? 'Perbarui Nilai' : 'Simpan Nilai',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 2),
          Text(value,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSuratDropdown(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedSuratNama != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.book, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$_selectedSuratNama ($_jumlahAyat ayat)',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.blue[800]),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() {
                    _selectedSuratNomor = null;
                    _selectedSuratNama = null;
                    _jumlahAyat = 0;
                  }),
                ),
              ],
            ),
          )
        else ...[
          TextField(
            controller: _suratSearchCtrl,
            decoration: _inputDecoration('Cari Surat...'),
            onChanged: _filterSurat,
          ),
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _filteredSurat.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Tidak ditemukan',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredSurat.length,
                    itemBuilder: (ctx, i) {
                      final s = _filteredSurat[i];
                      final nomor = s['nomor'] as int? ?? 0;
                      final nama = s['nama']?.toString() ?? '';
                      final ayat = s['jumlah_ayat'] as int? ?? 0;
                      final juz = s['juz']?.toString() ?? '';
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                          child: Text('$nomor',
                              style: TextStyle(
                                  fontSize: 12, color: theme.primaryColor)),
                        ),
                        title: Text(nama,
                            style: const TextStyle(fontSize: 14)),
                        subtitle: Text('$ayat ayat  •  Juz $juz',
                            style: const TextStyle(fontSize: 11)),
                        onTap: () {
                          setState(() {
                            _selectedSuratNomor = nomor;
                            _selectedSuratNama = nama;
                            _jumlahAyat = ayat;
                            _suratSearchCtrl.clear();
                            _filteredSurat = _suratList;
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }

  Widget _buildExpansionBidang({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: Icon(icon, color: color, size: 22),
        title: Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        initiallyExpanded: true,
        children: children,
      ),
    );
  }

  Widget _buildDeductionField(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label,
                style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int>(
              value: value,
              isDense: true,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              items: List.generate(5, (i) {
                final v = i + 1;
                String txt;
                switch (v) {
                  case 1:
                    txt = '1 (Baik)';
                    break;
                  case 2:
                    txt = '2 (Cukup)';
                    break;
                  case 3:
                    txt = '3 (Kurang)';
                    break;
                  case 4:
                    txt = '4 (Buruk)';
                    break;
                  case 5:
                    txt = '5 (Sangat Buruk)';
                    break;
                  default:
                    txt = '$v';
                }
                return DropdownMenuItem(
                  value: v,
                  child: Text(txt, style: const TextStyle(fontSize: 12)),
                );
              }),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: _deductionColor(value).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '-$value',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _deductionColor(value),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _deductionColor(int v) {
    if (v <= 1) return const Color(0xFF9C6644);
    if (v <= 2) return Colors.blue;
    if (v <= 3) return Colors.orange;
    return Colors.red;
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}
