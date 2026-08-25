import 'package:flutter/material.dart';
import '../../../../shared/widgets/dashboard_template.dart';
import '../../../../shared/widgets/app_utils.dart';
import '../../../../shared/models/user_model.dart';
import '../services/guru_service.dart';

class DashboardPageGuru extends StatefulWidget {
  final void Function(String feature) onFeatureTap;
  const DashboardPageGuru({super.key, required this.onFeatureTap});

  @override
  State<DashboardPageGuru> createState() => _DashboardPageGuruState();
}

class _DashboardPageGuruState extends State<DashboardPageGuru> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  bool _isWaliKelas = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await GuruService.getDashboard();
      final wali = await GuruService.cekWaliKelas();
      if (mounted) setState(() { _stats = data; _isWaliKelas = wali['is_wali_kelas'] == true; });
    } catch (e) {
      if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat dashboard');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final features = <FeatureItem>[
      const FeatureItem('Absensi', 'absensi', Icons.checklist_outlined, 'Input & rekap kehadiran'),
      const FeatureItem('Jadwal', 'jadwal', Icons.calendar_month_outlined, 'Lihat jadwal mengajar'),
      const FeatureItem('Nilai', 'nilai', Icons.grading_outlined, 'Input & kelola nilai siswa'),
      const FeatureItem('Materi', 'materi', Icons.menu_book_outlined, 'Upload & kelola materi'),
      if (_isWaliKelas) ...[
        const FeatureItem('Rapor', 'rapor', Icons.assignment_outlined, 'Cetak rapor siswa'),
        const FeatureItem('Wali Kelas', 'wali-kelas', Icons.people_outlined, 'Kelola data wali kelas'),
      ],
      const FeatureItem('Pengaduan', 'pengaduan', Icons.warning_amber_outlined, 'Lapor & pantau pengaduan', isSecondary: true),
    ];

    return DashboardTemplate(
      loading: _loading,
      showHeader: true,
      roleDisplay: UserModel.jabatanGuru(isWaliKelas: _isWaliKelas),
      stats: [
        StatItem(Icons.calendar_today, 'Jadwal Hari Ini', '${_stats?['jadwal_hari_ini'] ?? 0}', Colors.blue),
        StatItem(Icons.checklist, 'Total Absensi', '${_stats?['total_absensi'] ?? 0}', const Color(0xFF9C6644)),
        StatItem(Icons.grading, 'Total Nilai', '${_stats?['total_nilai'] ?? 0}', Colors.orange),
        StatItem(Icons.warning_amber, 'Pengaduan Aktif', '${_stats?['pengaduan_aktif'] ?? 0}', Colors.red),
      ],
      features: features,
      onFeatureTap: widget.onFeatureTap,
    );
  }
}
