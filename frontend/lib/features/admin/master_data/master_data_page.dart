import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/admin_service.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/app_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import 'widgets/master_data_table.dart';
import 'widgets/bulk_upload_dialog.dart';
import 'widgets/form_fields.dart';
import 'widgets/mata_pelajaran_form.dart';
import 'widgets/asatidz_form.dart';
import 'widgets/guru_mapel_kelas_form.dart';
import 'widgets/santri_form.dart';
import 'services/master_data_service.dart';

enum MasterDataType {
  tahunAjaran(
    label: 'Tahun Ajaran',
    resource: 'tahun-ajaran',
    icon: Icons.calendar_month_outlined,
    columns: ['nama', 'is_aktif'],
    displayCols: ['Nama', 'Aktif'],
  ),
  semester(
    label: 'Semester',
    resource: 'semester',
    icon: Icons.layers_outlined,
    columns: ['tahun_ajaran_id', 'nama', 'is_aktif'],
    displayCols: ['Tahun Ajaran', 'Semester', 'Aktif'],
  ),
  jurusan(
    label: 'Jurusan',
    resource: 'jurusan',
    icon: Icons.category_outlined,
    columns: ['nama', 'kode'],
    displayCols: ['Nama', 'Kode'],
  ),
  tingkat(
    label: 'Tingkat',
    resource: 'tingkat',
    icon: Icons.stairs_outlined,
    columns: ['nama', 'jenjang'],
    displayCols: ['Nama', 'Jenjang'],
  ),
  kelas(
    label: 'Kelas',
    resource: 'kelas',
    icon: Icons.meeting_room_outlined,
    columns: ['nama', 'tingkat_id', 'jurusan_id', 'tahun_ajaran_id'],
    displayCols: ['Nama', 'Tingkat', 'Jurusan', 'Tahun Ajaran'],
  ),
  mataPelajaran(
    label: 'Mata Pelajaran',
    resource: 'mata-pelajaran',
    icon: Icons.book_outlined,
    columns: ['nama', 'kode'],
    displayCols: ['Nama', 'Kode'],
    hasTemplate: true,
    templateFileName: 'template_mata_pelajaran.xlsx',
    previewEndpoint: 'mata-pelajaran',
    bulkEndpoint: '/admin/mata-pelajaran/bulk',
    bulkSaveFields: ['nama', 'kode'],
    previewTitle: 'Preview Data Mapel',
    previewWidth: 600,
    previewPrimaryLabel: _mapelPrimaryLabel,
    previewSecondaryLabel: null,
    previewTertiaryLabel: null,
  ),
  asatidz(
    label: 'Asatidz',
    resource: 'guru',
    icon: Icons.people_outline,
    columns: ['nip', 'nama', 'jenis_kelamin', 'jabatan', 'status_aktif'],
    displayCols: ['NIP', 'Nama', 'JK', 'Jabatan', 'Status'],
    hasTemplate: true,
    templateFileName: 'template_guru.xlsx',
    previewEndpoint: 'guru',
    bulkEndpoint: '/admin/guru/bulk',
    bulkSaveFields: ['nip', 'nama', 'jenis_kelamin', 'jabatan', 'status_aktif', 'username', 'password'],
    previewTitle: 'Preview Data Asatidz',
    previewWidth: 700,
    previewPrimaryLabel: _guruPrimaryLabel,
    previewSecondaryLabel: _guruSecondaryLabel,
    previewTertiaryLabel: _guruTertiaryLabel,
  ),
  waliKelas(
    label: 'Wali Kelas',
    resource: 'wali-kelas',
    icon: Icons.supervisor_account_outlined,
    columns: ['nip', 'nama', 'kelas_nama', 'jumlah_siswa', 'jabatan'],
    displayCols: ['NIP', 'Nama Asatidz', 'Kelas', 'Jml Santri', 'Jabatan'],
    isReadonly: true,
  ),
  guruMapelKelas(
    label: 'Guru Mapel Kelas',
    resource: 'guru-mapel-kelas',
    icon: Icons.school_outlined,
    columns: ['guru_nama', 'mapel_nama', 'kelas_nama'],
    displayCols: ['Guru Mapel', 'Mata Pelajaran', 'Kelas'],
    canAdd: false,
  ),
  asatidzBK(
    label: 'Asatidz BK',
    resource: 'guru-bk-list',
    icon: Icons.psychology_outlined,
    columns: ['nip', 'nama', 'jabatan'],
    displayCols: ['NIP', 'Nama Asatidz', 'Jabatan'],
    isReadonly: true,
  ),
  santri(
    label: 'Santri',
    resource: 'siswa',
    icon: Icons.person_outline,
    columns: ['nis', 'nisn', 'nama', 'jenis_kelamin', 'kelas_id', 'username', 'whatsapp', 'status'],
    displayCols: ['NIS', 'NISN', 'Nama', 'JK', 'Kelas', 'Username', 'WA', 'Status'],
    hasTemplate: true,
    hasFilters: true,
    templateFileName: 'template_siswa.xlsx',
    previewEndpoint: 'siswa',
    bulkEndpoint: '/admin/siswa/bulk',
    bulkSaveFields: ['nis', 'nisn', 'nama', 'jenis_kelamin', 'kelas_id', 'tahun_ajaran_id', 'status', 'nama_ayah', 'nama_ibu', 'pekerjaan_ayah', 'pekerjaan_ibu', 'whatsapp'],
    previewTitle: 'Preview Data Santri',
    previewWidth: 800,
    previewPrimaryLabel: _siswaPrimaryLabel,
    previewSecondaryLabel: _siswaSecondaryLabel,
    previewTertiaryLabel: null,
  ),
  ruangan(
    label: 'Ruangan',
    resource: 'ruangan',
    icon: Icons.room_outlined,
    columns: ['nama', 'kapasitas'],
    displayCols: ['Nama', 'Kapasitas'],
  );

