import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/dashboard_template.dart';
import '../services/santri_service.dart';
import '../services/dauroh_santri_service.dart';

class DashboardSantriPage extends StatefulWidget {
  final void Function(String) onFeatureTap;

  const DashboardSantriPage({super.key, required this.onFeatureTap});

  @override
  State<DashboardSantriPage> createState() => _DashboardSantriPageState();
}

class _DashboardSantriPageState extends State<DashboardSantriPage> {
  final _service = SantriService();
  final _daurohService = DaurohSantriService();
  List<Map<String, dynamic>> _jadwalHariIni = [];
  int _totalHadir = 0;
  int _totalAbsensi = 0;
  double _rataRataNilai = 0;
  int _totalProgramDauroh = 0;
  bool _loading = true;
  
  // Data profil santri
  String? _nis;
  String? _waliKelas;
  String? _kelas;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      const hariNames = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      final hariIni = hariNames[DateTime.now().weekday % 7];
      final now = DateTime.now();
      final bulan = now.month.toString();
      final tahun = now.year.toString();

      // Fetch semua data secara paralel
      final results = await Future.wait([
        _service.getJadwal(hari: hariIni),
        _service.getAbsensi(bulan: bulan, tahun: tahun),
        _service.getNilai(),
        _daurohService.getProgram(),
        _service.getProfil(),  // Tambahkan fetch profil
      ]);

      final jadwal = results[0] as List<Map<String, dynamic>>;
      final absensiRes = results[1] as Map<String, dynamic>;
      final nilaiRes = results[2] as Map<String, dynamic>;
      final programDauroh = results[3] as List<Map<String, dynamic>>;
      final profil = results[4] as Map<String, dynamic>;

      final absensiData = (absensiRes['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      int hadir = 0;
      for (final a in absensiData) {
        if (a['status'] == 'hadir') hadir++;
      }

      if (mounted) {
        setState(() {
          _jadwalHariIni = jadwal;
          _totalAbsensi = absensiData.length;
          _totalHadir = hadir;
          _rataRataNilai = (nilaiRes['rata_rata_keseluruhan'] as num?)?.toDouble() ?? 0;
          _totalProgramDauroh = programDauroh.length;
          _loading = false;
          
          // Simpan data profil
          _nis = profil['nis']?.toString();
          _waliKelas = profil['wali_kelas']?.toString();
          _kelas = profil['kelas']?['nama']?.toString();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardTemplate(
      loading: _loading,
      subtitle: _nis,
      info1: _waliKelas,
      info2: _kelas,
      stats: [
        StatItem(Icons.schedule, 'Jadwal Hari Ini', '${_jadwalHariIni.length} Mapel', AppTheme.primary),
        StatItem(Icons.how_to_reg, 'Kehadiran', '$_totalHadir dari $_totalAbsensi', const Color(0xFF9C6644)),
        StatItem(Icons.grade, 'Rata-rata Nilai', _rataRataNilai.toStringAsFixed(1), Colors.orange),
        StatItem(Icons.bookmark, 'Program at-Ta\'wid', '$_totalProgramDauroh Program', Colors.purple),
      ],
      features: const [
        FeatureItem('Jadwal', 'jadwal', Icons.calendar_today, 'Lihat jadwal pelajaran'),
        FeatureItem('Absensi', 'absensi', Icons.how_to_reg, 'Riwayat kehadiran'),
        FeatureItem('Nilai', 'nilai', Icons.grade, 'Nilai akademik'),
        FeatureItem('Materi', 'materi', Icons.menu_book, 'Materi pelajaran'),
        FeatureItem('at-Ta\'wid', 'dauroh', Icons.bookmark, 'Program at-Ta\'wid & Nilai'),
        FeatureItem('Idarat al-Madfu\'at', 'idarat', Icons.account_balance_wallet, 'Administrasi Pembayaran'),
      ],
      onFeatureTap: widget.onFeatureTap,
    );
  }
}
