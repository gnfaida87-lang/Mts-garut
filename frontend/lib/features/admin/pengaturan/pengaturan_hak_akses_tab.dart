part of 'pengaturan_page.dart';

// ── Hak Akses Tab ──
class _HakAksesTab extends StatefulWidget {
  @override
  State<_HakAksesTab> createState() => _HakAksesTabState();
}

class _HakAksesTabState extends State<_HakAksesTab> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await AdminService.getHakAkses();
      if (mounted) setState(() { _items = res.cast<Map<String, dynamic>>(); _loading = false; });
    } catch (e) { if (mounted) { setState(() => _loading = false); AppUtils.handleError(context, e, message: 'Gagal memuat hak akses'); } }
  }

  Future<void> _add() {
    String? role, modul, aksi = 'view';
    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Tambah Hak Akses'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              decoration: inputDecoration('Role', Icons.badge_outlined),
              items: roleIcons.entries.map((e) => DropdownMenuItem(value: e.key,
                child: Row(children: [Icon(e.value, size: 18), const SizedBox(width: 8), Text(UserModel.roleDisplayName(e.key))]),
              )).toList(),
              onChanged: (v) { role = v; setD(() {}); },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: inputDecoration('Modul', Icons.widgets_outlined),
              items: ['dashboard', 'master_data', 'penjadwalan', 'absensi', 'nilai', 'rapor', 'pengaduan', 'konseling', 'bakat_minat', 'kenaikan_kelas', 'alumni', 'users', 'pengaturan', 'laporan']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) { modul = v; setD(() {}); },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: inputDecoration('Aksi', Icons.flash_on_outlined),
              items: const ['view', 'create', 'edit', 'delete', 'validate']
                  .map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
              onChanged: (v) { aksi = v; setD(() {}); },
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(onPressed: () async {
              try {
                await AdminService.addHakAkses({'role': role, 'modul': modul, 'aksi': aksi});
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              } catch (e) { if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e'))); }
            }, child: const Text('Simpan')),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(int id) async {
    final ok = await AppUtils.confirm(context, title: 'Hapus', message: 'Yakin hapus hak akses ini?');
    if (!ok) return;
    try { await AdminService.deleteHakAkses(id); _load(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          FilledButton.icon(onPressed: _add, icon: const Icon(Icons.add, size: 18), label: const Text('Tambah')),
        ]),
        const SizedBox(height: 16),
        Expanded(child: _items.isEmpty
            ? const EmptyState(icon: Icons.security_outlined, message: 'Belum ada hak akses.')
            : ListView.builder(
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final item = _items[i];
                  final role = item['role']?.toString() ?? '';
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.grey200)),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(roleIcons[role] ?? Icons.person_outline, size: 20, color: AppTheme.blue),
                      ),
                      title: Text(UserModel.roleDisplayName(role), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('Modul: ${item['modul']}  ·  Aksi: ${item['aksi']}', style: const TextStyle(fontSize: 12, color: AppTheme.grey600)),
                      trailing: IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                          onPressed: () => _delete(item['id'] as int)),
                    ),
                  );
                },
              )),
      ]),
    );
  }
}
