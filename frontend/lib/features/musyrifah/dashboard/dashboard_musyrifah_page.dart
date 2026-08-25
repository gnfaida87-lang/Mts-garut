import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/musyrifah_service.dart';

class DashboardMusyrifahPage extends StatefulWidget {
  final void Function(String feature)? onFeatureTap;
  const DashboardMusyrifahPage({super.key, this.onFeatureTap});

  @override
  State<DashboardMusyrifahPage> createState() => _DashboardMusyrifahPageState();
}

class _DashboardMusyrifahPageState extends State<DashboardMusyrifahPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  String _greeting = '';

  @override
  void initState() {
    super.initState();
    _setGreeting();
    _load();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    setState(() {
      if (hour < 10) {
        _greeting = 'Selamat Pagi';
      } else if (hour < 15) {
        _greeting = 'Selamat Siang';
      } else if (hour < 18) {
        _greeting = 'Selamat Sore';
      } else {
        _greeting = 'Selamat Malam';
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await MusyrifahService.getDashboard();
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 14)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final name = _data?['nama'] ?? 'Musyrifah';
    final jadwalList = (_data?['jadwal_hari_ini'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final sudahAbsen = _data?['sudah_absen'] == true;

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(name, sudahAbsen, jadwalList.length),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  _buildSectionTitle('Jadwal Hari Ini'),
                  const SizedBox(height: 16),
                  if (jadwalList.isEmpty)
                    _buildEmptyJadwal()
                  else
                    ...jadwalList.map((j) => _buildJadwalCard(j)),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Menu Utama'),
                  const SizedBox(height: 16),
                  _buildFeatureGrid(),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'Sistem Informasi MA Persis Garut',
                      style: TextStyle(color: AppTheme.grey400, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name, bool sudahAbsen, int jadwalCount) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Padding(
          padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).viewPadding.top + 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _load,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildHeaderChip(
                    Icons.check_circle_outline,
                    sudahAbsen ? 'Sudah Absen' : 'Belum Absen',
                    color: sudahAbsen ? const Color(0xFFB08968) : Colors.orangeAccent,
                  ),
                  const SizedBox(width: 12),
                  _buildHeaderChip(
                    Icons.calendar_today_outlined,
                    '$jadwalCount Jadwal',
                  ),
                ],
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildHeaderChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color ?? Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.grey800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyJadwal() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.event_busy_outlined, size: 40, color: AppTheme.grey300),
            SizedBox(height: 12),
            Text(
              'Tidak ada jadwal hari ini',
              style: TextStyle(color: AppTheme.grey500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJadwalCard(Map<String, dynamic> jadwal) {
    final namaProgram = jadwal['nama_program']?.toString() ?? '-';
    final hari = jadwal['hari']?.toString() ?? '-';
    final jamMulai = jadwal['jam_mulai']?.toString() ?? '';
    final jamSelesai = jadwal['jam_selesai']?.toString() ?? '';
    final kelasNama = jadwal['kelas_nama']?.toString() ?? '-';
    final jenisDauroh = jadwal['jenis_dauroh']?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              jenisDauroh == 'tahfidz' ? Icons.menu_book_outlined : Icons.chrome_reader_mode_outlined,
              color: AppTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaProgram,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '$hari, $jamMulai - $jamSelesai',
                  style: const TextStyle(fontSize: 12, color: AppTheme.grey500),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kelas: $kelasNama',
                  style: const TextStyle(fontSize: 12, color: AppTheme.grey500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      _FeatureItem(Icons.calendar_month_outlined, 'Jadwal', 'Lihat jadwal mengajar', () => widget.onFeatureTap?.call('jadwal')),
      _FeatureItem(Icons.qr_code_scanner, 'Scan QR', 'Absensi at-Ta\'wid', () => widget.onFeatureTap?.call('scan-qr')),
      _FeatureItem(Icons.history, 'Riwayat', 'Riwayat absensi', () => widget.onFeatureTap?.call('riwayat')),
      _FeatureItem(Icons.grading_outlined, 'Nilai', 'Input & lihat nilai', () => widget.onFeatureTap?.call('nilai')),
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.4,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      itemBuilder: (_, i) => _buildFeatureCard(features[i]),
    );
  }

  Widget _buildFeatureCard(_FeatureItem item) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: item.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.grey200),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryLight,
                      AppTheme.primary.withValues(alpha: 0.2),
                    ],
                  ),
                ),
                child: Icon(item.icon, color: AppTheme.primaryDark, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.grey700),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppTheme.grey400),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  _FeatureItem(this.icon, this.title, this.subtitle, this.onTap);
}
