import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../features/admin/services/admin_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';
import 'form_fields.dart';

class MataPelajaranForm extends StatefulWidget {
  final Map<String, dynamic>? editData;
  final VoidCallback onSaved;

  const MataPelajaranForm({super.key, this.editData, required this.onSaved});

  @override
  State<MataPelajaranForm> createState() => _MataPelajaranFormState();
}

class _MataPelajaranFormState extends State<MataPelajaranForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaCtrl;
  late final TextEditingController _kodeCtrl;
  Set<int> _selectedKelasIds = {};
  List<Map<String, dynamic>> _kelasList = [];
  bool _isLoadingKelas = false;

  bool get isEditing => widget.editData != null;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.editData?['nama']?.toString() ?? '');
    _kodeCtrl = TextEditingController(text: widget.editData?['kode']?.toString() ?? '');
    _loadKelas();
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _kodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadKelas() async {
    setState(() => _isLoadingKelas = true);
    try {
      final res = await AdminService.list('kelas', page: 1, perPage: 100);
      _kelasList = (res['items'] as List).cast<Map<String, dynamic>>();
    } catch (_) {
      _kelasList = [];
    }
    if (isEditing && widget.editData != null) {
      await _loadExistingKelas();
    }
    if (mounted) setState(() => _isLoadingKelas = false);
  }

  Future<void> _loadExistingKelas() async {
    try {
      final mapelId = widget.editData!['id'] as int;
      final r = await ApiClient.get('/admin/mapel-kelas/$mapelId/kelas');
      final ids = (r['data'] as List).cast<int>();
      _selectedKelasIds = ids.toSet();
    } catch (_) { debugPrint('[mata_pelajaran_form.dart] error caught'); }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Mata Pelajaran' : 'Tambah Mata Pelajaran'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DataCard(
                header: Row(children: [
                  Icon(Icons.book_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Data Mata Pelajaran', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  ModernField(controller: _namaCtrl, label: 'Nama Mapel', icon: Icons.badge_outlined),
                  const SizedBox(height: 16),
                  ModernField(controller: _kodeCtrl, label: 'Kode Mapel', icon: Icons.code_outlined, hint: 'Contoh: MTK-WAJIB'),
                ]),
              ),
              const SizedBox(height: 16),
              DataCard(
                header: Row(children: [
                  Icon(Icons.meeting_room_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Kelas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  if (_isLoadingKelas)
                    const Text('Memuat data kelas...', style: TextStyle(color: AppTheme.grey500))
                  else
                    ..._kelasList.map((k) => CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      title: Text(k['nama']?.toString() ?? '', style: const TextStyle(fontSize: 14)),
                      value: _selectedKelasIds.contains(k['id'] as int),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedKelasIds.add(k['id'] as int);
                          } else {
                            _selectedKelasIds.remove(k['id'] as int);
                          }
                        });
                      },
                    )),
                ]),
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

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final body = <String, dynamic>{
      'nama': _namaCtrl.text,
      'kode': _kodeCtrl.text,
    };

    try {
      int? savedId;
      if (isEditing) {
        await AdminService.update('mata-pelajaran', widget.editData!['id'] as int, body);
        savedId = widget.editData!['id'] as int;
      } else {
        final result = await AdminService.create('mata-pelajaran', body);
        savedId = result['id'] as int?;
      }

      if (savedId != null) {
        await ApiClient.put('/admin/mapel-kelas/$savedId/kelas', body: {
          'kelas_ids': _selectedKelasIds.toList(),
        });
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }
}
