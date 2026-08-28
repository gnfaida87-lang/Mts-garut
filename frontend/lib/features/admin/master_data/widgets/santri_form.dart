import 'package:flutter/material.dart';
import '../../../../features/admin/services/admin_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/common_widgets.dart';
import 'form_fields.dart';

class SantriForm extends StatefulWidget {
  final Map<String, dynamic>? editData;
  final VoidCallback onSaved;

  const SantriForm({super.key, this.editData, required this.onSaved});

  @override
  State<SantriForm> createState() => _SantriFormState();
}

class _SantriFormState extends State<SantriForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nisCtrl;
  late final TextEditingController _nisnCtrl;
  late final TextEditingController _namaCtrl;
  late final TextEditingController _namaAyahCtrl;
  late final TextEditingController _namaIbuCtrl;
  late final TextEditingController _pekerjaanAyahCtrl;
  late final TextEditingController _pekerjaanIbuCtrl;
  late final TextEditingController _whatsappCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;

  String? _selectedJk;
  String? _selectedStatus;
  int? _selectedKelasId;
  int? _selectedTingkatId;
  bool _passwordObscure = true;

  List<Map<String, dynamic>> _kelasList = [];
  List<Map<String, dynamic>> _tingkatList = [];
  bool _isLoadingKelas = false;

  bool get isEditing => widget.editData != null;

  @override
  void initState() {
    super.initState();
    _nisCtrl = TextEditingController(text: widget.editData?['nis']?.toString() ?? '');
    _nisnCtrl = TextEditingController(text: widget.editData?['nisn']?.toString() ?? '');
    _namaCtrl = TextEditingController(text: widget.editData?['nama']?.toString() ?? '');
    _namaAyahCtrl = TextEditingController(text: widget.editData?['nama_ayah']?.toString() ?? '');
    _namaIbuCtrl = TextEditingController(text: widget.editData?['nama_ibu']?.toString() ?? '');
    _pekerjaanAyahCtrl = TextEditingController(text: widget.editData?['pekerjaan_ayah']?.toString() ?? '');
    _pekerjaanIbuCtrl = TextEditingController(text: widget.editData?['pekerjaan_ibu']?.toString() ?? '');
    _whatsappCtrl = TextEditingController(text: widget.editData?['whatsapp']?.toString() ?? '');
    _usernameCtrl = TextEditingController(text: widget.editData?['username']?.toString() ?? '');
    _passwordCtrl = TextEditingController(text: '');

    if (isEditing) {
      _selectedJk = widget.editData!['jenis_kelamin']?.toString();
      final rawStatus = widget.editData!['status']?.toString() ?? '';
      if (rawStatus.toLowerCase() == 'aktif') {
        _selectedStatus = 'aktif';
      } else if (rawStatus.toLowerCase() == 'lulus') {
        _selectedStatus = 'lulus';
      } else if (rawStatus.toLowerCase() == 'keluar') {
        _selectedStatus = 'keluar';
      } else if (rawStatus.toLowerCase() == 'pindah') {
        _selectedStatus = 'pindah';
      } else {
        _selectedStatus = rawStatus.isNotEmpty ? rawStatus : null;
      }
    }

    _loadKelas();
  }

  @override
  void dispose() {
    _nisCtrl.dispose();
    _nisnCtrl.dispose();
    _namaCtrl.dispose();
    _namaAyahCtrl.dispose();
    _namaIbuCtrl.dispose();
    _pekerjaanAyahCtrl.dispose();
    _pekerjaanIbuCtrl.dispose();
    _whatsappCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadKelas() async {
    setState(() => _isLoadingKelas = true);
    try {
      final tingkatRes = await AdminService.list('tingkat', perPage: 100);
      _tingkatList = (tingkatRes['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      _tingkatList = [];
    }
    try {
      final res = await AdminService.list('kelas', page: 1, perPage: 200);
      _kelasList = (res['items'] as List).cast<Map<String, dynamic>>();
    } catch (_) {
      _kelasList = [];
    }
    if (isEditing && widget.editData != null) {
      _selectedKelasId = int.tryParse(widget.editData!['kelas_id']?.toString() ?? '');
      if (_selectedKelasId != null) {
        final matchedKelas = _kelasList.firstWhere(
          (k) => k['id'] == _selectedKelasId,
          orElse: () => {},
        );
        _selectedTingkatId = matchedKelas['tingkat_id'] as int?;
      }
      if (_selectedKelasId != null && !_kelasList.any((k) => k['id'] == _selectedKelasId)) {
        _selectedKelasId = null;
      }
    }
    if (mounted) setState(() => _isLoadingKelas = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Santri' : 'Tambah Santri'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDataPribadiCard(),
              const SizedBox(height: 16),
              _buildPenempatanKelasCard(),
              const SizedBox(height: 16),
              _buildDataOrangTuaCard(),
              const SizedBox(height: 16),
              _buildAkunLoginCard(),
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

  Widget _buildDataPribadiCard() {
    return DataCard(
      header: Row(children: [
        Icon(Icons.person_outline, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        const Text('Data Pribadi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        FormRow(children: [
          Expanded(child: ModernField(controller: _nisCtrl, label: 'NIS', icon: Icons.badge_outlined, hint: 'Nomor Induk Santri')),
          const SizedBox(width: 16),
          Expanded(child: ModernField(controller: _nisnCtrl, label: 'NISN', icon: Icons.numbers_outlined, hint: 'Nomor Induk Santri Nasional', optional: true)),
        ]),
        const SizedBox(height: 16),
        ModernField(controller: _namaCtrl, label: 'Nama Santri', icon: Icons.text_fields, hint: 'Nama lengkap santri'),
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
                DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                DropdownMenuItem(value: 'lulus', child: Text('Lulus')),
                DropdownMenuItem(value: 'keluar', child: Text('Keluar')),
                DropdownMenuItem(value: 'pindah', child: Text('Pindah')),
              ],
              onChanged: (v) => setState(() => _selectedStatus = v),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildPenempatanKelasCard() {
    final filteredKelas = _selectedTingkatId == null
        ? _kelasList
        : _kelasList.where((k) => k['tingkat_id'] == _selectedTingkatId).toList();

    return DataCard(
      header: Row(children: [
        Icon(Icons.meeting_room_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        const Text('Penempatan Kelas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
      child: _isLoadingKelas
          ? const Text('Memuat data kelas...', style: TextStyle(color: AppTheme.grey500))
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ModernDropdown<int>(
                  value: _selectedTingkatId,
                  label: 'Jenjang / Tingkat',
                  icon: Icons.stairs_outlined,
                  items: _tingkatList.map((t) => DropdownMenuItem<int>(
                    value: t['id'] as int,
                    child: Text('${t['nama']} (${t['jenjang']})', style: const TextStyle(fontSize: 14)),
                  )).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedTingkatId = v;
                      if (_selectedKelasId != null) {
                        final stillValid = filteredKelas.any((k) => k['id'] == _selectedKelasId);
                        if (!stillValid) _selectedKelasId = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                ModernDropdown<int>(
                  value: _selectedKelasId,
                  label: 'Kelas',
                  icon: Icons.school_outlined,
                  items: filteredKelas.map((k) => DropdownMenuItem<int>(
                    value: k['id'] as int,
                    child: Text(k['nama']?.toString() ?? '', style: const TextStyle(fontSize: 14)),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedKelasId = v),
                ),
              ],
            ),
    );
  }

  Widget _buildDataOrangTuaCard() {
    return DataCard(
      header: Row(children: [
        Icon(Icons.family_restroom_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        const Text('Data Orang Tua', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        FormRow(children: [
          Expanded(child: ModernField(controller: _namaAyahCtrl, label: 'Nama Ayah', icon: Icons.man_outlined, hint: 'Nama lengkap ayah')),
          const SizedBox(width: 16),
          Expanded(child: ModernField(controller: _namaIbuCtrl, label: 'Nama Ibu', icon: Icons.woman_outlined, hint: 'Nama lengkap ibu')),
        ]),
        const SizedBox(height: 16),
        FormRow(children: [
          Expanded(child: ModernField(controller: _pekerjaanAyahCtrl, label: 'Pekerjaan Ayah', icon: Icons.work_outlined, hint: 'Pekerjaan ayah', optional: true)),
          const SizedBox(width: 16),
          Expanded(child: ModernField(controller: _pekerjaanIbuCtrl, label: 'Pekerjaan Ibu', icon: Icons.work_outlined, hint: 'Pekerjaan ibu', optional: true)),
        ]),
        const SizedBox(height: 16),
        ModernField(controller: _whatsappCtrl, label: 'Nomor WhatsApp', icon: Icons.phone_outlined, hint: '08xxxxxxxxxx', keyboardType: TextInputType.phone, optional: true),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        const Text(
          'Kosongkan Username & Password untuk otomatis memakai NIS sebagai username sekaligus password.',
          style: TextStyle(fontSize: 11, color: AppTheme.grey500),
        ),
        const SizedBox(height: 12),
        ModernField(controller: _usernameCtrl, label: 'Username', icon: Icons.alternate_email, hint: 'Username untuk login'),
        const SizedBox(height: 16),
        ModernPasswordField(
          controller: _passwordCtrl,
          label: 'Password',
          obscureText: _passwordObscure,
          onToggle: () => setState(() => _passwordObscure = !_passwordObscure),
          validator: null,
          suffixText: 'Kosong = NIS',
        ),
      ]),
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final body = <String, dynamic>{
      'nis': _nisCtrl.text,
      'nisn': _nisnCtrl.text,
      'nama': _namaCtrl.text,
      'jenis_kelamin': _selectedJk,
      'kelas_id': _selectedKelasId,
      'status': _selectedStatus,
      'nama_ayah': _namaAyahCtrl.text,
      'nama_ibu': _namaIbuCtrl.text,
      'pekerjaan_ayah': _pekerjaanAyahCtrl.text,
      'pekerjaan_ibu': _pekerjaanIbuCtrl.text,
      'whatsapp': _whatsappCtrl.text,
      'username': _usernameCtrl.text,
    };

    if (isEditing && _passwordCtrl.text.isEmpty) {
      // skip empty password on edit
    } else {
      body['password'] = _passwordCtrl.text;
    }

    try {
      if (isEditing) {
        await AdminService.update('siswa', widget.editData!['id'] as int, body);
      } else {
        await AdminService.create('siswa', body);
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
