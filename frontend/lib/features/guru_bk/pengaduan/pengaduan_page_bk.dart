import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_utils.dart';
import '../services/guru_bk_service.dart';

class PengaduanPageBK extends StatefulWidget {
  const PengaduanPageBK({super.key});

  @override
  State<PengaduanPageBK> createState() => _PengaduanPageBKState();
}

class _PengaduanPageBKState extends State<PengaduanPageBK>
    with SingleTickerProviderStateMixin {
  List<dynamic> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _errorMessage;
  String? _filterStatus;
  String? _filterKategori;
  int _page = 1;
  int _totalPages = 1;
  int _requestSeq = 0;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _load();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final seq = ++_requestSeq;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _page = 1;
      _errorMessage = null;
    });
    try {
      final data = await GuruBKService.getPengaduan(
        status: _filterStatus,
        kategori: _filterKategori,
        page: _page,
      );
      if (!mounted || seq != _requestSeq) return;
      _items = data['items'] as List<dynamic>? ?? [];
      final pag = data['pagination'] as Map<String, dynamic>?;
      _totalPages = pag?['total_pages'] as int? ?? 1;
      setState(() => _loading = false);
      _animCtrl.reset();
      _animCtrl.forward();
    } catch (e) {
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Gagal memuat data pengaduan. Periksa koneksi Anda.';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _totalPages) return;
    final seq = ++_requestSeq;
    setState(() => _loadingMore = true);
    try {
      final data = await GuruBKService.getPengaduan(
        status: _filterStatus,
        kategori: _filterKategori,
        page: _page + 1,
      );
      if (!mounted || seq != _requestSeq) return;
      final newItems = data['items'] as List<dynamic>? ?? [];
      final pag = data['pagination'] as Map<String, dynamic>?;
      _items.addAll(newItems);
      _page++;
      _totalPages = pag?['total_pages'] as int? ?? _totalPages;
    } catch (e) { if (mounted) AppUtils.handleError(context, e, message: 'Gagal memuat data pengaduan berikutnya'); }
    if (mounted) setState(() => _loadingMore = false);
  }

  void _onFilterChanged({String? status, String? kategori}) {
    setState(() {
      _filterStatus = status;
      _filterKategori = kategori;
    });
    _load();
  }

  Future<void> _updateStatus(int id, String status) async {
    String? tindakLanjut;
    if (status == 'selesai') {
      final ctl = TextEditingController();
      tindakLanjut = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.edit_note, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Tindak Lanjut'),
            ],
          ),
          content: TextField(
            controller: ctl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Catatan tindak lanjut...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctl.text),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      );
    }

    try {
      final body = <String, dynamic>{'status': status};
      if (tindakLanjut != null && tindakLanjut.isNotEmpty) {
        body['tindak_lanjut'] = tindakLanjut;
      }
      await GuruBKService.updatePengaduan(id, body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'diproses'
              ? 'Pengaduan sedang diproses'
              : status == 'selesai'
                  ? 'Pengaduan selesai'
                  : 'Status diperbarui'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 3));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: RefreshIndicator(
        onRefresh: _load,
        color: AppTheme.primary,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 768;
            return CustomScrollView(
              slivers: [
                // ── HEADER ──
                SliverToBoxAdapter(child: _buildHeader()),

                // ── FILTERS ──
                SliverToBoxAdapter(child: _buildFilters()),

                // ── LIST / GRID ──
                if (_items.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Tidak ada pengaduan',
                              style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    ),
                  )
                else
                  isWide ? _buildGridSliver() : _buildListSliver(),

                // ── LOAD MORE ──
                if (_page < _totalPages)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: _loadingMore
                            ? const CircularProgressIndicator(strokeWidth: 2)
                            : OutlinedButton.icon(
                                onPressed: _loadMore,
                                icon: const Icon(Icons.expand_more),
                                label: const Text('Muat Lebih Banyak'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  side: const BorderSide(color: AppTheme.primary),
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────────────────
  Widget _buildHeader() {
    final total = _items.length;
    final baru = _items.where((i) => i['status'] == 'baru').length;
    final diproses = _items.where((i) => i['status'] == 'diproses').length;
    final selesai = _items.where((i) => i['status'] == 'selesai').length;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.report_outlined, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PENGADUAN SANTRI',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Daftar Pengaduan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child:                    Text(
                      '${_totalPages > 1 ? "Hal $_page/" : ""}${_totalPages > 1 ? _totalPages : total}${_totalPages > 1 ? " ($total)" : ""}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _statChip('Baru', '$baru', Colors.red),
              const SizedBox(width: 8),
              _statChip('Diproses', '$diproses', Colors.orange),
              const SizedBox(width: 8),
              _statChip('Selesai', '$selesai', const Color(0xFFB08968)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── FILTERS ────────────────────────────────────────────
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Semua', null, _filterStatus),
                _filterChip('Baru', 'baru', _filterStatus),
                _filterChip('Diproses', 'diproses', _filterStatus),
                _filterChip('Selesai', 'selesai', _filterStatus),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Kategori filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _kategoriChip('Semua', null, _filterKategori),
                _kategoriChip('Perilaku', 'perilaku', _filterKategori),
                _kategoriChip('Kasus', 'kasus', _filterKategori),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? value, String? current) {
    final selected = value == current;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
        selected: selected,
        selectedColor: AppTheme.primary.withValues(alpha: 0.15),
        checkmarkColor: AppTheme.primary,
        onSelected: (_) => _onFilterChanged(
          status: value,
          kategori: _filterKategori,
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _kategoriChip(String label, String? value, String? current) {
    final selected = value == current;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
        selected: selected,
        selectedColor: Colors.deepPurple.withValues(alpha: 0.15),
        checkmarkColor: Colors.deepPurple,
        onSelected: (_) => _onFilterChanged(
          status: _filterStatus,
          kategori: value,
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  // ─── GRID SLIVER (WIDE) ────────────────────────────────
  Widget _buildGridSliver() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.6,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildCard(_items[index]),
          childCount: _items.length,
        ),
      ),
    );
  }

  // ─── LIST SLIVER (NARROW) ──────────────────────────────
  Widget _buildListSliver() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildCard(_items[index]),
          ),
          childCount: _items.length,
        ),
      ),
    );
  }

  // ─── CARD ───────────────────────────────────────────────
  Widget _buildCard(dynamic item) {
    final status = item['status']?.toString() ?? 'baru';
    final kategori = item['kategori']?.toString() ?? '';
    final statusColor = _statusColor(status);
    final statusLabel = _statusLabel(status);
    final kategoriIcon = kategori == 'kasus' ? Icons.gavel : Icons.warning_amber;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetail(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header card
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: kategori == 'kasus'
                          ? Colors.deepPurple.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(kategoriIcon, size: 18,
                        color: kategori == 'kasus' ? Colors.deepPurple : Colors.orange),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['siswa_nama']?.toString() ?? 'Santri',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'NIS: ${item['siswa_nis'] ?? '-'}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statusLabel.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Deskripsi
              Text(
                item['deskripsi']?.toString() ?? '-',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
              const SizedBox(height: 6),
              // Pelapor + kategori + aksi
              Row(
                children: [
                  Icon(Icons.person_outline, size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    item['pelapor_nama']?.toString() ?? '-',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                  ),
                  const Spacer(),
                  if (status == 'baru')
                    _miniAction(Icons.engineering, 'Proses', () => _updateStatus(item['id'], 'diproses'))
                  else if (status == 'diproses')
                    _miniAction(Icons.check, 'Selesai', () => _updateStatus(item['id'], 'selesai')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniAction(IconData icon, String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.primary),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ─── DETAIL DIALOG ──────────────────────────────────────
  void _showDetail(dynamic item) {
    final status = item['status']?.toString() ?? 'baru';
    final kategori = item['kategori']?.toString() ?? '';
    final statusColor = _statusColor(status);
    final statusLabel = _statusLabel(status);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kategori == 'kasus'
                            ? Colors.deepPurple.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        kategori == 'kasus' ? Icons.gavel : Icons.warning_amber,
                        color: kategori == 'kasus' ? Colors.deepPurple : Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kategori == 'kasus' ? 'Kasus' : 'Perilaku',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            item['siswa_nama'] ?? '',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusLabel.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                _detailRow('NIS', item['siswa_nis']?.toString() ?? '-'),
                _detailRow('Pelapor', item['pelapor_nama']?.toString() ?? '-'),
                _detailRow('Status', statusLabel),
                if (item['tindak_lanjut'] != null)
                  _detailRow('Tindak Lanjut', item['tindak_lanjut'].toString()),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade700)),
                      const SizedBox(height: 4),
                      Text(item['deskripsi']?.toString() ?? '-', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (status == 'baru')
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateStatus(item['id'], 'diproses');
                          },
                          icon: const Icon(Icons.engineering, size: 18),
                          label: const Text('Proses'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      )
                    else if (status == 'diproses')
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateStatus(item['id'], 'selesai');
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Selesaikan'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Tutup'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  // ─── HELPERS ────────────────────────────────────────────
  Color _statusColor(String s) {
    switch (s) {
      case 'baru':
        return Colors.red;
      case 'diproses':
        return Colors.orange;
      case 'selesai':
        return const Color(0xFF9C6644);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'baru':
        return 'Baru';
      case 'diproses':
        return 'Diproses';
      case 'selesai':
        return 'Selesai';
      default:
        return s;
    }
  }
}
