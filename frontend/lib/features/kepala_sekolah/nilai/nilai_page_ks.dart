import 'package:flutter/material.dart';
import '../../../shared/widgets/app_utils.dart';
import '../services/kepala_sekolah_service.dart';

class NilaiPageKS extends StatefulWidget {
  const NilaiPageKS({super.key});

  @override
  State<NilaiPageKS> createState() => _NilaiPageKSState();
}

class _NilaiPageKSState extends State<NilaiPageKS> {
  List<dynamic> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await KepalaSekolahService.getNilai();
      if (!mounted) return;
      _data = data;
    } catch (e) { if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat data nilai'); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_data.isEmpty) return const Center(child: Text('Belum ada data nilai'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _data.length,
      itemBuilder: (ctx, i) {
        final d = _data[i] as Map<String, dynamic>;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d['mapel_nama'] ?? '-', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Kelas: ${d['kelas_nama']} | Jenis: ${d['jenis']}'),
                Text('Rata-rata: ${d['rata_rata']} (min: ${d['min']}, max: ${d['max']})'),
              ],
            ),
          ),
        );
      },
    );
  }
}
