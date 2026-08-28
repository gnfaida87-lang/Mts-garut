import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/wakil_kurikulum_service.dart';
import '../../../shared/widgets/app_utils.dart';
part 'penjadwalan_dialogs.dart';


class PenjadwalanPage extends StatefulWidget {
  const PenjadwalanPage({super.key});

  @override
  State<PenjadwalanPage> createState() => _PenjadwalanPageState();
}

class _PenjadwalanPageState extends State<PenjadwalanPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  Map<String, dynamic>? _ref;
  bool _refLoading = true;
  String? _refError;
  List<Map<String, dynamic>> _jadwal = [];
  String? _jadwalError;
  List<Map<String, dynamic>> _jpSlots = [];
  bool _jadwalLoading = false;

  // Filters
  String? _filterTingkat;
  String? _filterGenre;
  String? _filterSemester;
  String? _selectedHari;

  // Kesiapan
  List<Map<String, dynamic>> _kesiapan = [];
  List<_KesiapanRowData> _kesiapanRows = [];
  bool _kesiapanLoading = false;

  // Wali Kelas
  List<Map<String, dynamic>> _waliKelas = [];
  bool _waliKelasLoading = false;

  static const _hariList = ['Sabtu', 'Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis'];
  static const _genreList = ['Pagi', 'Siang', 'Full Day'];

  // Kegiatan tetap
  List<Map<String, dynamic>> _kegiatanTetap = [];

  // Kelas gabungan
  List<Map<String, dynamic>> _kelasGabungan = [];

  static const List<Map<String, dynamic>> _defaultKegiatanTetap = [
    {'nama': 'Istirahat RG', 'tipe': 'istirahat'},
    {'nama': 'Istirahat UG', 'tipe': 'istirahat'},
    {'nama': 'Tahfidz & Tahsin', 'tipe': 'kegiatan'},
    {'nama': 'Murojaah', 'tipe': 'kegiatan'},
    {'nama': "Ba'at", 'tipe': 'kegiatan'},
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        if (_tabCtrl.index == 1) _loadKesiapan();
        if (_tabCtrl.index == 2) _loadWaliKelas();
      }
    });
    _selectedHari = _hariList.first;
    _loadRef();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRef() async {
    setState(() {
      _refLoading = true;
      _refError = null;
    });
    try {
      _ref = await WakilKurikulumService.getReferensi();
      _jpSlots = (await WakilKurikulumService.getJpSlots()).cast<Map<String, dynamic>>();
      _kegiatanTetap = _refList('kegiatan_tetap');
      if (_kegiatanTetap.isEmpty) _kegiatanTetap = _defaultKegiatanTetap;
      _kelasGabungan = _refList('kelas_gabungan');
    } catch (e) {
      _refError = 'Gagal memuat data referensi: $e';
    }
    if (mounted) setState(() => _refLoading = false);
    if (_refError == null) _loadJadwal();
  }

  Future<void> _loadJadwal() async {
    if (_filterSemester == null) return;
    setState(() {
      _jadwalLoading = true;
      _jadwalError = null;
    });
    try {
      final allKelas = _refList('kelas');
      final kelasLoop = _filterTingkat != null
          ? allKelas.where((k) => k['tingkat_id'].toString() == _filterTingkat).toList()
          : allKelas;

      final results = await Future.wait(kelasLoop.map((k) async {
        final kelasId = k['id'].toString();
        try {
          return await WakilKurikulumService.getJadwalPerKelas(kelasId, _filterSemester!);
        } catch (_) {
          return <dynamic>[];
        }
      }));

      final allJadwal = <Map<String, dynamic>>[];
      for (final r in results) {
        allJadwal.addAll(r.cast<Map<String, dynamic>>());
      }
      _jadwal = allJadwal;
    } catch (e) {
      _jadwal = [];
      _jadwalError = 'Gagal memuat jadwal: $e';
    }
    if (mounted) setState(() => _jadwalLoading = false);
  }

  Future<void> _loadKesiapan() async {
    if (_filterSemester == null) return;
    setState(() => _kesiapanLoading = true);
    try {
      _kesiapan = (await WakilKurikulumService.getKesiapan(int.parse(_filterSemester!)))
          .cast<Map<String, dynamic>>();
      _kesiapanRows = _kesiapan.map((k) => _KesiapanRowData.fromJson(k)).toList();
    } catch (_) {
      _kesiapan = [];
      _kesiapanRows = [];
    }
    if (mounted) setState(() => _kesiapanLoading = false);
  }

  Future<void> _loadWaliKelas() async {
    setState(() => _waliKelasLoading = true);
    try {
      _waliKelas = (await WakilKurikulumService.getWaliKelas())
          .cast<Map<String, dynamic>>();
    } catch (_) {
      _waliKelas = [];
    }
    if (mounted) setState(() => _waliKelasLoading = false);
  }

  List<Map<String, dynamic>> _refList(String key) =>
      (_ref?[key] as List?)?.cast<Map<String, dynamic>>() ?? [];

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â• MAIN BUILD â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab Bar
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
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Jadwal'),
              Tab(text: 'Kesiapan'),
              Tab(text: 'Wali Kelas'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _refLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : _refError != null
                  ? _buildErrorState(_refError!, _loadRef)
                  : TabBarView(controller: _tabCtrl, children: [
                      _buildJadwalTab(),
                      _buildKesiapanTab(),
                      _buildWaliKelasTab(),
                    ]),
        ),
      ],
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â• JADWAL TAB â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildJadwalTab() {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: _jadwalLoading
              ? const Center(child: CircularProgressIndicator())
              : _filterSemester == null
                  ? _buildEmptyState('Pilih semester terlebih dahulu')
                  : _jadwalError != null
                      ? _buildErrorState(_jadwalError!, _loadJadwal)
                      : _buildTwoColumnLayout(),
        ),
      ],
    );
  }

  // â”€â”€ Toolbar â”€â”€

  Widget _buildToolbar() {
    final tingkat = _refList('tingkat');
    final sem = _refList('semester');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Pilih Tingkat
          _buildDropdown(
            items: tingkat,
            value: _filterTingkat,
            hint: 'Pilih Tingkat',
            width: 150,
            onChanged: (v) {
              setState(() {
                _filterTingkat = v;
                _jadwal = [];
              });
              _loadJadwal();
            },
          ),
          // Genre Jadwal
          _buildGenreDropdown(),
          // Semester
          _buildDropdown(
            items: sem,
            value: _filterSemester,
            hint: 'Semester',
            width: 180,
            onChanged: (v) {
              setState(() => _filterSemester = v);
              _loadJadwal();
            },
          ),
          // Hari
          _buildHariDropdown(),
          // Generate
          _buildActionBtn(
            icon: Icons.auto_awesome,
            label: 'Generate',
            color: Colors.teal,
            onPressed: _filterSemester != null ? _generateJadwal : null,
          ),
          // Publikasi
          _buildActionBtn(
            icon: Icons.publish,
            label: 'Publikasi',
            color: const Color(0xFF9C6644),
            onPressed: _filterSemester != null ? _publikasiJadwal : null,
          ),
          // Unpublikasi
          _buildActionBtn(
            icon: Icons.unpublished_outlined,
            label: 'Unpublikasi',
            color: Colors.brown,
            onPressed: _filterSemester != null ? _unpublikasiJadwal : null,
          ),
          // Reset
          _buildActionBtn(
            icon: Icons.undo,
            label: 'Reset',
            color: Colors.red,
            onPressed: _resetJadwal,
          ),
          // Kelas Gabungan
          _buildActionBtn(
            icon: Icons.group_work_outlined,
            label: 'Gabungan',
            color: Colors.indigo,
            onPressed: _kelolaGabungan,
          ),
          // Simpan
          _buildActionBtn(
            icon: Icons.save_outlined,
            label: 'Simpan',
            color: AppTheme.primary,
            onPressed: _simpanJadwal,
          ),
        ],
      ),
    );
  }

  Widget _buildGenreDropdown() {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterGenre,
          hint: const Text('Genre Jadwal', style: TextStyle(fontSize: 13)),
          isExpanded: true,
          items: _genreList.map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) => setState(() => _filterGenre = v),
        ),
      ),
    );
  }

  Widget _buildHariDropdown() {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedHari,
          hint: const Text('Hari', style: TextStyle(fontSize: 13)),
          isExpanded: true,
          items: _hariList.map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) => setState(() => _selectedHari = v),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required List<Map<String, dynamic>> items,
    required String? value,
    required String hint,
    required double width,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            hint: Text(hint, style: const TextStyle(fontSize: 13)),
            isExpanded: true,
            items: items.map((e) => DropdownMenuItem(
              value: '${e['id']}',
              child: Text('${e['nama']}', style: const TextStyle(fontSize: 13)),
            )).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        disabledForegroundColor: Colors.grey[400],
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  // â”€â”€ Two Column Layout â”€â”€

  Widget _buildTwoColumnLayout() {
    return Row(
      children: [
        // Panel Kiri: Daftar Mapel
        SizedBox(width: 280, child: _buildMapelPanel()),
        // Divider
        VerticalDivider(width: 1, color: Colors.grey[200]),
        // Panel Kanan: Kegiatan Tetap + Tabel Jadwal + Bentrok
        Expanded(
          child: Column(
            children: [
              _buildKegiatanPanel(),
              Expanded(child: _buildTimetable()),
              _buildBentrokPanel(),
            ],
          ),
        ),
      ],
    );
  }

  // â”€â”€ Panel Kiri: Daftar Mapel â”€â”€

  Widget _buildMapelPanel() {
    final guruMapel = _refList('guru_mapel');
    final mapelFiltered = _filterTingkat != null
        ? guruMapel.where((gm) {
            final tingkatIds = (gm['tingkat_ids'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
            return tingkatIds.contains(_filterTingkat);
          }).toList()
        : guruMapel;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: const Row(
              children: [
                Icon(Icons.menu_book_outlined, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Daftar Mapel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ],
            ),
          ),

          // Daftar Mapel
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Text('DAFTAR MAPEL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey)),
                const Spacer(),
                Text('${mapelFiltered.length} mapel', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: mapelFiltered.length,
              itemBuilder: (_, i) => _buildMapelItem(mapelFiltered[i]),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Panel Kanan: Kegiatan Tetap â”€â”€

  Widget _buildKegiatanPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          const Icon(Icons.event_available, color: Colors.orange, size: 18),
          const SizedBox(width: 6),
          const Text('KEGIATAN TETAP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(width: 12),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 90),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final k in _kegiatanTetap) _buildKegiatanItem(k),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _kelolaKegiatanTetap,
            icon: const Icon(Icons.settings_outlined, size: 16),
            label: const Text('Kelola', style: TextStyle(fontSize: 11)),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKegiatanItem(Map<String, dynamic> kegiatan) {
    return LongPressDraggable<Map<String, dynamic>>(
      data: {
        'tipe': 'kegiatan',
        'nama': kegiatan['nama'],
        'is_istirahat': kegiatan['tipe'] == 'istirahat',
      },
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(kegiatan['nama'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildKegiatanItemContent(kegiatan)),
      child: _buildKegiatanItemContent(kegiatan),
    );
  }

  Widget _buildKegiatanItemContent(Map<String, dynamic> kegiatan) {
    final isIstirahat = kegiatan['tipe'] == 'istirahat';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isIstirahat ? Colors.orange[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isIstirahat ? Colors.orange[200]! : Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(
            isIstirahat ? Icons.coffee : Icons.school,
            size: 14,
            color: isIstirahat ? Colors.orange[700] : Colors.blue[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              kegiatan['nama'],
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isIstirahat ? Colors.orange[800] : Colors.blue[800]),
            ),
          ),
          Icon(Icons.drag_indicator, size: 14, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildMapelItem(Map<String, dynamic> guruMapel) {
    final namaMapel = guruMapel['mapel_nama']?.toString() ?? guruMapel['nama']?.toString() ?? '-';
    final namaGuru = guruMapel['guru_nama']?.toString() ?? guruMapel['nip']?.toString() ?? '-';

    return LongPressDraggable<Map<String, dynamic>>(
      data: {
        'tipe': 'mapel',
        'mata_pelajaran_id': guruMapel['mata_pelajaran_id'] ?? guruMapel['id'],
        'guru_id': guruMapel['guru_id'],
        'mapel_nama': namaMapel,
        'guru_nama': namaGuru,
      },
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(namaMapel, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              Text(namaGuru, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: _buildMapelItemContent(namaMapel, namaGuru)),
      child: _buildMapelItemContent(namaMapel, namaGuru),
    );
  }

  Widget _buildMapelItemContent(String namaMapel, String namaGuru) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.book_outlined, size: 16, color: AppTheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(namaMapel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                Text(namaGuru, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.drag_indicator, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  // â”€â”€ Tabel Jadwal (Panel Kanan) â”€â”€

  Widget _buildTimetable() {
    if (_selectedHari == null) {
      return _buildEmptyState('Pilih hari terlebih dahulu');
    }

    final kelasFiltered = _filterTingkat != null
        ? _refList('kelas').where((k) => k['tingkat_id'].toString() == _filterTingkat).toList()
        : _refList('kelas');

    if (kelasFiltered.isEmpty) {
      return _buildEmptyState('Tidak ada kelas untuk tingkat ini');
    }

    final jpFiltered = _filterGenre == null
        ? _jpSlots
        : _jpSlots.where((jp) {
            final mulai = jp['mulai']?.toString() ?? '';
            final hour = int.tryParse(mulai.split(':').first) ?? 0;
            switch (_filterGenre) {
              case 'Pagi': return hour < 12;
              case 'Siang': return hour >= 12 && hour < 17;
              case 'Full Day': return true;
              default: return true;
            }
          }).toList();

    if (jpFiltered.isEmpty) {
      return _buildEmptyState('Tidak ada slot jam untuk genre ini');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final kelasCount = kelasFiltered.length;
        const waktuW = 110.0;
        final spacingTotal = 8.0 * (kelasCount + 1);
        const marginTotal = 24.0;
        final sisa = kelasCount > 0
            ? (constraints.maxWidth - waktuW - spacingTotal - marginTotal) / kelasCount
            : 0.0;
        final kelasW = sisa < 120.0 ? 120.0 : sisa;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              columnSpacing: 8,
              horizontalMargin: 12,
              headingRowHeight: 44,
              dataRowMinHeight: 60,
              dataRowMaxHeight: 60,
              columns: [
                const DataColumn(label: SizedBox(
                  width: waktuW,
                  child: Text('Waktu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                )),
                ...kelasFiltered.map((k) => DataColumn(
                  label: SizedBox(
                    width: kelasW,
                    child: Text('${k['nama']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                )),
              ],
          rows: [
          ...jpFiltered.map((jp) {
            final jpKode = jp['kode'] as String;
            final jpWaktu = '${jp['mulai']}-${jp['selesai']}';

            return DataRow(cells: [
              DataCell(SizedBox(
                width: waktuW,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => _editWaktuSlot(jp),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('JP $jpKode', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _editWaktuSlot(jp),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(1),
                            child: Icon(Icons.edit_outlined, size: 10, color: Colors.grey[500]),
                          ),
                        ),
                        const SizedBox(width: 2),
                        InkWell(
                          onTap: () => _hapusJpSlot(jp),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(1),
                            child: Icon(Icons.close, size: 11, color: Colors.red[400]),
                          ),
                        ),
                      ],
                    ),
                    Text(jpWaktu, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
                  ],
                ),
                    ),
                  ),
                ),
              )),
              ...kelasFiltered.map((kelas) {
                final kelasId = kelas['id'].toString();
                final entry = _jadwal.firstWhere(
                  (j) =>
                      j['kelas_id'].toString() == kelasId &&
                      j['hari'] == _selectedHari &&
                      j['jam_mulai'] == jp['mulai'],
                  orElse: () => <String, dynamic>{},
                );

                return DataCell(
                  SizedBox(
                    width: kelasW,
                    child: entry.isNotEmpty
                        ? _buildScheduleCell(entry)
                        : DragTarget<Map<String, dynamic>>(
                            onAcceptWithDetails: (details) => _moveToSlot(details.data, kelasId, jp),
                            builder: (ctx, candidates, rejected) => Container(
                              height: 52,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[200]!, width: 0.5),
                                color: candidates.isNotEmpty ? Colors.blue[50] : null,
                              ),
                            ),
                          ),
                  ),
                );
              }),
            ]);
          }),
          // Baris Tambah JP manual (di bawah kolom Waktu)
          DataRow(cells: [
            DataCell(
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _tambahJpSlot,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Tambah', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ),
            ),
            ...kelasFiltered.map((_) => const DataCell(SizedBox())),
          ]),
        ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScheduleCell(Map<String, dynamic> j) {
    final tervalidasi = j['status_validasi'] == 'tervalidasi';
    final isKegiatan = j['nama_kegiatan'] != null && j['nama_kegiatan'].toString().isNotEmpty;
    final mapelNama = j['mapel_nama']?.toString() ?? (isKegiatan ? j['nama_kegiatan'].toString() : '-');
    final guruNama = j['guru_nama']?.toString() ?? '-';
    final isGabungan = j['gabungan_id'] != null && j['gabungan_id'].toString().isNotEmpty && j['gabungan_id'].toString() != 'null';
    final color = isKegiatan
        ? (j['is_istirahat'] == true || j['is_istirahat'] == 1 ? Colors.purple : Colors.teal)
        : (tervalidasi ? const Color(0xFF9C6644) : Colors.orange);

    final content = Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isGabungan ? color : color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(mapelNama, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isGabungan) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                  child: const Text('GAB', style: TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 3),
              ],
              Flexible(child: Text(guruNama, style: TextStyle(fontSize: 9, color: Colors.grey[600]), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ],
      ),
    );

    // Jadwal tervalidasi dikunci: tidak bisa di-drag maupun dihapus
    if (tervalidasi) return content;

    final cell = Stack(
      children: [
        Positioned.fill(child: content),
        Positioned(
          top: 0,
          right: 0,
          child: InkWell(
            onTap: () => _hapusJadwal(j),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.close, size: 11, color: Colors.red),
            ),
          ),
        ),
      ],
    );

    return LongPressDraggable<Map<String, dynamic>>(
      data: {
        ...j,
        'tipe': isKegiatan ? 'kegiatan' : 'mapel',
      },
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(6)),
          child: Text(mapelNama, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
      childWhenDragging: Container(
        height: 52,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), color: Colors.grey[100]),
      ),
      child: cell,
    );
  }

  Future<void> _tambahJpSlot() async {
    final hasil = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => const _WaktuDialog(
        title: 'Tambah JP Slot',
        confirmLabel: 'Tambah',
        note: 'Slot baru ditambahkan ke semua kelas & tingkat.',
      ),
    );
    if (hasil == null || !mounted) return;

    try {
      await WakilKurikulumService.createJpSlot(hasil['mulai']!, hasil['selesai']!);
      final slots = await WakilKurikulumService.getJpSlots();
      if (!mounted) return;
      setState(() => _jpSlots = slots.cast<Map<String, dynamic>>());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('JP slot baru ditambahkan'), backgroundColor: Color(0xFF9C6644)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal tambah JP: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadKegiatanTetap() async {
    try {
      final list = await WakilKurikulumService.getKegiatanTetap();
      if (!mounted) return;
      setState(() {
        _kegiatanTetap = list.cast<Map<String, dynamic>>();
        if (_kegiatanTetap.isEmpty) _kegiatanTetap = _defaultKegiatanTetap;
      });
    } catch (_) {
      // Abaikan: fallback ke list yang sudah ada
    }
  }

  Future<void> _kelolaKegiatanTetap() async {
    await showDialog(
      context: context,
      builder: (_) => _KelolaKegiatanDialog(awal: _kegiatanTetap),
    );
    await _loadKegiatanTetap();
  }

  Future<void> _kelolaGabungan() async {
    if (_filterSemester == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih semester dulu untuk mengelola kelas gabungan'), backgroundColor: Colors.orange),
        );
      }
      return;
    }
    await showDialog(
      context: context,
      builder: (_) => _KelolaGabunganDialog(semesterId: int.parse(_filterSemester!)),
    );
    await _loadRef();
  }

  Future<void> _editWaktuSlot(Map<String, dynamic> jp) async {
    final kode = jp['kode'] as String;

    final hasil = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => _WaktuDialog(
        title: 'Ubah Waktu $kode',
        confirmLabel: 'Simpan',
        mulai: jp['mulai']?.toString() ?? '',
        selesai: jp['selesai']?.toString() ?? '',
        note: 'Berlaku untuk semua kelas & tingkat. Seluruh jadwal dengan waktu ini ikut diperbarui.',
      ),
    );
    if (hasil == null || !mounted) return;

    try {
      await WakilKurikulumService.updateJpSlot(kode, hasil['mulai']!, hasil['selesai']!);
      final slots = await WakilKurikulumService.getJpSlots();
      if (!mounted) return;
      setState(() => _jpSlots = slots.cast<Map<String, dynamic>>());
      await _loadJadwal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Waktu JP diperbarui dan jadwal tersinkron'), backgroundColor: Color(0xFF9C6644)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ubah waktu: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _hapusJpSlot(Map<String, dynamic> jp) async {
    final kode = jp['kode'] as String;
    final nama = 'JP $kode (${jp['mulai']}-${jp['selesai']})';

    final ok = await AppUtils.confirm(
      context,
      title: 'Hapus JP Slot',
      message: 'Hapus slot $nama dari tabel jadwal?\n\n'
          'Jika slot ini masih dipakai jadwal, penghapusan akan ditolak.',
    );
    if (!ok || !mounted) return;

    try {
      await WakilKurikulumService.deleteJpSlot(kode);
      final slots = await WakilKurikulumService.getJpSlots();
      if (!mounted) return;
      setState(() => _jpSlots = slots.cast<Map<String, dynamic>>());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('JP slot dihapus'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal hapus JP: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // â”€â”€ Panel Bawah: Keterangan Jam Bentrok â”€â”€

  Widget _buildBentrokPanel() {
    final bentrok = _detectBentrok();
    final unmatched = _jadwalUnmatched();
    final issues = <String>[...unmatched, ...bentrok];
    final hasIssue = issues.isNotEmpty;

    return Container(
      height: hasIssue ? 100 : 60,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasIssue ? Colors.red[50] : Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasIssue ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                size: 16,
                color: hasIssue ? Colors.red : const Color(0xFF9C6644),
              ),
              const SizedBox(width: 6),
              Text(
                hasIssue ? 'Keterangan (${issues.length})' : 'Tidak ada masalah jam',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: hasIssue ? Colors.red[700] : const Color(0xFF7F5539),
                ),
              ),
            ],
          ),
          if (issues.isNotEmpty) ...[
            const SizedBox(height: 6),
            Expanded(
              child: ListView.builder(
                itemCount: issues.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    'â€¢ ${issues[i]}',
                    style: TextStyle(fontSize: 11, color: Colors.red[800]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Entri jadwal yang jam_mulai-nya tidak cocok dengan slot waktu manapun
  List<String> _jadwalUnmatched() {
    if (_jadwal.isEmpty || _selectedHari == null) return [];
    final slotMulai = _jpSlots.map((s) => s['mulai']?.toString()).toSet();
    final result = <String>[];
    for (final j in _jadwal) {
      if (j['hari'] != _selectedHari) continue;
      final mulai = j['jam_mulai']?.toString();
      if (mulai == null || mulai.isEmpty || !slotMulai.contains(mulai)) {
        final mapel = j['mapel_nama']?.toString() ?? j['nama_kegiatan']?.toString() ?? '-';
        final kelas = j['kelas_nama']?.toString() ?? j['kelas_id']?.toString() ?? '?';
        result.add('$mapel ($kelas) ${j['jam_mulai']}-${j['jam_selesai']} tidak cocok slot waktu');
      }
    }
    return result;
  }

  List<String> _detectBentrok() {
    if (_jadwal.isEmpty || _selectedHari == null) return [];

    final List<Map<String, dynamic>> hariJadwal = [];
    for (final j in _jadwal) {
      if (j['hari'] != _selectedHari) continue;
      if (j['is_istirahat'] == true || j['is_istirahat'] == 1) continue;

      final mulai = j['jam_mulai']?.toString();
      final selesai = j['jam_selesai']?.toString();
      if (mulai == null || selesai == null || mulai.isEmpty || selesai.isEmpty) continue;

      hariJadwal.add({
        'guru_id': j['guru_id']?.toString(),
        'kelas_id': j['kelas_id']?.toString(),
        'kelas_nama': j['kelas_nama']?.toString() ?? j['kelas_id']?.toString() ?? '?',
        'mapel': j['mapel_nama']?.toString() ?? j['nama_kegiatan']?.toString() ?? '-',
        'guru_nama': j['guru_nama']?.toString() ?? '-',
        'gabungan_id': j['gabungan_id']?.toString(),
        'mulai': _timeToMin(mulai),
        'selesai': _timeToMin(selesai),
      });
    }

    final List<String> bentrok = [];
    final seen = <String>{};

    void addIssue(String key, String msg) {
      if (seen.add(key)) bentrok.add(msg);
    }

    // Bentrok guru: guru sama, jam overlap
    for (var i = 0; i < hariJadwal.length; i++) {
      for (var j = i + 1; j < hariJadwal.length; j++) {
        final a = hariJadwal[i];
        final b = hariJadwal[j];
        if (a['guru_id'] == null || a['guru_id'] != b['guru_id']) continue;
        if (!_overlap(a, b)) continue;
        final aKey = _sessionKey(a);
        final bKey = _sessionKey(b);
        if (aKey != null && aKey == bKey) continue; // sesi gabungan yang sama = bukan bentrok
        addIssue(
          'guru:${a['guru_id']}:${a['mulai']}-${a['selesai']}',
          '${a['guru_nama']} mengajar di ${a['kelas_nama']} dan ${b['kelas_nama']} pada jam yang sama',
        );
      }
    }

    // Bentrok kelas: kelas sama, jam overlap (non-istirahat)
    for (var i = 0; i < hariJadwal.length; i++) {
      for (var j = i + 1; j < hariJadwal.length; j++) {
        final a = hariJadwal[i];
        final b = hariJadwal[j];
        if (a['kelas_id'] == null || a['kelas_id'] != b['kelas_id']) continue;
        if (!_overlap(a, b)) continue;
        addIssue(
          'kelas:${a['kelas_id']}:${a['mulai']}-${a['selesai']}',
          '${a['kelas_nama']} memiliki 2 jadwal pada jam yang sama: ${a['mapel']} & ${b['mapel']}',
        );
      }
    }

    return bentrok;
  }

  int _timeToMin(String t) {
    final parts = t.split(':');
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  bool _overlap(Map<String, dynamic> a, Map<String, dynamic> b) {
    final aMulai = a['mulai'] as int;
    final aSelesai = a['selesai'] as int;
    final bMulai = b['mulai'] as int;
    final bSelesai = b['selesai'] as int;
    return (aMulai < bSelesai) && (bMulai < aSelesai);
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(color: Colors.red[700]), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Muat Ulang'),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Drag & Drop â”€â”€

  Future<void> _moveToSlot(Map<String, dynamic> data, String kelasId, Map<String, dynamic> jp) async {
    if (_filterSemester == null) return;

    final tipe = data['tipe'] ?? 'mapel';
    final isKegiatan = tipe == 'kegiatan';
    final isIstirahat = data['is_istirahat'] == true || data['is_istirahat'] == 1;
    final existingId = data['id'];

    // No-op: drop di slot yang sama (kelas + hari + jam sama)
    if (existingId != null &&
        data['kelas_id']?.toString() == kelasId &&
        data['jam_mulai']?.toString() == jp['mulai'] &&
        data['hari']?.toString() == _selectedHari) {
      return;
    }

    Map<String, dynamic> body;

    if (isKegiatan) {
      body = {
        'kelas_id': int.tryParse(kelasId),
        'mata_pelajaran_id': null,
        'guru_id': null,
        'hari': _selectedHari,
        'jam_mulai': jp['mulai'],
        'jam_selesai': jp['selesai'],
        'semester_id': int.tryParse(_filterSemester!),
        'is_istirahat': isIstirahat,
        'nama_kegiatan': data['nama_kegiatan']?.toString() ?? data['nama']?.toString(),
      };
    } else {
      final targetGabungan = _gabunganForKelas(kelasId);
      body = {
        'kelas_id': int.tryParse(kelasId),
        'mata_pelajaran_id': data['mata_pelajaran_id'],
        'guru_id': data['guru_id'],
        'hari': _selectedHari,
        'jam_mulai': jp['mulai'],
        'jam_selesai': jp['selesai'],
        'semester_id': int.tryParse(_filterSemester!),
        if (targetGabungan != null) 'gabungan_id': int.tryParse('${targetGabungan['id']}'),
      };
    }

    try {
      final cek = await WakilKurikulumService.cekBentrok(body);
      if (cek['bentrok'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${cek['message']}'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      // Sudah ada di jadwal â†’ pindah (update), bukan duplikat
      if (existingId != null && existingId is int) {
        await WakilKurikulumService.updateJadwal(existingId, body);
      } else {
        await WakilKurikulumService.createJadwal(body);
      }
      await _loadJadwal();
      if (mounted) {
        final nama = isKegiatan
            ? (data['nama_kegiatan'] ?? data['nama'] ?? 'Kegiatan')
            : (data['mapel_nama'] ?? 'Mapel');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$nama dipindah ke ${_kelasNama(kelasId)}'), backgroundColor: const Color(0xFF9C6644), duration: const Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _kelasNama(String kelasId) {
    for (final k in _refList('kelas')) {
      if (k['id'].toString() == kelasId) return k['nama']?.toString() ?? kelasId;
    }
    return kelasId;
  }

  Map<String, dynamic>? _gabunganForKelas(String kelasId) {
    if (_filterSemester == null) return null;
    for (final g in _kelasGabungan) {
      if (g['semester_id'].toString() != _filterSemester) continue;
      final ids = (g['kelas_ids'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
      if (ids.contains(kelasId)) return g;
    }
    return null;
  }

  String? _sessionKey(Map<String, dynamic> e) {
    final gid = e['gabungan_id']?.toString();
    if (gid == null || gid.isEmpty || gid == 'null') return null;
    return 'g:$gid|${e['mulai']}-${e['selesai']}|guru:${e['guru_id']}';
  }

  Future<void> _hapusJadwal(Map<String, dynamic> j) async {
    final id = j['id'];
    if (id == null) return;
    final jadwalId = id is int ? id : int.tryParse('$id');
    if (jadwalId == null) return;

    final nama = j['mapel_nama']?.toString() ?? j['nama_kegiatan']?.toString() ?? 'Jadwal';
    final isGabungan = j['gabungan_id'] != null && j['gabungan_id'].toString().isNotEmpty && j['gabungan_id'].toString() != 'null';
    final ok = await AppUtils.confirm(
      context,
      title: 'Hapus Jadwal',
      message: isGabungan
          ? 'Hapus sesi gabungan $nama dari semua kelas anggotanya?'
          : 'Hapus $nama dari jadwal ini?',
    );
    if (!ok) return;

    try {
      await WakilKurikulumService.deleteJadwal(jadwalId);
      await _loadJadwal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jadwal dihapus'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal hapus: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // â”€â”€ Actions â”€â”€

  Future<void> _simpanJadwal() async {
    if (_jadwal.isEmpty) return;
    try {
      final data = _jadwal.map((j) => {
        'id': j['id'] as int,
        'kelas_id': j['kelas_id'] as int,
        'mata_pelajaran_id': j['mata_pelajaran_id'] as int?,
        'guru_id': j['guru_id'] as int?,
        'hari': j['hari'] as String,
        'jam_mulai': j['jam_mulai'] as String,
        'jam_selesai': j['jam_selesai'] as String,
        'semester_id': j['semester_id'] as int,
        if (j['ruangan_id'] != null) 'ruangan_id': j['ruangan_id'] as int,
        if (j['nama_kegiatan'] != null) 'nama_kegiatan': j['nama_kegiatan'] as String,
        if (j['gabungan_id'] != null) 'gabungan_id': j['gabungan_id'] as int,
        'is_istirahat': j['is_istirahat'] == true || j['is_istirahat'] == 1,
      }).toList();

      final res = await WakilKurikulumService.simpanJadwal(data);
      if (mounted) {
        final msg = res['errors'] != null
            ? '${res['saved']} tersimpan, ${(res['errors'] as List).length} error'
            : '${res['saved']} jadwal tersimpan';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: const Color(0xFF9C6644)),
        );
      }
      _loadJadwal();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal simpan: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _resetJadwal() async {
    if (_filterSemester == null) return;
    final ok = await AppUtils.confirm(context, title: 'Reset Jadwal',
        message: 'Hapus SEMUA jadwal draft semester ini? Jadwal tervalidasi tetap aman.');
    if (!ok) return;

    try {
      await WakilKurikulumService.resetJadwal(int.parse(_filterSemester!));
      _loadJadwal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jadwal direset'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _generateJadwal() async {
    if (_filterSemester == null) return;
    final ok = await AppUtils.confirm(context, title: 'Generate Jadwal',
        message: 'Hapus jadwal draft semester ini lalu buat ulang otomatis berdasarkan Kesiapan Mengajar guru?');
    if (!ok) return;

    try {
      final res = await WakilKurikulumService.generateJadwal(int.parse(_filterSemester!));
      await _loadJadwal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${res['message'] ?? 'Generate selesai'}'), backgroundColor: const Color(0xFF9C6644)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal generate: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _publikasiJadwal() async {
    if (_filterSemester == null) return;
    final ok = await AppUtils.confirm(context, title: 'Publikasi Jadwal',
        message: 'Validasi SEMUA jadwal draft semester ini? Setelah dipublikasi, jadwal tampil untuk guru & santri.');
    if (!ok) return;

    try {
      final res = await WakilKurikulumService.publikasiJadwal(int.parse(_filterSemester!));
      await _loadJadwal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${res['message'] ?? 'Jadwal dipublikasikan'}'), backgroundColor: const Color(0xFF9C6644)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal publikasi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _unpublikasiJadwal() async {
    if (_filterSemester == null) return;
    final ok = await AppUtils.confirm(context, title: 'Unpublikasi Jadwal',
        message: 'Kembalikan SEMUA jadwal tervalidasi semester ini ke draft untuk direvisi?\n\n'
            'Guru & santri TIDAK akan melihat jadwal sampai Anda publikasikan ulang.');
    if (!ok) return;

    try {
      final res = await WakilKurikulumService.unpublikasiJadwal(int.parse(_filterSemester!));
      await _loadJadwal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${res['message'] ?? 'Jadwal dikembalikan ke draft'}'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal unpublikasi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â• KESIAPAN MENGAJAR TAB â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildKesiapanTab() {
    final sem = _refList('semester');

    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          _buildDropdown(
            items: sem,
            value: _filterSemester,
            hint: 'Semester',
            width: 200,
            onChanged: (v) {
              setState(() => _filterSemester = v);
              _loadKesiapan();
            },
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _filterSemester != null ? _simpanKesiapan : null,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Simpan Semua'),
          ),
        ]),
      ),
      Expanded(
        child: _kesiapanLoading
            ? const Center(child: CircularProgressIndicator())
            : _filterSemester == null
                ? _buildEmptyState('Pilih semester terlebih dahulu')
                : _kesiapan.isEmpty
                    ? _buildEmptyState('Belum ada data kesiapan.')
                    : _buildKesiapanTable(),
      ),
    ]);
  }

  Widget _buildKesiapanTable() {
    final guruList = _kesiapanRows;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 12,
          headingRowHeight: 44,
          dataRowMinHeight: 52,
          dataRowMaxHeight: 80,
          columns: const [
            DataColumn(label: Text('Guru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('NIP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Hari Aktif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('JP/Hari', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('JP/Minggu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Kelas Diampu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Mapel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Kapasitas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
          rows: guruList.map((g) {
            final jpTerisi = g.jpTerisi;
            final jpMaxMinggu = g.jpMaxMinggu;
            final persen = jpMaxMinggu > 0 ? jpTerisi / jpMaxMinggu : 0.0;
            final capColor = persen >= 1.0 ? Colors.red : (persen >= 0.8 ? Colors.orange : const Color(0xFF9C6644));

            return DataRow(cells: [
              DataCell(Text(g.nama, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              DataCell(Text(g.nip, style: const TextStyle(fontSize: 11))),
              DataCell(_HariCheckboxRow(
                nilai: g.hariAktif,
                onChanged: (v) => setState(() => g.hariAktif = v),
              )),
              DataCell(SizedBox(
                width: 60,
                child: TextFormField(
                  initialValue: g.jpMaxPerHari.toString(),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), border: OutlineInputBorder(), isDense: true),
                  onChanged: (v) {
                    final val = int.tryParse(v);
                    if (val != null) g.jpMaxPerHari = val;
                  },
                ),
              )),
              DataCell(SizedBox(
                width: 60,
                child: TextFormField(
                  initialValue: g.jpMaxMinggu.toString(),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), border: OutlineInputBorder(), isDense: true),
                  onChanged: (v) {
                    final val = int.tryParse(v);
                    if (val != null) g.jpMaxMinggu = val;
                  },
                ),
              )),
              DataCell(ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(g.kelasDiampu.map((k) => k['kelas_nama'] ?? '').join(', '),
                    style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis, maxLines: 2),
              )),
              DataCell(ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(g.mapelDiampu.map((m) => m['mapel_nama'] ?? '').join(', '),
                    style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis, maxLines: 2),
              )),
              DataCell(Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$jpTerisi/$jpMaxMinggu JP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: capColor)),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: 80,
                    child: LinearProgressIndicator(value: persen.clamp(0.0, 1.0), backgroundColor: Colors.grey[200], color: capColor),
                  ),
                  if (persen >= 1.0) Text('Kelebihan ${jpTerisi - jpMaxMinggu} JP', style: const TextStyle(fontSize: 9, color: Colors.red)),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _simpanKesiapan() async {
    if (_filterSemester == null) return;
    setState(() => _kesiapanLoading = true);
    try {
      final data = _kesiapanRows.map((row) {
        return {
          'guru_id': row.guruId,
          'hari_aktif': row.hariAktif,
          'jp_max_per_hari': row.jpMaxPerHari,
          'jp_max_per_minggu': row.jpMaxMinggu,
        };
      }).toList();

      await WakilKurikulumService.batchUpdateKesiapan({
        'semester_id': int.parse(_filterSemester!),
        'data': data,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kesiapan berhasil disimpan'), backgroundColor: Color(0xFF9C6644)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal simpan: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _kesiapanLoading = false);
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â• WALI KELAS TAB â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildWaliKelasTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Icon(Icons.people_outline, color: Colors.blueGrey[600], size: 20),
          const SizedBox(width: 8),
          Text('Daftar Wali Kelas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueGrey[800])),
          const Spacer(),
          TextButton.icon(
            onPressed: _loadWaliKelas,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
          ),
        ]),
      ),
      Expanded(
        child: _waliKelasLoading
            ? const Center(child: CircularProgressIndicator())
            : _waliKelas.isEmpty
                ? _buildEmptyState('Belum ada data wali kelas.')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _waliKelas.length,
                    itemBuilder: (_, i) {
                      final w = _waliKelas[i];
                      final adaKelas = w['kelas_id'] != null;
                      final jumlahSiswa = w['jumlah_siswa'] as int? ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: adaKelas ? Colors.blue[50] : Colors.grey[100],
                            radius: 22,
                            child: Icon(Icons.person, color: adaKelas ? Colors.blue[700] : Colors.grey[400], size: 22),
                          ),
                          title: Text(w['nama']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('NIP: ${w['nip'] ?? '-'}'),
                              if (adaKelas) ...[
                                const SizedBox(height: 2),
                                Row(children: [
                                  Icon(Icons.class_outlined, size: 14, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text('${w['kelas_nama']}', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 12),
                                  Icon(Icons.people_alt_outlined, size: 14, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text('$jumlahSiswa Santri', style: TextStyle(color: Colors.grey[600])),
                                ]),
                              ],
                            ],
                          ),
                          trailing: adaKelas
                              ? const Icon(Icons.check_circle, color: Color(0xFFB08968), size: 20)
                              : Icon(Icons.remove_circle_outline, color: Colors.grey[400], size: 20),
                        ),
                      );
                    },
                  ),
      ),
    ]);
  }
}
