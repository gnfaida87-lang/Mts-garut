import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../features/admin/services/admin_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/guru_mapel_kelas_model.dart';
import '../../../../shared/widgets/app_utils.dart';
import '../../../../shared/widgets/common_widgets.dart';
import 'form_fields.dart';
import 'mapel_kelas_picker.dart';

class AsatidzForm extends StatefulWidget {
  final Map<String, dynamic>? editData;
  final VoidCallback onSaved;

  const AsatidzForm({super.key, this.editData, required this.onSaved});

  @override
  State<AsatidzForm> createState() => _AsatidzFormState();
}

class _AsatidzFormState extends State<AsatidzForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nipCtrl;
  late final TextEditingController _namaCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;

  String? _selectedJk;
  String? _selectedStatus;
  Set<String> _selectedJabatan = {};
  List<GuruMapelKelas> _assignments = [];
  int? _waliKelasId;

  List<Map<String, dynamic>> _kelasList = [];
  List<Map<String, dynamic>> _mapelList = [];
  bool _isLoadingData = false;
  bool _passwordObscure = true;
  bool _assignmentsLoadError = false;

  bool get isEditing => widget.editData != null;

  static const _jabatanOptions = [
    MapEntry('guru_mapel', 'Asatidz Mapel'),
    MapEntry('wali_kelas', 'Wali Kelas'),
    MapEntry('kepala_sekolah', 'Kepala Madrasah'),
    MapEntry('wakil_kurikulum', 'Wakil Kurikulum'),
    MapEntry('guru_bk', 'Asatidz BK'),
  ];

  @override
  void initState() {
    super.initState();
    _nipCtrl = TextEditingController(text: widget.editData?['nip']?.toString() ?? '');
    _namaCtrl = TextEditingController(text: widget.editData?['nama']?.toString() ?? '');
    _usernameCtrl = TextEditingController(text: widget.editData?['username']?.toString() ?? '');
    _passwordCtrl = TextEditingController(text: '');

    if (isEditing) {
      _selectedJk = widget.editData!['jenis_kelamin']?.toString();
      final statusVal = widget.editData!['status_aktif'];
      _selectedStatus = statusVal == 1 ? 'Aktif' : (statusVal == 0 ? 'Tidak Aktif' : null);
      final jabatanStr = widget.editData!['jabatan']?.toString() ?? '';
      if (jabatanStr.isNotEmpty) {
        _selectedJabatan = jabatanStr.split(',').map((s) => s.trim()).toSet();
      }
    }

    _loadData();
  }

  @override
  void dispose() {
    _nipCtrl.dispose();
    _namaCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      final kelasRes = await AdminService.list('kelas', page: 1, perPage: 100);
      _kelasList = (kelasRes['items'] as List).cast<Map<String, dynamic>>();
    } catch (_) {
      _kelasList = [];
    }
    try {
      final mapelRes = await AdminService.list('mata-pelajaran', page: 1, perPage: 100);
      _mapelList = (mapelRes['items'] as List).cast<Map<String, dynamic>>();
    } catch (_) {
      _mapelList = [];
    }
    if (isEditing) {
      await _loadExistingAssignments();
    }
    if (mounted) setState(() => _isLoadingData = false);
  }

  Future<void> _loadExistingAssignments() async {
    final gid = widget.editData!['id'] as int;
    try {
      final data = await AdminService.getGuruMapelKelas(gid);
      _assignments = data.map((e) => GuruMapelKelas.fromJson(e as Map<String, dynamic>)).toList();
      _assignmentsLoadError = false;
    } catch (_) {
      _assignments = [];
      _assignmentsLoadError = true;
    }
    try {
      final r = await ApiClient.get('/admin/guru-wali-kelas/$gid');
      _waliKelasId = r['data']?['kelas_id'] as int?;
    } catch (e) {
      if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat wali kelas');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Asatidz' : 'Tambah Asatidz'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDataAsatidzCard(),
              const SizedBox(height: 16),
              _buildAkunLoginCard(),
              const SizedBox(height: 16),
              _buildMapelKelasCard(),
              if (_selectedJabatan.contains('wali_kelas')) ...[
                const SizedBox(height: 16),
                _buildWaliKelasCard(),
              ],
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

  Widget _buildDataAsatidzCard() {
    return DataCard(
      header: Row(children: [
        Icon(Icons.people_outline, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        const Text('Data Asatidz', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        FormRow(children: [
          Expanded(child: ModernField(controller: _nipCtrl, label: 'NIP', icon: Icons.badge_outlined)),
          const SizedBox(width: 16),
          Expanded(child: ModernField(controller: _namaCtrl, label: 'Nama Asatidz', icon: Icons.text_fields)),
        ]),
        const SizedBox(height: 16),
        FormRow(children: [
          Expanded(
            child: ModernDropdown<String>(
              value: _selectedJk,
              label: 'Jenis Kelamin',
              icon: Icons.wc_outlined,
              items: const [
                DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                DropdownMenuItem(value: 'P', child: Text('Perempuan')),
              ],
              onChanged: (v) => setState(() => _selectedJk = v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ModernDropdown<String>(
              value: _selectedStatus,
              label: 'Status',
              icon: Icons.flag_outlined,
              items: const [
                DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                DropdownMenuItem(value: 'Tidak Aktif', child: Text('Tidak Aktif')),
              ],
              onChanged: (v) => setState(() => _selectedStatus = v),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        ModernCheckboxGroup(
          title: 'Jabatan',
          icon: Icons.work_outline,
          options: _jabatanOptions,
          selectedValues: _selectedJabatan,
          onChanged: (val) {
            setState(() {
              if (_selectedJabatan.contains(val)) {
                _selectedJabatan.remove(val);
              } else {
                _selectedJabatan.add(val);
              }
            });
          },
        ),
      ]),
    );
  }

  Widget _buildAkunLoginCard() {
    return DataCard(
      header: Row(children: [
        Icon(Icons.lock_outline, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        const Text('Akun Login', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
      child: FormRow(children: [
        Expanded(child: ModernField(controller: _usernameCtrl, label: 'Username', icon: Icons.person_outline)),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _passwordCtrl,
            obscureText: _passwordObscure,
            decoration: InputDecoration(
              labelText: isEditing ? 'Password (kosongkan jika tidak diubah)' : 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_passwordObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                onPressed: () => setState(() => _passwordObscure = !_passwordObscure),
              ),
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildMapelKelasCard() {
    return MapelKelasPicker(
      mapelList: _mapelList,
      kelasList: _kelasList,
      assignments: _assignments,
      onChanged: (value) => setState(() => _assignments = value),
    );
  }

  Widget _buildWaliKelasCard() {
    return DataCard(
      header: Row(children: [
        Icon(Icons.supervisor_account_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        const Text('Wali Kelas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        const Text('Pilih kelas yang menjadi wali kelas:', style: TextStyle(fontSize: 13, color: AppTheme.grey600)),
        const SizedBox(height: 12),
        if (_isLoadingData)
          const Text('Memuat data kelas...', style: TextStyle(color: AppTheme.grey500))
        else
          ModernDropdown<int>(
            value: _waliKelasId,
            label: 'Wali Kelas',
            icon: Icons.supervisor_account_outlined,
            items: [
              const DropdownMenuItem<int>(
                value: null,
                child: Text('— Tidak Ada —'),
              ),
              ..._kelasList.map((k) => DropdownMenuItem<int>(
                value: k['id'] as int,
                child: Text(k['nama']?.toString() ?? ''),
              )),
            ],
            onChanged: (val) => setState(() => _waliKelasId = val),
          ),
      ]),
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final errors = <String>[];
    if (_nipCtrl.text.trim().isEmpty) errors.add('NIP wajib diisi');
    if (_namaCtrl.text.trim().isEmpty) errors.add('Nama wajib diisi');
    if (_selectedJk == null) errors.add('Jenis Kelamin wajib dipilih');
    if (_selectedJabatan.isEmpty) errors.add('Minimal pilih satu Jabatan');
    if (_selectedStatus == null) errors.add('Status wajib dipilih');

    final hasUsername = _usernameCtrl.text.trim().isNotEmpty;
    final hasPassword = _passwordCtrl.text.isNotEmpty;
    if (!isEditing) {
      // Saat membuat akun baru: username + password harus lengkap bersama.
      if (hasUsername && !hasPassword) errors.add('Password wajib diisi jika username diisi');
      if (hasPassword && !hasUsername) errors.add('Username wajib diisi jika password diisi');
    } else if (hasPassword && !hasUsername) {
      // Saat mengedit: password opsional (kosong = tidak diubah).
      // Hanya dicek jika password diisi tapi username malah dikosongkan.
      errors.add('Username wajib diisi jika password diisi');
    }

    if (errors.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errors.join('\n')),
        duration: const Duration(seconds: 4),
      ));
      return;
    }

    final body = <String, dynamic>{
      'nip': _nipCtrl.text.trim(),
      'nama': _namaCtrl.text.trim(),
      'jenis_kelamin': _selectedJk,
      'jabatan': _selectedJabatan.join(','),
      'status_aktif': _selectedStatus == 'Aktif' ? 1 : 0,
    };

    if (hasUsername) body['username'] = _usernameCtrl.text.trim();
    if (hasPassword) body['password'] = _passwordCtrl.text;

    try {
      int? savedId;
      if (isEditing) {
        await AdminService.update('guru', widget.editData!['id'] as int, body);
        savedId = widget.editData!['id'] as int;
      } else {
        final result = await AdminService.create('guru', body);
        savedId = result['id'] as int?;
      }

      if (savedId != null) {
        // Jika data penugasan lama gagal dimuat, simpan sekarang akan
        // menghapus penugasan yang sudah ada — minta konfirmasi dulu.
        if (isEditing && _assignmentsLoadError) {
          if (!mounted) return;
          final proceed = await AppUtils.confirm(
            context,
            title: 'Perhatian',
            message: 'Data penugasan mapel-kelas guru ini gagal dimuat.\n\n'
                'Menyimpan sekarang akan MENGHAPUS penugasan yang sudah ada.\n'
                'Batalkan lalu buka kembali form untuk memuat ulang data, '
                'atau lanjutkan penyimpanan?',
            confirmText: 'Tetap Simpan',
            cancelText: 'Batal',
          );
          if (!proceed) return;
        }

        // Simpan guru_mapel_kelas (gabungan spesifik)
        final assignmentsData = _assignments.map((a) => a.toJson()).toList();
        await AdminService.saveGuruMapelKelas(savedId, assignmentsData);

        // Simpan wali kelas
        if (_selectedJabatan.contains('wali_kelas')) {
          await ApiClient.put('/admin/guru-wali-kelas/$savedId', body: {
            'kelas_id': _waliKelasId,
          });
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      final displayMsg = msg.contains('sudah ada')
          ? 'Error: $msg\nGunakan NIP atau Username yang berbeda.'
          : 'Gagal menyimpan: $msg';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(displayMsg),
        duration: const Duration(seconds: 5),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }
}
