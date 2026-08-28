import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_utils.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../services/dauroh_service.dart';

class AbsensiMonitoringPage extends StatefulWidget {
  const AbsensiMonitoringPage({super.key});

  @override
  State<AbsensiMonitoringPage> createState() => _AbsensiMonitoringPageState();
}

class _AbsensiMonitoringPageState extends State<AbsensiMonitoringPage> {
  List<Map<String, dynamic>> _data = [];
  Map<String, dynamic>? _rekap;
  bool _loading = true;
  String? _error;
  String _tanggal = '';
  String? _programId;
  List<Map<String, dynamic>> _programList = [];
  late final TextEditingController _tanggalCtrl;

  @override
  void initState() {
    super.initState();
    _tanggal = _wibDate();
    _tanggalCtrl = TextEditingController(text: _tanggal);
    _loadPrograms();
    _load();
  }

  String _wibDate() {
    final d = DateTime.now().toUtc().add(const Duration(hours: 7));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tanggalCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrograms() async {
    try {
      final res = await DaurohService.listProgram(perPage: 100);
      if (mounted) {
        setState(() {
          _programList = (res['items'] as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (_) { debugPrint('[absensi_monitoring_page.dart] error caught'); }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await DaurohService.monitoringAbsensi(
        tanggal: _tanggal,
        programId: _programId,
      );
      if (mounted) {
        setState(() {
          _data = (res['data'] as List).cast<Map<String, dynamic>>();
          _rekap = res['rekap'] as Map<String, dynamic>?;
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
          const Text(
            'Monitoring Absensi Musyrifah',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _buildFilters(),
          const SizedBox(height: 16),
          if (_rekap != null) _buildRekap(),
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
          width: 200,
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Tanggal',
              prefixIcon: Icon(Icons.calendar_today, size: 18),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            ),
            controller: _tanggalCtrl,
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.tryParse(_tanggal) ?? DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _tanggal = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  _tanggalCtrl.text = _tanggal;
                });
                _load();
              }
            },
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
                hint: const Text('Semua Program', style: TextStyle(fontSize: 13)),
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
      ],
    );
  }

  Widget _buildRekap() {
    final r = _rekap!;
    return Row(
      children: [
        StatChip(label: 'Total', value: '${r['total'] ?? 0}', color: AppTheme.grey600),
        const SizedBox(width: 8),
        StatChip(label: 'Hadir', value: '${r['hadir'] ?? 0}', color: AppTheme.primary),
        const SizedBox(width: 8),
        StatChip(label: 'Izin', value: '${r['izin'] ?? 0}', color: AppTheme.orange),
        const SizedBox(width: 8),
        StatChip(label: 'Sakit', value: '${r['sakit'] ?? 0}', color: AppTheme.blue),
        const SizedBox(width: 8),
        StatChip(label: 'Alpha', value: '${r['alpha'] ?? 0}', color: AppTheme.error),
        const SizedBox(width: 8),
        StatChip(label: 'Belum Absen', value: '${r['belum_absen'] ?? 0}', color: AppTheme.grey400),
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
        icon: Icons.checklist_outlined,
        message: 'Tidak ada jadwal dauroh aktif pada tanggal ini',
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
            DataColumn(label: Text('NIPMUS')),
            DataColumn(label: Text('Nama')),
            DataColumn(label: Text('JK')),
            DataColumn(label: Text('Program')),
            DataColumn(label: Text('Hari')),
            DataColumn(label: Text('Jam Jadwal')),
            DataColumn(label: Text('Masuk')),
            DataColumn(label: Text('Keluar')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Aksi')),
          ],
          rows: _data.map((row) {
            final status = row['status']?.toString() ?? 'hadir';
            final belumAbsen = (row['belum_absen'] as num?)?.toInt() == 1;
            return DataRow(cells: [
              DataCell(Text(row['nipmus']?.toString() ?? '-')),
              DataCell(Text(row['nama']?.toString() ?? '-')),
              DataCell(Text(row['jenis_kelamin']?.toString() == 'L' ? 'L' : 'P')),
              DataCell(Text(row['nama_program']?.toString() ?? '-')),
              DataCell(Text(row['hari']?.toString() ?? '-')),
              DataCell(Text('${row['jam_mulai'] ?? '-'} - ${row['jam_selesai'] ?? '-'}')),
              DataCell(Text(row['waktu_masuk']?.toString() ?? '-')),
              DataCell(Text(row['waktu_keluar']?.toString() ?? '-')),
              DataCell(
                belumAbsen
                    ? const StatusBadge(label: 'Belum Absen', color: AppTheme.grey400)
                    : AttendanceStatus.fromString(status),
              ),
              DataCell(row['absensi_id'] == null
                  ? const Text('-')
                  : IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary),
                      tooltip: 'Koreksi',
                      onPressed: () => _showEditDialog(row),
                    )),
            ]);
          }).toList(),
          headingRowColor: WidgetStateProperty.all(AppTheme.grey50),
          headingTextStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.grey700),
          dataTextStyle: const TextStyle(fontSize: 13, color: AppTheme.grey700),
          columnSpacing: 24,
          horizontalMargin: 20,
        ),
      ),
    );
  }

  Future<void> _showEditDialog(Map<String, dynamic> row) async {
    final id = (row['absensi_id'] as num).toInt();
    final waktuMasukCtrl = TextEditingController(text: row['waktu_masuk']?.toString() ?? '');
    final waktuKeluarCtrl = TextEditingController(text: row['waktu_keluar']?.toString() ?? '');
    String status = row['status']?.toString() ?? 'hadir';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Koreksi Absensi Musyrifah'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${row['nama'] ?? '-'} — ${row['nama_program'] ?? '-'}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.grey500),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: waktuMasukCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Jam Masuk (HH:MM)',
                    prefixIcon: Icon(Icons.login, size: 18),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  ),
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: waktuKeluarCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Jam Keluar (HH:MM)',
                    prefixIcon: Icon(Icons.logout, size: 18),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  ),
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: status,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.filter_alt_outlined, size: 18),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  ),
                  items: ['hadir', 'izin', 'sakit', 'alpha'].map((s) =>
                      DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => status = v ?? 'hadir'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                final body = <String, dynamic>{};
                if (waktuMasukCtrl.text.trim().isNotEmpty) body['waktu_masuk'] = waktuMasukCtrl.text.trim();
                if (waktuKeluarCtrl.text.trim().isNotEmpty) body['waktu_keluar'] = waktuKeluarCtrl.text.trim();
                body['status'] = status;

                if (body['waktu_masuk'] == null && body['waktu_keluar'] == null) {
                  AppUtils.showError(ctx, 'Isi minimal salah satu jam (masuk/keluar)');
                  return;
                }
                try {
                  await DaurohService.updateAbsensiMusyrifah(id, body);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) AppUtils.handleError(ctx, e, message: 'Gagal menyimpan koreksi');
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      if (!mounted) return;
      AppUtils.showSuccess(context, 'Koreksi absensi disimpan');
      _load();
    }
  }
}
