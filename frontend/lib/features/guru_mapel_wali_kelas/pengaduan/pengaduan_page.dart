import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import '../../../core/network/api_client.dart';
import '../services/guru_service.dart';

class PengaduanPageGuru extends StatefulWidget {
  const PengaduanPageGuru({super.key});

  @override
  State<PengaduanPageGuru> createState() => _PengaduanPageGuruState();
}

class _PengaduanPageGuruState extends State<PengaduanPageGuru> {
  // ── Form ──
  int? _kelasId, _siswaId;
  String _kategori = 'perilaku';
  final _deskripsiCtl = TextEditingController();
  final _buktiCtl = TextEditingController();

  // ── Data ──
  List<dynamic> _kelasList = [];
  List<dynamic> _siswaList = [];
  List<dynamic> _siswaFiltered = [];
  List<dynamic> _pengaduanList = [];
  String? _filterStatus;
  bool _loading = true, _sending = false;
  int _page = 1, _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/referensi');
      final data = res['data'] as Map<String, dynamic>;
      _kelasList = data['kelas'] as List<dynamic>? ?? [];
      _siswaList = data['siswa'] as List<dynamic>? ?? [];
      await _loadRiwayat();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadRiwayat() async {
    try {
      final p = await GuruService.getPengaduan(page: _page, status: _filterStatus);
      _pengaduanList = p['items'] as List<dynamic>? ?? [];
      final pag = p['pagination'] as Map<String, dynamic>? ?? {};
      _totalPages = pag['total_pages'] as int? ?? 1;
    } catch (_) {
      _pengaduanList = [];
    }
    if (mounted) setState(() {});
  }

  void _onKelasChanged(int? id) {
    setState(() {
      _kelasId = id;
      _siswaId = null;
      if (id != null) {
        _siswaFiltered = _siswaList.where((s) {
          final sKelasId = s['kelas_id'];
          return sKelasId != null && sKelasId == id;
        }).toList();
      } else {
        _siswaFiltered = [];
      }
    });
  }

