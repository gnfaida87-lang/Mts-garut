import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/dauroh_service.dart';
import '../widgets/dauroh_form_widgets.dart';

class ProgramFormPage extends StatefulWidget {
  final Map<String, dynamic>? editData;
  final VoidCallback? onSaved;

  const ProgramFormPage({super.key, this.editData, this.onSaved});

  @override
  State<ProgramFormPage> createState() => _ProgramFormPageState();
}

class _ProgramFormPageState extends State<ProgramFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();

  String _jenisProgram = 'kelas';
  String _jenisDauroh = 'tahfidz';
  String _skemaPenilaian = 'murojaah_tahfidz';
  bool _isAktif = true;
  bool _saving = false;

  // Konfigurasi Skema Penilaian
  final _maxBidang1Ctrl = TextEditingController(text: '40');
  final _maxBidang2Ctrl = TextEditingController(text: '30');
  final _maxBidang3Ctrl = TextEditingController(text: '30');
  final _labelBidang1Ctrl = TextEditingController(text: 'Kelancaran Hafalan');
  final _labelBidang2Ctrl = TextEditingController(text: 'Tajwid');
  final _labelBidang3Ctrl = TextEditingController(text: 'Fashohah dan Adab');
  bool _showSkemaConfig = false;

  bool get _isEdit => widget.editData != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final d = widget.editData!;
      _namaCtrl.text = d['nama_program']?.toString() ?? '';
      _keteranganCtrl.text = d['keterangan']?.toString() ?? '';
      _jenisProgram = d['jenis_program']?.toString() ?? 'kelas';
      _jenisDauroh = d['jenis_dauroh']?.toString() ?? 'tahfidz';
      _skemaPenilaian = d['skema_penilaian']?.toString() ?? 'murojaah_tahfidz';
      _isAktif = d['is_aktif'] == 1;
      _maxBidang1Ctrl.text = d['max_bidang1']?.toString() ?? '40';
      _maxBidang2Ctrl.text = d['max_bidang2']?.toString() ?? '30';
      _maxBidang3Ctrl.text = d['max_bidang3']?.toString() ?? '30';
      _labelBidang1Ctrl.text = d['label_bidang1']?.toString() ?? 'Kelancaran Hafalan';
      _labelBidang2Ctrl.text = d['label_bidang2']?.toString() ?? 'Tajwid';
      _labelBidang3Ctrl.text = d['label_bidang3']?.toString() ?? 'Fashohah dan Adab';
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _keteranganCtrl.dispose();
    _maxBidang1Ctrl.dispose();
    _maxBidang2Ctrl.dispose();
    _maxBidang3Ctrl.dispose();
    _labelBidang1Ctrl.dispose();
    _labelBidang2Ctrl.dispose();
    _labelBidang3Ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final body = {
        'nama_program': _namaCtrl.text,
        'jenis_program': _jenisProgram,
        'jenis_dauroh': _jenisDauroh,
        'skema_penilaian': _skemaPenilaian,
        'keterangan': _keteranganCtrl.text.isNotEmpty ? _keteranganCtrl.text : null,
        'is_aktif': _isAktif ? 1 : 0,
        'max_bidang1': int.tryParse(_maxBidang1Ctrl.text) ?? 40,
        'max_bidang2': int.tryParse(_maxBidang2Ctrl.text) ?? 30,
        'max_bidang3': int.tryParse(_maxBidang3Ctrl.text) ?? 30,
        'label_bidang1': _labelBidang1Ctrl.text.isNotEmpty ? _labelBidang1Ctrl.text : null,
        'label_bidang2': _labelBidang2Ctrl.text.isNotEmpty ? _labelBidang2Ctrl.text : null,
        'label_bidang3': _labelBidang3Ctrl.text.isNotEmpty ? _labelBidang3Ctrl.text : null,
      };

      if (_isEdit) {
        await DaurohService.updateProgram(widget.editData!['id'] as int, body);
      } else {
        await DaurohService.createProgram(body);
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Program' : 'Tambah Program'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── INFO DASAR ──────────────────────────
                DaurohField(
                  controller: _namaCtrl,
                  label: 'Nama Program',
                  icon: Icons.book_outlined,
                  hint: 'Contoh: Tahfidz Quran',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DaurohDropdown<String>(
                        value: _jenisProgram,
                        label: 'Jenis Program',
                        icon: Icons.category_outlined,
                        items: const [
                          DropdownMenuItem(value: 'kelas', child: Text('Kelas')),
                          DropdownMenuItem(value: 'khusus', child: Text('Khusus')),
                        ],
                        onChanged: (v) => setState(() => _jenisProgram = v ?? 'kelas'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DaurohDropdown<String>(
                        value: _jenisDauroh,
                        label: 'Jenis at-Ta\'wid',
                        icon: Icons.menu_book_outlined,
                        items: const [
                          DropdownMenuItem(value: 'tahfidz', child: Text('Tahfidz')),
                          DropdownMenuItem(value: 'murojaah', child: Text('Murojaah')),
                        ],
                        onChanged: (v) => setState(() => _jenisDauroh = v ?? 'tahfidz'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DaurohField(
                  controller: _keteranganCtrl,
                  label: 'Keterangan',
                  icon: Icons.notes_outlined,
                  optional: true,
                  hint: 'Deskripsi program',
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktif', style: TextStyle(fontSize: 14)),
                  subtitle: Text(
                    _isAktif ? 'Program aktif' : 'Program tidak aktif',
                    style: const TextStyle(fontSize: 12, color: AppTheme.grey500),
                  ),
                  value: _isAktif,
                  onChanged: (v) => setState(() => _isAktif = v),
                ),

                const Divider(height: 24),
                // ── SKEMA PENILAIAN ─────────────────────
                InkWell(
                  onTap: () => setState(() => _showSkemaConfig = !_showSkemaConfig),
                  child: Row(
                    children: [
                      const Icon(Icons.tune, size: 18, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Konfigurasi Skema Penilaian',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(
                        _showSkemaConfig ? Icons.expand_less : Icons.expand_more,
                        color: AppTheme.grey500,
                      ),
                    ],
                  ),
                ),
                if (_showSkemaConfig) ...[
                  const SizedBox(height: 12),
                  DaurohDropdown<String>(
                    value: _skemaPenilaian,
                    label: 'Skema Penilaian',
                    icon: Icons.grading_outlined,
                    items: const [
                      DropdownMenuItem(value: 'murojaah_tahfidz', child: Text('Murojaah + Tahfidz')),
                      DropdownMenuItem(value: 'custom', child: Text('Custom')),
                    ],
                    onChanged: (v) => setState(() => _skemaPenilaian = v ?? 'murojaah_tahfidz'),
                  ),
                  const SizedBox(height: 16),

                  // Bidang 1
                  _buildBidangConfig(
                    label: 'Bidang 1',
                    maxCtrl: _maxBidang1Ctrl,
                    labelCtrl: _labelBidang1Ctrl,
                    defaultLabel: 'Kelancaran Hafalan',
                    defaultMax: '40',
                    color: AppTheme.primary,
                  ),
                  const SizedBox(height: 12),

                  // Bidang 2
                  _buildBidangConfig(
                    label: 'Bidang 2',
                    maxCtrl: _maxBidang2Ctrl,
                    labelCtrl: _labelBidang2Ctrl,
                    defaultLabel: 'Tajwid',
                    defaultMax: '30',
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),

                  // Bidang 3
                  _buildBidangConfig(
                    label: 'Bidang 3',
                    maxCtrl: _maxBidang3Ctrl,
                    labelCtrl: _labelBidang3Ctrl,
                    defaultLabel: 'Fashohah dan Adab',
                    defaultMax: '30',
                    color: const Color(0xFF9C6644),
                  ),
                  const SizedBox(height: 8),

                  // Total preview
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.grey50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Total Maksimal: ', style: TextStyle(fontSize: 12, color: AppTheme.grey600)),
                        Text(
                          '${int.tryParse(_maxBidang1Ctrl.text) ?? 40} + ${int.tryParse(_maxBidang2Ctrl.text) ?? 30} + ${int.tryParse(_maxBidang3Ctrl.text) ?? 30} = ${(int.tryParse(_maxBidang1Ctrl.text) ?? 40) + (int.tryParse(_maxBidang2Ctrl.text) ?? 30) + (int.tryParse(_maxBidang3Ctrl.text) ?? 30)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),
                ],
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

  Widget _buildBidangConfig({
    required String label,
    required TextEditingController maxCtrl,
    required TextEditingController labelCtrl,
    required String defaultLabel,
    required String defaultMax,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: labelCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Label Bidang',
                    hintText: defaultLabel,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: maxCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Max',
                    hintText: defaultMax,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
