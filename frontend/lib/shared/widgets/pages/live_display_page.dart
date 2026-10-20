import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

/// Papan Absensi Live (asatidz + musyrifah at-Ta'wid) untuk monitor/TV.
///
/// Halaman publik (tanpa login): menampilkan daftar hadir live dalam
/// bentuk tabel (spreadsheet). Data diperbarui otomatis secara berkala.
class LiveDisplayPage extends StatefulWidget {
  const LiveDisplayPage({super.key});

  @override
  State<LiveDisplayPage> createState() => _LiveDisplayPageState();
}

class _LiveDisplayItem {
  final String nama;
  final String jamMasuk;
  final String? jamKeluar;

  /// true = musyrifah at-Ta'wid, false = asatidz.
  /// Dipakai sebagai penanda warna (titik) di depan nama.
  final bool musyrifah;

  const _LiveDisplayItem({
    required this.nama,
    required this.jamMasuk,
    this.jamKeluar,
    this.musyrifah = false,
  });

  factory _LiveDisplayItem.fromJson(
    Map<String, dynamic> json, {
    bool musyrifah = false,
  }) {
    return _LiveDisplayItem(
      nama: json['nama']?.toString() ?? '-',
      jamMasuk: json['jam_masuk']?.toString() ?? '',
      jamKeluar: json['jam_keluar']?.toString(),
      musyrifah: musyrifah,
    );
  }

  String get signature => '${musyrifah ? 'M' : 'A'}|$nama|$jamMasuk';
}

class _LiveDisplayStats {
  final int total;
  final int hadir;
  final int sudahKeluar;
  final int belumHadir;

  const _LiveDisplayStats({
    required this.total,
    required this.hadir,
    required this.sudahKeluar,
    required this.belumHadir,
  });

  factory _LiveDisplayStats.fromJson(
    Map<String, dynamic> json, {
    required String totalKey,
  }) {
    return _LiveDisplayStats(
      total: (json[totalKey] as num?)?.toInt() ?? 0,
      hadir: (json['hadir'] as num?)?.toInt() ?? 0,
      sudahKeluar: (json['sudah_keluar'] as num?)?.toInt() ?? 0,
      belumHadir: (json['belum_hadir'] as num?)?.toInt() ?? 0,
    );
  }

  static const empty = _LiveDisplayStats(
    total: 0,
    hadir: 0,
    sudahKeluar: 0,
    belumHadir: 0,
  );
}

class _LiveDisplayPageState extends State<LiveDisplayPage> {
  static const Duration _pollInterval = Duration(seconds: 15);
  static const Duration _welcomeDuration = Duration(seconds: 6);

  Timer? _pollTimer;
  Timer? _clockTimer;
  final ScrollController _listScrollCtrl = ScrollController();

  DateTime _nowWib = DateTime.now().toUtc().add(const Duration(hours: 7));
  List<_LiveDisplayItem> _items = const [];
  _LiveDisplayStats _stats = _LiveDisplayStats.empty;
  _LiveDisplayStats _statsMusyrifah = _LiveDisplayStats.empty;
  bool _loading = true;
  bool _offline = false;
  DateTime? _lastSuccessAt;

