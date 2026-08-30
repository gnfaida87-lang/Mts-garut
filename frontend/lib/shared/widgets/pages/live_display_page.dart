import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../config/env.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

/// Papan Absensi Asatidz Live - untuk monitor/TV di pintu masuk.
///
/// Halaman publik (tanpa login): menampilkan QR absensi di kiri dan
/// daftar hadir live di kanan. Data diperbarui otomatis tiap 5 detik.
class LiveDisplayPage extends StatefulWidget {
  const LiveDisplayPage({super.key});

  @override
  State<LiveDisplayPage> createState() => _LiveDisplayPageState();
}

class _LiveDisplayItem {
  final String nama;
  final String jamMasuk;
  final String? jamKeluar;

  const _LiveDisplayItem({
    required this.nama,
    required this.jamMasuk,
    this.jamKeluar,
  });

  factory _LiveDisplayItem.fromJson(Map<String, dynamic> json) {
    return _LiveDisplayItem(
      nama: json['nama']?.toString() ?? '-',
      jamMasuk: json['jam_masuk']?.toString() ?? '',
      jamKeluar: json['jam_keluar']?.toString(),
    );
  }

  String get signature => '$nama|$jamMasuk';
}

class _LiveDisplayStats {
  final int totalAsatidz;
  final int hadir;
  final int sudahKeluar;
  final int belumHadir;

  const _LiveDisplayStats({
    required this.totalAsatidz,
    required this.hadir,
    required this.sudahKeluar,
    required this.belumHadir,
  });

  static const empty = _LiveDisplayStats(
    totalAsatidz: 0,
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

  DateTime _nowWib = DateTime.now().toUtc().add(const Duration(hours: 7));
  List<_LiveDisplayItem> _items = const [];
  _LiveDisplayStats _stats = _LiveDisplayStats.empty;
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
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final body = await ApiClient.get('/public/absensi-hari-ini');
      if (!mounted) return;
      final data = body['data'] as Map<String, dynamic>? ?? {};
      final itemsRaw = (data['items'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(_LiveDisplayItem.fromJson)
          .toList();
      final statRaw = data['statistik'] as Map<String, dynamic>? ?? {};

      final newSignature =
          itemsRaw.isNotEmpty ? itemsRaw.first.signature : null;

      setState(() {
        _items = itemsRaw;
        _stats = _LiveDisplayStats(
          totalAsatidz: (statRaw['total_asatidz'] as num?)?.toInt() ?? 0,
          hadir: (statRaw['hadir'] as num?)?.toInt() ?? 0,
          sudahKeluar: (statRaw['sudah_keluar'] as num?)?.toInt() ?? 0,
          belumHadir: (statRaw['belum_hadir'] as num?)?.toInt() ?? 0,
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
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 900;

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
                    padding: const EdgeInsets.all(16),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 4, child: _buildQrPanel()),
                              const SizedBox(width: 16),
                              Expanded(flex: 6, child: _buildListPanel()),
                            ],
                          )
                        : Column(
                            children: [
                              SizedBox(
                                height: size.height * 0.44,
                                child: _buildQrPanel(),
                              ),
                              const SizedBox(height: 12),
                              Expanded(child: _buildListPanel()),
                            ],
                          ),
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
                  'Papan Absensi Asatidz - Live',
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

  Widget _buildQrPanel() {
    final size = MediaQuery.of(context).size;
    final qrSize = (size.width >= 900 ? size.width * 0.26 : size.width * 0.55)
        .clamp(180.0, 320.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statusDot(),
              const SizedBox(width: 8),
              Text(
                _offline ? 'KONEKSI TERPUTUS' : 'SCAN UNTUK ABSENSI',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: _offline ? AppTheme.error : AppTheme.grey800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.grey200),
            ),
            child: QrImageView(
              data: Env.qrAbsensiToken,
              version: QrVersions.auto,
              size: qrSize,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppTheme.grey900,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppTheme.grey900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Buka aplikasi, tap Scan,\narahkan kamera ke QR ini',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.grey600, height: 1.4),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'DAFTAR HADIR HARI INI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.grey800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                _updatedText,
                style: const TextStyle(fontSize: 11, color: AppTheme.grey400),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatsRow(),
          const SizedBox(height: 12),
          Expanded(child: _buildListBody()),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statCard('Hadir', _stats.hadir, AppTheme.primary, Icons.check_circle),
        const SizedBox(width: 10),
        _statCard(
            'Sudah Keluar', _stats.sudahKeluar, AppTheme.orange, Icons.logout),
        const SizedBox(width: 10),
        _statCard(
            'Belum Hadir', _stats.belumHadir, AppTheme.grey500, Icons.schedule),
      ],
    );
  }

  Widget _statCard(String label, int value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text('$value',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: AppTheme.grey600)),
          ],
        ),
      ),
    );
  }

  Widget _buildListBody() {
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
              'Belum ada asatidz yang absen hari ini',
              style: TextStyle(fontSize: 15, color: AppTheme.grey500),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildListItem(_items[index], index),
    );
  }

  Widget _buildListItem(_LiveDisplayItem item, int index) {
    final sudahKeluar = item.jamKeluar != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: index == 0 ? AppTheme.primaryLight : AppTheme.grey50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              index == 0 ? AppTheme.primary.withValues(alpha: 0.35) : AppTheme.grey200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: sudahKeluar
                  ? AppTheme.orange.withValues(alpha: 0.15)
                  : AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              sudahKeluar ? Icons.logout : Icons.check,
              size: 20,
              color: sudahKeluar ? AppTheme.orange : Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.nama,
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    index == 0 ? FontWeight.bold : FontWeight.w600,
                color: AppTheme.grey800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _shortTime(item.jamMasuk),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryDark,
                ),
              ),
              if (sudahKeluar)
                Text(
                  'keluar ${_shortTime(item.jamKeluar!)}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.orange),
                )
              else
                const Text('masuk',
                    style:
                        TextStyle(fontSize: 11, color: AppTheme.grey400)),
            ],
          ),
        ],
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