  Future<void> _kirim() async {
    if (_siswaId == null || _deskripsiCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Lengkapi semua field!'),
        backgroundColor: Colors.red[700], behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16),
      ));
      return;
    }

    setState(() => _sending = true);
    try {
      await GuruService.createPengaduan({
        'siswa_id': _siswaId,
        'kategori': _kategori,
        'deskripsi': _deskripsiCtl.text.trim(),
        'bukti_url': _buktiCtl.text.trim().isNotEmpty ? _buktiCtl.text.trim() : null,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [Icon(Icons.check_circle, color: Colors.white, size: 18), SizedBox(width: 8), Text('Laporan terkirim ke BK')]),
          backgroundColor: const Color(0xFF9C6644), behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16),
        ));
        _deskripsiCtl.clear();
        _buktiCtl.clear();
        _siswaId = null;
        _kelasId = null;
        _siswaFiltered = [];
        _page = 1;
        await _loadRiwayat();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal: $e'), backgroundColor: Colors.red[700], behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16),
        ));
      }
    }
    setState(() => _sending = false);
  }

  @override
  void dispose() {
    _deskripsiCtl.dispose();
    _buktiCtl.dispose();
    super.dispose();
  }

  // ── UI ──
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(children: [
      // Header
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
            Color(0xFFC62828), Color(0xFFD32F2F), Color(0xFFEF5350),
          ]),
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28)),
            const SizedBox(width: 14),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pengaduan Santri', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Laporkan perilaku & kasus ke BK', style: TextStyle(fontSize: 13, color: Colors.white70)),
            ]),
          ]),
        ]),
      ),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // ── FORM ──
          _buildFormCard(),
          const SizedBox(height: 20),
          // ── RIWAYAT ──
          _buildRiwayatSection(),
        ]),
      )),
    ]);
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFFC62828).withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 6))],
        border: Border.all(color: const Color(0xFFC62828).withValues(alpha: 0.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 4, height: 22, decoration: BoxDecoration(color: const Color(0xFFC62828), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          const Text('Laporan Baru', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFC62828))),
        ]),
        const SizedBox(height: 16),

        // Baris 1: Kelas + Santri
        LayoutBuilder(builder: (_, constraints) {
          final isWide = constraints.maxWidth >= 600;
          return Wrap(spacing: 16, runSpacing: 14, children: [
            SizedBox(width: isWide ? 240 : double.infinity, child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Kelas', border: OutlineInputBorder(), prefixIcon: Icon(Icons.school_rounded, size: 20)),
              value: _kelasId,
              items: _kelasList.map((k) => DropdownMenuItem(value: k['id'] as int, child: Text(k['nama']?.toString() ?? ''))).toList(),
              onChanged: _onKelasChanged,
            )),
            SizedBox(width: isWide ? 300 : double.infinity, child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Nama Santri', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_rounded, size: 20)),
              value: _siswaId,
              items: _siswaFiltered.map((s) => DropdownMenuItem(value: s['id'] as int, child: Text('${s['nis']} - ${s['nama']}', overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) => setState(() => _siswaId = v),
            )),
          ]);
        }),
        const SizedBox(height: 14),

        // Baris 2: Kategori
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category_rounded, size: 20)),
          value: _kategori,
          items: const [
            DropdownMenuItem(value: 'perilaku', child: Row(children: [Icon(Icons.warning_rounded, size: 18, color: Colors.orange), SizedBox(width: 8), Text('Perilaku')])),
            DropdownMenuItem(value: 'kasus', child: Row(children: [Icon(Icons.gavel_rounded, size: 18, color: Colors.red), SizedBox(width: 8), Text('Kasus')])),
          ],
          onChanged: (v) => setState(() => _kategori = v!),
        ),
        const SizedBox(height: 14),

        // Baris 3: Deskripsi
        TextField(
          controller: _deskripsiCtl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Deskripsi',
            hintText: 'Jelaskan kronologi kejadian secara detail...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
            prefixIcon: Padding(padding: EdgeInsets.only(bottom: 60), child: Icon(Icons.description_rounded, size: 20)),
          ),
        ),
        const SizedBox(height: 14),

        // Baris 4: URL Bukti
        TextField(
          controller: _buktiCtl,
          decoration: const InputDecoration(
            labelText: 'URL Google Drive / Bukti (opsional)',
            hintText: 'https://drive.google.com/...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.link_rounded, size: 20),
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 20),

        // Tombol Kirim
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: _sending ? null : _kirim,
            icon: _sending
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Icon(Icons.send_rounded, size: 20),
            label: Text(_sending ? 'Mengirim...' : 'Kirim Laporan ke BK',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildRiwayatSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Section title
      Row(children: [
        Container(width: 4, height: 22, decoration: BoxDecoration(color: const Color(0xFFC62828), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        const Text('Riwayat Laporan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFC62828))),
        const Spacer(),
        Text('${_pengaduanList.length} laporan', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ]),
      const SizedBox(height: 12),

      // Filter status
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        _filterChip('Semua', null),
        const SizedBox(width: 8),
        _filterChip('Baru', 'baru'),
        const SizedBox(width: 8),
        _filterChip('Diproses', 'diproses'),
        const SizedBox(width: 8),
        _filterChip('Selesai', 'selesai'),
      ])),
      const SizedBox(height: 12),

      // List riwayat
      if (_pengaduanList.isEmpty)
        Container(
          padding: const EdgeInsets.all(40),
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
          child: Column(children: [
            Icon(Icons.inbox_rounded, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Belum ada laporan', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
            const SizedBox(height: 4),
            Text('Kirim laporan pertama Anda', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          ]),
        )
      else ...[
        ...List.generate(_pengaduanList.length, (i) => _buildRiwayatCard(_pengaduanList[i] as Map<String, dynamic>)),
        if (_totalPages > 1) ...[
          const SizedBox(height: 12),
          Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _page > 1 ? () { setState(() => _page--); _loadRiwayat(); } : null,
              style: IconButton.styleFrom(backgroundColor: Colors.grey[100], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(width: 12),
            Text('Halaman $_page dari $_totalPages', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _page < _totalPages ? () { setState(() => _page++); _loadRiwayat(); } : null,
              style: IconButton.styleFrom(backgroundColor: Colors.grey[100], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
          ])),
        ],
      ],
    ]);
  }

  Widget _filterChip(String label, String? value) {
    final selected = _filterStatus == value;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.grey[700])),
      selected: selected,
      selectedColor: const Color(0xFFC62828),
      backgroundColor: Colors.grey[100],
      checkmarkColor: Colors.white,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: selected ? const Color(0xFFC62828) : Colors.grey[300]!)),
      onSelected: (_) {
        setState(() {
          _filterStatus = value;
          _page = 1;
        });
        _loadRiwayat();
      },
    );
  }

  Widget _buildRiwayatCard(Map<String, dynamic> p) {
    final status = p['status']?.toString() ?? 'baru';
    final isBaru = status == 'baru';
    final isDiproses = status == 'diproses';
    final statusColor = isBaru ? const Color(0xFFC62828) : (isDiproses ? const Color(0xFFEF6C00) : const Color(0xFF9C6644));
    final statusIcon = isBaru ? Icons.fiber_new_rounded : (isDiproses ? Icons.pending_actions_rounded : Icons.check_circle_rounded);
    final statusLabel = isBaru ? 'Belum Diterima' : (isDiproses ? 'Diproses BK' : 'Selesai');
    final tgl = p['created_at']?.toString() ?? '';
    final tglLabel = tgl.length >= 16 ? tgl.substring(0, 16).replaceAll('T', ' ') : tgl;
    final kategori = p['kategori']?.toString() ?? '';
    final isKasus = kategori == 'kasus';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.04),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetailDialog(p),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header card
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(isKasus ? Icons.gavel_rounded : Icons.warning_rounded,
                      color: isKasus ? Colors.deepOrange : Colors.orange, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p['kelas_nama']?.toString() ?? '-', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(p['siswa_nama']?.toString() ?? 'Santri', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ])),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              // Deskripsi
              Text(p['deskripsi']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4)),
              const SizedBox(height: 10),
              // Footer
              Row(children: [
                Icon(Icons.access_time_rounded, size: 13, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(tglLabel, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                const Spacer(),
                Text(isKasus ? 'Kasus' : 'Perilaku', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isKasus ? Colors.deepOrange : Colors.orange)),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> p) {
    final status = p['status']?.toString() ?? 'baru';
    final isBaru = status == 'baru';
    final isDiproses = status == 'diproses';
    final statusColor = isBaru ? const Color(0xFFC62828) : (isDiproses ? const Color(0xFFEF6C00) : const Color(0xFF9C6644));
    final statusLabel = isBaru ? 'Belum Diterima BK' : (isDiproses ? '✓ Diproses BK' : '✓ Selesai');
    final tgl = p['created_at']?.toString() ?? '';
    final tglLabel = tgl.length >= 16 ? tgl.substring(0, 16).replaceAll('T', ' ') : tgl;
    final buktiUrl = p['bukti_url']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(p['kategori'] == 'kasus' ? Icons.gavel_rounded : Icons.warning_rounded, color: Colors.deepOrange, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Detail Pengaduan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.grey[800])),
                  Text('${p['kelas_nama'] ?? '-'} • ${p['siswa_nama'] ?? '-'}', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                ])),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded), style: IconButton.styleFrom(backgroundColor: Colors.grey[100])),
              ]),
              const SizedBox(height: 16),
              // Status
              Container(
                width: double.infinity, padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: statusColor.withValues(alpha: 0.15))),
                child: Row(children: [
                  Icon(status == 'baru' ? Icons.fiber_new_rounded : (status == 'diproses' ? Icons.pending_actions_rounded : Icons.check_circle_rounded), color: statusColor, size: 22),
                  const SizedBox(width: 10),
                  Text(statusLabel, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: statusColor)),
                  const Spacer(),
                  Text(tglLabel, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ]),
              ),
              const SizedBox(height: 16),
              // Deskripsi
              Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 8),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                child: Text(p['deskripsi']?.toString() ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.5)),
              ),
              const SizedBox(height: 16),
              // Kategori
              _detailRow('Kategori', p['kategori']?.toString() == 'kasus' ? 'Kasus' : 'Perilaku'),
              const SizedBox(height: 8),
              _detailRow('NIS Santri', p['siswa_nis']?.toString() ?? '-'),
              const SizedBox(height: 8),
              if (buktiUrl.isNotEmpty) ...[
                _detailRow('URL Bukti', buktiUrl),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: buktiUrl));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Row(children: [Icon(Icons.check_circle, color: Colors.white, size: 18), SizedBox(width: 8), Text('URL bukti disalin ke clipboard')]),
                        backgroundColor: const Color(0xFF9C6644), behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16),
                      ));
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Salin URL Bukti', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1565C0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: const Color(0xFF1565C0).withValues(alpha: 0.3)),
                    ),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500))),
      Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: Colors.grey[800], fontWeight: FontWeight.w500))),
    ]);
  }
}