  // Popup sambutan saat ada scan baru
  String? _welcomeName;
  Timer? _welcomeTimer;
  String? _lastSignature;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _fetchData());
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _nowWib = DateTime.now().toUtc().add(const Duration(hours: 7));
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _clockTimer?.cancel();
    _welcomeTimer?.cancel();
    _listScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final body = await ApiClient.get('/public/absensi-hari-ini');
      if (!mounted) return;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final itemsRaw = [
        ...(data['items'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(_LiveDisplayItem.fromJson),
        ...(data['items_musyrifah'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map((json) => _LiveDisplayItem.fromJson(json, musyrifah: true)),
      ]..sort((a, b) => b.jamMasuk.compareTo(a.jamMasuk));
      final statRaw = data['statistik'] as Map<String, dynamic>? ?? {};
      final statMusyrifahRaw =
          data['statistik_musyrifah'] as Map<String, dynamic>? ?? {};

      final newSignature =
          itemsRaw.isNotEmpty ? itemsRaw.first.signature : null;

      setState(() {
        _items = itemsRaw;
        _stats = _LiveDisplayStats.fromJson(statRaw, totalKey: 'total_asatidz');
        _statsMusyrifah = _LiveDisplayStats.fromJson(
          statMusyrifahRaw,
          totalKey: 'total_musyrifah',
        );
        _loading = false;
        _offline = false;
        _lastSuccessAt = DateTime.now();

        if (_lastSignature != null &&
            newSignature != null &&
            newSignature != _lastSignature) {
          _showWelcome(itemsRaw.first.nama);
        }
        _lastSignature = newSignature;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      AppLogger.error('[LiveDisplay] Gagal memuat data: ${e.message}');
      setState(() {
        _offline = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      AppLogger.error('[LiveDisplay] Error tak terduga: $e');
      setState(() {
        _offline = true;
        _loading = false;
      });
    }
  }

  void _showWelcome(String nama) {
    _welcomeTimer?.cancel();
    setState(() => _welcomeName = nama);
    _welcomeTimer = Timer(_welcomeDuration, () {
      if (mounted) setState(() => _welcomeName = null);
    });
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String get _clockText =>
      '${_two(_nowWib.hour)}:${_two(_nowWib.minute)}:${_two(_nowWib.second)}';

  String get _dateText {
    final df = DateFormat('EEEE, d MMMM yyyy', 'id');
    return df.format(_nowWib);
  }

  String _shortTime(String hhmmss) =>
      hhmmss.length >= 5 ? hhmmss.substring(0, 5) : hhmmss;

  String get _updatedText {
    final t = _lastSuccessAt;
    if (t == null) return '';
    final wib = t.toUtc().add(const Duration(hours: 7));
    return 'Diperbarui ${_two(wib.hour)}:${_two(wib.minute)}:${_two(wib.second)} WIB';
  }

  @override
  Widget build(BuildContext context) {
    // Di monitor POTRAIT (tegak) lebar layar sempit, jadi ruang tepi
    // dipadatkan supaya daftar hadir terlihat lebih luas.
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final margin = isPortrait ? 10.0 : 16.0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(margin),
                    child: _buildListPanel(),
                  ),
                ),
              ],
            ),
            _buildWelcomeOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.school, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MTs PERSIS GARUT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Papan Absensi Asatidz & Musyrifah - Live',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _clockText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    _dateText,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('WIB',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusDot() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: _offline ? AppTheme.error : AppTheme.primary,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildListPanel() {
    // Portrait: isi panel dipadatkan (16 vs 20) supaya tabel dapat ruang
    // lebih banyak secara horizontal.
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    return Container(
      padding: EdgeInsets.all(isPortrait ? 14 : 20),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'DAFTAR HADIR HARI INI',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.grey800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _statusDot(),
                  const SizedBox(width: 8),
                  Text(
                    _offline ? 'Koneksi terputus' : _updatedText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: _offline ? AppTheme.error : AppTheme.grey400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildStatsRow(),
          const SizedBox(height: 10),
          Expanded(child: _buildSpreadsheet()),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baris 1: ringkasan Asatidz (tanpa kotak/kartu)
        _statsLine(
          'Asatidz',
          _stats,
          AppTheme.primary,
        ),
        const SizedBox(height: 6),
        // Baris 2: ringkasan Musyrifah at-Ta'wid
        _statsLine(
          "Musyrifah at-Ta'wid",
          _statsMusyrifah,
          AppTheme.orange,
        ),
      ],
    );
  }

  /// Satu baris ringkasan angka, contoh:
  ///   ● Asatidz — Hadir 12 · Sudah Keluar 5 · Belum Hadir 3
  ///
  /// Tanpa kotak, supaya ruang daftar hadir terlihat lebih luas.
  /// Bila layar sempit (mode portrait), teks otomatis turun ke baris
  /// berikutnya sehingga tidak terpotong.
  Widget _statsLine(String label, _LiveDisplayStats stats, Color color) {
    final valueStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      color: color,
    );
    const labelStyle = TextStyle(
      fontSize: 12,
      color: AppTheme.grey600,
    );

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Titik penanda: warnanya sama dengan titik di depan nama
        // pada tabel, jadi pembaca tahu ini ringkasan kategori mana.
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const Text('—', style: labelStyle),
        const Text('Hadir ', style: labelStyle),
        Text('${stats.hadir}', style: valueStyle),
        const Text('·', style: labelStyle),
        const Text('Sudah Keluar ', style: labelStyle),
        Text('${stats.sudahKeluar}', style: valueStyle),
        const Text('·', style: labelStyle),
        const Text('Belum Hadir ', style: labelStyle),
        Text('${stats.belumHadir}', style: valueStyle),
      ],
    );
  }

  Widget _buildSpreadsheet() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.how_to_reg, size: 48, color: AppTheme.grey300),
            SizedBox(height: 10),
            Text(
              'Belum ada yang absen hari ini',
              style: TextStyle(fontSize: 15, color: AppTheme.grey500),
            ),
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.grey300),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sheetHeader(),
          Expanded(
            child: Scrollbar(
              controller: _listScrollCtrl,
              thumbVisibility: _items.length > 8,
              child: ListView.builder(
                controller: _listScrollCtrl,
                itemCount: _items.length,
                itemBuilder: (context, index) =>
                    _sheetRow(_items[index], index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Lebar kolom tabel (relatif): NO · NAMA · JAM MASUK · JAM KELUAR · STATUS
  static const List<int> _sheetFlex = [1, 6, 2, 2, 2];

  /// Lebar kolom versi POTRAIT: nama dibuat lebih luas, sedangkan nomor dan
  /// status dipersempit, karena layar tegak lebih sempit.
  static const List<int> _sheetFlexPortrait = [1, 10, 3, 3, 3];

  List<int> get _flex =>
      MediaQuery.of(context).orientation == Orientation.portrait
          ? _sheetFlexPortrait
          : _sheetFlex;

  static const TextStyle _sheetHeaderStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 0.8,
  );

  Widget _sheetHeader() {
    return Container(
      height: 46,
      color: AppTheme.primary,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sheetCell(
            const Text('NO', style: _sheetHeaderStyle),
            flex: _flex[0],
            header: true,
          ),
          _sheetCell(
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('NAMA', style: _sheetHeaderStyle),
            ),
            flex: _flex[1],
            header: true,
          ),
          _sheetCell(
            const Text('JAM MASUK', style: _sheetHeaderStyle),
            flex: _flex[2],
            header: true,
          ),
          _sheetCell(
            const Text('JAM KELUAR', style: _sheetHeaderStyle),
            flex: _flex[3],
            header: true,
          ),
          _sheetCell(
            const Text('STATUS', style: _sheetHeaderStyle),
            flex: _flex[4],
            header: true,
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _sheetRow(_LiveDisplayItem item, int index) {
    final sudahKeluar = item.jamKeluar != null;
    final isNewest = index == 0;
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isNewest
            ? AppTheme.primaryLight
            : (index.isEven ? Colors.white : AppTheme.grey50),
        border: const Border(
          bottom: BorderSide(color: AppTheme.grey200),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sheetCell(
            Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.grey500,
              ),
            ),
            flex: _flex[0],
          ),
          _sheetCell(
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: item.musyrifah
                          ? AppTheme.orange
                          : AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isNewest ? FontWeight.bold : FontWeight.w600,
                        color: AppTheme.grey800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            flex: _flex[1],
          ),
          _sheetCell(
            Text(
              _shortTime(item.jamMasuk),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryDark,
              ),
            ),
            flex: _flex[2],
          ),
          _sheetCell(
            Text(
              sudahKeluar ? _shortTime(item.jamKeluar!) : '-',
              style: TextStyle(
                fontSize: 15,
                fontWeight: sudahKeluar ? FontWeight.w700 : FontWeight.w400,
                color: sudahKeluar ? AppTheme.orange : AppTheme.grey400,
              ),
            ),
            flex: _flex[3],
          ),
          _sheetCell(
            _statusChip(sudahKeluar),
            flex: _flex[4],
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _sheetCell(
    Widget child, {
    required int flex,
    bool last = false,
    bool header = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: last
            ? null
            : BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: header ? Colors.white24 : AppTheme.grey200,
                  ),
                ),
              ),
        child: child,
      ),
    );
  }

  Widget _statusChip(bool sudahKeluar) {
    final color = sudahKeluar ? AppTheme.orange : AppTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        sudahKeluar ? 'KELUAR' : 'HADIR',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }

  Widget _buildWelcomeOverlay() {
    final nama = _welcomeName;
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedOpacity(
        opacity: nama != null ? 1 : 0,
        duration: const Duration(milliseconds: 400),
        child: nama == null
            ? const SizedBox.shrink()
            : Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.waving_hand,
                        color: Colors.white, size: 26),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Selamat datang, $nama!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
