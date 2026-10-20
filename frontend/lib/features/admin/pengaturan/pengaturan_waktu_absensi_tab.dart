part of 'pengaturan_page.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Waktu Absensi Tab (jam masuk & jam keluar absensi QR asatidz)
// ═══════════════════════════════════════════════════════════════════════════════

class _WaktuAbsensiTab extends StatefulWidget {
  @override
  State<_WaktuAbsensiTab> createState() => _WaktuAbsensiTabState();
}

class _WaktuAbsensiTabState extends State<_WaktuAbsensiTab> {
  final _masukMulaiCtrl = TextEditingController();
  final _masukSelesaiCtrl = TextEditingController();
  final _keluarMulaiCtrl = TextEditingController();
  final _keluarSelesaiCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() {
    _masukMulaiCtrl.dispose();
    _masukSelesaiCtrl.dispose();
    _keluarMulaiCtrl.dispose();
    _keluarSelesaiCtrl.dispose();
    super.dispose();
  }

  /// 'HH:MM:SS' atau 'HH:MM' -> 'HH:MM'
  String _short(String? t) {
    final v = t ?? '';
    return v.length >= 5 ? v.substring(0, 5) : v;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await AdminService.getPengaturanWaktuAbsensi();
      _masukMulaiCtrl.text = _short(data['jam_masuk_mulai']?.toString());
      _masukSelesaiCtrl.text = _short(data['jam_masuk_selesai']?.toString());
      _keluarMulaiCtrl.text = _short(data['jam_keluar_mulai']?.toString());
      _keluarSelesaiCtrl.text = _short(data['jam_keluar_selesai']?.toString());
    } catch (e) {
      if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat pengaturan waktu absensi');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final values = <String, String>{
      'jam_masuk_mulai': _masukMulaiCtrl.text.trim(),
      'jam_masuk_selesai': _masukSelesaiCtrl.text.trim(),
      'jam_keluar_mulai': _keluarMulaiCtrl.text.trim(),
      'jam_keluar_selesai': _keluarSelesaiCtrl.text.trim(),
    };
    final re = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
    if (values.values.any((v) => !re.hasMatch(v))) {
      AppUtils.showError(context, 'Format jam tidak valid (gunakan HH:MM)');
      return;
    }

    setState(() => _saving = true);
    try {
      await AdminService.updatePengaturanWaktuAbsensi(values);
      if (mounted) AppUtils.showSuccess(context, 'Pengaturan waktu absensi tersimpan');
    } catch (e) {
      if (mounted) AppUtils.handleError(context, e, message: 'Gagal menyimpan pengaturan');
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final parts = ctrl.text.split(':');
    final initial = TimeOfDay(
      hour: parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 7) : 7,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        ctrl.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Widget _timeField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      readOnly: true,
      onTap: () => _pickTime(ctrl),
      decoration: inputDecoration(label, Icons.access_time).copyWith(
        suffixIcon: IconButton(
          icon: const Icon(Icons.schedule, size: 18),
          onPressed: () => _pickTime(ctrl),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: DataCard(
            header: const Row(children: [
              Icon(Icons.schedule_outlined, size: 20, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Waktu Absensi Asatidz', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              const Text(
                'Atur jam masuk dan jam keluar untuk absensi QR asatidz. Perubahan langsung berlaku untuk scan berikutnya.',
                style: TextStyle(fontSize: 12, color: AppTheme.grey600),
              ),
              const SizedBox(height: 20),
              const Text('Jam Masuk', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.grey800)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _timeField('Mulai', _masukMulaiCtrl)),
                const SizedBox(width: 12),
                Expanded(child: _timeField('Selesai', _masukSelesaiCtrl)),
              ]),
              const SizedBox(height: 20),
              const Text('Jam Keluar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.grey800)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _timeField('Mulai', _keluarMulaiCtrl)),
                const SizedBox(width: 12),
                Expanded(child: _timeField('Selesai', _keluarSelesaiCtrl)),
              ]),
              const SizedBox(height: 12),
              const Row(children: [
                Icon(Icons.info_outline, size: 14, color: AppTheme.grey400),
                SizedBox(width: 6),
                Expanded(child: Text(
                  'Jam masuk selesai harus sebelum jam keluar mulai. Waktu mengikuti zona WIB.',
                  style: TextStyle(fontSize: 11, color: AppTheme.grey500),
                )),
              ]),
              const SizedBox(height: 20),
              Wrap(spacing: 16, runSpacing: 8, children: [
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save, size: 18),
                  label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                ),
                OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh, size: 18), label: const Text('Reset')),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
