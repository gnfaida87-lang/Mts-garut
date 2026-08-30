import 'package:flutter/material.dart';
import '../../../shared/widgets/app_utils.dart';
import '../services/kepala_sekolah_service.dart';

class BKPageKS extends StatefulWidget {
  const BKPageKS({super.key});

  @override
  State<BKPageKS> createState() => _BKPageKSState();
}

class _BKPageKSState extends State<BKPageKS> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await KepalaSekolahService.getBK();
      if (!mounted) return;
      _data = data;
    } catch (e) { if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat data monitoring'); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_data == null) return const Center(child: Text('Gagal memuat data'));

    final konseling = _data!['konseling_per_bulan'] as List<dynamic>? ?? [];
    final bakatMinat = _data!['bakat_minat_per_jenis'] as List<dynamic>? ?? [];
    final siswaBermasalah = _data!['siswa_bermasalah'] as List<dynamic>? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Konseling per Bulan', style: Theme.of(context).textTheme.titleMedium),
        ...konseling.map((k) {
          final m = k as Map<String, dynamic>;
          return Card(child: ListTile(title: Text(m['periode'] ?? ''), trailing: Text('${m['total']} sesi')));
        }),
        const SizedBox(height: 16),
        Text('Bakat & Minat per Jenis', style: Theme.of(context).textTheme.titleMedium),
        ...bakatMinat.map((b) {
          final m = b as Map<String, dynamic>;
          return Card(child: ListTile(title: Text(m['jenis'] ?? ''), subtitle: Text('${m['siswa']} santri'), trailing: Text('${m['total']}')));
        }),
        const SizedBox(height: 16),
        Text('Santri dengan Pelanggaran Terbanyak', style: Theme.of(context).textTheme.titleMedium),
        ...siswaBermasalah.map((s) {
          final m = s as Map<String, dynamic>;
          return Card(child: ListTile(title: Text(m['siswa_nama'] ?? ''), subtitle: Text('${m['kelas_nama']} - ${m['nis']}'), trailing: Text('${m['total_pengaduan']} kasus')));
        }),
      ],
    );
  }
}
