part of 'nilai_page.dart';

class _RiwayatNilaiPage extends StatefulWidget {
  const _RiwayatNilaiPage();
  @override
  State<_RiwayatNilaiPage> createState() => __RiwayatNilaiPageState();
}

class __RiwayatNilaiPageState extends State<_RiwayatNilaiPage> {
  List<dynamic> _items = [];
  bool _loading = true;
  int _page = 1, _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await GuruService.getNilai(page: _page, perPage: 20);
      _items = data['items'] as List<dynamic>? ?? [];
      final pag = data['pagination'] as Map<String, dynamic>?;
      _totalPages = pag?['total_pages'] as int? ?? 1;
    } catch (_) { debugPrint('[nilai_riwayat_analisis.dart] error caught'); }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Nilai'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('Belum ada nilai', style: TextStyle(fontSize: 15, color: Colors.grey[500])),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final n = _items[i] as Map<String, dynamic>;
                          final nilai = (n['nilai'] as num?)?.toDouble() ?? 0;
                          final color = _nilaiColor(nilai);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey[200]!),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                  child: Center(child: Text('${nilai.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(n['siswa_nama'] as String? ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text('${n['mapel_nama']} â€¢ ${n['kelas_nama']}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(_jenisLabel(n['jenis'] as String? ?? ''), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1565C0))),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(n['created_at'] as String? ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                                          if (n['status_validasi'] == 'tervalidasi') ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: const Color(0xFF9C6644).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                              child: const Text('Tervalidasi', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9C6644))),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (n['status_validasi'] != 'tervalidasi')
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Hapus Nilai'),
                                          content: Text('Hapus nilai ${n['siswa_nama']}?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        try {
                                          await GuruService.deleteNilai(n['id'] as int);
                                          if (!mounted) return;
                                          if (mounted) {
                                            ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Nilai dihapus')));
                                          }
                                          _load();
                                        } catch (e) {
                                          if (!mounted) return;
                                          if (mounted) {
                                            ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                                          }
                                        }
                                      }
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (_totalPages > 1)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded),
                              onPressed: _page > 1 ? () => setState(() { _page--; _load(); }) : null,
                            ),
                            const SizedBox(width: 8),
                            Text('$_page / $_totalPages', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded),
                              onPressed: _page < _totalPages ? () => setState(() { _page++; _load(); }) : null,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}

// â”€â”€â”€ ANALISIS NILAI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AnalisisNilaiPage extends StatefulWidget {
  const _AnalisisNilaiPage();
  @override
  State<_AnalisisNilaiPage> createState() => __AnalisisNilaiPageState();
}

class __AnalisisNilaiPageState extends State<_AnalisisNilaiPage> {
  bool _loading = true;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Load semua data untuk analisis yang akurat
      final data = await GuruService.getNilai(page: 1, perPage: 1000);
      final items = data['items'] as List<dynamic>? ?? [];
      final total = data['pagination'] is Map ? (data['pagination'] as Map)['total'] as int? ?? 0 : 0;
      double avg = 0;
      if (items.isNotEmpty) {
        final sum = items.fold<double>(0.0, (s, e) => s + (((e as Map)['nilai'] as num?) ?? 0).toDouble());
        avg = sum / items.length;
      }
      _stats = {'total': total, 'rata_rata': avg};
    } catch (_) { debugPrint('[nilai_riwayat_analisis.dart] error caught'); }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisis Nilai'),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(color: const Color(0xFFE65100).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.bar_chart_rounded, color: Color(0xFFE65100), size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Text('Statistik Nilai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _statCard('Total Input', '${_stats?['total'] ?? 0}', Icons.grading_rounded, const Color(0xFF1565C0)),
                          const SizedBox(width: 12),
                          _statCard('Rata-rata', (_stats?['rata_rata'] as double?)?.toStringAsFixed(1) ?? '0', Icons.trending_up_rounded, const Color(0xFF9C6644)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ SHARED WIDGETS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF9C6644)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;
  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}
