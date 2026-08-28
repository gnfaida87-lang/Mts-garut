part of 'pengaturan_page.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// API Keys Tab
// ═══════════════════════════════════════════════════════════════════════════════

class _ApiKeysTab extends StatefulWidget {
  @override
  State<_ApiKeysTab> createState() => _ApiKeysTabState();
}

class _ApiKeysTabState extends State<_ApiKeysTab> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  int _page = 1, _totalPages = 1;
  String? _search;
  String? _statusFilter; // 'aktif', 'nonaktif', null
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await AdminService.getApiKeys(
        page: _page,
        perPage: 20,
        search: _search,
        status: _statusFilter,
      );
      if (mounted) {
        setState(() {
          _items = (res['items'] as List).cast<Map<String, dynamic>>();
          _totalPages = res['pagination']?['total_pages'] ?? 1;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final namaCtrl = TextEditingController();
    String permissions = 'readwrite';
    final rateLimitCtrl = TextEditingController(text: '1000');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Generate API Key Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaCtrl,
                decoration: inputDecoration('Nama Pihak', Icons.badge_outlined)
                    .copyWith(hintText: 'Contoh: Bank BRI, Toko Maju, Aplikasi Pihak Kedua'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: permissions,
                decoration: inputDecoration('Permission', Icons.lock_outline),
                items: const [
                  DropdownMenuItem(value: 'read', child: Text('Read Only (GET santri, kelas, kenaikan-kelas)')),
                  DropdownMenuItem(value: 'write', child: Text('Write Only (POST pembayaran, notifikasi)')),
                  DropdownMenuItem(value: 'readwrite', child: Text('Read + Write (Semua akses)')),
                ],
                onChanged: (v) { permissions = v!; setD(() {}); },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rateLimitCtrl,
                decoration: inputDecoration('Rate Limit (request/hari)', Icons.speed_outlined),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                if (namaCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Nama pihak wajib diisi')),
                  );
                  return;
                }
                try {
                  final res = await AdminService.createApiKey({
                    'nama_pihak': namaCtrl.text.trim(),
                    'permissions': permissions,
                    'rate_limit': int.tryParse(rateLimitCtrl.text) ?? 5000,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                  // Show API Key once
                  if (ctx.mounted) {
                    final apiKey = res['api_key'] as String?;
                    if (apiKey != null) {
                      _showApiKeyDialog(apiKey);
                    }
                  }
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e')));
                }
              },
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  void _showApiKeyDialog(String apiKey) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.orange, size: 24),
            SizedBox(width: 8),
            Expanded(child: Text('API Key Dihasilkan')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Simpan API Key ini sekarang! Tidak dapat ditampilkan lagi.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.grey100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.grey300),
              ),
              child: SelectableText(
                apiKey,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Gunakan header: ', style: TextStyle(fontSize: 12, color: AppTheme.grey600)),
            const Text('X-API-Key: <api_key>', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppTheme.primary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Saya Sudah Menyimpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStatus(Map<String, dynamic> item) async {
    final newStatus = !(item['is_aktif'] as bool);
    final nama = item['nama_pihak'] as String;
    try {
      await AdminService.updateApiKey(item['id'] as int, {'is_aktif': newStatus});
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$nama ${newStatus ? "diaktifkan" : "dinonaktifkan"}')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _editPermissions(Map<String, dynamic> item) async {
    String permissions = item['permissions'] as String? ?? 'readwrite';
    final rateLimitCtrl = TextEditingController(text: (item['rate_limit'] ?? 5000).toString());

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('Edit: ${item['nama_pihak']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: permissions,
                decoration: inputDecoration('Permission', Icons.lock_outline),
                items: const [
                  DropdownMenuItem(value: 'read', child: Text('Read Only')),
                  DropdownMenuItem(value: 'write', child: Text('Write Only')),
                  DropdownMenuItem(value: 'readwrite', child: Text('Read + Write')),
                ],
                onChanged: (v) { permissions = v!; setD(() {}); },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rateLimitCtrl,
                decoration: inputDecoration('Rate Limit (request/hari)', Icons.speed_outlined),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                try {
                  await AdminService.updateApiKey(item['id'] as int, {
                    'permissions': permissions,
                    'rate_limit': int.tryParse(rateLimitCtrl.text) ?? 5000,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e')));
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final ok = await AppUtils.confirm(
      context,
      title: 'Hapus API Key',
      message: 'Yakin hapus API Key "${item['nama_pihak']}"? Tindakan ini tidak dapat dibatalkan.',
    );
    if (!ok) return;
    try {
      await AdminService.deleteApiKey(item['id'] as int);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Key dihapus')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Header actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FilledButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.key_outlined, size: 18),
              label: const Text('Generate API Key'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Filter row
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 160,
              child: DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.grey300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _statusFilter,
                    hint: const Text('Semua Status', style: TextStyle(fontSize: 13)),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Semua Status')),
                      DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                      DropdownMenuItem(value: 'nonaktif', child: Text('Nonaktif')),
                    ],
                    onChanged: (v) { setState(() => _statusFilter = v); _load(); },
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 200,
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari nama pihak...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onSubmitted: (v) {
                  setState(() => _search = v.trim().isEmpty ? null : v.trim());
                  _load();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // List
        Expanded(child: _items.isEmpty
            ? const EmptyState(icon: Icons.key_outlined, message: 'Belum ada API Key. Klik "Generate API Key" untuk membuat.')
            : ListView.builder(
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final item = _items[i];
                  final isActive = item['is_aktif'] as bool? ?? false;
                  final permissions = item['permissions'] as String? ?? 'readwrite';
                  final rateLimit = item['rate_limit'] as int? ?? 5000;
                  final lastUsed = item['last_used_at'] as String?;
                  final createdAt = item['created_at'] as String?;

                  Color permColor;
                  String permLabel;
                  switch (permissions) {
                    case 'read':
                      permColor = AppTheme.blue;
                      permLabel = 'Read';
                      break;
                    case 'write':
                      permColor = AppTheme.orange;
                      permLabel = 'Write';
                      break;
                    case 'readwrite':
                      permColor = AppTheme.indigo;
                      permLabel = 'Read + Write';
                      break;
                    default:
                      permColor = AppTheme.grey600;
                      permLabel = permissions;
                  }

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isActive ? AppTheme.grey200 : AppTheme.grey100),
                    ),
                    color: isActive ? null : AppTheme.grey50.withValues(alpha: 0.5),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isActive ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.grey300.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.key_outlined,
                                  size: 22,
                                  color: isActive ? AppTheme.primary : AppTheme.grey400,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['nama_pihak'] as String? ?? '-',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        StatusBadge(label: isActive ? 'Aktif' : 'Nonaktif', color: isActive ? AppTheme.teal : AppTheme.grey400),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: permColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            permLabel,
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: permColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Actions
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: AppTheme.grey500),
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      _editPermissions(item);
                                      break;
                                    case 'toggle':
                                      _toggleStatus(item);
                                      break;
                                    case 'delete':
                                      _delete(item);
                                      break;
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit Permission')])),
                                  // ignore: prefer_const_constructors - uses runtime variable isActive
                                  PopupMenuItem(value: 'toggle', child: Row(children: [Icon(isActive ? Icons.block_outlined : Icons.check_circle_outline, size: 18), SizedBox(width: 8), Text(isActive ? 'Nonaktifkan' : 'Aktifkan')])),
                                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppTheme.error), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: AppTheme.error))])),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: AppTheme.grey100),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 24,
                            runSpacing: 8,
                            children: [
                              _InfoChip(icon: Icons.speed_outlined, label: 'Rate Limit', value: '$rateLimit/hari'),
                              _InfoChip(icon: Icons.access_time_outlined, label: 'Terakhir Dipakai', value: _formatDate(lastUsed)),
                              _InfoChip(icon: Icons.calendar_today_outlined, label: 'Dibuat', value: _formatDate(createdAt)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )),
        // Pagination
        if (_totalPages > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: PaginationRow(
              currentPage: _page,
              totalPages: _totalPages,
              onPrevious: _page > 1 ? () { _page--; _load(); } : null,
              onNext: _page < _totalPages ? () { _page++; _load(); } : null,
            ),
          ),
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.grey500),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AppTheme.grey500)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.grey700)),
      ],
    );
  }
}
