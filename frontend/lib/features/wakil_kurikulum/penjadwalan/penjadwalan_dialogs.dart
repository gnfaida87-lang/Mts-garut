part of 'penjadwalan_page.dart';

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â• DATA CLASSES â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _KesiapanRowData {
  final int guruId;
  final String nama;
  final String nip;
  List<String> hariAktif;
  int jpMaxPerHari;
  int jpMaxMinggu;
  final List<Map<String, dynamic>> kelasDiampu;
  final List<Map<String, dynamic>> mapelDiampu;
  final int jpTerisi;

  _KesiapanRowData({
    required this.guruId,
    required this.nama,
    required this.nip,
    required this.hariAktif,
    required this.jpMaxPerHari,
    required this.jpMaxMinggu,
    required this.kelasDiampu,
    required this.mapelDiampu,
    required this.jpTerisi,
  });

  factory _KesiapanRowData.fromJson(Map<String, dynamic> json) {
    List<String> hariAktif = [];
    if (json['hari_aktif'] is String) {
      try {
        final parsed = json['hari_aktif'] as String;
        if (parsed.isNotEmpty && parsed != '[]') {
          hariAktif = (jsonDecode(parsed) as List).cast<String>();
        }
      } catch (_) { debugPrint('[penjadwalan_dialogs.dart] error caught'); }
    } else if (json['hari_aktif'] is List) {
      hariAktif = (json['hari_aktif'] as List).cast<String>();
    }

    List<Map<String, dynamic>> kelasDiampu = [];
    if (json['kelas_diampu'] is String) {
      try {
        final parsed = json['kelas_diampu'] as String;
        if (parsed.isNotEmpty && parsed != '[]') {
          kelasDiampu = (jsonDecode(parsed) as List).cast<Map<String, dynamic>>();
        }
      } catch (_) { debugPrint('[penjadwalan_dialogs.dart] error caught'); }
    } else if (json['kelas_diampu'] is List) {
      kelasDiampu = (json['kelas_diampu'] as List).cast<Map<String, dynamic>>();
    }

    List<Map<String, dynamic>> mapelDiampu = [];
    if (json['mapel_diampu'] is String) {
      try {
        final parsed = json['mapel_diampu'] as String;
        if (parsed.isNotEmpty && parsed != '[]') {
          mapelDiampu = (jsonDecode(parsed) as List).cast<Map<String, dynamic>>();
        }
      } catch (_) { debugPrint('[penjadwalan_dialogs.dart] error caught'); }
    } else if (json['mapel_diampu'] is List) {
      mapelDiampu = (json['mapel_diampu'] as List).cast<Map<String, dynamic>>();
    }

    return _KesiapanRowData(
      guruId: json['id'] as int,
      nama: json['nama']?.toString() ?? '-',
      nip: json['nip']?.toString() ?? '-',
      hariAktif: hariAktif,
      jpMaxPerHari: json['jp_max_per_hari'] as int? ?? 8,
      jpMaxMinggu: json['jp_max_per_minggu'] as int? ?? 24,
      kelasDiampu: kelasDiampu,
      mapelDiampu: mapelDiampu,
      jpTerisi: json['jp_terisi'] as int? ?? 0,
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â• SHARED WIDGETS â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _KelolaKegiatanDialog extends StatefulWidget {
  final List<Map<String, dynamic>> awal;

  const _KelolaKegiatanDialog({required this.awal});

  @override
  State<_KelolaKegiatanDialog> createState() => _KelolaKegiatanDialogState();
}

class _KelolaKegiatanDialogState extends State<_KelolaKegiatanDialog> {
  late final List<Map<String, dynamic>> _items;
  final TextEditingController _namaCtrl = TextEditingController();
  String _tipe = 'kegiatan';
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _items = widget.awal.map((k) => Map<String, dynamic>.from(k)).toList();
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final list = await WakilKurikulumService.getKegiatanTetap();
      if (mounted) setState(() => _items = list.cast<Map<String, dynamic>>());
    } catch (_) { debugPrint('[penjadwalan_dialogs.dart] error caught'); }
  }

  Future<void> _tambah() async {
    final nama = _namaCtrl.text.trim();
    if (nama.isEmpty) {
      setState(() => _error = 'Nama kegiatan tidak boleh kosong');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await WakilKurikulumService.createKegiatanTetap(nama, _tipe);
      _namaCtrl.clear();
      await _refresh();
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal tambah: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _ubah(Map<String, dynamic> item) async {
    final id = int.tryParse('${item['id']}');
    if (id == null) return;
    final hasil = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => _FormKegiatanDialog(
        title: 'Ubah Kegiatan',
        nama: item['nama']?.toString() ?? '',
        tipe: item['tipe']?.toString() == 'istirahat' ? 'istirahat' : 'kegiatan',
      ),
    );
    if (hasil == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await WakilKurikulumService.updateKegiatanTetap(id, hasil['nama']!, hasil['tipe']!);
      await _refresh();
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal ubah: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _hapus(Map<String, dynamic> item) async {
    final id = int.tryParse('${item['id']}');
    if (id == null) return;
    final ok = await AppUtils.confirm(
      context,
      title: 'Hapus Kegiatan',
      message: 'Hapus "${item['nama']}" dari daftar kegiatan tetap?',
    );
    if (!ok) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await WakilKurikulumService.deleteKegiatanTetap(id);
      await _refresh();
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal hapus: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kelola Kegiatan Tetap', style: TextStyle(fontSize: 16)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
              const SizedBox(height: 8),
            ],
            Text(
              'Kegiatan ini bisa di-drag ke tabel jadwal. Drag item yang ada, atau tambah kegiatan baru di bawah.',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 260),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Belum ada kegiatan tetap.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final k = _items[i];
                          final isIstirahat = k['tipe'] == 'istirahat';
                          final nama = k['nama']?.toString() ?? '-';
                          final color = isIstirahat ? Colors.orange : Colors.blue;
                          return ListTile(
                            dense: true,
                            leading: Icon(isIstirahat ? Icons.coffee : Icons.school, size: 18, color: color[700]),
                            title: Text(nama, style: const TextStyle(fontSize: 12.5)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  tooltip: 'Ubah',
                                  onPressed: _loading ? null : () => _ubah(k),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                  tooltip: 'Hapus',
                                  onPressed: _loading ? null : () => _hapus(k),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            const Divider(height: 16),
            Row(
              children: [
                DropdownButton<String>(
                  value: _tipe,
                  isDense: true,
                  items: const [
                    DropdownMenuItem(value: 'kegiatan', child: Text('Kegiatan', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'istirahat', child: Text('Istirahat', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: _loading ? null : (v) => setState(() => _tipe = v!),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _namaCtrl,
                    enabled: !_loading,
                    decoration: const InputDecoration(
                      labelText: 'Nama kegiatan baru',
                      hintText: 'cth: Shalat Dzuhur Berjamaah',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _tambah(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: _loading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add, size: 18),
                  tooltip: 'Tambah',
                  onPressed: _loading ? null : _tambah,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}

class _FormKegiatanDialog extends StatefulWidget {
  final String title;
  final String nama;
  final String tipe;

  const _FormKegiatanDialog({required this.title, this.nama = '', this.tipe = 'kegiatan'});

  @override
  State<_FormKegiatanDialog> createState() => _FormKegiatanDialogState();
}

class _FormKegiatanDialogState extends State<_FormKegiatanDialog> {
  late final TextEditingController _namaCtrl;
  late String _tipe;
  String? _error;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.nama);
    _tipe = widget.tipe;
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    super.dispose();
  }

  void _simpan() {
    final nama = _namaCtrl.text.trim();
    if (nama.isEmpty) {
      setState(() => _error = 'Nama kegiatan tidak boleh kosong');
      return;
    }
    Navigator.pop(context, {'nama': nama, 'tipe': _tipe});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, style: const TextStyle(fontSize: 16)),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _namaCtrl,
              decoration: const InputDecoration(labelText: 'Nama kegiatan', isDense: true),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _tipe,
              isDense: true,
              items: const [
                DropdownMenuItem(value: 'kegiatan', child: Text('Kegiatan')),
                DropdownMenuItem(value: 'istirahat', child: Text('Istirahat')),
              ],
              onChanged: (v) => setState(() => _tipe = v!),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _simpan,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _KelolaGabunganDialog extends StatefulWidget {
  final int semesterId;

  const _KelolaGabunganDialog({required this.semesterId});

  @override
  State<_KelolaGabunganDialog> createState() => _KelolaGabunganDialogState();
}

class _KelolaGabunganDialogState extends State<_KelolaGabunganDialog> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await WakilKurikulumService.getKelasGabungan();
      if (mounted) {
        setState(() {
          _items = list.cast<Map<String, dynamic>>().where((g) => g['semester_id'].toString() == widget.semesterId.toString()).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Gagal memuat: $e';
        });
      }
    }
  }

  Future<void> _tambah() async {
    final hasil = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _FormGabunganDialog(semesterId: widget.semesterId),
    );
    if (hasil == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await WakilKurikulumService.createKelasGabungan(hasil);
      await _refresh();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Gagal tambah: $e';
        });
      }
    }
  }

  Future<void> _ubah(Map<String, dynamic> item) async {
    final id = int.tryParse('${item['id']}');
    if (id == null) return;
    final hasil = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _FormGabunganDialog(
        semesterId: widget.semesterId,
        nama: item['nama']?.toString() ?? '',
        kelasAwal: (item['kelas_ids'] as List?)?.map((e) => int.tryParse('$e') ?? 0).toSet() ?? <int>{},
      ),
    );
    if (hasil == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await WakilKurikulumService.updateKelasGabungan(id, hasil);
      await _refresh();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Gagal ubah: $e';
        });
      }
    }
  }

  Future<void> _hapus(Map<String, dynamic> item) async {
    final id = int.tryParse('${item['id']}');
    if (id == null) return;
    final ok = await AppUtils.confirm(
      context,
      title: 'Hapus Gabungan',
      message: 'Hapus gabungan "${item['nama']}"? Jadwal yang sudah dibuat akan dilepas dari gabungan (tidak dihapus).',
    );
    if (!ok) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await WakilKurikulumService.deleteKelasGabungan(id);
      await _refresh();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Gagal hapus: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kelola Kelas Gabungan', style: TextStyle(fontSize: 16)),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
              const SizedBox(height: 8),
            ],
            Text(
              'Kelas yang digabung dianggap satu sesi: jika dijadwalkan ke salah satu kelas anggotanya, semua kelas terisi sekaligus tanpa bentrok.',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('DAFTAR KELAS GABUNGAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey)),
                const Spacer(),
                Text('${_items.length} gabungan', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 260),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _loading && _items.isEmpty
                    ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 2)))
                    : _items.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Belum ada kelas gabungan untuk semester ini.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _items.length,
                            itemBuilder: (_, i) {
                              final g = _items[i];
                              final ids = (g['kelas_ids'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
                              final kelasNama = g['kelas_nama']?.toString() ?? '';
                              final subtitle = kelasNama.isNotEmpty ? kelasNama : 'Kelas id: ${ids.join(', ')}';
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.group_work, size: 18, color: Colors.indigo),
                                title: Text(g['nama']?.toString() ?? '-', style: const TextStyle(fontSize: 12.5)),
                                subtitle: Text(subtitle, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 16),
                                      tooltip: 'Ubah',
                                      onPressed: _loading ? null : () => _ubah(g),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                      tooltip: 'Hapus',
                                      onPressed: _loading ? null : () => _hapus(g),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ),
            const Divider(height: 16),
            FilledButton.icon(
              onPressed: _loading ? null : _tambah,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Buat Gabungan Baru'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}

class _FormGabunganDialog extends StatefulWidget {
  final int semesterId;
  final String nama;
  final Set<int> kelasAwal;

  const _FormGabunganDialog({required this.semesterId, this.nama = '', this.kelasAwal = const {}});

  @override
  State<_FormGabunganDialog> createState() => _FormGabunganDialogState();
}

class _FormGabunganDialogState extends State<_FormGabunganDialog> {
  late final TextEditingController _namaCtrl;
  late Set<int> _selected;
  List<Map<String, dynamic>> _kelas = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.nama);
    _selected = Set<int>.from(widget.kelasAwal);
    _loadKelas();
  }

  Future<void> _loadKelas() async {
    try {
      final ref = await WakilKurikulumService.getReferensi();
      if (mounted) {
        setState(() {
          _kelas = (ref['kelas'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Gagal memuat daftar kelas: $e';
        });
      }
    }
  }

  void _simpan() {
    final nama = _namaCtrl.text.trim();
    if (nama.isEmpty) {
      setState(() => _error = 'Nama gabungan tidak boleh kosong');
      return;
    }
    if (_selected.length < 2) {
      setState(() => _error = 'Pilih minimal 2 kelas');
      return;
    }
    Navigator.pop(context, {
      'nama': nama,
      'semester_id': widget.semesterId,
      'kelas_ids': _selected.toList()..sort(),
    });
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Buat Gabungan Kelas', style: TextStyle(fontSize: 16)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _namaCtrl,
              decoration: const InputDecoration(labelText: 'Nama gabungan', hintText: 'cth: Gabungan X A+B', isDense: true),
            ),
            const SizedBox(height: 8),
            Text('Pilih kelas anggota (minimal 2):', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            const SizedBox(height: 4),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 240),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(8)),
                child: _loading
                    ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _kelas.length,
                        itemBuilder: (_, i) {
                          final k = _kelas[i];
                          final id = int.tryParse('${k['id']}');
                          if (id == null) return const SizedBox.shrink();
                          final namaKelas = k['nama']?.toString() ?? 'Kelas';
                          return CheckboxListTile(
                            dense: true,
                            value: _selected.contains(id),
                            title: Text(namaKelas, style: const TextStyle(fontSize: 12.5)),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selected.add(id);
                                } else {
                                  _selected.remove(id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _simpan,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _WaktuDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final String? mulai;
  final String? selesai;
  final String note;

  const _WaktuDialog({
    required this.title,
    required this.confirmLabel,
    this.mulai,
    this.selesai,
    required this.note,
  });

  @override
  State<_WaktuDialog> createState() => _WaktuDialogState();
}

class _WaktuDialogState extends State<_WaktuDialog> {
  late final TextEditingController _mulaiCtrl;
  late final TextEditingController _selesaiCtrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mulaiCtrl = TextEditingController(text: widget.mulai ?? '');
    _selesaiCtrl = TextEditingController(text: widget.selesai ?? '');
  }

  @override
  void dispose() {
    _mulaiCtrl.dispose();
    _selesaiCtrl.dispose();
    super.dispose();
  }

  static bool _valid(String t) => RegExp(r'^\d{2}:\d{2}$').hasMatch(t);

  static int _toMin(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  void _simpan() {
    final mulai = _mulaiCtrl.text.trim();
    final selesai = _selesaiCtrl.text.trim();
    if (!_valid(mulai) || !_valid(selesai)) {
      setState(() => _error = 'Format waktu harus HH:MM (contoh: 07:00)');
      return;
    }
    if (_toMin(mulai) >= _toMin(selesai)) {
      setState(() => _error = 'Jam mulai harus lebih awal dari jam selesai');
      return;
    }
    Navigator.pop(context, {'mulai': mulai, 'selesai': selesai});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, style: const TextStyle(fontSize: 16)),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mulaiCtrl,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(labelText: 'Mulai', hintText: '07:00', isDense: true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('â€“', style: TextStyle(fontSize: 16)),
                ),
                Expanded(
                  child: TextField(
                    controller: _selesaiCtrl,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(labelText: 'Selesai', hintText: '07:40', isDense: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(widget.note, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _simpan,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

class _HariCheckboxRow extends StatelessWidget {
  final List<String> nilai;
  final ValueChanged<List<String>> onChanged;
  static const _semuaHari = ['Sabtu', 'Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis'];

  const _HariCheckboxRow({required this.nilai, required this.onChanged});

  String _getHariLabel() {
    if (nilai.isEmpty) return 'Pilih Hari';
    if (nilai.length == _semuaHari.length) return 'Semua Hari';
    final abbr = nilai.map((h) => h.substring(0, 2)).join(', ');
    return abbr;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: InkWell(
        onTap: () async {
          final hasil = await showDialog<List<String>>(
            context: context,
            builder: (ctx) => _HariMultiSelectDialog(
              selectedHari: List.from(nilai),
              semuaHari: _semuaHari,
            ),
          );
          if (hasil != null) onChanged(hasil);
        },
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: const Icon(Icons.arrow_drop_down, size: 20),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _getHariLabel(),
                  style: TextStyle(
                    fontSize: 11,
                    color: nilai.isEmpty ? Colors.grey[500] : Colors.grey[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HariMultiSelectDialog extends StatefulWidget {
  final List<String> selectedHari;
  final List<String> semuaHari;

  const _HariMultiSelectDialog({required this.selectedHari, required this.semuaHari});

  @override
  State<_HariMultiSelectDialog> createState() => _HariMultiSelectDialogState();
}

class _HariMultiSelectDialogState extends State<_HariMultiSelectDialog> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedHari);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Hari Aktif', style: TextStyle(fontSize: 16)),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              value: _selected.length == widget.semuaHari.length,
              onChanged: (v) {
                setState(() {
                  _selected = v == true ? List.from(widget.semuaHari) : [];
                });
              },
              title: const Text('Semua Hari', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 1),
            ...widget.semuaHari.map((hari) {
              final isSelected = _selected.contains(hari);
              return CheckboxListTile(
                value: isSelected,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selected.add(hari);
                    } else {
                      _selected.remove(hari);
                    }
                  });
                },
                title: Text(hari, style: const TextStyle(fontSize: 13)),
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
