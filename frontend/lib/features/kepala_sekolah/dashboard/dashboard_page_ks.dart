import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_utils.dart';
import '../../../shared/widgets/dashboard_template.dart';
import '../services/kepala_sekolah_service.dart';

class DashboardPageKS extends StatefulWidget {
  final void Function(String feature)? onFeatureTap;
  const DashboardPageKS({super.key, this.onFeatureTap});

  @override
  State<DashboardPageKS> createState() => _DashboardPageKSState();
}

class _DashboardPageKSState extends State<DashboardPageKS> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      _data = await KepalaSekolahService.getDashboard();
    } catch (e) { if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat dashboard'); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final stats = _data?['statistik'] as Map<String, dynamic>? ?? {};

    return DashboardTemplate(
      loading: _loading,
      stats: [
        StatItem(Icons.people_outline, 'Santri Aktif', '${stats['total_siswa'] ?? 0}', AppTheme.primary),
        StatItem(Icons.school_outlined, 'Asatidz', '${stats['total_guru'] ?? 0}', AppTheme.primaryDark),
        StatItem(Icons.meeting_room_outlined, 'Kelas', '${stats['total_kelas'] ?? 0}', AppTheme.secondary),
        StatItem(Icons.book_outlined, 'Mapel', '${stats['total_mapel'] ?? 0}', AppTheme.blue),
      ],
      features: const [
        FeatureItem('Jadwal', 'jadwal', Icons.calendar_month_outlined, 'Jadwal pelajaran'),
        FeatureItem('Absensi', 'absensi', Icons.checklist_outlined, 'Monitoring kehadiran'),
        FeatureItem('Nilai', 'nilai', Icons.grading_outlined, 'Rekap nilai akademik'),
        FeatureItem('Rapor', 'rapor', Icons.assignment_outlined, 'Nilai rapor santri'),
        FeatureItem('at-Ta\'wid', 'dauroh', Icons.bookmark_outlined, 'Monitoring nilai at-Ta\'wid'),
        FeatureItem('Laporan', 'laporan', Icons.description_outlined, 'Generate & unduh laporan'),
        FeatureItem('Monitoring', 'monitoring', Icons.trending_up_outlined, 'Pantau aktivitas sekolah'),
      ],
      onFeatureTap: widget.onFeatureTap,
    );
  }
}