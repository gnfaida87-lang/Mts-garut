import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/admin_service.dart';

class DashboardPage extends StatefulWidget {
  final void Function(String feature)? onFeatureTap;
  const DashboardPage({super.key, this.onFeatureTap});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
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
      final data = await AdminService.getDashboard();
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: _loading
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
    final r = _data!['ringkasan'] as Map<String, dynamic>;
    final d = _data!['detail'] as Map<String, dynamic>;

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(r),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  _buildSectionTitle('Ringkasan Data'),
                  const SizedBox(height: 16),
                  _buildStatGrid(r),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Statistik Detail'),
                  const SizedBox(height: 16),
                  _buildDetailGrid(d),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Menu Fitur'),
                  const SizedBox(height: 16),
                  _buildFeatureGrid(),
                  const SizedBox(height: 24),
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> r) {
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
                      const Text(
                        'Dashboard Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
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
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildHeaderChip(Icons.people_outline, '${r['guru'] ?? 0} Asatidz'),
                  const SizedBox(width: 12),
                  _buildHeaderChip(Icons.person_outline, '${r['siswa'] ?? 0} Santri'),
                  const SizedBox(width: 12),
                  _buildHeaderChip(Icons.meeting_room_outlined, '${r['kelas'] ?? 0} Kelas'),
                ],
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildHeaderChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
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

  Widget _buildStatGrid(Map<String, dynamic> r) {
    final stats = [
      _StatItem(Icons.people_outline, 'Asatidz', '${r['guru'] ?? 0}', AppTheme.primary, AppTheme.primaryLight),
      _StatItem(Icons.person_outline, 'Santri', '${r['siswa'] ?? 0}', AppTheme.secondary, AppTheme.secondaryLight),
      _StatItem(Icons.meeting_room_outlined, 'Kelas', '${r['kelas'] ?? 0}', AppTheme.blue, AppTheme.blueLight),
      _StatItem(Icons.checklist_outlined, 'Absensi Hari Ini', '${r['absensi_hari_ini'] ?? 0}', AppTheme.orange, AppTheme.orangeLight),
      _StatItem(Icons.grading_outlined, 'Nilai', '${r['nilai'] ?? 0}', AppTheme.teal, AppTheme.primaryLight),
      _StatItem(Icons.calendar_month_outlined, 'Jadwal', '${r['jadwal'] ?? 0}', AppTheme.indigo, AppTheme.primaryLight),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.6,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          itemBuilder: (_, i) => _ModernStatCard(item: stats[i]),
        );
      },
    );
  }

  Widget _buildDetailGrid(Map<String, dynamic> d) {
    final details = [
      _DetailInfo('Statistik Asatidz', d['guru'] as Map<String, dynamic>? ?? {}, Icons.people_outline, AppTheme.primary),
      _DetailInfo('Statistik Santri', d['siswa'] as Map<String, dynamic>? ?? {}, Icons.person_outline, AppTheme.secondary),
      _DetailInfo('Absensi Hari Ini', d['absensi'] as Map<String, dynamic>? ?? {}, Icons.checklist_outlined, AppTheme.blue),
      _DetailInfo('Statistik Nilai', d['nilai'] as Map<String, dynamic>? ?? {}, Icons.grading_outlined, AppTheme.teal),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 900 ? 2 : 1;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: cols > 1 ? 1.8 : 2.2,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: details.length,
          itemBuilder: (_, i) => _ModernDetailCard(info: details[i]),
        );
      },
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      _FeatureItem(Icons.storage_outlined, 'Master Data', 'Kelola data master', () => widget.onFeatureTap?.call('master-data')),
      _FeatureItem(Icons.menu_book_outlined, 'at-Ta\'wid', 'Kelola program at-Ta\'wid', () => widget.onFeatureTap?.call('dauroh')),
      _FeatureItem(Icons.calendar_today_outlined, 'Absensi', 'Monitoring absensi', () => widget.onFeatureTap?.call('absensi')),
      _FeatureItem(Icons.grading_outlined, 'Nilai', 'Monitoring nilai', () => widget.onFeatureTap?.call('nilai')),
      _FeatureItem(Icons.description_outlined, 'Rapor', 'Monitoring rapor', () => widget.onFeatureTap?.call('rapor')),
      _FeatureItem(Icons.qr_code, 'QR Absensi', 'Cetak QR Code absensi', () => widget.onFeatureTap?.call('qr-absensi'), isSecondary: true),
      _FeatureItem(Icons.settings_outlined, 'Pengaturan', 'Pengaturan sistem', () => widget.onFeatureTap?.call('pengaturan'), isSecondary: true),
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.0,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      itemBuilder: (_, i) => _buildFeatureCard(features[i]),
    );
  }

  Widget _buildFeatureCard(_FeatureItem item) {
    final primaryColor = item.isSecondary ? AppTheme.secondary : AppTheme.primary;
    final bgColor = item.isSecondary ? AppTheme.secondaryLight : AppTheme.primaryLight;
    final iconColor = item.isSecondary ? AppTheme.orange : AppTheme.primaryDark;

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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      bgColor,
                      primaryColor.withValues(alpha: 0.2),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(item.icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppTheme.grey700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.grey400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return const Center(
      child: Text(
        'Sistem Informasi MTs Persis Garut',
        style: TextStyle(color: AppTheme.grey400, fontSize: 12),
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isSecondary;
  _FeatureItem(this.icon, this.title, this.subtitle, this.onTap, {this.isSecondary = false});
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  _StatItem(this.icon, this.label, this.value, this.color, this.bgColor);
}

class _ModernStatCard extends StatelessWidget {
  final _StatItem item;
  const _ModernStatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.grey200),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
            ],
          ),
          const Spacer(),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: item.color,
              height: 1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: const TextStyle(fontSize: 13, color: AppTheme.grey500, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _DetailInfo {
  final String title;
  final Map<String, dynamic> data;
  final IconData icon;
  final Color color;
  _DetailInfo(this.title, this.data, this.icon, this.color);
}

class _ModernDetailCard extends StatelessWidget {
  final _DetailInfo info;
  const _ModernDetailCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.grey200),
        boxShadow: [
          BoxShadow(
            color: info.color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(info.icon, color: info.color, size: 20),
              const SizedBox(width: 8),
              Text(
                info.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.grey800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (info.data.isEmpty)
            const Text('Belum ada data', style: TextStyle(color: AppTheme.grey400, fontSize: 14))
          else
            ...info.data.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: info.color.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${e.key}: ${e.value}',
                          style: const TextStyle(color: AppTheme.grey600, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
