import 'package:flutter/material.dart';
import '../services/dauroh_service.dart';
import '../widgets/dauroh_form_widgets.dart';

class JadwalFormPage extends StatefulWidget {
  final Map<String, dynamic>? editData;
  final VoidCallback? onSaved;

  const JadwalFormPage({super.key, this.editData, this.onSaved});

  @override
  State<JadwalFormPage> createState() => _JadwalFormPageState();
}

class _JadwalFormPageState extends State<JadwalFormPage> {
  final _formKey = GlobalKey<FormState>();

  int? _programId;
  int? _musyrifah1Id;
  int? _musyrifah2Id;
  final Set<String> _selectedHari = {'Senin'};
  final _jamMulaiCtrl = TextEditingController(text: '08:00');
  final _jamSelesaiCtrl = TextEditingController(text: '10:00');
  bool _isAktif = true;
  bool _saving = false;

  static bool _validWaktu(String t) => RegExp(r'^\d{2}:\d{2}$').hasMatch(t);

  static int _toMenit(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  List<Map<String, dynamic>> _programList = [];
  List<Map<String, dynamic>> _musyrifahList = [];
  List<Map<String, dynamic>> _kelasList = [];
  Set<int> _selectedKelas = {};

  bool get _isEdit => widget.editData != null;

  @override
  void initState() {
    super.initState();
    _loadReferensi();
    if (_isEdit) {
      final d = widget.editData!;
      _programId = d['program_id'] as int?;
      _musyrifah1Id = d['musyrifah_1_id'] as int?;
      _musyrifah2Id = d['musyrifah_2_id'] as int?;
      _selectedHari
        ..clear()
        ..add(d['hari']?.toString() ?? 'Senin');
      _jamMulaiCtrl.text = d['jam_mulai']?.toString() ?? '08:00';
      _jamSelesaiCtrl.text = d['jam_selesai']?.toString() ?? '10:00';
      _isAktif = d['is_aktif'] == 1;
      // Load kelas terkait
      _loadKelasTerkait(d['id'] as int);
    }
  }

  Future<void> _loadReferensi() async {
    try {
      final programRes = await DaurohService.listProgram(perPage: 100);
      final musyrifahRes = await DaurohService.listMusyrifah(perPage: 100);
      final kelasRes = await DaurohService.getReferensi();
      if (mounted) {
        setState(() {
          _programList = (programRes['items'] as List).cast<Map<String, dynamic>>();
          _musyrifahList = (musyrifahRes['items'] as List).cast<Map<String, dynamic>>();
          _kelasList = (kelasRes['kelas'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        });
      }
    } catch (_) { debugPrint('[jadwal_form_page.dart] error caught'); }
  }

  Future<void> _loadKelasTerkait(int jadwalId) async {
    try {
      final detail = await DaurohService.getJadwal(jadwalId);
      final kelas = detail['kelas'] as List?;
      if (kelas != null && mounted) {
        setState(() {
          _selectedKelas = kelas
              .map((k) => (k as Map<String, dynamic>)['id'] as int)
              .toSet();
        });
      }
    } catch (_) { debugPrint('[jadwal_form_page.dart] error caught'); }
  }

  @override
  void dispose() {
    _jamMulaiCtrl.dispose();
    _jamSelesaiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Jadwal' : 'Tambah Jadwal'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DaurohDropdown<int>(
                  value: _programId,
                  label: 'Program Kegiatan',
                  icon: Icons.book_outlined,
                  items: _programList.map((p) => DropdownMenuItem<int>(
                    value: p['id'] as int,
                    child: Text('${p['nama_program']} (${p['jenis_dauroh']})'),
                  )).toList(),
                  onChanged: (v) => setState(() => _programId = v),
                ),
                const SizedBox(height: 16),
                DaurohDropdown<int>(
                  value: _musyrifah1Id,
                  label: 'Musyrifah 1 (Wajib)',
                  icon: Icons.person_outline,
                  items: _musyrifahList.map((m) => DropdownMenuItem<int>(
                    value: m['id'] as int,
                    child: Text('${m['nama']} - ${m['nipmus']}'),
                  )).toList(),
                  onChanged: (v) => setState(() => _musyrifah1Id = v),
                ),
                const SizedBox(height: 16),
                DaurohDropdown<int>(
                  value: _musyrifah2Id,
                  label: 'Musyrifah 2 (Opsional)',
                  icon: Icons.person_outline,
                  items: [
                    const DropdownMenuItem<int>(value: null, child: Text('- Tidak Ada -')),
                    ..._musyrifahList.map((m) => DropdownMenuItem<int>(
                      value: m['id'] as int,
                      child: Text('${m['nama']} - ${m['nipmus']}'),
                    )),
                  ],
                  onChanged: (v) => setState(() => _musyrifah2Id = v),
                ),
                const SizedBox(height: 16),
                DaurohMultiSelect<String>(
                  title: 'Hari (bisa pilih beberapa)',
                  icon: Icons.calendar_today_outlined,
                  items: const ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'],
                  selectedIds: _selectedHari,
                  idFn: (h) => h,
                  labelFn: (h) => h,
                  onChanged: (h) {
                    setState(() {
                      if (_selectedHari.contains(h)) {
                        _selectedHari.remove(h);
                      } else {
                        _selectedHari.add(h);
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildWaktuField(
                        controller: _jamMulaiCtrl,
                        label: 'Jam Mulai',
                        icon: Icons.access_time,
                        hint: 'cth: 07:45',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildWaktuField(
                        controller: _jamSelesaiCtrl,
                        label: 'Jam Selesai',
                        icon: Icons.access_time_filled,
                        hint: 'cth: 10:30',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DaurohMultiSelect<Map<String, dynamic>>(
                  title: 'Kelas',
                  icon: Icons.meeting_room_outlined,
                  items: _kelasList,
                  selectedIds: _selectedKelas,
                  idFn: (k) => k['id'],
                  labelFn: (k) => k['nama']?.toString() ?? '',
                  onChanged: (k) {
                    final id = k['id'] as int;
                    setState(() {
                      if (_selectedKelas.contains(id)) {
                        _selectedKelas.remove(id);
                      } else {
                        _selectedKelas.add(id);
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktif', style: TextStyle(fontSize: 14)),
                  value: _isAktif,
                  onChanged: (v) => setState(() => _isAktif = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }

  Widget _buildWaktuField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: (v) {
        final t = v?.trim() ?? '';
        if (t.isEmpty) return '$label wajib diisi';
        if (!_validWaktu(t)) return 'Format jam harus HH:MM';
        return null;
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_programId == null || _musyrifah1Id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Program dan Musyrifah 1 wajib dipilih')),
      );
      return;
    }
    if (_selectedHari.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 hari')),
      );
      return;
    }

    final jamMulai = _jamMulaiCtrl.text.trim();
    final jamSelesai = _jamSelesaiCtrl.text.trim();
    if (_toMenit(jamMulai) >= _toMenit(jamSelesai)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jam mulai harus lebih awal dari jam selesai')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final body = {
        'program_id': _programId,
        'musyrifah_1_id': _musyrifah1Id,
        'musyrifah_2_id': _musyrifah2Id,
        'hari': _selectedHari.toList(),
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,
        'kelas_ids': _selectedKelas.toList(),
        'is_aktif': _isAktif ? 1 : 0,
      };

      if (_isEdit) {
        await DaurohService.updateJadwal(widget.editData!['id'] as int, body);
      } else {
        await DaurohService.createJadwal(body);
      }

      if (mounted) {
        widget.onSaved?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
