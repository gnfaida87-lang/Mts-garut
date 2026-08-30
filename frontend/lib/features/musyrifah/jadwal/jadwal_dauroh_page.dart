import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../services/musyrifah_service.dart';

class JadwalDaurohPage extends StatefulWidget {
  const JadwalDaurohPage({super.key});

  @override
  State<JadwalDaurohPage> createState() => _JadwalDaurohPageState();
}

class _JadwalDaurohPageState extends State<JadwalDaurohPage> {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;
  String? _error;
  String? _filterHari;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await MusyrifahService.getJadwal(hari: _filterHari);
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              const Text('Jadwal Mengajar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.grey800)),
              const Spacer(),
              _buildHariFilter(),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: AppTheme.error)),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    )
                  : _data.isEmpty
                      ? const EmptyState(
                          icon: Icons.calendar_month_outlined,
                          message: 'Belum ada jadwal mengajar',
                        )
                      : RefreshIndicator(
                          color: AppTheme.primary,
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _data.length,
                            itemBuilder: (_, i) => _buildJadwalCard(_data[i]),
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildJadwalCard(Map<String, dynamic> jadwal) {
    final namaProgram = jadwal['nama_program']?.toString() ?? '-';
    final hari = jadwal['hari']?.toString() ?? '-';
    final jamMulai = jadwal['jam_mulai']?.toString() ?? '';
    final jamSelesai = jadwal['jam_selesai']?.toString() ?? '';
    final kelasNama = jadwal['kelas_nama']?.toString() ?? '-';
    final jenisDauroh = jadwal['jenis_dauroh']?.toString() ?? '-';
    final musyrifah2 = jadwal['musyrifah_2_nama']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  jenisDauroh == 'tahfidz' ? Icons.menu_book_outlined : Icons.chrome_reader_mode_outlined,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      namaProgram,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Text(
                      '$jenisDauroh • $hari',
                      style: const TextStyle(fontSize: 12, color: AppTheme.grey500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildInfoRow(Icons.access_time, 'Jam', '$jamMulai - $jamSelesai'),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.meeting_room_outlined, 'Kelas', kelasNama),
          if (musyrifah2 != null) ...[
            const SizedBox(height: 6),
            _buildInfoRow(Icons.person_outline, 'Musyrifah 2', musyrifah2),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.grey500),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AppTheme.grey500)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildHariFilter() {
    final hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String?>(
        icon: const Icon(Icons.filter_list_outlined),
        tooltip: 'Filter Hari',
        onSelected: (v) {
          setState(() => _filterHari = v);
          _load();
        },
        itemBuilder: (_) => [
          const PopupMenuItem(value: null, child: Text('Semua Hari')),
          ...hari.map((h) => PopupMenuItem(value: h, child: Text(h))),
        ],
      ),
    );
  }
}
