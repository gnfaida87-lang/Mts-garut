import 'package:flutter/material.dart';
import '../../../shared/widgets/app_utils.dart';
import '../services/kepala_sekolah_service.dart';

class RaporPageKS extends StatefulWidget {
  const RaporPageKS({super.key});

  @override
  State<RaporPageKS> createState() => _RaporPageKSState();
}

class _RaporPageKSState extends State<RaporPageKS> {
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
      final data = await KepalaSekolahService.getRapor();
      if (!mounted) return;
      _data = data;
    } catch (e) { if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat data rapor'); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_data.isEmpty) return const Center(child: Text('Belum ada data rapor'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _data.length,
      itemBuilder: (ctx, i) {
        final d = _data[i] as Map<String, dynamic>;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                ((d['siswa_nama'] as String? ?? '').isNotEmpty ? d['siswa_nama'] as String : '?').substring(0, 1),
              ),
            ),
            title: Text(d['siswa_nama'] ?? ''),
            subtitle: Text('${d['mapel_nama']} - ${d['kelas_nama']}'),
            trailing: Text('Nilai: ${d['nilai'] ?? '-'}'),
          ),
        );
      },
    );
  }
}
