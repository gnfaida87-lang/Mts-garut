import 'package:flutter/material.dart';
import '../../../admin/services/admin_service.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/widgets/app_utils.dart';
import 'form_fields.dart';

class GuruMapelKelasForm extends StatefulWidget {
  final Map<String, dynamic>? editData;
  final VoidCallback onSaved;

  const GuruMapelKelasForm({super.key, this.editData, required this.onSaved});

  @override
  State<GuruMapelKelasForm> createState() => _GuruMapelKelasFormState();
}

class _GuruMapelKelasFormState extends State<GuruMapelKelasForm> {
  final _formKey = GlobalKey<FormState>();

  bool get isEditing => widget.editData != null;

  int? _guruId;
  int? _mapelId;
  int? _kelasId;

  List<Map<String, dynamic>> _guruList = [];
  List<Map<String, dynamic>> _mapelList = [];
  List<Map<String, dynamic>> _kelasList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _guruId = widget.editData!['guru_id'] as int?;
      _mapelId = widget.editData!['mata_pelajaran_id'] as int?;
      _kelasId = widget.editData!['kelas_id'] as int?;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final guruRes = await AdminService.list('guru', page: 1, perPage: 100);
      _guruList = (guruRes['items'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _guruList = [];
      if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat daftar guru');
    }
    try {
      final mapelRes = await AdminService.list('mata-pelajaran', page: 1, perPage: 100);
      _mapelList = (mapelRes['items'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _mapelList = [];
      if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat daftar mata pelajaran');
    }
    try {
      final kelasRes = await AdminService.list('kelas', page: 1, perPage: 100);
      _kelasList = (kelasRes['items'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _kelasList = [];
      if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat daftar kelas');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _onSave() async {
    if (_guruId == null || _mapelId == null || _kelasId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guru, mata pelajaran, dan kelas wajib dipilih')),
      );
      return;
    }
    final body = <String, dynamic>{
      'guru_id': _guruId,
      'mata_pelajaran_id': _mapelId,
      'kelas_id': _kelasId,
    };
    try {
      if (isEditing) {
        await AdminService.updateGuruMapelKelas(widget.editData!['id'] as int, body);
      } else {
        await AdminService.createGuruMapelKelas(body);
      }
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Penugasan Mengajar' : 'Tambah Penugasan Mengajar'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DataCard(
                header: Row(children: [
                  Icon(Icons.school_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Penugasan Mengajar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ]),
                child: _isLoading
                    ? const Center(
                        child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ModernDropdown<int>(
                            value: _guruId,
                            label: 'Guru (Asatidz)',
                            icon: Icons.people_outline,
                            items: _guruList.map((g) => DropdownMenuItem<int>(
                              value: g['id'] as int,
                              child: Text('${g['nip']} - ${g['nama']}', style: const TextStyle(fontSize: 13)),
                            )).toList(),
                            onChanged: (v) => setState(() => _guruId = v),
                          ),
                          const SizedBox(height: 16),
                          ModernDropdown<int>(
                            value: _mapelId,
                            label: 'Mata Pelajaran',
                            icon: Icons.book_outlined,
                            items: _mapelList.map((m) => DropdownMenuItem<int>(
                              value: m['id'] as int,
                              child: Text(m['nama']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                            )).toList(),
                            onChanged: (v) => setState(() => _mapelId = v),
                          ),
                          const SizedBox(height: 16),
                          ModernDropdown<int>(
                            value: _kelasId,
                            label: 'Kelas',
                            icon: Icons.meeting_room_outlined,
                            items: _kelasList.map((k) => DropdownMenuItem<int>(
                              value: k['id'] as int,
                              child: Text(k['nama']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                            )).toList(),
                            onChanged: (v) => setState(() => _kelasId = v),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(onPressed: _onSave, child: const Text('Simpan')),
      ],
    );
  }
}