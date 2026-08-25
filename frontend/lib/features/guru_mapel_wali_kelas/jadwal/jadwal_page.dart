import 'package:flutter/material.dart';
import '../services/guru_service.dart';
import 'package:intl/intl.dart';

class JadwalPageGuru extends StatefulWidget {
  const JadwalPageGuru({super.key});

  @override
  State<JadwalPageGuru> createState() => _JadwalPageGuruState();
}

class _JadwalPageGuruState extends State<JadwalPageGuru> {
  List<dynamic> _jadwal = [];
  bool _loading = true;
  String? _error;
  bool _viewMapel = true;

  static const _dayOrder = ['Sabtu', 'Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis'];
  static const _dayMap = {'Sabtu': 6, 'Minggu': 7, 'Senin': 1, 'Selasa': 2, 'Rabu': 3, 'Kamis': 4, 'Jumat': 5};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _error = null;
    try {
      _jadwal = await GuruService.getJadwal();
    } catch (e) {
      _error = e.toString();
    }
    setState(() => _loading = false);
  }

  Map<String, List<Map<String, dynamic>>> _groupByMapel() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in _jadwal) {
      final j = item as Map<String, dynamic>;
      final key = j['mapel_nama'] as String? ?? 'Tanpa Mapel';
      grouped.putIfAbsent(key, () => []).add(j);
    }
    return grouped;
  }

  Map<String, List<Map<String, dynamic>>> _groupByHari() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final day in _dayOrder) { grouped[day] = []; }
    for (final item in _jadwal) {
      final j = item as Map<String, dynamic>;
      final hari = j['hari'] as String? ?? '';
      if (grouped.containsKey(hari)) grouped[hari]!.add(j);
    }
    grouped.removeWhere((_, list) => list.isEmpty);
    return grouped;
  }

  String _nextDate(String hari) {
    final target = _dayMap[hari];
    if (target == null) return '';
    final today = DateTime.now();
    final current = today.weekday;
    var diff = target - current;
    if (diff <= 0) diff += 7;
    final next = today.add(Duration(days: diff));
    return DateFormat('d MMM yyyy', 'id').format(next);
  }

  int _jamKe(String jam) {
    try {
      final parts = jam.split(':');
      final totalMenit = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      final menitDariPagi = totalMenit - 7 * 60;
      if (menitDariPagi < 0) return 1;
      return (menitDariPagi ~/ 45) + 1;
    } catch (_) {
      return 1;
    }
  }

  bool _isNow(String jamMulai, String jamSelesai) {
    try {
      final now = TimeOfDay.now();
      final mulai = TimeOfDay(hour: int.parse(jamMulai.split(':')[0]), minute: int.parse(jamMulai.split(':')[1]));
      final selesai = TimeOfDay(hour: int.parse(jamSelesai.split(':')[0]), minute: int.parse(jamSelesai.split(':')[1]));
      final nowMin = now.hour * 60 + now.minute;
      return nowMin >= mulai.hour * 60 + mulai.minute && nowMin <= selesai.hour * 60 + selesai.minute;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Mengajar'),
        backgroundColor: const Color(0xFF9C6644),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                _toggleBtn('Per Mapel', true, Icons.book_rounded),
                const SizedBox(width: 8),
                _toggleBtn('Per Hari', false, Icons.calendar_view_week_rounded),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool isMapel, IconData icon) {
    final selected = _viewMapel == isMapel;
    return GestureDetector(
      onTap: () => setState(() => _viewMapel = isMapel),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF9C6644).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFF9C6644).withValues(alpha: 0.3) : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? const Color(0xFF9C6644) : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? const Color(0xFF9C6644) : Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('Gagal memuat jadwal', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C6644), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF9C6644),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _viewMapel ? _buildMapelView() : _buildHariView(),
      ),
    );
  }

  List<Widget> _buildMapelView() {
    final grouped = _groupByMapel();
    if (grouped.isEmpty) return [_emptyState()];
    final sortedKeys = grouped.keys.toList()..sort();
    return [
      ...sortedKeys.map((mapel) {
        final entries = grouped[mapel]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MapelHeader(mapel: mapel, total: entries.length),
            ...entries.asMap().entries.map((e) => _jadwalCard(e.value, e.key)),
            const SizedBox(height: 16),
          ],
        );
      }),
    ];
  }

  List<Widget> _buildHariView() {
    final grouped = _groupByHari();
    if (grouped.isEmpty) return [_emptyState()];

    final todayHari = _dayMap.entries.firstWhere((e) => e.value == DateTime.now().weekday, orElse: () => const MapEntry('', 0)).key;

    return [
      ..._dayOrder.where((day) => grouped.containsKey(day) || day == 'Jumat').map((day) {
        if (day == 'Jumat') {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.weekend_rounded, size: 36, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Text('Jumat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[500])),
                Text('Libur', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
              ],
            ),
          );
        }
        final entries = grouped[day]!;
        final isToday = day == todayHari;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HariHeader(hari: day, total: entries.length, isToday: isToday, tanggal: _nextDate(day)),
            ...entries.asMap().entries.map((e) => _jadwalCard(e.value, e.key)),
            const SizedBox(height: 16),
          ],
        );
      }),
    ];
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Belum ada jadwal mengajar', style: TextStyle(fontSize: 15, color: Colors.grey[500])),
            const SizedBox(height: 4),
            Text('Jadwal muncul setelah Wakil Kurikulum\nmempublikasikan penjadwalan', style: TextStyle(fontSize: 13, color: Colors.grey[400]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _jadwalCard(Map<String, dynamic> j, int idx) {
    final hari = j['hari'] as String? ?? '';
    final jamMulai = j['jam_mulai'] as String? ?? '';
    final jamSelesai = j['jam_selesai'] as String? ?? '';
    final kelas = j['kelas_nama'] as String? ?? '-';
    final ruang = j['ruangan_nama'] as String? ?? '';

    final today = _dayMap[hari] == DateTime.now().weekday;
    final active = today && _isNow(jamMulai, jamSelesai);
    final jamMulaiShort = jamMulai.length >= 5 ? jamMulai.substring(0, 5) : jamMulai;
    final jamSelesaiShort = jamSelesai.length >= 5 ? jamSelesai.substring(0, 5) : jamSelesai;
    final jk = _jamKe(jamMulai);
    final jkEnd = _jamKe(jamSelesai);

    return Container(
      margin: EdgeInsets.only(bottom: idx < _jadwal.length - 1 ? 10 : 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? const Color(0xFF9C6644).withValues(alpha: 0.3) : Colors.grey[200]!,
          width: active ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(color: (active ? const Color(0xFF9C6644) : Colors.grey).withValues(alpha: active ? 0.1 : 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF9C6644).withValues(alpha: 0.08) : Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(jamMulaiShort, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: active ? const Color(0xFF9C6644) : Colors.grey[700])),
                  const SizedBox(height: 2),
                  Text(jamSelesaiShort, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_viewMapel) ...[
                    Text(j['mapel_nama'] as String? ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF9C6644).withValues(alpha: 0.06), borderRadius: BorderRadius.circular(6)),
                        child: Text('Jam ke-$jk${jkEnd != jk ? '-$jkEnd' : ''}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.school_rounded, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text('Kelas $kelas', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      if (ruang.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.meeting_room_rounded, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(ruang, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      ],
                    ],
                  ),
                  if (active)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF9C6644), shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          const Text('Sedang Berlangsung', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9C6644))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapelHeader extends StatelessWidget {
  final String mapel;
  final int total;
  const _MapelHeader({required this.mapel, required this.total});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF9C6644), const Color(0xFF1565C0), const Color(0xFFE65100),
      const Color(0xFF6A1B9A), const Color(0xFFC62828), const Color(0xFF00838F),
    ];
    final color = colors[mapel.hashCode.abs() % colors.length];
    final lightColors = [
      const Color(0xFFF5EBE0), const Color(0xFFE3F2FD), const Color(0xFFFFF3E0),
      const Color(0xFFF3E5F5), const Color(0xFFFFEBEE), const Color(0xFFE0F7FA),
    ];
    final lightColor = lightColors[mapel.hashCode.abs() % lightColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.book_rounded, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mapel, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
                Text('$total jadwal', style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.7))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.menu_book_rounded, size: 16, color: color),
          ),
        ],
      ),
    );
  }
}

class _HariHeader extends StatelessWidget {
  final String hari;
  final int total;
  final bool isToday;
  final String tanggal;
  const _HariHeader({required this.hari, required this.total, required this.isToday, required this.tanggal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Container(
            width: 4, height: 22,
            decoration: BoxDecoration(
              color: isToday ? const Color(0xFFF9A825) : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(hari, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isToday ? const Color(0xFF9C6644) : Colors.grey[700])),
          const SizedBox(width: 6),
          Text(tanggal, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
            child: Text('$total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[600])),
          ),
          if (isToday) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFF9C6644).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Text('Hari Ini', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9C6644))),
            ),
          ],
        ],
      ),
    );
  }
}
