import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_utils.dart';
import '../services/dauroh_service.dart';
import '../widgets/dauroh_table.dart';
import 'jadwal_form_page.dart';

class JadwalListPage extends StatefulWidget {
  const JadwalListPage({super.key});

  @override
  State<JadwalListPage> createState() => _JadwalListPageState();
}

class _JadwalListPageState extends State<JadwalListPage> {
  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _programList = [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  int _totalPages = 1;
  final _searchCtrl = TextEditingController();
  String? _filterHari;
  String? _filterProgram;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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
    } catch (_) { debugPrint('[jadwal_list_page.dart] error caught'); }
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) _page = 1;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await DaurohService.listJadwal(
        page: _page,
        search: _searchCtrl.text,
        hari: _filterHari,
        programId: _filterProgram,
      );
      if (mounted) {
        setState(() {
          _data = (res['items'] as List).cast<Map<String, dynamic>>();
          _totalPages = res['pagination']?['total_pages'] ?? 1;
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

  Future<void> _delete(int id) async {
    final ok = await AppUtils.confirm(
      context,
      title: 'Hapus Jadwal',
      message: 'Yakin menghapus jadwal ini?',
    );
    if (!ok) return;
    try {
      await DaurohService.deleteJadwal(id);
      _load(refresh: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal hapus: $e')),
        );
      }
    }
  }

  void _showForm({Map<String, dynamic>? edit}) {
    showDialog(
      context: context,
      builder: (_) => JadwalFormPage(
        editData: edit,
        onSaved: () => _load(refresh: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Atur Jadwal Dauroh',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  if (_data.isNotEmpty)
                    Text(
                      '${_data.length} data',
                      style: const TextStyle(fontSize: 12, color: AppTheme.grey500),
                    ),
                ],
              ),
              Row(
                children: [
                  _buildProgramFilter(),
                  const SizedBox(width: 8),
                  _buildHariFilter(),
                  const SizedBox(width: 8),
                  _buildResetButton(),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Cari jadwal...',
                        prefixIcon: Icon(Icons.search, size: 20),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onSubmitted: (_) => _load(refresh: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => _showForm(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah Jadwal'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: DaurohTable(
              columns: const [
                DaurohTableColumn(key: 'nama_program', label: 'Program', width: 160),
                DaurohTableColumn(key: 'hari', label: 'Hari', width: 90),
                DaurohTableColumn(key: 'jam_mulai', label: 'Mulai', width: 80),
                DaurohTableColumn(key: 'jam_selesai', label: 'Selesai', width: 80),
                DaurohTableColumn(key: 'musyrifah_1_nama', label: 'Musyrifah 1', width: 140),
                DaurohTableColumn(key: 'musyrifah_2_nama', label: 'Musyrifah 2', width: 140),
                DaurohTableColumn(key: 'kelas_nama', label: 'Kelas', width: 150),
                DaurohTableColumn(key: 'is_aktif', label: 'Aktif', width: 70),
              ],
              data: _data,
              isLoading: _loading,
              error: _error,
              currentPage: _page,
              totalPages: _totalPages,
              onPrevious: _page > 1
                  ? () {
                      setState(() => _page--);
                      _load();
                    }
                  : null,
              onNext: _page < _totalPages
                  ? () {
                      setState(() => _page++);
                      _load();
                    }
                  : null,
              onRetry: () => _load(refresh: true),
              onEdit: (row) => _showForm(edit: row),
              onDelete: (row) => _delete(row['id'] as int),
              displayFn: (key, value, row) {
                if (key == 'is_aktif') return value == 1 ? 'Ya' : 'Tidak';
                if (key == 'musyrifah_2_nama') return value?.toString() ?? '-';
                return value?.toString() ?? '-';
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramFilter() {
    return SizedBox(
      width: 160,
      child: DropdownButtonHideUnderline(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.grey300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: _filterProgram,
            hint: const Text('Semua Program', style: TextStyle(fontSize: 13)),
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('Semua Program', style: TextStyle(fontSize: 13))),
              ..._programList.map((p) => DropdownMenuItem(
                value: '${p['id']}',
                child: Text(p['nama_program']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
              )),
            ],
            onChanged: (v) {
              setState(() => _filterProgram = v);
              _load(refresh: true);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHariFilter() {
    final hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return SizedBox(
      width: 120,
      child: DropdownButtonHideUnderline(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.grey300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: _filterHari,
            hint: const Text('Semua Hari', style: TextStyle(fontSize: 13)),
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('Semua Hari', style: TextStyle(fontSize: 13))),
              ...hari.map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontSize: 13)))),
            ],
            onChanged: (v) {
              setState(() => _filterHari = v);
              _load(refresh: true);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    final hasFilter = _filterProgram != null || _filterHari != null;
    if (!hasFilter) return const SizedBox.shrink();
    return ActionChip(
      avatar: const Icon(Icons.close, size: 16, color: AppTheme.error),
      label: const Text('Reset', style: TextStyle(fontSize: 12, color: AppTheme.error)),
      onPressed: () {
        setState(() {
          _filterProgram = null;
          _filterHari = null;
        });
        _load(refresh: true);
      },
      backgroundColor: AppTheme.redLight,
      side: BorderSide(color: AppTheme.error.withValues(alpha: 0.3)),
    );
  }
}
