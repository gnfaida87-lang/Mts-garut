part of 'pengaturan_page.dart';

// ── Backup Tab ──
class _BackupTab extends StatefulWidget {
  @override
  State<_BackupTab> createState() => _BackupTabState();
}

class _BackupTabState extends State<_BackupTab> {
  bool _loading = false;
  String? _lastBackup;

  @override
  void initState() {
    super.initState();
    _loadLastBackup();
  }

  Future<void> _loadLastBackup() async {
    try {
      final res = await AdminService.getLogAktivitas(page: 1, perPage: 1);
      final items = res['items'] as List;
      for (final item in items) {
        final m = item as Map<String, dynamic>;
        if (m['aksi'] == 'backup') {
          _lastBackup = m['created_at']?.toString();
          return;
        }
      }
    } catch (_) { debugPrint('[pengaturan_backup_restore_tab.dart] error caught'); }
  }

  Future<void> _doBackup() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.post('/admin/backup');
      final data = res['data'] as Map<String, dynamic>;
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final blob = html.Blob([jsonStr], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final now = DateTime.now();
      final filename = 'backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      _lastBackup = now.toIso8601String().replaceAll('T', ' ').split('.')[0];
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup berhasil: $filename')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: DataCard(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.backup, size: 48, color: AppTheme.blue),
            ),
            const SizedBox(height: 20),
            Text('Backup Database', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Download seluruh data ke file JSON.', style: TextStyle(color: AppTheme.grey600)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.grey50, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.calendar_today, size: 16, color: AppTheme.grey500),
                const SizedBox(width: 8),
                Text(_lastBackup != null ? 'Backup terakhir: $_lastBackup' : 'Belum pernah backup',
                    style: TextStyle(fontSize: 13, color: _lastBackup != null ? AppTheme.grey700 : AppTheme.grey500)),
              ]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _doBackup,
                icon: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download),
                label: Text(_loading ? 'Memproses...' : 'Download Backup'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Restore Tab ──
class _RestoreTab extends StatefulWidget {
  @override
  State<_RestoreTab> createState() => _RestoreTabState();
}

class _RestoreTabState extends State<_RestoreTab> {
  bool _loading = false;
  String? _fileName;
  int? _fileSize;

  Future<void> _pickAndRestore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membaca file')));
      return;
    }

    setState(() {
      _fileName = result.files.first.name;
      _fileSize = bytes.length;
      _loading = true;
    });

    try {
      final jsonStr = utf8.decode(bytes);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      final data = parsed['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('File backup tidak valid: field "data" tidak ditemukan');
      }
      await AdminService.restore({'data': data});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore berhasil!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
    if (mounted) setState(() => _loading = false);
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: DataCard(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.restore, size: 48, color: AppTheme.orange),
            ),
            const SizedBox(height: 20),
            Text('Restore Database', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Pilih file backup JSON untuk mengembalikan data.', style: TextStyle(color: AppTheme.grey600)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _fileName != null ? AppTheme.orange.withValues(alpha: 0.05) : AppTheme.grey50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _fileName != null ? AppTheme.orange.withValues(alpha: 0.3) : AppTheme.grey200),
              ),
              child: _fileName != null
                  ? Row(children: [
                      const Icon(Icons.insert_drive_file, size: 20, color: AppTheme.orange),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_fileName!, style: const TextStyle(fontSize: 13, color: AppTheme.grey700)),
                      ),
                      Text(_fmtSize(_fileSize!), style: const TextStyle(fontSize: 11, color: AppTheme.grey500)),
                    ])
                  : const Row(children: [
                      Icon(Icons.folder_open, size: 20, color: AppTheme.grey400),
                      SizedBox(width: 8),
                      Text('Belum ada file dipilih', style: TextStyle(fontSize: 13, color: AppTheme.grey500)),
                    ]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _pickAndRestore,
                icon: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload_file),
                label: Text(_loading ? 'Merestore...' : 'Pilih & Restore File'),
              ),
            ),
            const SizedBox(height: 12),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.warning_amber_outlined, size: 14, color: AppTheme.grey400),
              SizedBox(width: 6),
              Text('Akan menimpa data yang sudah ada', style: TextStyle(fontSize: 11, color: AppTheme.grey500)),
            ]),
          ]),
        ),
      ),
    );
  }
}
