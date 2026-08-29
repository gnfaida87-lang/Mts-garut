import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/santri_service.dart';

class AbsensiSantriPage extends StatefulWidget {
  const AbsensiSantriPage({super.key});

  @override
  State<AbsensiSantriPage> createState() => _AbsensiSantriPageState();
}

class _AbsensiSantriPageState extends State<AbsensiSantriPage> {
  final _service = SantriService();
  List<Map<String, dynamic>> _data = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  int _page = 1;
  int _totalPages = 1;

  String _bulan = DateTime.now().month.toString();
  String _tahun = DateTime.now().year.toString();
  String? _tanggal;

  Future<void> _pickTanggal() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _tanggal = '${picked.year.toString().padLeft(4, '0')}-'
            '${picked.month.toString().padLeft(2, '0')}-'
            '${picked.day.toString().padLeft(2, '0')}';
      });
      _loadAbsensi();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAbsensi();
  }

  Future<void> _loadAbsensi() async {
    setState(() => _loading = true);
    try {
      final result = await _service.getAbsensi(
        tanggal: _tanggal,
        bulan: _bulan,
        tahun: _tahun,
        page: _page,
      );
      if (mounted) {
        setState(() {
          _data = (result['data'] as List).cast<Map<String, dynamic>>();
          _stats = Map<String, dynamic>.from(result['statistik'] ?? {});
          _totalPages = result['pagination']?['total_pages'] ?? 1;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _getStat(String status) {
    for (final s in _stats.entries) {
      if (s.key == status) return (s.value as num).toInt();
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stats
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildStatCard('Hadir', _getStat('hadir'), const Color(0xFF9C6644)),
              const SizedBox(width: 8),
              _buildStatCard('Izin', _getStat('izin'), Colors.orange),
              const SizedBox(width: 8),
              _buildStatCard('Sakit', _getStat('sakit'), Colors.red),
              const SizedBox(width: 8),
              _buildStatCard('Alpa', _getStat('alpa'), Colors.grey),
            ],
          ),
        ),
        // Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.grey300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _bulan,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: '1', child: Text('Januari', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: '2', child: Text('Februari', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: '3', child: Text('Maret', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: '4', child: Text('April', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: '5', child: Text('Mei', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: '6', child: Text('Juni', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: '7', child: Text('Juli', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: '8', child: Text('Agustus', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: '9', child: Text('September', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: '10', child: Text('Oktober', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: '11', child: Text('November', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: '12', child: Text('Desember', style: TextStyle(fontSize: 13))),
                      ],
                      onChanged: (v) { if (v != null) { setState(() => _bulan = v); _loadAbsensi(); } },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.grey300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _tahun,
                      isExpanded: true,
                      items: List.generate(5, (i) {
                        final year = (DateTime.now().year - i).toString();
                        return DropdownMenuItem(value: year, child: Text(year, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (v) { if (v != null) { setState(() => _tahun = v); _loadAbsensi(); } },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: _pickTanggal,
              icon: const Icon(Icons.event, size: 18),
              label: Text(
                _tanggal == null
                    ? 'Filter Tanggal (Semua)'
                    : 'Tanggal: $_tanggal',
                style: const TextStyle(fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ),
        if (_tanggal != null)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton.icon(
                onPressed: () {
                  setState(() => _tanggal = null);
                  _loadAbsensi();
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Reset Tanggal', style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
        const SizedBox(height: 16),
        // Data
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _data.isEmpty
                  ? const Center(child: Text('Belum ada data absensi'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _data.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final a = _data[i];
                        final status = a['status'] ?? '';
                        final color = status == 'hadir' ? const Color(0xFF9C6644)
                            : status == 'izin' ? Colors.orange
                            : status == 'sakit' ? Colors.red
                            : Colors.grey;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.1),
                            child: Icon(status == 'hadir' ? Icons.check : status == 'izin' ? Icons.note : status == 'sakit' ? Icons.sick : Icons.close, color: color, size: 18),
                          ),
                          title: Text(a['mapel_nama'] ?? 'Harian', style: const TextStyle(fontSize: 14)),
                          subtitle: Text(a['tanggal'] ?? '-', style: const TextStyle(fontSize: 12)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(status[0].toUpperCase() + status.substring(1), style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                          ),
                        );
                      },
                    ),
        ),
        // Pagination
        if (_totalPages > 1)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _page > 1 ? () { setState(() => _page--); _loadAbsensi(); } : null,
                ),
                Text('$_page / $_totalPages'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _page < _totalPages ? () { setState(() => _page++); _loadAbsensi(); } : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}