  final String label;
  final String resource;
  final IconData icon;
  final List<String> columns;
  final List<String> displayCols;
  final bool isReadonly;
  final bool canAdd;
  final bool hasTemplate;
  final bool hasFilters;
  final String? templateFileName;
  final String? previewEndpoint;
  final String? bulkEndpoint;
  final List<String>? bulkSaveFields;
  final String? previewTitle;
  final double? previewWidth;
  final String Function(Map<String, dynamic>)? previewPrimaryLabel;
  final String Function(Map<String, dynamic>)? previewSecondaryLabel;
  final String Function(Map<String, dynamic>)? previewTertiaryLabel;

  const MasterDataType({
    required this.label,
    required this.resource,
    required this.icon,
    required this.columns,
    required this.displayCols,
    this.isReadonly = false,
    this.canAdd = true,
    this.hasTemplate = false,
    this.hasFilters = false,
    this.templateFileName,
    this.previewEndpoint,
    this.bulkEndpoint,
    this.bulkSaveFields,
    this.previewTitle,
    this.previewWidth,
    this.previewPrimaryLabel,
    this.previewSecondaryLabel,
    this.previewTertiaryLabel,
  });
}

String _mapelPrimaryLabel(Map<String, dynamic> r) {
  final updateTag = r['is_update'] == true ? ' [UPDATE]' : '';
  return 'Nama: ${r['nama']}  |  Kode: ${r['kode'] ?? '-'}$updateTag';
}
String _guruPrimaryLabel(Map<String, dynamic> r) {
  final updateTag = r['is_update'] == true ? ' [UPDATE]' : '';
  return 'NIP: ${r['nip']}  |  ${r['nama']}$updateTag';
}
String _guruSecondaryLabel(Map<String, dynamic> r) => 'JK: ${r['jenis_kelamin']}  |  Jabatan: ${r['jabatan']}  |  Status: ${r['status_aktif'] == 1 ? 'Aktif' : 'Tidak Aktif'}';
String _guruTertiaryLabel(Map<String, dynamic> r) => 'Username: ${r['username']}  |  Password: ${r['password'] ?? ''}';
String _siswaPrimaryLabel(Map<String, dynamic> r) {
  final updateTag = r['is_update'] == true ? ' [UPDATE]' : '';
  return 'NIS: ${r['nis']}  |  ${r['nama']}$updateTag';
}
String _siswaSecondaryLabel(Map<String, dynamic> r) => 'JK: ${r['jenis_kelamin']}  |  Kelas: ${r['kelas_nama']}  |  Status: ${r['status']}';

class MasterDataPage extends StatefulWidget {
  const MasterDataPage({super.key});

  @override
  State<MasterDataPage> createState() => _MasterDataPageState();
}

class _MasterDataPageState extends State<MasterDataPage> {
  MasterDataType _selectedType = MasterDataType.tahunAjaran;

  final _data = <MasterDataType, List<Map<String, dynamic>>>{};
  final _loading = <MasterDataType, bool>{};
  final _page = <MasterDataType, int>{};
  final _totalPages = <MasterDataType, int>{};
  final _error = <MasterDataType, String?>{};
  final _searchCtrl = <MasterDataType, TextEditingController>{};

  String? _filterTingkat;
  String? _filterKelas;
  String? _filterStatus;
  List<Map<String, dynamic>> _tingkatList = [];
  List<Map<String, dynamic>> _kelasList = [];

  @override
  void initState() {
    super.initState();
    for (final type in MasterDataType.values) {
      _data[type] = [];
      _loading[type] = false;
      _page[type] = 1;
      _totalPages[type] = 1;
      _searchCtrl[type] = TextEditingController();
    }
    _load(MasterDataType.tahunAjaran);
    _loadSantriFilters();
  }

