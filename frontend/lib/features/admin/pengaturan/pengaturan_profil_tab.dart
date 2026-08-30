part of 'pengaturan_page.dart';

// ── Profil Sekolah Tab ──
class _ProfilTab extends StatefulWidget {
  @override
  State<_ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends State<_ProfilTab> {
  final _namaCtrl = TextEditingController();
  final _alamatCtrl = TextEditingController();
  final _telpCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await AdminService.getProfil();
      _namaCtrl.text = data['nama']?.toString() ?? '';
      _alamatCtrl.text = data['alamat']?.toString() ?? '';
      _telpCtrl.text = data['telepon']?.toString() ?? '';
      _emailCtrl.text = data['email']?.toString() ?? '';
    } catch (e) {
      if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat profil sekolah');
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    try {
      await AdminService.updateProfil({
        'nama': _namaCtrl.text,
        'alamat': _alamatCtrl.text,
        'telepon': _telpCtrl.text,
        'email': _emailCtrl.text,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil sekolah tersimpan')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose(); _alamatCtrl.dispose(); _telpCtrl.dispose(); _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            DataCard(
              header: const Row(children: [
                Icon(Icons.school_outlined, size: 20, color: AppTheme.primary),
                SizedBox(width: 8),
                Text('Profil Sekolah', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: _namaCtrl, decoration: inputDecoration('Nama Sekolah', Icons.badge_outlined)),
                const SizedBox(height: 16),
                TextField(controller: _alamatCtrl, maxLines: 3, decoration: inputDecoration('Alamat', Icons.location_on_outlined)),
                const SizedBox(height: 16),
                TextField(controller: _telpCtrl, decoration: inputDecoration('Telepon', Icons.phone_outlined)),
                const SizedBox(height: 16),
                TextField(controller: _emailCtrl, decoration: inputDecoration('Email', Icons.email_outlined)),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save, size: 18), label: const Text('Simpan Profil')),
                    OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh, size: 18), label: const Text('Reset')),
                  ],
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Tampilan Login Tab ──
class _TampilanLoginTab extends StatefulWidget {
  @override
  State<_TampilanLoginTab> createState() => _TampilanLoginTabState();
}

class _TampilanLoginTabState extends State<_TampilanLoginTab> {
  final _heroTitleCtrl = TextEditingController();
  final _heroSubtitleCtrl = TextEditingController();
  final _logoUrlCtrl = TextEditingController();
  final _bgUrlCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await AdminService.getPengaturanTampilan();
      for (final item in items) {
        final m = item as Map<String, dynamic>;
        if (m['key'] == 'hero_title') _heroTitleCtrl.text = m['value'] as String? ?? '';
        if (m['key'] == 'hero_subtitle') _heroSubtitleCtrl.text = m['value'] as String? ?? '';
        if (m['key'] == 'logo_url') _logoUrlCtrl.text = m['value'] as String? ?? '';
        if (m['key'] == 'background_url') _bgUrlCtrl.text = m['value'] as String? ?? '';
      }
    } catch (e) {
      if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat tampilan login');
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    try {
      await AdminService.updatePengaturanTampilan({
        'hero_title': _heroTitleCtrl.text,
        'hero_subtitle': _heroSubtitleCtrl.text,
        'logo_url': _logoUrlCtrl.text,
        'background_url': _bgUrlCtrl.text,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tampilan login tersimpan')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  @override
  void dispose() {
    _heroTitleCtrl.dispose(); _heroSubtitleCtrl.dispose();
    _logoUrlCtrl.dispose(); _bgUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            DataCard(
              header: const Row(children: [
                Icon(Icons.login_outlined, size: 20, color: AppTheme.primary),
                SizedBox(width: 8),
                Text('Tampilan Halaman Login', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: _heroTitleCtrl, decoration: inputDecoration('Judul Hero', Icons.title)),
                const SizedBox(height: 16),
                TextField(controller: _heroSubtitleCtrl, maxLines: 3, decoration: inputDecoration('Subtitle Hero', Icons.description_outlined)),
                const SizedBox(height: 16),
                TextField(controller: _logoUrlCtrl, decoration: inputDecoration('URL Logo', Icons.image_outlined).copyWith(hintText: 'https://...')),
                const SizedBox(height: 16),
                TextField(controller: _bgUrlCtrl, decoration: inputDecoration('URL Background', Icons.wallpaper_outlined).copyWith(hintText: 'https://...')),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save, size: 18), label: const Text('Simpan')),
                    OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh, size: 18), label: const Text('Reset')),
                  ],
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Text('Pratinjau', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primaryDark, AppTheme.secondary]),
                borderRadius: BorderRadius.circular(12),
                image: _bgUrlCtrl.text.isNotEmpty
                    ? DecorationImage(image: NetworkImage(_bgUrlCtrl.text), fit: BoxFit.cover, opacity: 0.3)
                    : null,
              ),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _logoUrlCtrl.text.isNotEmpty
                      ? Image.network(_logoUrlCtrl.text, width: 40, height: 40, color: Colors.white)
                      : const Icon(Icons.school, size: 40, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(_heroTitleCtrl.text.isNotEmpty ? _heroTitleCtrl.text : 'Judul',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(_heroSubtitleCtrl.text.isNotEmpty ? _heroSubtitleCtrl.text : 'Subtitle',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
