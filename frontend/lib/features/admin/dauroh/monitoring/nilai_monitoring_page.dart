import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/dauroh_pdf_export.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../services/dauroh_service.dart';

class NilaiMonitoringPage extends StatefulWidget {
  const NilaiMonitoringPage({super.key});

  @override
  State<NilaiMonitoringPage> createState() => _NilaiMonitoringPageState();
}

class _NilaiMonitoringPageState extends State<NilaiMonitoringPage> {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;
  String? _error;
  String? _jenjang;
  String? _kelasId;
  String? _programId;
  String? _status;

  List<Map<String, dynamic>> _kelasList = [];
  List<Map<String, dynamic>> _programList = [];

  @override
  void initState() {
    super.initState();
    _loadReferensi();
    _load();
  }

  Future<void> _loadReferensi() async {
    try {
      final results = await Future.wait([
        DaurohService.listProgram(perPage: 100),
        DaurohService.getReferensi(),
      ]);
      if (mounted) {
        setState(() {
          _programList = (results[0]['items'] as List).cast<Map<String, dynamic>>();
          _kelasList = (results[1]['kelas'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        });
      }
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await DaurohService.monitoringNilai(
        jenjang: _jenjang,
        kelasId: _kelasId,
        programId: _programId,
        status: _status,
      );
      if (mounted) {
        setState(() {
          _data = res;
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Monitoring Nilai at-Ta\'wid',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              if (_data.isNotEmpty)
                FilledButton.icon(
                  onPressed: () => DaurohPdfExport.exportBatch(
                    _data,
                    title: 'Monitoring Nilai at-Ta\'wid',
                  ),
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Export PDF'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFilters(),
          const SizedBox(height: 16),
          Expanded(child: _buildTable()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return FilterCard(
      children: [
        SizedBox(
          width: 140,
          child: DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.grey300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton<String>(
                value: _jenjang,
                hint: const Text('Jenjang', style: TextStyle(fontSize: 13)),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua Jenjang')),
                  DropdownMenuItem(value: 'MTs', child: Text('MTs')),
                  DropdownMenuItem(value: 'MA', child: Text('MA')),
                ],
                onChanged: (v) {
                  setState(() => _jenjang = v);
                  _load();
                },
              ),
            ),
          ),
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.grey300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton<String>(
                value: _kelasId,
                hint: const Text('Kelas', style: TextStyle(fontSize: 13)),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Semua Kelas')),
                  ..._kelasList.map((k) => DropdownMenuItem(
                    value: '${k['id']}',
                    child: Text(k['nama']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                  )),
                ],
                onChanged: (v) {
                  setState(() => _kelasId = v);
                  _load();
                },
              ),
            ),
          ),
        ),
        SizedBox(
          width: 200,
          child: DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.grey300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton<String>(
                value: _programId,
                hint: const Text('Program', style: TextStyle(fontSize: 13)),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Semua Program')),
                  ..._programList.map((p) => DropdownMenuItem(
                    value: '${p['id']}',
                    child: Text(p['nama_program']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                  )),
                ],
                onChanged: (v) {
                  setState(() => _programId = v);
                  _load();
                },
              ),
            ),
          ),
        ),
        SizedBox(
          width: 160,
          child: DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.grey300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton<String>(
                value: _status,
                hint: const Text('Status', style: TextStyle(fontSize: 13)),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: null, child: Text('Semua Status')),
                  DropdownMenuItem(value: 'mengulang', child: Text('Mengulang')),
                  DropdownMenuItem(value: 'melanjutkan', child: Text('Melanjutkan')),
                  DropdownMenuItem(value: 'selesai', child: Text('Selesai')),
                ],
                onChanged: (v) {
                  setState(() => _status = v);
                  _load();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTable() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_error != null) {
      return Center(
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
      );
    }
    if (_data.isEmpty) {
      return const EmptyState(
        icon: Icons.grading_outlined,
        message: 'Belum ada data nilai at-Ta\'wid',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grey200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('NIS')),
            DataColumn(label: Text('Nama')),
            DataColumn(label: Text('Kelas')),
            DataColumn(label: Text('Program')),
            DataColumn(label: Text('Surat')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Bidang 1')),
            DataColumn(label: Text('Bidang 2')),
            DataColumn(label: Text('Bidang 3')),
            DataColumn(label: Text('Total')),
            DataColumn(label: Text('Musyrifah')),
          ],
          rows: _data.map((row) {
            final status = row['status_hafalan']?.toString() ?? '-';
            Color statusColor;
            switch (status) {
              case 'mengulang':
                statusColor = AppTheme.orange;
                break;
              case 'melanjutkan':
                statusColor = AppTheme.primary;
                break;
              case 'selesai':
                statusColor = const Color(0xFF9C6644);
                break;
              default:
                statusColor = AppTheme.grey500;
            }

            return DataRow(cells: [
              DataCell(Text(row['nis']?.toString() ?? '-')),
              DataCell(Text(row['nama']?.toString() ?? '-')),
              DataCell(Text(row['kelas_nama']?.toString() ?? '-')),
              DataCell(Text(row['nama_program']?.toString() ?? '-')),
              DataCell(Text(row['surat_nama']?.toString() ?? '-')),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                  ),
                ),
              ),
              DataCell(_buildNilaiValue(row['nilai_bidang1'], max: _maxOf(row, 'max_bidang1', 40))),
              DataCell(_buildNilaiValue(row['nilai_bidang2'], max: _maxOf(row, 'max_bidang2', 30))),
              DataCell(_buildNilaiValue(row['nilai_bidang3'], max: _maxOf(row, 'max_bidang3', 30))),
              DataCell(_buildTotalValue(row['total_nilai'])),
              DataCell(Text(row['musyrifah_nama']?.toString() ?? '-')),
            ]);
          }).toList(),
          headingRowColor: WidgetStateProperty.all(AppTheme.grey50),
          headingTextStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.grey700),
          dataTextStyle: const TextStyle(fontSize: 13, color: AppTheme.grey700),
          columnSpacing: 16,
          horizontalMargin: 16,
        ),
      ),
    );
  }

  Widget _buildNilaiValue(dynamic value, {required double max}) {
    if (value == null) return const Text('-', style: TextStyle(color: AppTheme.grey400));
    final num = double.tryParse(value.toString());
    if (num == null) return Text(value.toString());
    final ratio = max <= 0 ? 1 : num / max;
    Color color;
    if (ratio >= 0.8) {
      color = AppTheme.primary;
    } else if (ratio >= 0.6) {
      color = AppTheme.orange;
    } else {
      color = AppTheme.error;
    }
    return Text(
      num.toStringAsFixed(0),
      style: TextStyle(fontWeight: FontWeight.w600, color: color),
    );
  }

  double _maxOf(Map<String, dynamic> row, String key, double fallback) {
    final v = row[key];
    if (v == null) return fallback;
    final n = double.tryParse(v.toString());
    return (n == null || n <= 0) ? fallback : n;
  }

  Widget _buildTotalValue(dynamic value) {
    if (value == null) return const Text('-', style: TextStyle(color: AppTheme.grey400));
    final num = double.tryParse(value.toString());
    if (num == null) return Text(value.toString());
    Color bgColor;
    if (num >= 80) {
      bgColor = AppTheme.primary;
    } else if (num >= 60) {
      bgColor = AppTheme.orange;
    } else {
      bgColor = AppTheme.error;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        num.toStringAsFixed(0),
        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 12),
      ),
    );
  }
}
