import 'package:flutter/material.dart';
import '../../../shared/widgets/app_utils.dart';
import '../services/kepala_sekolah_service.dart';

class JadwalPageKS extends StatefulWidget {
  const JadwalPageKS({super.key});

  @override
  State<JadwalPageKS> createState() => _JadwalPageKSState();
}

class _JadwalPageKSState extends State<JadwalPageKS> {
  List<dynamic> _jadwal = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await KepalaSekolahService.getJadwal();
      if (!mounted) return;
      _jadwal = data;
    } catch (e) { if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat data jadwal'); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_jadwal.isEmpty) return const Center(child: Text('Belum ada data jadwal'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _jadwal.length,
      itemBuilder: (ctx, i) {
        final j = _jadwal[i] as Map<String, dynamic>;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                ((j['hari']?.toString() ?? '').isNotEmpty ? j['hari'].toString() : '-').substring(0, 1),
              ),
            ),
            title: Text(j['mapel_nama'] ?? ''),
            subtitle: Text('${j['guru_nama']} - ${j['kelas_nama']}'),
            trailing: Text('${j['jam_mulai'] ?? ''}-${j['jam_selesai'] ?? ''}'),
          ),
        );
      },
    );
  }
}
