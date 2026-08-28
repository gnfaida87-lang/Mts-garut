import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/dashboard_template.dart';
import '../services/wakil_kurikulum_service.dart';

class DashboardPageWK extends StatefulWidget {
  final void Function(String feature) onFeatureTap;
  const DashboardPageWK({super.key, required this.onFeatureTap});

  @override
  State<DashboardPageWK> createState() => _DashboardPageWKState();
}

class _DashboardPageWKState extends State<DashboardPageWK> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _data = await WakilKurikulumService.getDashboard(); }
    catch (_) { debugPrint('[dashboard_page.dart] error caught'); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DashboardTemplate(
      loading: _loading,
      stats: [
        StatItem(Icons.calendar_month_outlined, 'Jadwal', '${_data?['jadwal'] ?? 0}', AppTheme.blue),
        StatItem(Icons.grading_outlined, 'Total Nilai', '${_data?['total_nilai'] ?? 0}', AppTheme.primary),
        StatItem(Icons.pending_outlined, 'Nilai Draft', '${_data?['nilai_belum_divalidasi'] ?? 0}', AppTheme.orange),
      ],
      features: const [
        FeatureItem('Absensi', 'absensi', Icons.checklist_outlined, 'Rekap kehadiran siswa & guru'),
        FeatureItem('Penjadwalan', 'penjadwalan', Icons.calendar_month_outlined, 'Atur jadwal pelajaran'),
        FeatureItem('Nilai', 'nilai', Icons.grading_outlined, 'Validasi & kelola nilai'),
        FeatureItem('at-Ta\'wid', 'dauroh', Icons.bookmark_outlined, 'Monitoring nilai at-Ta\'wid'),
        FeatureItem('Kenaikan Kelas', 'kenaikan-kelas', Icons.trending_up_outlined, 'Proses kenaikan kelas'),
        FeatureItem('Laporan', 'laporan', Icons.description_outlined, 'Generate laporan akademik', isSecondary: true),
      ],
      onFeatureTap: widget.onFeatureTap,
    );
  }
}