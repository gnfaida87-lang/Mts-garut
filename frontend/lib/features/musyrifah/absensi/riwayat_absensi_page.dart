import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../services/musyrifah_service.dart';

class RiwayatAbsensiPage extends StatefulWidget {
  const RiwayatAbsensiPage({super.key});

  @override
  State<RiwayatAbsensiPage> createState() => _RiwayatAbsensiPageState();
}

class _RiwayatAbsensiPageState extends State<RiwayatAbsensiPage> {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _bulan;

  @override
  void initState() {
    super.initState();
    _bulan = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await MusyrifahService.listAbsensi(
        page: _currentPage,
        bulan: _bulan,
      );
      if (mounted) {
        setState(() {
          _data = (res['items'] as List).cast<Map<String, dynamic>>();
          final pagination = res['pagination'] as Map<String, dynamic>?;
          if (pagination != null) {
            _totalPages = pagination['total_pages'] as int? ?? 1;
            _currentPage = pagination['page'] as int? ?? 1;
          }
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
              const Text('Riwayat Absensi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.grey800)),
              const Spacer(),
              _buildBulanFilter(),
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
                          icon: Icons.history,
                          message: 'Belum ada riwayat absensi',
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: RefreshIndicator(
                                color: AppTheme.primary,
                                onRefresh: _load,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _data.length,
                                  itemBuilder: (_, i) => _buildAbsensiCard(_data[i]),
                                ),
                              ),
                            ),
                            if (_totalPages > 1)
                              _buildPaginationBar(),
                          ],
                        ),
        ),
      ],
    );
  }

  Widget _buildAbsensiCard(Map<String, dynamic> absensi) {
    final waktuMasuk = absensi['waktu_masuk']?.toString() ?? '-';
    final waktuKeluar = absensi['waktu_keluar']?.toString() ?? '-';
    final status = absensi['status']?.toString() ?? 'hadir';
    final hari = absensi['hari']?.toString() ?? '-';
    final jamMulai = absensi['jam_mulai']?.toString() ?? '';
    final jamSelesai = absensi['jam_selesai']?.toString() ?? '';
    final namaProgram = absensi['nama_program']?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AttendanceStatus.colorFor(status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _statusIcon(status),
              color: AttendanceStatus.colorFor(status),
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
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '$hari, $jamMulai - $jamSelesai',
                  style: const TextStyle(fontSize: 12, color: AppTheme.grey500),
                ),
                const SizedBox(height: 2),
                Text(
                  'Masuk: $waktuMasuk   Keluar: $waktuKeluar',
                  style: const TextStyle(fontSize: 11, color: AppTheme.grey400),
                ),
              ],
            ),
          ),
          AttendanceStatus.fromString(status),
        ],
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'hadir': return Icons.check_circle_outline;
      case 'izin': return Icons.info_outline;
      case 'sakit': return Icons.local_hospital_outlined;
      case 'alpha': return Icons.cancel_outlined;
      default: return Icons.help_outline;
    }
  }

  Widget _buildBulanFilter() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.calendar_month_outlined),
        tooltip: 'Filter Bulan',
        onSelected: (v) {
          setState(() {
            _bulan = v;
            _currentPage = 1;
          });
          _load();
        },
        itemBuilder: (_) {
          final now = DateTime.now();
          final items = <PopupMenuEntry<String>>[];
          for (int i = 0; i < 6; i++) {
            final date = DateTime(now.year, now.month - i, 1);
            final value = '${date.year}-${date.month.toString().padLeft(2, '0')}';
            final label = _bulanLabel(date.month, date.year);
            items.add(PopupMenuItem(value: value, child: Text(label)));
          }
          return items;
        },
      ),
    );
  }

  String _bulanLabel(int bulan, int tahun) {
    const names = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${names[bulan]} $tahun';
  }

  Widget _buildPaginationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.grey200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _load();
                  }
                : null,
          ),
          Text(
            'Halaman $_currentPage / $_totalPages',
            style: const TextStyle(fontSize: 13),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() => _currentPage++);
                    _load();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
