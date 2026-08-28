import 'package:flutter/material.dart';
import '../../../core/utils/dauroh_pdf_export.dart';
import '../services/musyrifah_service.dart';
part 'nilai_dauroh_input_dialog.dart';


class NilaiDaurohPage extends StatefulWidget {
  const NilaiDaurohPage({super.key});

  @override
  State<NilaiDaurohPage> createState() => _NilaiDaurohPageState();
}

class _NilaiDaurohPageState extends State<NilaiDaurohPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  // Filters
  final _searchCtrl = TextEditingController();
  String? _filterStatus;
  String? _filterProgram;
  List<Map<String, dynamic>> _programs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await MusyrifahService.listNilai(
        programId: _filterProgram,
        search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
        status: _filterStatus,
      );
      // Build unique program list: gabungkan dengan daftar lama agar
      // tidak hilang saat filter aktif
      final Map<String, Map<String, dynamic>> progMap = {};
      for (final p in _programs) {
        progMap[p['id']?.toString() ?? ''] = p;
      }
      for (final item in data) {
        final pid = item['program_id']?.toString() ?? '';
        if (pid.isNotEmpty && !progMap.containsKey(pid)) {
          progMap[pid] = {
            'id': pid,
            'nama': item['nama_program'] ?? 'Program',
          };
        }
      }
      setState(() {
        _items = data;
        _programs = progMap.values.toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openDialog({Map<String, dynamic>? existing}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _InputNilaiDialog(
        existing: existing,
      ),
    );
    if (result == true) {
      _load();
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'selesai':
        return const Color(0xFF9C6644);
      case 'melanjutkan':
        return Colors.blue;
      case 'mengulang':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'selesai':
        return 'Selesai';
      case 'melanjutkan':
        return 'Melanjutkan';
      case 'mengulang':
        return 'Mengulang';
      default:
        return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nilai at-Ta\'wid'),
        automaticallyImplyLeading: false,
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Export Semua ke PDF',
              onPressed: () => DaurohPdfExport.exportBatch(
                _items,
                title: 'Laporan Penilaian at-Ta\'wid',
              ),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Input Nilai Baru',
            onPressed: () => _openDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(
                bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Cari nama santri...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    _load();
                                  },
                                )
                              : null,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onSubmitted: (_) => _load(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        value: _filterStatus,
                        isDense: true,
                        decoration: InputDecoration(
                          hintText: 'Status',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('Semua Status'),
                          ),
                          DropdownMenuItem(
                            value: 'mengulang',
                            child: Text('Mengulang'),
                          ),
                          DropdownMenuItem(
                            value: 'melanjutkan',
                            child: Text('Melanjutkan'),
                          ),
                          DropdownMenuItem(
                            value: 'selesai',
                            child: Text('Selesai'),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _filterStatus = v);
                          _load();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        value: _filterProgram,
                        isDense: true,
                        decoration: InputDecoration(
                          hintText: 'Program',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Semua Program'),
                          ),
                          ..._programs.map(
                            (p) => DropdownMenuItem(
                              value: p['id']?.toString(),
                              child: Text(p['nama'] ?? ''),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _filterProgram = v);
                          _load();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!,
                                style: TextStyle(color: theme.colorScheme.error)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _load,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    : _items.isEmpty
                        ? const Center(child: Text('Tidak ada data nilai'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _items.length,
                              itemBuilder: (ctx, i) =>
                                  _buildCard(_items[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final status = item['status_hafalan']?.toString();
    final totalNilai = (item['total_nilai'] as num?)?.toDouble() ?? 0;
    final b1 = (item['nilai_bidang1'] as num?)?.toDouble() ?? 0;
    final b2 = (item['nilai_bidang2'] as num?)?.toDouble() ?? 0;
    final b3 = (item['nilai_bidang3'] as num?)?.toDouble() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openDialog(existing: item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['santri_nama'] ?? '-',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'NIS: ${item['nis'] ?? '-'}  â€¢  ${item['kelas_nama'] ?? '-'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildStatChip('Program', item['nama_program'] ?? '-'),
                  const SizedBox(width: 8),
                  _buildStatChip(
                      'Surat', '${item['surat_nama'] ?? '-'} (${item['dari_ayat'] ?? '-'}-${item['sampai_ayat'] ?? '-'})'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _scoreCircle('B1', b1, _maxOf(item, 'max_bidang1', 40), theme),
                  const SizedBox(width: 8),
                  _scoreCircle('B2', b2, _maxOf(item, 'max_bidang2', 30), theme),
                  const SizedBox(width: 8),
                  _scoreCircle('B3', b3, _maxOf(item, 'max_bidang3', 30), theme),
                  const Spacer(),
                  _totalBadge(totalNilai, theme),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    tooltip: 'Export PDF',
                    onPressed: () => DaurohPdfExport.exportNilaiPerSantri(item),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
              if (item['musyrifah_nama'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Oleh: ${item['musyrifah_nama']}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _scoreCircle(String label, double value, double max, ThemeData theme) {
    final pct = max > 0 ? value / max : 0.0;
    final color = pct >= 0.8
        ? const Color(0xFF9C6644)
        : pct >= 0.6
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w600),
          ),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  double _maxOf(Map<String, dynamic> item, String key, double fallback) {
    final v = item[key];
    if (v == null) return fallback;
    final n = double.tryParse(v.toString());
    return (n == null || n <= 0) ? fallback : n;
  }

  Widget _totalBadge(double total, ThemeData theme) {
    final color = total >= 80
        ? const Color(0xFF9C6644)
        : total >= 60
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'TOTAL',
            style: TextStyle(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600),
          ),
          Text(
            total.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Input Dialog
// ---------------------------------------------------------------------------

