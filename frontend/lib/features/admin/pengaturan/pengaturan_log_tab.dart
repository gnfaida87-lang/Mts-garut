part of 'pengaturan_page.dart';

// ── Log Tab ──
class _LogTab extends StatefulWidget {
  @override
  State<_LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<_LogTab> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  int _page = 1, _totalPages = 1;
  String? _filterModul;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await AdminService.getLogAktivitas(page: _page);
      if (mounted) { setState(() {
        _logs = (res['items'] as List).cast<Map<String, dynamic>>();
        _totalPages = res['pagination']?['total_pages'] ?? 1;
        _loading = false;
      }); }
    } catch (e) { if (mounted) { setState(() => _loading = false); AppUtils.handleError(context, e, message: 'Gagal memuat log aktivitas'); } }
  }

  List<Map<String, dynamic>> get _filteredLogs {
    var result = _logs;
    if (_filterModul != null && _filterModul!.isNotEmpty) {
      result = result.where((l) => l['modul']?.toString() == _filterModul).toList();
    }
    if (_searchCtrl.text.isNotEmpty) {
      final q = _searchCtrl.text.toLowerCase();
      result = result.where((l) =>
        (l['detail']?.toString() ?? '').toLowerCase().contains(q) ||
        (l['username']?.toString() ?? '').toLowerCase().contains(q)
      ).toList();
    }
    return result;
  }

  IconData aksiIcon(String? aksi) {
    switch (aksi) {
      case 'create': return Icons.add_circle_outline;
      case 'update': return Icons.edit_outlined;
      case 'delete': return Icons.remove_circle_outline;
      case 'login': return Icons.login;
      case 'backup': return Icons.backup;
      case 'restore': return Icons.restore;
      default: return Icons.history;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final filteredLogs = _filteredLogs;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 180,
              child: DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.grey300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _filterModul,
                    hint: const Text('Semua Modul', style: TextStyle(fontSize: 13)),
                    isExpanded: true,
                    items: ['absensi', 'guru', 'siswa', 'users', 'backup', 'restore', 'nilai', 'rapor', 'pengaduan', 'master_data', 'pengaturan']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) { setState(() => _filterModul = v); },
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 200,
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari detail...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(child: filteredLogs.isEmpty
            ? const EmptyState(icon: Icons.history, message: 'Belum ada log.')
            : ListView.builder(
                itemCount: filteredLogs.length,
                itemBuilder: (_, i) {
                  final log = filteredLogs[i];
                  final aksi = log['aksi']?.toString();
                  final color = AuditAction.colorFor(aksi ?? '');
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.grey200)),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(aksiIcon(aksi), size: 20, color: color),
                      ),
                      title: Row(children: [
                        Text(log['username']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(width: 8),
                        StatusBadge(label: aksi ?? '-', color: color),
                      ]),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SizedBox(height: 2),
                        Text('${log['modul'] ?? '-'} — ${log['detail'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppTheme.grey600)),
                        Text(log['created_at']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.grey400)),
                      ]),
                    ),
                  );
                },
              )),
        const SizedBox(height: 8),
        PaginationRow(
          currentPage: _page,
          totalPages: _totalPages,
          onPrevious: _page > 1 ? () { _page--; _load(); } : null,
          onNext: _page < _totalPages ? () { _page++; _load(); } : null,
        ),
      ]),
    );
  }
}