  @override
  void dispose() {
    for (final c in _searchCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSantriFilters() async {
    try {
      final tingkatRes = await AdminService.list('tingkat', perPage: 100);
      _tingkatList = (tingkatRes['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      _tingkatList = [];
    }
    try {
      final kelasRes = await AdminService.list('kelas', perPage: 100);
      _kelasList = (kelasRes['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (_) {
      _kelasList = [];
    }
    if (mounted) setState(() {});
  }

  Future<void> _load(MasterDataType type, {bool refresh = false}) async {
    if (refresh) _page[type] = 1;
    setState(() {
      _loading[type] = true;
      _error[type] = null;
    });

    try {
      if (type == MasterDataType.waliKelas) {
        final res = await ApiClient.get('/admin/wali-kelas');
        if (mounted) {
          setState(() {
            _data[type] = (res['data'] as List).cast<Map<String, dynamic>>();
            _totalPages[type] = 1;
            _loading[type] = false;
          });
        }
        return;
      }

      if (type == MasterDataType.asatidzBK) {
        final res = await ApiClient.get('/admin/guru-bk-list');
        if (mounted) {
          setState(() {
            _data[type] = (res['data'] as List).cast<Map<String, dynamic>>();
            _totalPages[type] = 1;
            _loading[type] = false;
          });
        }
        return;
      }

      final filters = <String, String>{};
      if (type == MasterDataType.santri) {
        if (_filterTingkat != null) filters['tingkat_id'] = _filterTingkat!;
        if (_filterKelas != null) filters['kelas_id'] = _filterKelas!;
        if (_filterStatus != null) filters['status'] = _filterStatus!;
      }

      final res = await AdminService.list(
        type.resource,
        page: _page[type]!,
        perPage: 20,
        search: _searchCtrl[type]!.text,
        filters: filters,
      );
      if (mounted) {
        setState(() {
          _data[type] = (res['items'] as List).cast<Map<String, dynamic>>();
          _totalPages[type] = res['pagination']?['total_pages'] ?? 1;
          _loading[type] = false;
        });
      }

      // Load tahun ajaran data if viewing semester (for display)
      if (type == MasterDataType.semester && (_data[MasterDataType.tahunAjaran]?.isEmpty ?? true)) {
        try {
          final taRes = await AdminService.list('tahun-ajaran', page: 1, perPage: 100);
          if (mounted) {
            setState(() {
              _data[MasterDataType.tahunAjaran] = (taRes['items'] as List).cast<Map<String, dynamic>>();
            });
          }
        } catch (_) { debugPrint('[master_data_page.dart] error caught'); }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error[type] = e.toString();
          _loading[type] = false;
        });
      }
    }
  }

  String _displayValue(MasterDataType type, String col, dynamic val, {Map<String, dynamic>? row}) {
    if (val == null) return '-';
    if (col == 'guru_nama' && type == MasterDataType.guruMapelKelas) {
      final nip = row?['guru_nip'];
      return nip != null && nip.toString().isNotEmpty ? '$nip - $val' : val.toString();
    }
    if (col == 'password') return '\u2022\u2022\u2022\u2022\u2022\u2022';
    if (col == 'is_aktif' || col == 'status_aktif') return val == 1 ? 'Ya' : 'Tidak';
    if (col == 'jenis_kelamin') return val == 'L' ? 'Laki-laki' : 'Perempuan';
    if (col == 'tahun_ajaran_id' && type == MasterDataType.semester) {
      final taList = _data[MasterDataType.tahunAjaran] ?? [];
      final ta = taList.cast<Map<String, dynamic>?>().firstWhere(
        (t) => t?['id'] == val,
        orElse: () => null,
      );
      return ta?['nama']?.toString() ?? val.toString();
    }
    if (col == 'kelas_id' && (type == MasterDataType.mataPelajaran || type == MasterDataType.santri)) {
      final kelasList = type == MasterDataType.santri ? _kelasList : (_data[MasterDataType.kelas] ?? []);
      final k = kelasList.cast<Map<String, dynamic>?>().firstWhere(
        (k) => k?['id'] == val,
        orElse: () => null,
      );
      return k?['nama']?.toString() ?? val.toString();
    }
    return val.toString();
  }

  void _showForm(MasterDataType type, {Map<String, dynamic>? edit}) {
    switch (type) {
      case MasterDataType.mataPelajaran:
        showDialog(
          context: context,
          builder: (_) => MataPelajaranForm(editData: edit, onSaved: () => _load(type, refresh: true)),
        );
        break;
      case MasterDataType.asatidz:
        showDialog(
          context: context,
          builder: (_) => AsatidzForm(editData: edit, onSaved: () => _load(type, refresh: true)),
        );
        break;
      case MasterDataType.guruMapelKelas:
        showDialog(
          context: context,
          builder: (_) => GuruMapelKelasForm(editData: edit, onSaved: () => _load(type, refresh: true)),
        );
        break;
      case MasterDataType.santri:
        showDialog(
          context: context,
          builder: (_) => SantriForm(editData: edit, onSaved: () => _load(type, refresh: true)),
        );
        break;
      default:
        _showGenericForm(type, edit: edit);
    }
  }

  Future<void> _showGenericForm(MasterDataType type, {Map<String, dynamic>? edit}) async {
    final formKey = GlobalKey<FormState>();
    final ctrls = <String, TextEditingController>{};
    for (final col in type.columns) {
      ctrls[col] = TextEditingController(text: edit?[col]?.toString() ?? '');
    }

    String? selectedAktif;
    if (type == MasterDataType.tahunAjaran || type == MasterDataType.semester) {
      final val = edit?['is_aktif'];
      selectedAktif = val == 1 ? 'Aktif' : (val == 0 ? 'Tidak Aktif' : null);
    }

    int? yearAwal;
    int? yearAkhir;
    if (type == MasterDataType.tahunAjaran && edit != null && edit['nama'] != null) {
      final parts = edit['nama'].toString().split('-');
      if (parts.length == 2) {
        yearAwal = int.tryParse(parts[0].trim());
        yearAkhir = int.tryParse(parts[1].trim());
      }
    }

    String? selectedNamaSemester;
    if (type == MasterDataType.semester) {
      final val = edit?['nama'];
      selectedNamaSemester = (val == 'Ganjil' || val == 'Genap') ? val : null;
    }

    int? selectedTaId;
    List<Map<String, dynamic>> taList = _data[MasterDataType.tahunAjaran] ?? [];
    if ((type == MasterDataType.semester || type == MasterDataType.kelas) && taList.isEmpty) {
      AdminService.list('tahun-ajaran', page: 1, perPage: 100).then((res) {
        if (mounted) setState(() { _data[MasterDataType.tahunAjaran] = (res['items'] as List).cast<Map<String, dynamic>>(); });
      });
    }
    if ((type == MasterDataType.semester || type == MasterDataType.kelas) && edit != null) {
      selectedTaId = int.tryParse(edit['tahun_ajaran_id']?.toString() ?? '');
    }

    int? selectedTingkatId;
    int? selectedJurusanId;
    List<Map<String, dynamic>> tingkatList = _data[MasterDataType.tingkat] ?? [];
    List<Map<String, dynamic>> jurusanList = _data[MasterDataType.jurusan] ?? [];
    if (type == MasterDataType.kelas) {
      if (tingkatList.isEmpty) {
        AdminService.list('tingkat', page: 1, perPage: 100).then((res) {
          if (mounted) setState(() { _data[MasterDataType.tingkat] = (res['items'] as List).cast<Map<String, dynamic>>(); });
        });
      }
      if (jurusanList.isEmpty) {
        AdminService.list('jurusan', page: 1, perPage: 100).then((res) {
          if (mounted) setState(() { _data[MasterDataType.jurusan] = (res['items'] as List).cast<Map<String, dynamic>>(); });
        });
      }
      if (edit != null) {
        selectedTingkatId = int.tryParse(edit['tingkat_id']?.toString() ?? '');
        selectedJurusanId = int.tryParse(edit['jurusan_id']?.toString() ?? '');
      }
    }

    if (!mounted) return;
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(edit != null ? 'Edit ${type.label}' : 'Tambah ${type.label}'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: _buildGenericFormContent(type, ctx, ctrls, edit,
              selectedAktif: selectedAktif,
              onAktifChanged: (v) => selectedAktif = v,
              yearAwal: yearAwal,
              onYearAwalChanged: (v) => yearAwal = v,
              yearAkhir: yearAkhir,
              onYearAkhirChanged: (v) => yearAkhir = v,
              selectedNamaSemester: selectedNamaSemester,
              onNamaSemesterChanged: (v) => selectedNamaSemester = v,
              selectedTaId: selectedTaId,
              onTaIdChanged: (v) => selectedTaId = v,
              taList: taList,
              selectedTingkatId: selectedTingkatId,
              onTingkatIdChanged: (v) => selectedTingkatId = v,
              tingkatList: tingkatList,
              selectedJurusanId: selectedJurusanId,
              onJurusanIdChanged: (v) => selectedJurusanId = v,
              jurusanList: jurusanList,
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final body = <String, dynamic>{};
              for (final col in type.columns) {
                if (type == MasterDataType.tahunAjaran && col == 'nama') {
                  body[col] = yearAwal != null && yearAkhir != null ? '$yearAwal-$yearAkhir' : '';
                } else if ((type == MasterDataType.tahunAjaran || type == MasterDataType.semester) && col == 'is_aktif') {
                  body[col] = selectedAktif == 'Aktif' ? 1 : 0;
                } else if ((type == MasterDataType.semester || type == MasterDataType.kelas) && col == 'tahun_ajaran_id') {
                  body[col] = selectedTaId;
                } else if (type == MasterDataType.semester && col == 'nama') {
                  body[col] = selectedNamaSemester;
                } else if (type == MasterDataType.kelas && col == 'tingkat_id') {
                  body[col] = selectedTingkatId;
                } else if (type == MasterDataType.kelas && col == 'jurusan_id') {
                  body[col] = selectedJurusanId;
                } else {
                  body[col] = ctrls[col]!.text;
                }
              }
              try {
                if (edit != null) {
                  await AdminService.update(type.resource, edit['id'] as int, body);
                } else {
                  await AdminService.create(type.resource, body);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _load(type, refresh: true);
              } catch (e) {
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Gagal: $e')));
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericFormContent(
    MasterDataType type,
    BuildContext ctx,
    Map<String, TextEditingController> ctrls,
    Map<String, dynamic>? edit, {
    String? selectedAktif,
    ValueChanged<String?>? onAktifChanged,
    int? yearAwal,
    ValueChanged<int?>? onYearAwalChanged,
    int? yearAkhir,
    ValueChanged<int?>? onYearAkhirChanged,
    String? selectedNamaSemester,
    ValueChanged<String?>? onNamaSemesterChanged,
    int? selectedTaId,
    ValueChanged<int?>? onTaIdChanged,
    List<Map<String, dynamic>>? taList,
    int? selectedTingkatId,
    ValueChanged<int?>? onTingkatIdChanged,
    List<Map<String, dynamic>>? tingkatList,
    int? selectedJurusanId,
    ValueChanged<int?>? onJurusanIdChanged,
    List<Map<String, dynamic>>? jurusanList,
  }) {
    if (type == MasterDataType.tahunAjaran) {
      return StatefulBuilder(
        builder: (ctx, setInnerState) => Column(mainAxisSize: MainAxisSize.min, children: [
          FormRow(children: [
            Expanded(
              child: ModernDropdown<int>(
                value: yearAwal,
                label: 'Tahun Awal',
                icon: Icons.calendar_today_outlined,
                items: List.generate(11, (i) => 2020 + i).map((y) => DropdownMenuItem(
                  value: y,
                  child: Text('$y'),
                )).toList(),
                onChanged: (v) {
                  setInnerState(() {
                    onYearAwalChanged?.call(v);
                    yearAwal = v;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ModernDropdown<int>(
                value: yearAkhir,
                label: 'Tahun Akhir',
                icon: Icons.calendar_today_outlined,
                items: List.generate(11, (i) => 2021 + i).map((y) => DropdownMenuItem(
                  value: y,
                  child: Text('$y'),
                )).toList(),
                onChanged: (v) {
                  setInnerState(() {
                    onYearAkhirChanged?.call(v);
                    yearAkhir = v;
                  });
                },
              ),
            ),
          ]),
          const SizedBox(height: 16),
          ModernDropdown<String>(
            value: selectedAktif,
            label: 'Status',
            icon: Icons.toggle_on_outlined,
            items: const [
              DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
              DropdownMenuItem(value: 'Tidak Aktif', child: Text('Tidak Aktif')),
            ],
            onChanged: onAktifChanged,
          ),
        ]),
      );
    }

    if (type == MasterDataType.semester) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        DataCard(
          header: Row(children: [
            Icon(Icons.layers_outlined, size: 20, color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Data Semester', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            ModernDropdown<String>(
              value: selectedNamaSemester,
              label: 'Semester',
              icon: Icons.numbers,
              items: const [
                DropdownMenuItem(value: 'Ganjil', child: Text('Ganjil')),
                DropdownMenuItem(value: 'Genap', child: Text('Genap')),
              ],
              onChanged: onNamaSemesterChanged,
            ),
            const SizedBox(height: 16),
            ModernDropdown<int>(
              value: selectedTaId,
              label: 'Tahun Ajaran',
              icon: Icons.calendar_month_outlined,
              items: (taList ?? []).map((ta) => DropdownMenuItem<int>(
                value: ta['id'] as int,
                child: Text(ta['nama']?.toString() ?? ''),
              )).toList(),
              onChanged: onTaIdChanged,
            ),
            const SizedBox(height: 16),
            ModernDropdown<String>(
              value: selectedAktif,
              label: 'Status',
              icon: Icons.toggle_on_outlined,
              items: const [
                DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                DropdownMenuItem(value: 'Tidak Aktif', child: Text('Tidak Aktif')),
              ],
              onChanged: onAktifChanged,
            ),
          ]),
        ),
      ]);
    }

    if (type == MasterDataType.jurusan) {
      return DataCard(
        header: Row(children: [
          Icon(Icons.category_outlined, size: 20, color: Theme.of(ctx).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Data Jurusan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          ModernField(controller: ctrls['nama']!, label: 'Nama Jurusan', icon: Icons.badge_outlined),
          const SizedBox(height: 16),
          ModernField(controller: ctrls['kode']!, label: 'Kode Jurusan', icon: Icons.code_outlined, hint: 'Contoh: IPA, IPS, AGAMA'),
        ]),
      );
    }

    if (type == MasterDataType.tingkat) {
      // Parse existing jenjang value
      String? selectedJenjang;
      if (edit != null && edit['jenjang'] != null) {
        final val = edit['jenjang'].toString();
        if (['MTs', 'MA/MLN'].contains(val)) {
          selectedJenjang = val;
        }
      }

      return StatefulBuilder(
        builder: (ctx, setInnerState) => DataCard(
          header: Row(children: [
            Icon(Icons.stairs_outlined, size: 20, color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Data Tingkat', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            ModernField(controller: ctrls['nama']!, label: 'Nama Tingkat', icon: Icons.badge_outlined, hint: 'VII, VIII, IX, X, XI, XII'),
            const SizedBox(height: 16),
            ModernDropdown<String>(
              value: selectedJenjang,
              label: 'Jenjang',
              icon: Icons.school_outlined,
              items: const [
                DropdownMenuItem(value: 'MTs', child: Text('MTs')),
                DropdownMenuItem(value: 'MA/MLN', child: Text('MA/MLN')),
              ],
              onChanged: (v) {
                setInnerState(() => selectedJenjang = v);
                ctrls['jenjang']!.text = v ?? '';
              },
            ),
          ]),
        ),
      );
    }

    if (type == MasterDataType.kelas) {
      return DataCard(
        header: Row(children: [
          Icon(Icons.meeting_room_outlined, size: 20, color: Theme.of(ctx).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Data Kelas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          ModernField(controller: ctrls['nama']!, label: 'Nama Kelas', icon: Icons.badge_outlined, hint: 'Contoh: X IPA 1'),
          const SizedBox(height: 16),
          FormRow(children: [
            Expanded(
              child: ModernDropdown<int>(
                value: selectedTingkatId,
                label: 'Tingkat',
                icon: Icons.stairs_outlined,
                items: (tingkatList ?? []).map((t) => DropdownMenuItem<int>(
                  value: t['id'] as int,
                  child: Text(t['nama']?.toString() ?? ''),
                )).toList(),
                onChanged: onTingkatIdChanged,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ModernDropdown<int>(
                value: selectedJurusanId,
                label: 'Jurusan',
                icon: Icons.category_outlined,
                items: (jurusanList ?? []).map((j) => DropdownMenuItem<int>(
                  value: j['id'] as int,
                  child: Text(j['nama']?.toString() ?? ''),
                )).toList(),
                onChanged: onJurusanIdChanged,
              ),
            ),
          ]),
          const SizedBox(height: 16),
          ModernDropdown<int>(
            value: selectedTaId,
            label: 'Tahun Ajaran',
            icon: Icons.calendar_month_outlined,
            items: (taList ?? []).map((ta) => DropdownMenuItem<int>(
              value: ta['id'] as int,
              child: Text(ta['nama']?.toString() ?? ''),
            )).toList(),
            onChanged: onTaIdChanged,
          ),
        ]),
      );
    }

    if (type == MasterDataType.ruangan) {
      return DataCard(
        header: Row(children: [
          Icon(Icons.room_outlined, size: 20, color: Theme.of(ctx).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Data Ruangan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          ModernField(controller: ctrls['nama']!, label: 'Nama Ruangan', icon: Icons.badge_outlined, hint: 'Contoh: Aula, Lab. Komputer, Kelas 1A'),
          const SizedBox(height: 16),
          ModernField(controller: ctrls['kapasitas']!, label: 'Kapasitas', icon: Icons.people_outlined, hint: 'Jumlah maksimal orang'),
        ]),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: [
      for (final col in type.columns)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: ctrls[col],
            decoration: InputDecoration(
              labelText: col == 'nama' ? 'Nama' : col,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
    ]);
  }

  Future<void> _delete(MasterDataType type, int id) async {
    final ok = await AppUtils.confirm(context, title: 'Hapus', message: 'Yakin hapus ${type.label} ini?');
    if (!ok) return;
    try {
      await AdminService.delete(type.resource, id);
      _load(type, refresh: true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _handleUpload(MasterDataType type) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );
      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.first.bytes;
      if (bytes == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membaca file')));
        return;
      }

      final rows = await MasterDataService.previewUpload(
        entity: type.previewEndpoint!,
        fileBytes: bytes,
      );

      if (!mounted) return;

      BulkUploadDialog.show(
        context: context,
        config: BulkUploadConfig(
          title: type.previewTitle!,
          dialogWidth: type.previewWidth ?? 700,
          primaryLabel: type.previewPrimaryLabel!,
          secondaryLabel: type.previewSecondaryLabel,
          tertiaryLabel: type.previewTertiaryLabel,
          saveFields: type.bulkSaveFields!,
          bulkEndpoint: type.bulkEndpoint!,
          onSaved: () => _load(type, refresh: true),
        ),
        rows: rows,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal upload: $e')));
    }
  }

  Future<void> _downloadTemplate(MasterDataType type) async {
    try {
      await MasterDataService.downloadTemplate(
        entity: type.resource,
        fileName: type.templateFileName!,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal download template: $e')));
    }
  }

  // Bobot lebar kolom (flex) & lebar minimum per kolom, kunci: '<tipe>.<kolom>'.
  static const Map<String, int> _colFlex = {
    'tahunAjaran.nama': 2,
    'tahunAjaran.is_aktif': 1,
    'semester.tahun_ajaran_id': 2,
    'semester.nama': 2,
    'semester.is_aktif': 1,
    'jurusan.nama': 3,
    'jurusan.kode': 1,
    'tingkat.nama': 1,
    'tingkat.jenjang': 1,
    'kelas.nama': 2,
    'kelas.tingkat_id': 1,
    'kelas.jurusan_id': 1,
    'kelas.tahun_ajaran_id': 1,
    'mataPelajaran.nama': 3,
    'mataPelajaran.kode': 1,
    'asatidz.nip': 2,
    'asatidz.nama': 4,
    'asatidz.jenis_kelamin': 1,
    'asatidz.jabatan': 2,
    'asatidz.status_aktif': 1,
    'waliKelas.nip': 2,
    'waliKelas.nama': 4,
    'waliKelas.kelas_nama': 1,
    'waliKelas.jumlah_siswa': 1,
    'waliKelas.jabatan': 2,
    'guruMapelKelas.guru_nama': 3,
    'guruMapelKelas.mapel_nama': 3,
    'guruMapelKelas.kelas_nama': 2,
    'asatidzBK.nip': 2,
    'asatidzBK.nama': 4,
    'asatidzBK.jabatan': 2,
    'santri.nis': 1,
    'santri.nisn': 2,
    'santri.nama': 4,
    'santri.jenis_kelamin': 1,
    'santri.kelas_id': 1,
    'santri.username': 2,
    'santri.whatsapp': 2,
    'santri.status': 1,
    'ruangan.nama': 3,
    'ruangan.kapasitas': 1,
  };

  static const Map<String, double> _colMinWidth = {
    'santri.jenis_kelamin': 50.0,
    'santri.nis': 80.0,
    'santri.kelas_id': 85.0,
    'santri.status': 80.0,
    'santri.nisn': 100.0,
    'santri.username': 110.0,
    'santri.whatsapp': 125.0,
    'santri.nama': 180.0,
    'asatidz.jenis_kelamin': 50.0,
    'asatidz.nip': 130.0,
    'asatidz.jabatan': 120.0,
    'asatidz.nama': 180.0,
    'asatidz.status_aktif': 90.0,
    'mataPelajaran.kode': 80.0,
    'mataPelajaran.nama': 170.0,
    'jurusan.kode': 80.0,
    'jurusan.nama': 150.0,
    'kelas.nama': 120.0,
    'kelas.tingkat_id': 95.0,
    'kelas.jurusan_id': 105.0,
    'kelas.tahun_ajaran_id': 115.0,
    'waliKelas.kelas_nama': 90.0,
    'waliKelas.jumlah_siswa': 80.0,
    'waliKelas.jabatan': 110.0,
    'guruMapelKelas.kelas_nama': 100.0,
    'ruangan.kapasitas': 90.0,
    'semester.is_aktif': 80.0,
    'tahunAjaran.is_aktif': 80.0,
  };

  List<MasterDataTableColumn> _buildTableColumns(MasterDataType type) {
    return List.generate(type.columns.length, (i) {
      final colKey = '${type.name}.${type.columns[i]}';
      return MasterDataTableColumn(
        key: type.columns[i],
        label: type.displayCols[i],
        flex: _colFlex[colKey] ?? 1,
        minWidth: _colMinWidth[colKey] ?? MasterDataTable.defaultMinColWidth,
        displayFn: (val, row) => _displayValue(type, type.columns[i], val, row: row),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Master Data'), automaticallyImplyLeading: false),
      body: Row(children: [
        _buildSidebar(),
        const VerticalDivider(width: 1),
        Expanded(child: _buildContent()),
      ]),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      decoration: const BoxDecoration(color: AppTheme.grey50, border: Border(right: BorderSide(color: AppTheme.grey200))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Menu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.grey500)),
        ),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 8),
          itemCount: MasterDataType.values.length,
          itemBuilder: (_, i) {
            final type = MasterDataType.values[i];
            final isActive = _selectedType == type;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primary.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                dense: true,
                leading: Icon(type.icon, size: 20, color: isActive ? AppTheme.primary : AppTheme.grey500),
                title: Text(type.label, style: TextStyle(fontSize: 13, fontWeight: isActive ? FontWeight.w600 : null, color: isActive ? null : AppTheme.grey600)),
                selected: isActive,
                onTap: () {
                  setState(() => _selectedType = type);
                  if (_data[type]!.isEmpty && _loading[type] == false) _load(type);
                },
              ),
            );
          },
        )),
      ]),
    );
  }

  Widget _buildContent() {
    final type = _selectedType;
    final totalData = _data[type]?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Baris 1: Judul + Tombol Tambah
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(type.label, style: Theme.of(context).textTheme.titleLarge),
            if (totalData > 0) Text('$totalData data', style: const TextStyle(fontSize: 12, color: AppTheme.grey500)),
          ]),
          if (!type.isReadonly && type.canAdd)
            FilledButton.icon(
              onPressed: () => _showForm(type),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            ),
        ]),
        // Baris 2: Filter, Search, Template, Upload
        if (!type.isReadonly) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (type.hasTemplate) ...[
                OutlinedButton.icon(
                  onPressed: () => _downloadTemplate(type),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Template'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                ),
                OutlinedButton.icon(
                  onPressed: () => _handleUpload(type),
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Upload Excel'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                ),
              ],
              if (type.hasFilters) ...[
                _buildFilterTingkat(),
                _buildFilterKelas(),
                _buildFilterStatus(),
                _buildFilterReset(),
              ],
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _searchCtrl[type],
                  decoration: _searchDeco(),
                  onSubmitted: (_) => _load(type, refresh: true),
                ),
              ),
            ],
          ),
        ],
        if (type.isReadonly) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: 280,
            child: TextField(
              controller: _searchCtrl[type],
              decoration: _searchDeco().copyWith(hintText: 'Cari nama atau NIP...'),
              onSubmitted: (_) => _load(type, refresh: true),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Expanded(child: _buildTable(type)),
      ]),
    );
  }

  Widget _buildFilterTingkat() {
    return SizedBox(
      width: 160,
      child: ModernDropdown<String>(
        value: _filterTingkat,
        label: 'Tingkat',
        icon: Icons.stairs_outlined,
        items: [
          const DropdownMenuItem<String>(value: null, child: Text('Semua')),
          ..._tingkatList.map((t) => DropdownMenuItem(
            value: '${t['id']}',
            child: Text('${t['nama']}', style: const TextStyle(fontSize: 13)),
          )),
        ],
        onChanged: (v) {
          setState(() {
            _filterTingkat = v;
            _filterKelas = null;
          });
          _load(MasterDataType.santri, refresh: true);
        },
      ),
    );
  }

  Widget _buildFilterKelas() {
    return SizedBox(
      width: 180,
      child: ModernDropdown<String>(
        value: _filterKelas,
        label: 'Kelas',
        icon: Icons.meeting_room_outlined,
        items: [
          const DropdownMenuItem<String>(value: null, child: Text('Semua')),
          ..._kelasList.where((k) {
            if (_filterTingkat == null) return true;
            return k['tingkat_id'].toString() == _filterTingkat;
          }).map((k) => DropdownMenuItem(
            value: '${k['id']}',
            child: Text('${k['nama']}', style: const TextStyle(fontSize: 13)),
          )),
        ],
        onChanged: (v) {
          setState(() => _filterKelas = v);
          _load(MasterDataType.santri, refresh: true);
        },
      ),
    );
  }

  Widget _buildFilterStatus() {
    return SizedBox(
      width: 140,
      child: ModernDropdown<String>(
        value: _filterStatus,
        label: 'Status',
        icon: Icons.info_outline,
        items: [
          const DropdownMenuItem<String>(value: null, child: Text('Semua')),
          const DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
          const DropdownMenuItem(value: 'lulus', child: Text('Lulus')),
          const DropdownMenuItem(value: 'keluar', child: Text('Keluar')),
          const DropdownMenuItem(value: 'pindah', child: Text('Pindah')),
        ],
        onChanged: (v) {
          setState(() => _filterStatus = v);
          _load(MasterDataType.santri, refresh: true);
        },
      ),
    );
  }

  Widget _buildFilterReset() {
    final hasFilter = _filterTingkat != null || _filterKelas != null || _filterStatus != null;
    if (!hasFilter) return const SizedBox.shrink();
    return ActionChip(
      avatar: const Icon(Icons.close, size: 16, color: AppTheme.error),
      label: const Text('Reset', style: TextStyle(fontSize: 12, color: AppTheme.error)),
      onPressed: () {
        setState(() {
          _filterTingkat = null;
          _filterKelas = null;
          _filterStatus = null;
        });
        _load(MasterDataType.santri, refresh: true);
      },
      backgroundColor: AppTheme.redLight,
      side: BorderSide(color: AppTheme.error.withValues(alpha: 0.3)),
    );
  }

  Widget _buildTable(MasterDataType type) {
    final columns = _buildTableColumns(type);

    return MasterDataTable(
      columns: columns,
      data: _data[type]!,
      showActions: !type.isReadonly,
      isLoading: _loading[type]!,
      error: _error[type],
      currentPage: _page[type]!,
      totalPages: _totalPages[type]!,
      onPrevious: _page[type]! > 1
          ? () {
              _page[type] = _page[type]! - 1;
              _load(type);
            }
          : null,
      onNext: _page[type]! < _totalPages[type]!
          ? () {
              _page[type] = _page[type]! + 1;
              _load(type);
            }
          : null,
      onEdit: type.isReadonly ? null : (row) => _showForm(type, edit: row),
      onDelete: type.isReadonly ? null : (row) => _delete(type, row['id'] as int),
    );
  }

  InputDecoration _searchDeco() {
    return const InputDecoration(
      hintText: 'Cari...',
      prefixIcon: Icon(Icons.search, size: 20),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
