import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_utils.dart';
import '../services/wakil_kurikulum_service.dart';

class LaporanPageWK extends StatefulWidget {
  const LaporanPageWK({super.key});

  @override
  State<LaporanPageWK> createState() => _LaporanPageWKState();
}

class _LaporanPageWKState extends State<LaporanPageWK> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Map<String, dynamic>> _data = [];
  bool _loading = false;
  String _jenis = 'jadwal';

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 4, vsync: this); _load(); }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await WakilKurikulumService.getLaporan(_jenis);
      _data = res.cast<Map<String, dynamic>>();
    } catch (e) {
      _data = [];
      if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat laporan');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
            onTap: (i) {
              _jenis = ['jadwal', 'absensi', 'nilai', 'rapor'][i];
              _load();
            },
            tabs: const [
              Tab(text: 'Jadwal'), Tab(text: 'Absensi'), Tab(text: 'Nilai'), Tab(text: 'Rapor'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : _data.isEmpty
                  ? const Center(child: Text('Tidak ada data.', style: TextStyle(color: AppTheme.grey500)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _data.length,
                      itemBuilder: (_, i) {
                        final d = _data[i];
                        return Card(child: ListTile(
                          title: Text(_formatTitle(d), style: const TextStyle(fontSize: 13)),
                          subtitle: Text(_formatSubtitle(d), style: const TextStyle(fontSize: 11, color: AppTheme.grey500)),
                        ));
                      },
                    ),
        ),
      ],
    );
  }

  String _formatTitle(Map<String, dynamic> d) {
    switch (_jenis) {
      case 'jadwal': return '${d['hari'] ?? '-'} | ${d['jam_mulai'] ?? '-'}-${d['jam_selesai'] ?? '-'} | ${d['mapel'] ?? '-'}';
      case 'absensi': return '${d['siswa_nama'] ?? '-'} | ${d['status'] ?? '-'}';
      case 'nilai': return '${d['siswa_nama'] ?? '-'} | ${d['mapel_nama'] ?? '-'} | ${d['nilai'] ?? ''}';
      case 'rapor': return '${d['siswa_nama'] ?? '-'} | ${d['mapel_nama'] ?? '-'} | ${d['nilai_akhir'] ?? ''}';
      default: return '-';
    }
  }

  String _formatSubtitle(Map<String, dynamic> d) {
    switch (_jenis) {
      case 'jadwal': return 'Asatidz: ${d['guru'] ?? '-'} | Kelas: ${d['kelas'] ?? '-'} | Ruang: ${d['ruangan'] ?? '-'}';
      case 'absensi': return 'Kelas: ${d['kelas_nama'] ?? '-'} | Tgl: ${d['tanggal'] ?? '-'}';
      case 'nilai': return 'Kelas: ${d['kelas_nama'] ?? '-'} | ${d['jenis'] ?? '-'} | ${d['status_validasi'] ?? '-'}';
      case 'rapor': return 'Kelas: ${d['kelas_nama'] ?? '-'} | ${d['predikat'] ?? ''} | ${d['status_kirim'] ?? '-'}';
      default: return '-';
    }
  }
}
